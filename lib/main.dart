import 'package:flutter/material.dart';
import 'akor.dart';
import 'kalip.dart';
import 'ses.dart';

const hucreSayisi = 16;
const enFazlaSayfa = 8;
const enFazlaParca = 6;

const _neon = Color(0xFF00E5FF);
const _mor = Color(0xFFB388FF);
const _pembe = Color(0xFFFF4081);
const _cam = Color(0x1FFFFFFF);
const _kenar = Color(0x33FFFFFF);

// Akor adının ilk harfinden bir renk üretir (her kök farklı renk).
Color akorRengi(String? adi,
    {double a = 1.0, double s = 0.65, double v = 0.9}) {
  final h = (adi == null || adi.isEmpty)
      ? 260.0
      : ((adi.codeUnitAt(0) * 47) % 360).toDouble();
  return HSVColor.fromAHSV(a, h, s, v).toColor();
}

IconData ensIkon(String e) => e == 'gitar'
    ? Icons.music_note
    : e == 'piyano'
        ? Icons.piano
        : Icons.graphic_eq;

Color ensRenk(String e) => e == 'gitar'
    ? Colors.amberAccent
    : e == 'piyano'
        ? _neon
        : _pembe;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seslerHazirla();
  runApp(const AkorStudyo());
}

class AkorStudyo extends StatelessWidget {
  const AkorStudyo({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const AkorEkrani(),
    );
  }
}

enum Durum { durdu, caliyor, duraklatildi }

class AkorEkrani extends StatefulWidget {
  const AkorEkrani({super.key});
  @override
  State<AkorEkrani> createState() => _AkorEkraniState();
}

class _AkorEkraniState extends State<AkorEkrani> {
  int ton = 2;
  final List<List<Akor?>> sayfalar = [List<Akor?>.filled(hucreSayisi, null)];
  int aktifSayfa = 0;
  int secili = 0;
  Durum durum = Durum.durdu;
  int calanIndex = -1;
  int oynatmaNo = 0;

  // Vuruş çubuğu için hafif bildirimciler (tüm ekranı yeniden çizdirmez).
  final ValueNotifier<int> adimNo = ValueNotifier<int>(-1);
  final ValueNotifier<int> kutuSlot = ValueNotifier<int>(0);

  int tempo = 100;
  Olcu olcu = olculer[2];
  final List<Parca> parcalar = [
    Parca(kaliplar
        .firstWhere((k) => k.enstruman == 'gitar' && k.ad == 'Strum')),
    Parca(kaliplar
        .firstWhere((k) => k.enstruman == 'davul' && k.tarz == 'Pop')),
  ];
  String secEns = 'gitar';
  String secTarz = 'Tümü';
  Kalip? secKalip;

  List<Akor?> get tablo => sayfalar[aktifSayfa];

  @override
  void dispose() {
    oynatmaNo++;
    adimNo.dispose();
    kutuSlot.dispose();
    super.dispose();
  }

  void akorYerlestir(Akor a) {
    setState(() {
      tablo[secili] = a;
      if (secili < hucreSayisi - 1) secili++;
    });
    akorOnizle(a, secEns == 'davul' ? 'gitar' : secEns);
  }

  int sonDoluIndex() {
    for (int s = sayfalar.length - 1; s >= 0; s--) {
      for (int k = hucreSayisi - 1; k >= 0; k--) {
        if (sayfalar[s][k] != null) return s * hucreSayisi + k;
      }
    }
    return -1;
  }

  Akor? akorAl(int i) {
    final s = i ~/ hucreSayisi;
    if (s >= sayfalar.length) return null;
    return sayfalar[s][i % hucreSayisi];
  }

  Future<void> oynat() async {
    if (durum == Durum.caliyor) return;
    final benimNo = ++oynatmaNo;
    int i = (durum == Durum.duraklatildi && calanIndex >= 0) ? calanIndex : 0;
    setState(() => durum = Durum.caliyor);
    final saat = Stopwatch()..start();
    double hedefMs = 0;
    while (benimNo == oynatmaNo && mounted) {
      final son = sonDoluIndex();
      if (son < 0) break;
      if (i > son) i = 0;
      final akor = akorAl(i);
      final sayfa = i ~/ hucreSayisi;

      // Çalacak parçaların planı. Kutu süresi gitar/piyano kalıbının
      // uzunluğuna göre belirlenir (en uzun olan). Melodik parça yoksa
      // (sadece davul) kutu bir tam ölçü sürer.
      final planlar = <Parca, List<List<String>>>{};
      int enUzun = 0;
      for (final p in parcalar) {
        if (p.sessiz || !p.kalip.olcuVar(olcu.ad)) continue;
        final a = p.kalip.adimlar(olcu.ad);
        if (a.isEmpty) continue;
        planlar[p] = a;
        if (p.kalip.enstruman != 'davul' && a.length > enUzun) {
          enUzun = a.length;
        }
      }
      final slotlar = enUzun > 0 ? enUzun : olcu.slot;
      kutuSlot.value = slotlar;

      for (int adim = 0; adim < slotlar; adim++) {
        if (benimNo != oynatmaNo || !mounted) return;
        if (akor != null) {
          planlar.forEach((p, adimlar) {
            // Kısa kalıp tekrar eder, uzun kalıp (davul) kutu boyunda kesilir.
            final olaylar = adimlar[adim % adimlar.length];
            if (olaylar.isEmpty) return;
            kalipAdimiCal(p.kalip, akor, olaylar, p.ses);
          });
        }
        adimNo.value = adim;
        // Ekranı, kutunun ilk vuruşu çaldıktan sonra güncelle.
        if (adim == 0 && (calanIndex != i || aktifSayfa != sayfa)) {
          setState(() {
            calanIndex = i;
            aktifSayfa = sayfa;
          });
        }
        hedefMs += 30000 / tempo;
        final bekle = (hedefMs - saat.elapsedMilliseconds).round();
        if (bekle > 0) {
          await Future.delayed(Duration(milliseconds: bekle));
        }
      }
      i++;
    }
    if (benimNo == oynatmaNo && mounted) {
      adimNo.value = -1;
      kutuSlot.value = 0;
      setState(() {
        durum = Durum.durdu;
        calanIndex = -1;
      });
    }
  }

  void duraklat() {
    if (durum != Durum.caliyor) return;
    oynatmaNo++;
    adimNo.value = -1;
    kutuSlot.value = 0;
    setState(() => durum = Durum.duraklatildi);
  }

  void durdur() {
    oynatmaNo++;
    adimNo.value = -1;
    kutuSlot.value = 0;
    setState(() {
      durum = Durum.durdu;
      calanIndex = -1;
    });
  }

  void sayfaGit(int s) {
    if (s < 0 || s >= sayfalar.length) return;
    setState(() {
      aktifSayfa = s;
      secili = 0;
    });
  }

  void sayfaEkle() {
    if (sayfalar.length >= enFazlaSayfa) return;
    setState(() {
      sayfalar.add(List<Akor?>.filled(hucreSayisi, null));
      aktifSayfa = sayfalar.length - 1;
      secili = 0;
    });
  }

  Future<void> sayfaSil() async {
    if (sayfalar.length <= 1) return;
    final bos = tablo.every((a) => a == null);
    if (!bos) {
      final onay = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Tablo ${aktifSayfa + 1} silinsin mi?'),
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
      if (onay != true || !mounted) return;
    }
    setState(() {
      sayfalar.removeAt(aktifSayfa);
      if (aktifSayfa >= sayfalar.length) aktifSayfa = sayfalar.length - 1;
      secili = 0;
    });
  }

  // ---------- Arayüz parçaları ----------

  Widget yatayStrip(List<Widget> cocuklar) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: cocuklar),
    );
  }

  Widget pilli(IconData ikon, String yazi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cam,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kenar),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 16, color: _neon),
          const SizedBox(width: 6),
          Text(yazi, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget baslik() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [_neon, _mor, _pembe],
            ).createShader(r),
            child: const Text(
              'AKOR STÜDYO',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              pilli(Icons.music_note, globalIsimler[ton]),
              pilli(Icons.av_timer, olcu.ad),
              pilli(Icons.speed, '$tempo BPM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget kart(String baslikYazi, IconData ikon, List<Widget> cocuklar,
      {bool acik = false}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: _cam,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kenar),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ExpansionTile(
          initiallyExpanded: acik,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(ikon, color: _neon),
          title: Text(
            baslikYazi,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: cocuklar,
        ),
      ),
    );
  }

  Widget tonSecici() {
    const dogal = [0, 2, 4, 5, 7, 9, 11];
    const diyezli = [1, 3, null, 6, 8, 10, null];

    Widget kutu(int? i) {
      if (i == null) return const Expanded(child: SizedBox());
      final secildi = ton == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => ton = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secildi ? const Color(0x66B388FF) : const Color(0x14FFFFFF),
              border: Border.all(
                color: secildi ? _neon : _kenar,
                width: secildi ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              globalIsimler[i],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget akorChip(Akor a) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          a.adi,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: akorRengi(a.adi, a: 0.35, s: 0.7, v: 0.9),
        side: BorderSide(color: akorRengi(a.adi, s: 0.6, v: 1.0)),
        onPressed: () => akorYerlestir(a),
      ),
    );
  }

  Widget hucre(int i) {
    final akor = tablo[i];
    final secildi = i == secili;
    final calan = (aktifSayfa * hucreSayisi + i) == calanIndex;
    final r1 = akorRengi(akor?.adi, s: 0.75, v: calan ? 1.0 : 0.8);
    final r2 = akorRengi(akor?.adi, s: 0.9, v: calan ? 0.8 : 0.5);
    final isik = akorRengi(akor?.adi, a: 0.8, s: 0.6, v: 1.0);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => secili = i),
        onLongPress: () => setState(() => tablo[i] = null),
        child: AnimatedScale(
          scale: calan ? 1.07 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 50,
            margin: const EdgeInsets.all(3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: akor == null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [r1, r2],
                    ),
              color: akor == null ? const Color(0x14FFFFFF) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: secildi ? Colors.white : _kenar,
                width: secildi ? 2.5 : 1,
              ),
              boxShadow: calan
                  ? [BoxShadow(color: isik, blurRadius: 18, spreadRadius: 2)]
                  : null,
            ),
            child: Text(
              akor?.adi ?? '+',
              style: TextStyle(
                fontSize: akor == null ? 18 : 16,
                fontWeight: FontWeight.w800,
                color: akor == null ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget sayfaCubugu() {
    return Row(
      children: [
        IconButton(
          onPressed: aktifSayfa > 0 ? () => sayfaGit(aktifSayfa - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              for (int s = 0; s < sayfalar.length; s++)
                ChoiceChip(
                  label: Text('${s + 1}'),
                  selected: aktifSayfa == s,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => sayfaGit(s),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: aktifSayfa < sayfalar.length - 1
              ? () => sayfaGit(aktifSayfa + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget tabloKarti() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: BoxDecoration(
        color: _cam,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kenar),
      ),
      child: Column(
        children: [
          for (int s = 0; s < 4; s++)
            Row(children: [
              for (int k = 0; k < 4; k++) hucre(s * 4 + k),
            ]),
          const SizedBox(height: 4),
          sayfaCubugu(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: sayfalar.length < enFazlaSayfa ? sayfaEkle : null,
                icon: const Icon(Icons.add),
                label: const Text('Tablo ekle'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: sayfalar.length > 1 ? sayfaSil : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Tablo sil'),
              ),
            ],
          ),
          const Text(
            'Dokun: kutuyu seç. Basılı tut: kutuyu sil. Kutunun süresi seçili arpejin uzunluğuna göre değişir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget vurusCubugu() {
    return ListenableBuilder(
      listenable: Listenable.merge([adimNo, kutuSlot]),
      builder: (context, _) {
        final n = kutuSlot.value > 0 ? kutuSlot.value : olcu.slot;
        final a = adimNo.value;
        return SizedBox(
          height: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int k = 0; k < n; k++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: k == a ? 14 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: k == a
                          ? _neon
                          : (k < a ? _mor : const Color(0x33FFFFFF)),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: k == a
                          ? const [BoxShadow(color: _neon, blurRadius: 10)]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buyukOynat() {
    final caliyor = durum == Durum.caliyor;
    return GestureDetector(
      onTap: caliyor ? duraklat : oynat,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: caliyor ? const [_pembe, _mor] : const [_neon, _mor],
          ),
          boxShadow: [
            BoxShadow(
              color: caliyor
                  ? const Color(0x99FF4081)
                  : const Color(0x9900E5FF),
              blurRadius: caliyor ? 26 : 14,
            ),
          ],
        ),
        child: Icon(
          caliyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 44,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget kucukDugme(IconData ikon, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _cam,
          border: Border.all(color: _kenar),
        ),
        child: Icon(ikon, size: 26),
      ),
    );
  }

  Widget oynatPaneli() {
    final yazi = durum == Durum.caliyor
        ? 'Çalıyor'
        : durum == Durum.duraklatildi
            ? 'Duraklatıldı'
            : 'Hazır';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x337C4DFF), Color(0x2200E5FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kenar),
      ),
      child: Column(
        children: [
          vurusCubugu(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              kucukDugme(Icons.stop_rounded, durdur),
              const SizedBox(width: 24),
              buyukOynat(),
              const SizedBox(width: 24),
              SizedBox(
                width: 52,
                child: Text(
                  yazi,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget parcaSatiri(int p) {
    final parca = parcalar[p];
    final olcudeVar = parca.kalip.olcuVar(olcu.ad);
    final renk = ensRenk(parca.kalip.enstruman);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Bord
