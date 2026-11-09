const hepsiKodu = -1;

const enstrumanAdlari = {
  'gitar': 'Gitar',
  'piyano': 'Piyano',
  'davul': 'Davul',
};

const davulSesleri = ['kick', 'snare', 'hihat'];

const tarzlar = ['Rock', 'Pop', 'Akustik', 'Country'];

class Kalip {
  final String ad;
  final String enstruman;
  final String tarz;
  final List<List<int>> adimlar;
  const Kalip(this.ad, this.enstruman, this.tarz, this.adimlar);

  String get etiket => '${enstrumanAdlari[enstruman]}.$ad';
}

class Parca {
  final Kalip kalip;
  double ses = 0.8;
  bool sessiz = false;
  Parca(this.kalip);
}

List<List<int>> _adimlar(Map<int, List<int>> m) =>
    List.generate(16, (i) => m[i] ?? const <int>[]);

final List<Kalip> kaliplar = [
  // Gitar
  Kalip('Rock vuruş', 'gitar', 'Rock', _adimlar({
    0: [0, 2], 2: [0, 2], 4: [0, 2], 6: [0, 2],
    8: [0, 2], 10: [0, 2], 12: [0, 2], 14: [0, 2],
  })),
  Kalip('Strum', 'gitar', 'Pop', _adimlar({
    0: [hepsiKodu], 4: [hepsiKodu], 6: [hepsiKodu],
    10: [hepsiKodu], 12: [hepsiKodu],
  })),
  Kalip('Arpej', 'gitar', 'Akustik', _adimlar({
    0: [0], 2: [1], 4: [2], 6: [3], 8: [2], 10: [1], 12: [2], 14: [1],
  })),
  Kalip('Bas-akor', 'gitar', 'Country', _adimlar({
    0: [0], 4: [hepsiKodu], 8: [2], 12: [hepsiKodu],
  })),
  // Piyano
  Kalip('Sinkop', 'piyano', 'Rock', _adimlar({
    0: [hepsiKodu], 6: [hepsiKodu], 8: [hepsiKodu], 14: [hepsiKodu],
  })),
  Kalip('Blok akor', 'piyano', 'Pop', _adimlar({
    0: [hepsiKodu], 8: [hepsiKodu],
  })),
  Kalip('Arpej', 'piyano', 'Akustik', _adimlar({
    0: [0], 2: [1], 4: [2], 6: [3], 8: [4], 10: [3], 12: [2], 14: [1],
  })),
  Kalip('Ritim', 'piyano', 'Country', _adimlar({
    0: [0], 4: [hepsiKodu], 8: [2], 12: [hepsiKodu],
  })),
  // Davul (0 kick, 1 snare, 2 hihat)
  Kalip('Rock 4/4', 'davul', 'Rock', _adimlar({
    0: [0, 2], 2: [2], 4: [1, 2], 6: [2],
    8: [0, 2], 10: [0, 2], 12: [1, 2], 14: [2],
  })),
  Kalip('Pop', 'davul', 'Pop', _adimlar({
    0: [0, 2], 2: [2], 4: [1, 2], 6: [2],
    8: [0, 2], 10: [2], 12: [1, 2], 14: [2],
  })),
  Kalip('Hafif', 'davul', 'Akustik', _adimlar({
    0: [0], 4: [2], 8: [1], 12: [2],
  })),
  Kalip('Tren ritmi', 'davul', 'Country', _adimlar({
    0: [0, 2], 2: [1], 4: [0, 2], 6: [1],
    8: [0, 2], 10: [1], 12: [0, 2], 14: [1],
  })),
];
