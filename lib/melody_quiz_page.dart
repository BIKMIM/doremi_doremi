import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_sheet_music/simple_sheet_music.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol.dart';
import 'piano_keyboard.dart';
import 'note_player.dart';
import 'melody_loader.dart';

class MelodyQuizPage extends StatefulWidget {
  const MelodyQuizPage({super.key});

  @override
  State<MelodyQuizPage> createState() => _MelodyQuizPageState();
}

class _MelodyQuizPageState extends State<MelodyQuizPage> with NotePlayerMixin {
  List<List<List<MusicalSymbol>>> _melodyLibrary = [];
  List<List<MusicalSymbol>> _currentMelody = [];
  List<Measure> _measures = [];

  int _correctCount = 0;
  int _wrongCount = 0;
  int _expectedNoteCount = 0;
  bool _isQuizActive = true;

  List<Pitch> _userInputs = [];
  List<Color> _noteColors = [];
  String? _activeKey;

  @override
  void initState() {
    super.initState();
    preloadNotes();
    loadMelodies().then((loaded) {
      setState(() {
        _melodyLibrary = loaded;
      });
      _generateNewMelody();
    });
  }

  void _generateNewMelody() {
    final random = Random();
    _currentMelody = _melodyLibrary[random.nextInt(_melodyLibrary.length)];
    _expectedNoteCount = _currentMelody.expand((chord) => chord.whereType<Note>()).length;
    _noteColors = List.generate(_expectedNoteCount, (_) => Colors.black);
    _userInputs.clear();
    _isQuizActive = true;
    _buildMeasures();
    setState(() {});
  }

  void _buildMeasures() {
    _measures = [];
    int playedIndex = 0;

    for (int i = 0; i < _currentMelody.length; i += 4) {
      final symbols = <MusicalSymbol>[];
      if (i == 0) symbols.add(const Clef.treble());

      for (int j = i; j < i + 4 && j < _currentMelody.length; j++) {
        final chord = _currentMelody[j];

        for (final symbol in chord) {
          if (symbol is Note) {
            final color = playedIndex < _noteColors.length ? _noteColors[playedIndex] : Colors.black;
            symbols.add(Note(symbol.pitch, noteDuration: symbol.noteDuration, color: color));
            playedIndex++;
          } else {
            symbols.add(symbol);
          }
        }
      }

      _measures.add(Measure(symbols));
    }
  }

  void _onKeyPressed(Pitch pitch, [Accidental? accidental]) async {
    if (!_isQuizActive) return;
    await playPitchSound(pitch, accidental);

    final correctNotes = _currentMelody.expand((chord) => chord.whereType<Note>().map((n) => n.pitch)).toList();
    if (_userInputs.length >= _expectedNoteCount) return;

    _userInputs.add(pitch);
    final index = _userInputs.length - 1;
    final isCorrect = index < correctNotes.length && pitch == correctNotes[index];
    _noteColors[index] = isCorrect ? Colors.green : Colors.red;

    if (!isCorrect) {
      _wrongCount++;
      _isQuizActive = false;
      setState(() => _buildMeasures());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 틀렸습니다!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), _generateNewMelody);
      return;
    }

    if (_userInputs.length == _expectedNoteCount) {
      _correctCount++;
      _isQuizActive = false;
      setState(() => _buildMeasures());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 정답!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), _generateNewMelody);
    } else {
      setState(() => _buildMeasures());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SimpleSheetMusic(
                    width: size.width * 0.9,
                    height: size.height * 0.4,
                    measures: _measures,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('정답: $_correctCount / 오답: $_wrongCount'),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _generateNewMelody,
                              child: const Text("다른 멜로디"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                if (_currentMelody.isNotEmpty) {
                                  final melodyPitches = _currentMelody
                                      .map((chord) => chord
                                      .whereType<Note>()
                                      .map((n) => n.pitch)
                                      .toList())
                                      .toList();
                                  await playMelody(melodyPitches);
                                }
                              },
                              child: const Text("힌트 🎵"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          PianoKeyboard(
            activeKey: _activeKey,
            onKeyPressed: _onKeyPressed,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}