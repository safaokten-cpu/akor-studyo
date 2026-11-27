import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'durum.dart';
import 'tema.dart';

// Şarkılarım: akorları ve ayarları bir adla uygulamanın içine kaydeder.
// Kayıtlar telefonda kalıcıdır (uygulama kapansa da silinmez).
// Uygulama silinirse ya da verileri temizlenirse kayıtlar da gider.

class KayitliSarki {
  final String ad;
  // Kaydedilme zamanı (milisaniye).
  final int zaman;
  // durum.dart'taki sarkiVerisi() çıktısı: akorlar, arpejler, ton, tempo...
  final Map<String, dynamic> veri;
  const KayitliSarki(this.ad, this.zaman, this.veri);

  Map<String, dynamic> toJson() => {'ad': ad, 'zaman': zaman, 'veri': veri};

  factory KayitliSarki.fromJson(Map<String, dynamic> j) => KayitliSarki(
        (j['ad'] ?? '').toString(),
        (j['zaman'] as num?)?.toInt() ?? 0,
        Map<String, dynamic>.from((j['veri'] as Map?) ?? const {}),
      );

  int get akorSayisi {
    var n = 0;
    final sayfalar = veri['sayfalar'];
    if (sayfalar is List) {
      for (final sayfa in sayfalar) {
        if (sayfa is List) {
          for (final a in sayfa) {
            if (a != null) n++;
          }
        }
      }
    }
    return n;
  }

  String get ozet {
    final tempo = veri['tempo'];
    final olcu = veri['olcu'];
    final t = DateTime.fromMillisecondsSinceEpoch(zaman);
    final gun = '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.${t.year}';
    return '$akorSayisi akor · $tempo BPM · $olcu · $gun';
  }
}

class SarkiDeposu {
  static const _anahtar = 'akor_studyo_sarkilar';

  static Future<List<KayitliSarki>> oku() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final ham = sp.getString(_anahtar);
      if (ham == null || ham.isEmpty) return [];
      final liste = jsonDecode(ham) as List;
      return [
        for (final x in liste)
          KayitliSarki.fromJson(Map<String, dynamic>.from(x as Map)),
      ];
    } catch (e) {
      return [];
    }
  }

  static Future<void> _yaz(List<KayitliSarki> liste) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _anahtar,
      jsonEncode([for (final s in liste) s.toJson()]),
    );
  }

  static bool _ayniAd(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static Future<bool> varMi(String ad) async {
    final liste = await oku();
    return liste.any((s) => _ayniAd(s.ad, ad));
  }

  // Aynı adlı şarkı varsa üstüne yazar, yeni kayıt listenin başına gelir.
  static Future<void> kaydet(KayitliSarki sarki) async {
    final liste = await oku();
    liste.removeWhere((s) => _ayniAd(s.ad, sarki.ad));
    liste.insert(0, sarki);
    await _yaz(liste);
  }

  static Future<void> sil(String ad) async {
    final liste = await oku();
    liste.removeWhere((s) => _ayniAd(s.ad, ad));
    await _yaz(liste);
  }
}

// ---------------------------------------------------------------------
// Kaydet penceresi
// ---------------------------------------------------------------------

Future<void> sarkiKaydetPenceresi(BuildContext context, StudyoDurumu d) async {
  final ad = await showDialog<String>(
    context: context,
    builder: (_) => _KaydetDialogu(d),
  );
  if (ad == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Kaydedildi: $ad')),
  );
}

class _KaydetDialogu extends StatefulWidget {
  final StudyoDurumu d;
  const _KaydetDialogu(this.d);

  @override
  State<_KaydetDialogu> createState() => _KaydetDialoguDurumu();
}

class _KaydetDialoguDurumu extends State<_KaydetDialogu> {
  late final TextEditingController _ad;
  bool _ustuneYaz = false;
  String? _mesaj;

  @override
  void initState() {
    super.initState();
    _ad = TextEditingController(text: widget.d.sonSarkiAdi);
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  bool get _bos =>
      widget.d.sayfalar.every((sayfa) => sayfa.every((a) => a == null));

  Future<void> _kaydet() async {
    final ad = _ad.text.trim();
    if (ad.isEmpty) {
      setState(() => _mesaj = 'Şarkıya bir ad yaz.');
      return;
    }
    if (!_ustuneYaz && await SarkiDeposu.varMi(ad)) {
      if (!mounted) return;
      setState(() {
        _ustuneYaz = true;
        _mesaj = 'Bu adla bir şarkı var. Tekrar Kaydet\'e basarsan üstüne yazılır.';
      });
      return;
    }
    await SarkiDeposu.kaydet(
      KayitliSarki(
        ad,
        DateTime.now().millisecondsSinceEpoch,
        widget.d.sarkiVerisi(),
      ),
    );
    widget.d.sonSarkiAdi = ad;
    if (!mounted) return;
    Navigator.pop(context, ad);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: renkKart,
      title: const Text('Şarkıyı kaydet', style: TextStyle(fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bos)
            const Text(
              'Tabloda henüz akor yok. Önce akor ekle.',
              style: TextStyle(fontSize: 13),
            )
          else ...[
            const Text(
              'Akorlar, arpejler, ton, tempo, ölçü ve parçalar kaydedilir.',
              style: TextStyle(fontSize: 12, color: renkToprakAcik),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ad,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Şarkı adı',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) {
                if (_ustuneYaz || _mesaj != null) {
                  setState(() {
                    _ustuneYaz = false;
                    _mesaj = null;
                  });
                }
              },
              onSubmitted: (_) => _kaydet(),
            ),
            if (_mesaj != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _mesaj!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        if (!_bos)
          FilledButton(
            onPressed: _kaydet,
            child: Text(_ustuneYaz ? 'Üstüne yaz' : 'Kaydet'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Şarkılarım listesi
// ---------------------------------------------------------------------

Future<void> sarkilarimPenceresi(BuildContext context, StudyoDurumu d) async {
  final ad = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: renkKart,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SarkilarSayfasi(d),
  );
  if (ad == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Açıldı: $ad')),
  );
}

class _SarkilarSayfasi extends StatefulWidget {
  final StudyoDurumu d;
  const _SarkilarSayfasi(this.d);

  @override
  State<_SarkilarSayfasi> createState() => _SarkilarSayfasiDurumu();
}

class _SarkilarSayfasiDurumu extends State<_SarkilarSayfasi> {
  List<KayitliSarki>? _liste;

  @override
  void initState() {
    super.initState();
    _yenile();
  }

  Future<void> _yenile() async {
    final l = await SarkiDeposu.oku();
    if (!mounted) return;
    setState(() => _liste = l);
  }

  void _ac(KayitliSarki s) {
    widget.d.sarkiYukle(s.veri);
    widget.d.sonSarkiAdi = s.ad;
    Navigator.pop(context, s.ad);
  }

  Future<void> _sil(KayitliSarki s) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: renkKart,
        title: const Text('Şarkı silinsin mi?', style: TextStyle(fontSize: 17)),
        content: Text('"${s.ad}" kalıcı olarak silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    await SarkiDeposu.sil(s.ad);
    await _yenile();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _liste;
    final yukseklik = MediaQuery.of(context).size.height * 0.65;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: yukseklik),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Şarkılarım',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (liste == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (liste.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Henüz kayıtlı şarkı yok. Tablodaki Kaydet düğmesiyle ekleyebilirsin.',
                  style: TextStyle(fontSize: 13, color: renkToprakAcik),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: liste.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = liste[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        s.ad,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        s.ozet,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _ac(s),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _sil(s),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
