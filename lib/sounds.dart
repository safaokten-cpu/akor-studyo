import 'package:flutter/material.dart';
import 'akor.dart';
import 'durum.dart';
import 'kalip.dart';
import 'katalog.dart';
import 'ortak.dart';
import 'tema.dart';

// Sounds: enstrüman, tür, tarz ve kalıp seçip parçalara ekleme.
class SoundsKarti extends StatelessWidget {
  final StudyoDurumu d;
  const SoundsKarti(this.d, {super.key});

  Widget _icerik() {
    final filtre = kaliplar
        .where((k) =>
            k.enstruman == d.secEns &&
            k.olcuVar(d.olcu.ad) &&
            (d.secTarz == 'Tümü' || k.tarz == d.secTarz))
        .toList();
    final gecerli = filtre.contains(d.secKalip)
        ? d.secKalip
        : (filtre.isNotEmpty ? filtre.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        altBaslik('Enstrüman:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final e in enstrumanAdlari.entries)
              secChip(
                e.value,
                d.secEns == e.key,
                () => d.enstrumanSec(e.key),
                avatar: Icon(ensIkon(e.key), size: 16),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Tür: sadece birden fazla türü olan enstrümanda görünür (şimdilik gitar).
        if (turSecimiVar(d.secEns)) ...[
          altBaslik('Tür:'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              for (final t in gitarTurleri)
                secChip(
                  d.yukleniyorMu(t) ? '${t.ad} (yükleniyor…)' : t.ad,
                  d.secTur == t.kod,
                  () => d.turSec(t.kod),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        altBaslik('Tarz:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            for (final t in ['Tümü', ...tarzlar])
              secChip(t, d.secTarz == t, () => d.tarzSec(t)),
          ],
        ),
        const SizedBox(height: 10),
        altBaslik('Kalıp (${d.olcu.ad} ölçüsüne uyanlar):'),
        DropdownButton<Kalip>(
          isExpanded: true,
          value: gecerli,
          dropdownColor: renkKrem,
          items: [
            for (final k in filtre)
              DropdownMenuItem(
                value: k,
                child: Text(k.ad, style: const TextStyle(fontSize: 14)),
              ),
          ],
          onChanged: (k) => d.kalipSec(k),
        ),
        const SizedBox(height: 6),
        Center(
          child: FilledButton.icon(
            onPressed: (gecerli == null || d.parcalar.length >= enFazlaParca)
                ? null
                : () => d.parcaEkle(gecerli!),
            icon: const Icon(Icons.add),
            label: const Text('Parçalara ekle'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        return KartKabugu(
          baslik: 'Sounds',
          ikon: Icons.library_music,
          cocuklar: [_icerik()],
        );
      },
    );
  }
}
