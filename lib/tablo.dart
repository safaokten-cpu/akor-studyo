import 'package:flutter/material.dart';
import 'akor_yazi.dart';
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

  Widget _yaziDugmesi(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _YaziDialogu(d),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: renkKum,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: renkKenar),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.text_snippet_outlined, size: 15, color: renkToprak),
            SizedBox(width: 5),
            Text(
              'Yazıdan yükle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: renkToprak,
              ),
            ),
          ],
        ),
      ),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dokun: seç. Basılı tut: sil.',
                  style: TextStyle(fontSize: 11, color: renkToprakAcik),
                ),
              ),
              _yaziDugmesi(context),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// Yazıdan yükleme penceresi: önce yapıştır ve oku, sonra düzelt ve aktar.
class _YaziDialogu extends StatefulWidget {
  final StudyoDurumu d;
  const _YaziDialogu(this.d);

  @override
  State<_YaziDialogu> createState() => _YaziDialoguDurumu();
}

class _YaziDialoguDurumu extends State<_YaziDialogu> {
  final TextEditingController _yapistir = TextEditingController();
  final TextEditingController _akorlar = TextEditingController();
  final TextEditingController _ritim = TextEditingController();
  bool _okundu = false;
  bool _temizle = true;
  String? _hata;
  int _okunanAkor = 0;

  @override
  void dispose() {
    _yapistir.dispose();
    _akorlar.dispose();
    _ritim.dispose();
    super.dispose();
  }

  void _oku() {
    final s = yaziyiOku(_yapistir.text);
    if (s.akorlar.isEmpty) {
      setState(() => _hata =
          'Akor satırı bulunamadı. Akorların yazılı olduğu satırları da kopyaladığından emin ol.');
      return;
    }
    setState(() {
      _akorlar.text = s.akorlar.join(' ');
      _ritim.text = s.ritim ?? '';
      _okunanAkor = s.akorlar.length;
      _okundu = true;
      _hata = null;
    });
  }

  void _aktar() {
    final liste = akorlariCoz(_akorlar.text);
    if (liste.hatali.isNotEmpty) {
      setState(() => _hata =
          'Okunamadı: ${liste.hatali.join(', ')}. Düzeltip tekrar dene.');
      return;
    }
    if (liste.akorlar.isEmpty) {
      setState(() => _hata = 'Aktarılacak akor yok.');
      return;
    }
    final ritim = ritimTemizle(_ritim.text);
    final mesaj = ScaffoldMessenger.maybeOf(context);
    final yerlesen = widget.d.yaziUygula(liste.akorlar, ritim, _temizle);
    Navigator.pop(context);
    final atlanan = liste.akorlar.length - yerlesen;
    mesaj?.showSnackBar(
      SnackBar(
        content: Text(
          atlanan > 0
              ? '$yerlesen akor aktarıldı, $atlanan akor sığmadı'
              : '$yerlesen akor tabloya aktarıldı',
        ),
      ),
    );
  }

  Widget _hataYazisi() {
    if (_hata == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _hata!,
        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
      ),
    );
  }

  Widget _birinciAdim() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Akor sitesinden kopyaladığın metni yapıştır. Akor satırları ve '
          '"Ritim:" satırı otomatik bulunur.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _yapistir,
          minLines: 5,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Metni buraya yapıştır',
          ),
        ),
        _hataYazisi(),
      ],
    );
  }

  Widget _ikinciAdim() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_okunanAkor akor okundu. Yanlış olanı düzeltebilirsin.',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _akorlar,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Akorlar (sırayla)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ritim,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Ritim (p i m a ...)',
            helperText: 'Boşsa mevcut gitar kalıbı kalır. Nokta = boşluk.',
            helperMaxLines: 2,
          ),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Tabloyu temizle', style: TextStyle(fontSize: 13)),
          value: _temizle,
          onChanged: (v) => setState(() => _temizle = v),
        ),
        _hataYazisi(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yazıdan yükle'),
      content: SingleChildScrollView(
        child: _okundu ? _ikinciAdim() : _birinciAdim(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        if (_okundu)
          TextButton(
            onPressed: () => setState(() {
              _okundu = false;
              _hata = null;
            }),
            child: const Text('Geri'),
          ),
        TextButton(
          onPressed: _okundu ? _aktar : _oku,
          child: Text(_okundu ? 'Aktar' : 'Oku'),
        ),
      ],
    );
  }
}
