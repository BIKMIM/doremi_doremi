import 'package:flutter/material.dart';
import 'package:simple_sheet_music/simple_sheet_music.dart';

// ✅ 화면 하단의 피아노 건반 UI
// - 사용자 입력을 받는 피아노 인터페이스
// - 누른 키를 MelodyQuizPage 쪽으로 전달함 (onKeyPressed)


typedef OnKeyPressed = void Function(Pitch pitch, [Accidental? accidental]);

class PianoKeyboard extends StatelessWidget {
  final String? activeKey;
  final OnKeyPressed onKeyPressed;

  const PianoKeyboard({
    super.key,
    required this.activeKey,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    const whiteKeyWidth = 52.0;
    const blackKeyWidth = 30.0;

    final whiteKeys = [
      {'note': 'C4', 'pitch': Pitch.c4},
      {'note': 'D4', 'pitch': Pitch.d4},
      {'note': 'E4', 'pitch': Pitch.e4},
      {'note': 'F4', 'pitch': Pitch.f4},
      {'note': 'G4', 'pitch': Pitch.g4},
      {'note': 'A4', 'pitch': Pitch.a4},
      {'note': 'B4', 'pitch': Pitch.b4},
      {'note': 'C5', 'pitch': Pitch.c5},
      {'note': 'D5', 'pitch': Pitch.d5},
      {'note': 'E5', 'pitch': Pitch.e5},
    ];

    final blackKeyDefs = [
      {'left': 'C4', 'right': 'D4', 'pitch': Pitch.c4, 'accidental': Accidental.sharp},
      {'left': 'D4', 'right': 'E4', 'pitch': Pitch.d4, 'accidental': Accidental.sharp},
      {'left': 'F4', 'right': 'G4', 'pitch': Pitch.f4, 'accidental': Accidental.sharp},
      {'left': 'G4', 'right': 'A4', 'pitch': Pitch.g4, 'accidental': Accidental.sharp},
      {'left': 'A4', 'right': 'B4', 'pitch': Pitch.a4, 'accidental': Accidental.sharp},
      {'left': 'C5', 'right': 'D5', 'pitch': Pitch.c5, 'accidental': Accidental.sharp},
      {'left': 'D5', 'right': 'E5', 'pitch': Pitch.d5, 'accidental': Accidental.sharp},
    ];

    final whiteNoteIndex = {
      for (int i = 0; i < whiteKeys.length; i++) whiteKeys[i]['note']: i
    };

    final blackKeyWidgets = blackKeyDefs.map((bk) {
      final li = whiteNoteIndex[bk['left']]!;
      final ri = whiteNoteIndex[bk['right']]!;
      final center = ((li + ri + 1) / 2) * whiteKeyWidth;
      final noteName = (bk['pitch'] as Pitch).name.toUpperCase()[0] + 'S4';

      return Positioned(
        left: center - blackKeyWidth / 2,
        child: GestureDetector(
          onTapDown: (_) => onKeyPressed(bk['pitch'] as Pitch, bk['accidental'] as Accidental),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: blackKeyWidth,
            height: 100.0,
            decoration: BoxDecoration(
              color: activeKey == noteName ? Colors.grey[800] : Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }).toList();

    return Center(
      child: SizedBox(
        height: 160,
        width: whiteKeyWidth * whiteKeys.length,
        child: Stack(
          children: [
            Row(
              children: whiteKeys.map((key) {
                final noteName = key['note'] as String;
                return GestureDetector(
                  onTapDown: (_) => onKeyPressed(key['pitch'] as Pitch),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: whiteKeyWidth,
                    height: 160,
                    decoration: BoxDecoration(
                      color: activeKey == noteName ? Colors.grey[300] : Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(noteName, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
            ...blackKeyWidgets,
          ],
        ),
      ),
    );
  }
}
