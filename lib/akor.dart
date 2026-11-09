const notalar = [
  'do', 'do_diyez', 're', 're_diyez', 'mi', 'fa',
  'fa_diyez', 'sol', 'sol_diyez', 'la', 'la_diyez', 'si'
];

const globalIsimler = [
  'C', 'C#', 'D', 'D#', 'E', 'F',
  'F#', 'G', 'G#', 'A', 'A#', 'B'
];

String globalIsim(String nota) => globalIsimler[notalar.indexOf(nota)];

class NotaSesi {
  final String nota;
  final int oktav;
  const NotaSesi(this.nota, this.oktav);
}

class AkorTuru {
  final String kod;
  final String ek;
  final String ad;
  final List<int> aralik;
  const AkorTuru(this.kod, this.ek, this.ad, this.aralik);
}

const akorTurleri = [
  AkorTuru('maj', '', 'Majör', [0, 4, 7]),
  AkorTuru('m', 'm', 'Minör', [0, 3, 7]),
  AkorTuru('7', '7', 'Dominant 7', [0, 4, 7, 10]),
  AkorTuru('maj7', 'maj7', 'Majör 7', [0, 4, 7, 11]),
  AkorTuru('m7', 'm7', 'Minör 7', [0, 3, 7, 10]),
  AkorTuru('6', '6', 'Majör 6', [0, 4, 7, 9]),
  AkorTuru('m6', 'm6', 'Minör 6', [0, 3, 7, 9]),
  AkorTuru('dim', 'dim', 'Diminished', [0, 3, 6]),
  AkorTuru('dim7', 'dim7', 'Diminished 7', [0, 3, 6, 9]),
  AkorTuru('m7b5', 'm7b5', 'Yarı diminished', [0, 3, 6, 10]),
  AkorTuru('aug', 'aug', 'Augmented', [0, 4, 8]),
  AkorTuru('sus2', 'sus2', 'Sus2', [0, 2, 7]),
  AkorTuru('sus4', 'sus4', 'Sus4', [0, 5, 7]),
  AkorTuru('add9', 'add9', 'Add9', [0, 4, 7, 14]),
  AkorTuru('9', '9', 'Dominant 9', [0, 4, 7, 10, 14]),
];

AkorTuru turBul(String kod) =>
    akorTurleri.firstWhere((t) => t.kod == kod);

List<String> akorNotalari(int kok, String tur) {
  return turBul(tur).aralik.map((a) => notalar[(kok + a) % 12]).toList();
}

class Akor {
  final int kok;
  final String tur;
  const Akor(this.kok, this.tur);

  String get adi => globalIsimler[kok] + turBul(tur).ek;
  List<String> get notaListesi => akorNotalari(kok, tur);

  List<NotaSesi> sesleri(int tabanOktav) {
    return turBul(tur).aralik.map((a) {
      final yarimSes = tabanOktav * 12 + kok + a;
      return NotaSesi(notalar[yarimSes % 12], yarimSes ~/ 12);
    }).toList();
  }
}

List<Akor> tonAkorlari(int ton) {
  return [
    Akor(ton, 'maj'),
    Akor((ton + 5) % 12, 'maj'),
    Akor((ton + 7) % 12, 'maj'),
    Akor((ton + 2) % 12, 'm'),
    Akor((ton + 4) % 12, 'm'),
    Akor((ton + 9) % 12, 'm'),
  ];
}
