import 'package:flutter/material.dart';
import 'durum.dart';
import 'ortak.dart';
import 'tema.dart';

// Akor tablosu: 16 kutu, sayfa çubuğu, oynat/duraklat/durdur tuşları, vuruş çubuğu.
class TabloKarti extends StatelessWidget {
  final StudyoDurumu d;
  const TabloKarti(this.d, {super.key});

  Widget _hucre(int i) {
    final akor = d.tablo[i];
    final secildi = i == d.secili;
    final calan = (d.aktifSayfa * hucreSayisi + i) == d.calanIndex;
    final baz = akor == null ? null : akorRengi(akor);
    final zemin =
        baz == null ? renkKum : (calan ? baz : Color.lerp(renkKrem, baz, 0.6)!);
    return Expanded(
      child: GestureDetector(
        onTap: () => d.hucreSec(i),
        onLongPress: () => d.hucreSil(i),
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: zemin,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: calan || secildi ? renkToprak : renkKenar,
              width: calan ? 3 : (secildi ? 2.5 : 1),
            ),
          ),
          child: Text(
            akor?.adi ?? '+',
            style: TextStyle(
              fontSize: akor == null ? 18 : 16,
              fontWeight: FontWeight.w800,
              color: baz == null ? renkToprakAcik : yaziRengi(zemin),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sayfaSil(BuildContext context) async {
    if (d.sayfalar.length <= 1) return;
    if (!d.tabloBos) {
      final onay = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Tablo ${d.aktifSayfa + 1} silinsin mi?'),
          content: const Text('İçindeki akorlar da silinir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      );
      if (onay != true) return;
    }
    d.sayfaSilKesin();
  }

  Widget _sayfaCubugu(BuildContext context) {
    return Row(
      children: [
        kucukIkon(Icons.chevron_left,
            d.aktifSayfa > 0 ? () => d.sayfaGit(d.aktifSayfa - 1) : null),
        Expanded(
          child: yatayStrip([
            for (int s = 0; s < d.sayfalar.length; s++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: secChip('${s + 1}', d.aktifSayfa == s, () => d.sayfaGit(s)),
              ),
          ]),
        ),
        kucukIkon(
            Icons.chevron_right,
            d.aktifSayfa < d.sayfalar.length - 1
                ? () => d.sayfaGit(d.aktifSayfa + 1)
                : null),
        kucukIkon(Icons.add,
            d.sayfalar.length < enFazlaSayfa ? d.sayfaEkle : null),
        kucukIkon(Icons.delete_outline,
            d.sayfalar.length > 1 ? () => _sayfaSil(context) : null),
      ],
    );
  }

  Widget _vurusCubugu() {
    return ListenableBuilder(
      listenable: Listenable.merge([d.adimNo, d.kutuSlot]),
      builder: (context, _) {
        final n = d.kutuSlot.value > 0 ? d.kutuSlot.value : d.olcu.slot;
        final a = d.adimNo.value;
        return SizedBox(
          height: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int k = 0; k < n; k++)
                Expanded(
                  child: Container(
                    height: k == a ? 13 : 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: k == a
                          ? renkSonbahar
                          : (k < a ? renkCimen : renkKenar),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _yuvarlakDugme(
      IconData ikon, double boy, Color zemin, Color renk, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: Container(
        width: boy,
        height: boy,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: zemin,
          border: Border.all(color: renkToprak.withAlpha(60)),
        ),
        child: Icon(ikon, size: boy * 0.62, color: renk),
      ),
    );
  }

  Widget _kontrolSatiri() {
    final caliyor = d.durum == Durum.caliyor;
    return Row(
      children: [
        _yuvarlakDugme(
            Icons.stop_rounded, 38, renkKum, renkToprak, d.durdur),
        const SizedBox(width: 8),
        _yuvarlakDugme(
          caliyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
          48,
          caliyor ? renkDeniz : renkYaprak,
          Colors.white,
          caliyor ? d.duraklat : d.oynat,
        ),
        const SizedBox(width: 12),
        Expanded(child: _vurusCubugu()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: renkKart,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: renkKenar),
      ),
      child: Column(
        children: [
          // Kutu değişince sadece bu kısım yeniden çizilir.
          ListenableBuilder(
            listenable: Listenable.merge([d, d.tabloTik]),
            builder: (context, _) {
              return Column(
                children: [
                  for (int s = 0; s < 4; s++)
                    Row(children: [
                      for (int k = 0; k < 4; k++) _hucre(s * 4 + k),
                    ]),
                  const SizedBox(height: 4),
                  _sayfaCubugu(context),
                ],
              );
            },
          ),
          const SizedBox(height: 2),
          ListenableBuilder(
            listenable: d,
            builder: (context, _) => _kontrolSatiri(),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dokun: seç. Basılı tut: sil.',
            style: TextStyle(fontSize: 11, color: renkToprakAcik),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
