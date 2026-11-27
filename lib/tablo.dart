import 'package:flutter/material.dart';
import 'akor_yazi.dart';
import 'durum.dart';
import 'ortak.dart';
import 'sarkilar.dart';
import 'tema.dart';

// Akor tablosu: 16 kutu, sayfa çubuğu, oynat/duraklat/durdur tuşları, vuruş çubuğu.
class TabloKarti extends StatelessWidget {
  final StudyoDurumu d;
  const TabloKarti(this.d, {super.key});

  void _desenSec(BuildContext context, int i) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: renkKart,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DesenSecici(d, d.aktifSayfa, i),
    );
  }

  Widget _hucre(BuildContext context, int i) {
    final akor = d.tablo[i];
    final secildi = i == d.secili;
    final calan = (d.aktifSayfa * hucreSayisi + i) == d.calanIndex;
    final baz = akor == null ? null : akorRengi(akor);
    final zemin =
        baz == null ? renkKum : (calan ? baz : Color.lerp(renkKrem, baz, 0.6)!);
    final yaziRenk = baz == null ? renkToprakAcik : yaziRengi(zemin);
    final desen = akor == null ? null : d.desenAl(d.aktifSayfa, i);
    return Expanded(
      child: GestureDetector(
        onTap: () => d.hucreSec(i),
        onLongPress: () => d.hucreSil(i),
        child: Container(
          height: 56,
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
          child: akor == null
              ? Text(
                  '+',
                  style: TextStyle(fontSize: 18, color: yaziRenk),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      akor.adi,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: yaziRenk,
                      ),
                    ),
                    // İmleç: dokununca bu akorun arpej seçenekleri açılır.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        d.hucreSec(i);
                        _desenSec(context, i);
                      },
                      child: SizedBox(
                        height: 20,
                        width: double.infinity,
                        child: Center(
                          child: desen == null
                              ? Icon(Icons.arrow_drop_down,
                                  size: 20, color: yaziRenk)
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  child: Text(
                                    desen.replaceAll(' ', ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: yaziRenk,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
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

  // Tablonun altındaki küçük düğmelerin ortak görünümü.
  Widget _kucukDugme(IconData ikon, String yazi, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: renkKum,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: renkKenar),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 15, color: renkToprak),
            const SizedBox(width: 5),
            Text(
              yazi,
              style: const TextStyle(
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

  Widget _yaziDugmesi(BuildContext context) => _kucukDugme(
        Icons.text_snippet_outlined,
        'Yazıdan yükle',
        () => showDialog<void>(
          context: context,
          builder: (_) => _YaziDialogu(d),
        ),
      );

  Widget _kaydetDugmesi(BuildContext context) => _kucukDugme(
        Icons.save_outlined,
        'Kaydet',
        () => sarkiKaydetPenceresi(context, d),
      );

  Widget _sarkilarDugmesi(BuildContext context) => _kucukDugme(
        Icons.library_music_outlined,
        'Şarkılarım',
        () => sarkilarimPenceresi(context, d),
      );

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
                      for (int k = 0; k < 4; k++) _hucre(context, s * 4 + k),
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dokun: seç. Basılı tut: sil. Ok: arpej.',
              style: TextStyle(fontSize: 11, color: renkToprakAcik),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _kaydetDugmesi(context),
                _sarkilarDugmesi(context),
                _yaziDugmesi(context),
              ],
            ),
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

// Bir akor kutusunun arpej seçimi: hazır desenler ya da elle yazılan desen.
class _DesenSecici extends StatefulWidget {
  final StudyoDurumu d;
  final int sayfa;
  final int hucre;
  const _DesenSecici(this.d, this.sayfa, this.hucre);

  @override
  State<_DesenSecici> createState() => _DesenSeciciDurumu();
}

class _DesenSeciciDurumu extends State<_DesenSecici> {
  final TextEditingController _yazi = TextEditingController();
  late int _adim;
  String? _hata;

  @override
  void initState() {
    super.initState();
    final mevcut = widget.d.desenAl(widget.sayfa, widget.hucre);
    if (mevcut != null) {
      _adim = mevcut.split(' ').length;
      _yazi.text = mevcut.replaceAll(' ', '');
    } else if (arpejAdimSayilari.contains(widget.d.olcu.slot)) {
      _adim = widget.d.olcu.slot;
    } else {
      _adim = arpejAdimSayilari.first;
    }
  }

  @override
  void dispose() {
    _yazi.dispose();
    super.dispose();
  }

  void _sec(String? desen) {
    widget.d.desenAyarla(widget.sayfa, widget.hucre, desen);
    Navigator.pop(context);
  }

  void _yazidanUygula() {
    final desen = desenTemizle(_yazi.text);
    if (desen == null) {
      setState(() => _hata =
          'Desen okunamadı. p i m a gibi yaz (harfler: p P i m a c d u b h, nokta = boşluk).');
      return;
    }
    _sec(desen);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final akor = d.akorAl(widget.sayfa * hucreSayisi + widget.hucre);
    final mevcut = d.desenAl(widget.sayfa, widget.hucre);
    final liste = [
      for (final x in arpejHavuzu)
        if (x.split(' ').length == _adim) x,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${akor?.adi ?? ''} akoru için arpej',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            secChip('Varsayılan (parçanın kalıbı)', mevcut == null,
                () => _sec(null)),
            const SizedBox(height: 10),
            altBaslik('Adım sayısı:'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final n in arpejAdimSayilari)
                  secChip('$n', _adim == n, () => setState(() => _adim = n)),
              ],
            ),
            const SizedBox(height: 10),
            altBaslik('Desenler:'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final x in liste)
                  secChip(x, mevcut == x, () => _sec(x)),
              ],
            ),
            const SizedBox(height: 12),
            altBaslik('Kendin yaz:'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yazi,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'pima ya da p i m a',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _yazidanUygula,
                  child: const Text('Uygula'),
                ),
              ],
            ),
            if (_hata != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _hata!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
