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

  // Seçili kitin/türün ses dosyaları bulunamadıysa küçük kırmızı uyarı.
  Widget _eksikUyarisi() {
    final tur = sesTuruBul(d.secEns, d.secTur);
    if (tur == null) return const SizedBox.shrink();
    final eksik = d.eksikSesler(tur);
    if (eksik.isEmpty) return const SizedBox.shrink();
    final ilk = eksik.take(3).map((x) => '$x.wav').join(', ');
    final fazla = eksik.length > 3 ? ' ve ${eksik.length - 3} tane daha' : '';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Eksik ses dosyası: $ilk$fazla. Dosyalar assets/sesler/ içinde mi, adları aynı mı kontrol et.',
        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
      ),
    );
  }

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
          altBaslik(d.secEns == 'davul' ? 'Kit:' : 'Tür:'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              for (final t in sesKatalogu[d.secEns] ?? const <SesTuru>[])
                secChip(
                  d.yukleniyorMu(t) ? '${t.ad} (yükleniyor…)' : t.ad,
                  d.secTur == t.kod,
                  () => d.turSec(t.kod),
                ),
            ],
          ),
          _eksikUyarisi(),
          const SizedBox(height: 10),
        ],
        altBaslik('Tarz:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            // Sadece bu enstrümanda kalıbı olan tarzlar gösterilir.
            for (final t in [
              'Tümü',
              ...tarzlar.where((x) =>
                  kaliplar.any((k) => k.enstruman == d.secEns && k.tarz == x)),
            ])
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
