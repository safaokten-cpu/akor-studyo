const notalar = [
  'do', 'do_diyez', 're', 're_diyez', 'mi', 'fa',
  'fa_diyez', 'sol', 'sol_diyez', 'la', 'la_diyez', 'si'
];

const globalIsimler = [
  'C', 'C#', 'D', 'D#', 'E', 'F',
  'F#', 'G', 'G#', 'A', 'A#', 'B'
];

String globalIsim(String nota) => globalIsimler[notalar.indexOf(nota)];

List<String> akorNotalari(int kok, String tur) {
  final aralik = tur == 'min' ? [0, 3, 7] : [0, 4, 7];
  return aralik.map((a) => notalar[(kok + a) % 12]).toList();
}
