import 'package:flutter/material.dart';
import 'akor.dart';
import 'durum.dart';
import 'ortak.dart';
import 'tema.dart';

// Ton seçimi ve o tonun akor çipleri.
class TonKarti extends StatelessWidget {
  final StudyoDurumu d;
  const TonKarti(this.d, {super.key});

  Widget _tonSecici() {
    const dogal = [0, 2, 4, 5, 7, 9, 11];
    const diyezli = [1, 3, null, 6, 8, 10, null];

    Widget kutu(int? i) {
      if (i == null) return const Expanded(child: SizedBox());
      final secildi = d.ton == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => d.tonSec(i),
          child: Container(
            height: 34,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secildi ? renkYaprak : renkKum,
              border: Border.all(
                color: secildi ? renkToprak : renkKenar,
                width: secildi ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              globalIsimler[i],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: secildi ? Colors.white : renkToprak,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [for (final i in dogal) kutu(i)]),
        Row(children: [for (final i in diyezli) kutu(i)]),
      ],
    );
  }

  Widget _akorChip(Akor a) {
    final renk = akorRengi(a);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          a.adi,
          style:
              const TextStyle(fontWeight: FontWeight.w800, color: renkToprak),
        ),
        backgroundColor: Color.lerp(renkKrem, renk, 0.4)!,
        side: BorderSide(color: renk, width: 1.5),
        visualDensity: VisualDensity.compact,
        onPressed: () => d.akorYerlestir(a),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        return KartKabugu(
          baslik: 'Ton ve Akorlar',
          ikon: Icons.queue_music,
          acik: true,
          cocuklar: [
            altBaslik('Ton:'),
            const SizedBox(height: 4),
            _tonSecici(),
            const SizedBox(height: 10),
            altBaslik('${globalIsimler[d.ton]} tonunun akorları:'),
            const SizedBox(height: 2),
            yatayStrip([
              for (final t in akorTurleri) _akorChip(Akor(d.ton, t.kod)),
            ]),
          ],
        );
      },
    );
  }
}
