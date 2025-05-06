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

  String? _topMessage; // ✅ 상단 메시지 저장
  Color _topMessageColor = Colors.transparent;
  double _topMessageOpacity = 0;

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

  void _showTopMessage(String text, Color color) {
    setState(() {
      _topMessage = text;
      _topMessageColor = color;
      _topMessageOpacity = 1;
    });

    // 2초 뒤에 메시지 숨기기
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _topMessageOpacity = 0;
      });
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

      _showTopMessage('❌ 틀렸습니다!', Colors.red); // ✅ 상단에 메시지 표시
      Future.delayed(const Duration(seconds: 2), _generateNewMelody);
      return;
    }

    if (_userInputs.length == _expectedNoteCount) {
      _correctCount++;
      _isQuizActive = false;
      setState(() => _buildMeasures());

      _showTopMessage('🎉 정답!', Colors.green); // ✅ 정답 메시지 상단에 표시
      Future.delayed(const Duration(seconds: 2), _generateNewMelody);
    } else {
      setState(() => _buildMeasures());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 🔼 악보 및 정보 영역
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
              // 🎹 피아노 건반
              PianoKeyboard(
                activeKey: _activeKey,
                onKeyPressed: _onKeyPressed,
              ),
              const SizedBox(height: 10),
            ],
          ),
          // ✅ 상단 메시지 오버레이
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _topMessageOpacity,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _topMessageColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _topMessage ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
