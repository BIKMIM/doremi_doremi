import 'package:flutter/services.dart';
import 'package:simple_sheet_music/simple_sheet_music.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol.dart';


Future<List<List<List<MusicalSymbol>>>> loadMelodies() async {
  final raw = await rootBundle.loadString('assets/melodies.txt');
  final blocks = raw.split('---');
  final List<List<List<MusicalSymbol>>> melodies = [];

  for (var block in blocks) {
    final lines = block.trim().split('\n');
    final melody = <List<MusicalSymbol>>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final tokens = trimmed.split('+');
      final chord = <MusicalSymbol>[];

      for (var token in tokens) {
        final parts = token.trim().toLowerCase().split(':');
        final raw = parts[0];
        final durationCode = (parts.length > 1) ? parts[1] : 'q';

        final duration = switch (durationCode) {
          'w' => NoteDuration.whole, //온음표
          'h' => NoteDuration.half, //2분음표
          'q' => NoteDuration.quarter, //4분음표
          'e' => NoteDuration.eighth, //8분음표
          's' => NoteDuration.sixteenth, // 16분음표 추가
          _ => NoteDuration.quarter,
        };

        if (raw == 'rest') {
          final rest = switch (duration) {
            NoteDuration.whole => const Rest(RestType.whole),
            NoteDuration.half => const Rest(RestType.half),
            NoteDuration.quarter => const Rest(RestType.quarter),
            NoteDuration.eighth => const Rest(RestType.eighth),
            NoteDuration.sixteenth => const Rest(RestType.sixteenth), // 16분쉼 추가
            _ => const Rest(RestType.quarter),
          };
          chord.add(rest);
        } else {
          try {
            final pitchName = raw.replaceAll('#', 'Sharp');
            final pitch = Pitch.values.firstWhere((p) => p.name.toLowerCase() == pitchName);
            chord.add(Note(pitch, noteDuration: duration));
          } catch (_) {
            debugPrint('⚠️ 잘못된 음표: $raw');
          }
        }
      }

      if (chord.isNotEmpty) {
        melody.add(chord);
      }
    }

    if (melody.isNotEmpty) {
      melodies.add(melody);
    }
  }

  return melodies;
}
