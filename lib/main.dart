import 'package:flutter/material.dart';
import 'akor.dart';
import 'ses.dart';

void main() => runApp(const AkorStudyo());

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
  int nota = 5;
  final List<Akor?> tablo = List<Akor?>.filled(16, null);
  int secili = 0;
  Durum durum = Durum.durdu;
  int calanIndex = -1;
  int oynatmaNo = 0;

  @override
  void dispose() {
    oynatmaNo++;
    super.dispose();
  }

  void akorYerlestir(Akor a) {
    setState(() {
      tablo[secili] = a;
      if (secili < tablo.length - 1) secili++;
    });
    akorCal('gitar', a.notaListesi);
  }

  Future<void> oynat() async {
    if (durum == Durum.caliyor) return;
    final benimNo = ++oynatmaNo;
    final baslangic = durum == Durum.duraklatildi ? calanIndex : 0;
    setState(() => durum = Durum.caliyor);
    for (int i = baslangic; i < tablo.length; i++) {
      if (benimNo != oynatmaNo || !mounted) return;
      final akor = tablo[i];
      if (akor == null) continue;
      setState(() => calanIndex = i);
      akorCal('gitar', akor.notaListesi);
      await Future.delayed(const Duration(milliseconds: 2000));
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

  Widget yatayStrip(List<Widget> cocuklar) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: cocuklar),
    );
  }

  Widget notaSecici(int secilen, void Function(int) degisti) {
    return yatayStrip([
      for (int i = 0; i < 12; i++)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(globalIsimler[i]),
            selected: secilen == i,
            onSelected: (_) => degisti(i),
          ),
        ),
    ]);
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
    final calan = i == calanIndex;
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
              notaSecici(ton, (i) => setState(() => ton = i)),
              const SizedBox(height: 8),
              Text('${globalIsimler[ton]} tonunun akorları:'),
              yatayStrip([
                for (final a in tonAkorlari(ton)) akorChip(a),
              ]),
              const SizedBox(height: 12),
              const Text('Nota seç:'),
              notaSecici(nota, (i) => setState(() => nota = i)),
              const SizedBox(height: 8),
              Text('${globalIsimler[nota]} akor çeşitleri:'),
              yatayStrip([
                for (final t in akorTurleri) akorChip(Akor(nota, t.kod)),
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
              const Text(
                'Dokun: kutuyu seç. Basılı tut: kutuyu sil.',
                style: TextStyle(fontSize: 12),
              ),
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
          const ExpansionTile(
            title: Text('Loop Page'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Parça listesi burada olacak (Ders 7).'),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Sounds'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Enstrüman ve çalış tarzı burada olacak (Ders 8).'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
