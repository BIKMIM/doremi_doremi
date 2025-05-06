// 🎵 note_player.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_sheet_music/simple_sheet_music.dart';

/// ✅ 음 재생 전용 기능 모음 (Mixin)
/// - preloadNotes(): 미리 음원 로딩 (반응성 향상)
/// - playPitchSound(): 단일 음 재생
/// - playMelody(): 화음을 포함한 멜로디 재생
mixin NotePlayerMixin {
  // 🎹 미리 준비된 음표 이름들
  static const validFiles = <String>{
    'a2', 'a2s', 'b2',
    'c3', 'c3s', 'd3', 'd3s', 'e3', 'f3', 'f3s', 'g3', 'g3s', 'a3', 'a3s', 'b3',
    'c4', 'c4s', 'd4', 'd4s', 'e4', 'f4', 'f4s', 'g4', 'g4s', 'a4', 'a4s', 'b4',
    'c5', 'c5s', 'd5', 'd5s', 'e5', 'f5', 'f5s', 'g5',
  };

  // 🧠 파일 이름 → ByteData 캐시
  final Map<String, Uint8List> _audioCache = {};

  // 🔁 재사용 가능한 AudioPlayer 풀
  final List<AudioPlayer> _playerPool = List.generate(12, (_) => AudioPlayer());
  int _poolIndex = 0;

  /// ✅ 앱 시작 시 음원 파일을 메모리에 미리 로딩
  Future<void> preloadNotes() async {
    for (final name in validFiles) {
      try {
        final bytes = await AudioCache.instance.loadAsBytes('audio/$name.mp3');
        _audioCache[name] = bytes;
      } catch (e) {
        debugPrint('⚠️ $name 로딩 실패: $e');
      }
    }
  }

  /// ✅ 단일 음 재생
  Future<void> playPitchSound(Pitch pitch, [Accidental? accidental]) async {
    String noteName = pitch.name.toLowerCase();
    if (noteName.contains('#')) {
      noteName = noteName.replaceAll('#', '') + 's'; // 예: "c#4" → "c4s"
    }

    final bytes = _audioCache[noteName];
    if (bytes == null) {
      debugPrint('⛔ 캐시에 없는 음: $noteName');
      return;
    }

    final player = _playerPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _playerPool.length;

    try {
      await player.stop(); // 혹시 이전 소리 재생 중일 경우 대비
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(BytesSource(bytes), volume: 1.0);
    } catch (e) {
      debugPrint('🎵 재생 실패 ($noteName): $e');
    }
  }

  /// ✅ 멜로디(화음 포함) 연주
  Future<void> playMelody(List<List<Pitch>> melody) async {
    for (final chord in melody) {
      final tasks = <Future<void>>[];
      for (final pitch in chord) {
        tasks.add(playPitchSound(pitch));
      }

      await Future.wait(tasks);
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }
}
