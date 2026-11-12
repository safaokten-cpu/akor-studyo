import 'package:flutter/material.dart';
import 'akor.dart';
import 'kalip.dart';
import 'ses.dart';

const hucreSayisi = 16;
const enFazlaSayfa = 8;
const enFazlaParca = 6;

// ---- Doğa paleti ----
// Gökyüzü, çayır, toprak, deniz ve sonbahar yaprağı.
const _gokAcik = Color(0xFFD5E7EC); // sabah gökyüzü
const _cayirAcik = Color(0xFFE6EDD3); // çayır
const _krem = Color(0xFFF4F1DE); // kuru ot
const _kum = Color(0xFFE3E6CC); // boş kutu
const _kart = Color(0xB3FFFFFF);
const _kenar = Color(0xFFB9BF98);
const _toprak = Color(0xFF3E2C1F); // yazı
const _toprakAcik = Color(0xFF7A6248); // ikincil yazı
const _yaprak = Color(0xFF4F7F36);
const _cimen = Color(0xFF8DB255);
const _cimenAcik = Color(0xFFCFE0A6);
const _deniz = Color(0xFF2B7A86);
const _sonbahar = Color(0xFFE0A32E);
const _kutuk = Color(0xFF8B5E3C);

// Her akor kökü için doğadan bir renk.
const _kokRenkleri = [
  Color(0xFF5B8C3E), // C  yaprak
  Color(0xFF8DB255), // C# taze çimen
  Color(0xFF2F7F86), // D  deniz
  Color(0xFF7FB7D9), // D# gök
  Color(0xFFE0A32E), // E  sonbahar sarısı
  Color(0xFFB5792F), // F  kuru yaprak
  Color(0xFF8B5E3C), // F# ağaç kabuğu
  Color(0xFF6B8E4E), // G  zeytin
  Color(0xFF4F9DA6), // G# turkuaz
  Color(0xFFD98B2B), // A  kehribar
  Color(0xFF9C7A55), // A# toprak
  Color(0xFF5E8CB0), // B  derin gök
];

Color akorRengi(Akor? a) => a == null ? _kenar : _kokRenkleri[a.kok % 12];

Color yaziRengi(Color zemin) =>
    zemin.computeLuminance() > 0.42 ? _toprak : Colors.white;

IconData ensIkon(String e) => e == 'gitar'
    ? Icons.music_note
    : e == 'piyano'
        ? Icons.piano
        : Icons.graphic_eq;

Color ensRenk(String e) => e == 'gitar'
    ? _sonbahar
    : e == 'piyano'
        ? _deniz
        : _kutuk;

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
        brightness: Brightness.light,
        scaffoldBackgroundColor: _krem,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _yaprak,
          brightness: Brightness.light,
        ).copyWith(surface: _krem, onSurface: _toprak),
        chipTheme: const ChipThemeData(
          backgroundColor: _kum,
          selectedColor: _cimenAcik,
          side: BorderSide(color: _kenar),
          labelStyle: TextStyle(
              fontSize: 12.5, color: _toprak, fontWeight: FontWeight.w600),
          secondaryLabelStyle: TextStyle(
              fontSize: 12.5, color: _toprak, fontWeight: FontWeight.w600),
          padding: EdgeInsets.symmetric(horizontal: 2),
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

  // Hafif bildirimciler: çalarken tüm ekranı değil, sadece ilgili kısmı çizdirir.
  final ValueNotifier<int> adimNo = ValueNotifier<int>(-1);
  final ValueNotifier<int> kutuSlot = ValueNotifier<int>(0);
  final ValueNotifier<int> tabloTik = ValueNotifier<int>(0);

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
    tabloTik.dispose();
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
        // Önce ses: çizimden hiçbir şey sesi bekletmesin.
        if (akor != null) {
          planlar.forEach((p, adimlar) {
            // Kısa kalıp tekrar eder, uzun kalıp (davul) kutu boyunda kesilir.
            final olaylar = adimlar[adim % adimlar.length];
            if (olaylar.isEmpty) return;
            kalipAdimiCal(p.kalip, akor, olaylar, p.ses);
          });
        }
        adimNo.value = adim;
        // Kutu değişince sadece tabloyu yeniden çiz (tüm ekranı değil).
        if (adim == 0 && (calanIndex != i || aktifSayfa != sayfa)) {
          calanIndex = i;
          aktifSayfa = sayfa;
          tabloTik.value++;
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

  Widget etiket(String yazi) {
    return Text(
      yazi,
      style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13, color: _toprakAcik),
    );
  }

  Widget secChip(String yazi, bool secildi, VoidCallback f, {Widget? avatar}) {
    return ChoiceChip(
      avatar: avatar,
      label: Text(yazi),
      selected: secildi,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => f(),
    );
  }

  Widget kucukIkon(IconData ikon, VoidCallback? f) {
    return IconButton(
      onPressed: f,
      icon: Icon(ikon),
      iconSize: 22,
      color: _toprak,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }

  Widget kucukSlider({
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SizedBox(
      height: 26,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          activeTrackColor: _yaprak,
          inactiveTrackColor: _kenar,
          thumbColor: _yaprak,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget pilli(IconData ikon, String yazi) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kart,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kenar),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: _yaprak),
          const SizedBox(width: 4),
          Text(yazi,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget baslik() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          const Icon(Icons.eco, color: _yaprak, size: 22),
          const SizedBox(width: 6),
          const Text(
            'Akor Stüdyo',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _toprak),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    pilli(Icons.music_note, globalIsimler[ton]),
                    pilli(Icons.av_timer, olcu.ad),
                    pilli(Icons.speed, '$tempo BPM'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget kart(String baslikYazi, IconData ikon, List<Widget> cocuklar,
      {bool acik = false}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: _kart,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kenar),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ExpansionTile(
          initiallyExpanded: acik,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          iconColor: _yaprak,
          collapsedIconColor: _yaprak,
          textColor: _toprak,
          collapsedTextColor: _toprak,
          leading: Icon(ikon, color: _yaprak, size: 22),
          title: Text(
            baslikYazi,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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
          child: Container(
            height: 34,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secildi ? _yaprak : _kum,
              border: Border.all(
                color: secildi ? _toprak : _kenar,
                width: secildi ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              globalIsimler[i],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: secildi ? Colors.white : _toprak,
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

  Widget akorChip(Akor a) {
    final renk = akorRengi(a);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          a.adi,
          style: const TextStyle(fontWeight: FontWeight.w800, color: _toprak),
        ),
        backgroundColor: Color.lerp(_krem, renk, 0.4)!,
        side: BorderSide(color: renk, width: 1.5),
        visualDensity: VisualDensity.compact,
        onPressed: () => akorYerlestir(a),
      ),
    );
  }

  Widget hucre(int i) {
    final akor = tablo[i];
    final secildi = i == secili;
    final calan = (aktifSayfa * hucreSayisi + i) == calanIndex;
    final baz = akor == null ? null : akorRengi(akor);
    final zemin =
        baz == null ? _kum : (calan ? baz : Color.lerp(_krem, baz, 0.6)!);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => secili = i),
        onLongPress: () => setState(() => tablo[i] = null),
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: zemin,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: calan || secildi ? _toprak : _kenar,
              width: calan ? 3 : (secildi ? 2.5 : 1),
            ),
          ),
          child: Text(
            akor?.adi ?? '+',
            style: TextStyle(
              fontSize: akor == null ? 18 : 16,
              fontWeight: FontWeight.w800,
              color: baz == null ? _toprakAcik : yaziRengi(zemin),
            ),
          ),
        ),
      ),
    );
  }

  Widget sayfaCubugu() {
    return Row(
      children: [
        kucukIkon(Icons.chevron_left,
            aktifSayfa > 0 ? () => sayfaGit(aktifSayfa - 1) : null),
        Expanded(
          child: yatayStrip([
            for (int s = 0; s < sayfalar.length; s++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: secChip('${s + 1}', aktifSayfa == s, () => sayfaGit(s)),
              ),
          ]),
        ),
        kucukIkon(Icons.chevron_right,
            aktifSayfa < sayfalar.length - 1
                ? () => sayfaGit(aktifSayfa + 1)
                : null),
        kucukIkon(Icons.add, sayfalar.length < enFazlaSayfa ? sayfaEkle : null),
        kucukIkon(Icons.delete_outline, sayfalar.length > 1 ? sayfaSil : null),
      ],
    );
  }

  Widget vurusCubugu() {
    return ListenableBuilder(
      listenable: Listenable.merge([adimNo, kutuSlot]),
      builder: (context, _) {
        final n = kutuSlot.value > 0 ? kutuSlot.value : olcu.slot;
        final a = adimNo.value;
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
                      color: k == a ? _sonbahar : (k < a ? _cimen : _kenar),
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

  Widget yuvarlakDugme(
      IconData ikon, double boy, Color zemin, Color renk, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: Container(
        width: boy,
        height: boy,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: zemin,
          border: Border.all(color: _toprak.withAlpha(60)),
        ),
        child: Icon(ikon, size: boy * 0.62, color: renk),
      ),
    );
  }

  Widget kontrolSatiri() {
    final caliyor = durum == Durum.caliyor;
    return Row(
      children: [
        yuvarlakDugme(Icons.stop_rounded, 38, _kum, _toprak, durdur),
        const SizedBox(width: 8),
        yuvarlakDugme(
          caliyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
          48,
          caliyor ? _deniz : _yaprak,
          Colors.white,
          caliyor ? duraklat : oynat,
        ),
        const SizedBox(width: 12),
        Expanded(child: vurusCubugu()),
      ],
    );
  }

  Widget tabloKarti() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: _kart,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kenar),
      ),
      child: Column(
        children: [
          ListenableBuilder(
            listenable: tabloTik,
            builder: (context, _) {
              return Column(
                children: [
                  for (int s = 0; s < 4; s++)
                    Row(children: [
                      for (int k = 0; k < 4; k++) hucre(s * 4 + k),
                    ]),
                  const SizedBox(height: 4),
                  sayfaCubugu(),
                ],
              );
            },
          ),
          const SizedBox(height: 2),
          kontrolSatiri(),
          const SizedBox(height: 6),
          const Text(
            'Dokun: seç. Basılı tut: sil.',
            style: TextStyle(fontSize: 11, color: _toprakAcik),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget parcaSatiri(int p) {
    final parca = parcalar[p];
    final olcudeVar = parca.kalip.olcuVar(olcu.ad);
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
            onPressed: () => setState(() => parca.sessiz = !parca.sessiz),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            icon: Icon(
              parca.sessiz ? Icons.volume_off : ensIkon(parca.kalip.enstruman),
              color: parca.sessiz ? _toprakAcik : renk,
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
                    '${olcu.ad} ölçüsünde yok, çalmaz',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFFB3472B)),
                  ),
                kucukSlider(
                  value: parca.ses,
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(() => parca.ses = v),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => parcalar.removeAt(p)),
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

  Widget loopBolumu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        yatayStrip([
          for (final o in olculer)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: secChip(o.ad, olcu.ad == o.ad, () => setState(() => olcu = o)),
            ),
        ]),
        Row(
          children: [
            kucukIkon(Icons.remove_circle_outline,
                () => setState(() => tempo = (tempo - 5).clamp(60, 180).toInt())),
            Expanded(
              child: kucukSlider(
                min: 60,
                max: 180,
                divisions: 120,
                value: tempo.toDouble(),
                onChanged: (v) => setState(() => tempo = v.round()),
              ),
            ),
            kucukIkon(Icons.add_circle_outline,
                () => setState(() => tempo = (tempo + 5).clamp(60, 180).toInt())),
            SizedBox(
              width: 62,
              child: Text(
                '$tempo BPM',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        if (parcalar.isEmpty)
          const Padding(
            padding: EdgeInsets.all(6),
            child: Text('Parça yok. Sounds menüsünden parça ekle.',
                style: TextStyle(fontSize: 12)),
          ),
        for (int p = 0; p < parcalar.length; p++) parcaSatiri(p),
      ],
    );
  }

  Widget soundsBolumu() {
    final filtre = kaliplar
        .where((k) =>
            k.enstruman == secEns &&
            k.olcuVar(olcu.ad) &&
            (secTarz == 'Tümü' || k.tarz == secTarz))
        .toList();
    final gecerli = filtre.contains(secKalip)
        ? secKalip
        : (filtre.isNotEmpty ? filtre.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        etiket('Enstrüman:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final e in enstrumanAdlari.entries)
              secChip(
                e.value,
                secEns == e.key,
                () => setState(() => secEns = e.key),
                avatar: Icon(ensIkon(e.key), size: 16),
              ),
          ],
        ),
        const SizedBox(height: 10),
        etiket('Tarz:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            for (final t in ['Tümü', ...tarzlar])
              secChip(t, secTarz == t, () => setState(() => secTarz = t)),
          ],
        ),
        const SizedBox(height: 10),
        etiket('Kalıp (${olcu.ad} ölçüsüne uyanlar):'),
        DropdownButton<Kalip>(
          isExpanded: true,
          value: gecerli,
          dropdownColor: _krem,
          items: [
            for (final k in filtre)
              DropdownMenuItem(
                value: k,
                child: Text(k.ad, style: const TextStyle(fontSize: 14)),
              ),
          ],
          onChanged: (k) => setState(() => secKalip = k),
        ),
        const SizedBox(height: 6),
        Center(
          child: FilledButton.icon(
            onPressed: (gecerli == null || parcalar.length >= enFazlaParca)
                ? null
                : () => setState(() => parcalar.add(Parca(gecerli!))),
            icon: const Icon(Icons.add),
            label: const Text('Parçalara ekle'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gokAcik, _cayirAcik],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              baslik(),
              tabloKarti(),
              kart('Ton ve Akorlar', Icons.queue_music, [
                etiket('Ton:'),
                const SizedBox(height: 4),
                tonSecici(),
                const SizedBox(height: 10),
                etiket('${globalIsimler[ton]} tonunun akorları:'),
                const SizedBox(height: 2),
                yatayStrip([
                  for (final t in akorTurleri) akorChip(Akor(ton, t.kod)),
                ]),
              ], acik: true),
              kart('Loop Page', Icons.loop, [loopBolumu()]),
              kart('Sounds', Icons.library_music, [soundsBolumu()]),
            ],
          ),
        ),
      ),
    );
  }
}
