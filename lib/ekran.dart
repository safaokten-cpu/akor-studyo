import 'package:flutter/material.dart';
import 'akor.dart';
import 'durum.dart';
import 'loop.dart';
import 'ortak.dart';
import 'sounds.dart';
import 'tablo.dart';
import 'tema.dart';
import 'ton.dart';

// Ana ekran: sadece parçaları alt alta dizer. Asıl iş diğer dosyalarda.
class AkorEkrani extends StatefulWidget {
  const AkorEkrani({super.key});

  @override
  State<AkorEkrani> createState() => _AkorEkraniState();
}

class _AkorEkraniState extends State<AkorEkrani> {
  final StudyoDurumu d = StudyoDurumu();

  @override
  void dispose() {
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [renkGok, renkCayir],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              UstBaslik(d),
              TabloKarti(d),
              TonKarti(d),
              LoopKarti(d),
              SoundsKarti(d),
            ],
          ),
        ),
      ),
    );
  }
}

class UstBaslik extends StatelessWidget {
  final StudyoDurumu d;
  const UstBaslik(this.d, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Row(
            children: [
              const Icon(Icons.eco, color: renkYaprak, size: 22),
              const SizedBox(width: 6),
              const Text(
                'Akor Stüdyo',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: renkToprak),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        pilli(Icons.music_note, globalIsimler[d.ton]),
                        pilli(Icons.av_timer, d.olcu.ad),
                        pilli(Icons.speed, '${d.tempo} BPM'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
