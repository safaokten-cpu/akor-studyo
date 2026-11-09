import 'package:flutter/material.dart';
import 'akor.dart';
import 'kalip.dart';
import 'ses.dart';

const hucreSayisi = 16;
const enFazlaSayfa = 8;
const enFazlaParca = 6;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seslerHazirla();
  runApp(const AkorStudyo());
}

class AkorStudyo extends StatelessWidget {
  const AkorStudyo({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AkorEkrani());
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

  int tempo = 100;
  final List<Parca> parcalar = [
    Parca(kaliplar.firstWhere((k) => k.enstruman == 'gitar' && k.tarz == 'Pop')),
    Parca(kaliplar.firstWhere((k) => k.enstruman == 'davul' && k.tarz == 'Pop')),
  ];
  String secEns = 'gitar';
  String secTarz = 'Tümü';
  Kalip? secKalip;

  List<Akor?> get tablo => sayfalar[aktifSayfa];

  @override
  void dispose() {
    oynatmaNo++;
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
    int hedefMs = 0;
    while (benimNo == oynatmaNo && mounted) {
      final son = sonDoluIndex();
      if (son < 0) break;
      if (i > son) i = 0;
      final akor = akorAl(i);
      if (akor != null) {
        setState(() {
          calanIndex = i;
          aktifSayfa = i ~/ hucreSayisi;
        });
        for (int adim = 0; adim < 16; adim++) {
          if (benimNo != oynatmaNo || !mounted) return;
          for (final p in parcalar) {
            if (p.sessiz) continue;
            final olaylar = p.kalip.adimlar[adim];
            if (olaylar.isEmpty) continue;
            kalipAdimiCal(p.kalip, akor, olaylar, p.ses);
          }
          hedefMs += 15000 ~/ tempo;
          final bekle = hedefMs - saat.elapsedMilliseconds;
          if (bekle > 0) {
            await Future.delayed(Duration(milliseconds: bekle));
          }
        }
      }
      i++;
    }
    if (benimNo == oynatmaNo && mounted) {
      setState(() {
        durum = Durum.durdu;
        calanIndex = -1;
      });
    }
  }

  void duraklat() {
    if (durum != Durum.caliyor) return;
    oynatmaNo++;
    setState(() => durum = Durum.duraklatildi);
  }

  void durdur() {
    oynatmaNo++;
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

  Widget yatayStrip(List<Widget> cocuklar) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: cocuklar),
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
            height: 40,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secildi
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              border: Border.all(
                color: secildi ? Colors.deepPurple : Colors.grey,
                width: secildi ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              globalIsimler[i],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        label: Text(a.adi),
        onPressed: () => akorYerlestir(a),
      ),
    );
  }

  Widget hucre(int i) {
    final akor = tablo[i];
    final secildi = i == secili;
    final calan = (aktifSayfa * hucreSayisi + i) == calanIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => secili = i),
        onLongPress: () => setState(() => tablo[i] = null),
        child: Container(
          height: 38,
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: calan ? Colors.amber.shade200 : null,
            border: Border.all(
              color: secildi ? Colors.deepPurple : Colors.grey,
              width: secildi ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            akor?.adi ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget parcaSatiri(int p) {
    final parca = parcalar[p];
    return Row(
      children: [
        IconButton(
          onPressed: () => setState(() => parca.sessiz = !parca.sessiz),
          icon: Icon(parca.sessiz ? Icons.volume_off : Icons.volume_up),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parca.kalip.etiket,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: parca.ses,
                onChanged: (v) => setState(() => parca.ses = v),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => parcalar.removeAt(p)),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget soundsBolumu() {
    final filtre = kaliplar
        .where((k) =>
            k.enstruman == secEns && (secTarz == 'Tümü' || k.tarz == secTarz))
        .toList();
    final gecerli = filtre.contains(secKalip)
        ? secKalip
        : (filtre.isNotEmpty ? filtre.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enstrüman:'),
        DropdownButton<String>(
          isExpanded: true,
          value: secEns,
          items: [
            for (final e in enstrumanAdlari.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() => secEns = v ?? secEns),
        ),
        const SizedBox(height: 8),
        const Text('Tarz:'),
        DropdownButton<String>(
          isExpanded: true,
          value: secTarz,
          items: [
            for (final t in ['Tümü', ...tarzlar])
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => secTarz = v ?? secTarz),
        ),
        const SizedBox(height: 8),
        const Text('Kalıp:'),
        DropdownButton<Kalip>(
          isExpanded: true,
          value: gecerli,
          items: [
            for (final k in filtre)
              DropdownMenuItem(value: k, child: Text(k.ad)),
          ],
          onChanged: (k) => setState(() => secKalip = k),
        ),
        const SizedBox(height: 8),
        Center(
          child: FilledButton.icon(
            onPressed: (gecerli == null || parcalar.length >= enFazlaParca)
                ? null
                : () => setState(() => parcalar.add(Parca(gecerli!))),
            icon: const Icon(Icons.add),
            label: const Text('Parçalara ekle'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akor Stüdyo')),
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('Ton ve Akorlar'),
            initiallyExpanded: true,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              const Text('Ton:'),
              const SizedBox(height: 4),
              tonSecici(),
              const SizedBox(height: 12),
              Text('${globalIsimler[ton]} tonunun akorları:'),
              yatayStrip([
                for (final t in akorTurleri) akorChip(Akor(ton, t.kod)),
              ]),
              const SizedBox(height: 8),
            ],
          ),
          ExpansionTile(
            title: const Text('Akor Tablosu'),
            initiallyExpanded: true,
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    onPressed:
                        sayfalar.length < enFazlaSayfa ? sayfaEkle : null,
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
                'Dokun: kutuyu seç. Basılı tut: kutuyu sil.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: oynat,
                  icon: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: duraklat,
                  icon: const Icon(Icons.pause),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: durdur,
                  icon: const Icon(Icons.stop),
                ),
              ],
            ),
          ),
          ExpansionTile(
            title: const Text('Loop Page'),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              Row(
                children: [
                  Text('Tempo: $tempo'),
                  Expanded(
                    child: Slider(
                      min: 60,
                      max: 180,
                      divisions: 120,
                      label: '$tempo',
                      value: tempo.toDouble(),
                      onChanged: (v) => setState(() => tempo = v.round()),
                    ),
                  ),
                ],
              ),
              if (parcalar.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Parça yok. Sounds menüsünden parça ekle.'),
                ),
              for (int p = 0; p < parcalar.length; p++) parcaSatiri(p),
            ],
          ),
          ExpansionTile(
            title: const Text('Sounds'),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [soundsBolumu()],
          ),
        ],
      ),
    );
  }
}
