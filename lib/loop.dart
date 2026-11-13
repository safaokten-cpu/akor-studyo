import 'package:flutter/material.dart';
import 'akor.dart';
import 'durum.dart';
import 'kalip.dart';
import 'ortak.dart';
import 'tema.dart';

// Loop Page: ölçü, tempo ve çalan parçalar.
class LoopKarti extends StatelessWidget {
  final StudyoDurumu d;
  const LoopKarti(this.d, {super.key});

  Widget _parcaSatiri(BuildContext context, int p) {
    final parca = d.parcalar[p];
    final olcudeVar = parca.kalip.olcuVar(d.olcu.ad);
    final renk = ensRenk(parca.kalip.enstruman);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk, width: 1.5),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => d.parcaSessizDegistir(parca),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            icon: Icon(
              parca.sessiz ? Icons.volume_off : ensIkon(parca.kalip.enstruman),
              color: parca.sessiz ? renkToprakAcik : renk,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parca.kalip.etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                if (!olcudeVar)
                  Text(
                    '${d.olcu.ad} ölçüsünde yok, çalmaz',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFFB3472B)),
                  ),
                kucukSlider(
                  context,
                  value: parca.ses,
                  min: 0,
                  max: 1,
                  onChanged: (v) => d.parcaSesAyarla(parca, v),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => d.parcaSil(p),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _icerik(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        yatayStrip([
          for (final o in olculer)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: secChip(o.ad, d.olcu.ad == o.ad, () => d.olcuSec(o)),
            ),
        ]),
        Row(
          children: [
            kucukIkon(Icons.remove_circle_outline,
                () => d.tempoAyarla(d.tempo - 5)),
            Expanded(
              child: kucukSlider(
                context,
                min: 60,
                max: 180,
                divisions: 120,
                value: d.tempo.toDouble(),
                onChanged: (v) => d.tempoAyarla(v.round()),
              ),
            ),
            kucukIkon(
                Icons.add_circle_outline, () => d.tempoAyarla(d.tempo + 5)),
            SizedBox(
              width: 62,
              child: Text(
                '${d.tempo} BPM',
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        if (d.parcalar.isEmpty)
          const Padding(
            padding: EdgeInsets.all(6),
            child: Text('Parça yok. Sounds menüsünden parça ekle.',
                style: TextStyle(fontSize: 12)),
          ),
        for (int p = 0; p < d.parcalar.length; p++) _parcaSatiri(context, p),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        return KartKabugu(
          baslik: 'Loop Page',
          ikon: Icons.loop,
          cocuklar: [_icerik(context)],
        );
      },
    );
  }
}
