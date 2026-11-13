import 'akor.dart';
import 'ses_motoru.dart';

// Gitar açık telleri (Mi La Re Sol Si Mi), ses dosyalarının aralığına göre.
const _gitarTelleri = [52, 57, 62, 67, 71, 76];

// Akoru gerçek tellere dizer. Dönen liste: [tel, midi], alttan üste.
List<List<int>> _gitarDizilimi(Akor a) {
  final siniflar = turBul(a.tur).aralik.map((x) => (a.kok + x) % 12).toSet();
  int bas = -1;
  int basPitch = 0;
  for (int tel = 0; tel < 3 && bas < 0; tel++) {
    for (int f = 0; f <= 4; f++) {
      final p = _gitarTelleri[tel] + f;
      if (p % 12 == a.kok) {
        bas = tel;
        basPitch = p;
        break;
      }
    }
  }
  if (bas < 0) {
    bas = 0;
    basPitch = _gitarTelleri[0];
  }
  final sonuc = <List<int>>[
    [bas, basPitch]
  ];
  for (int tel = bas + 1; tel < 6; tel++) {
    for (int f = 0; f <= 5; f++) {
      final p = _gitarTelleri[tel] + f;
      if (p > enYuksekNota) break;
      if (siniflar.contains(p % 12)) {
        sonuc.add([tel, p]);
        break;
      }
    }
  }
  return sonuc;
}

void _gitarNota(List<int> tm, double vs, int gecikme) {
  final ad = sesDosyaAdi('gitar', tm[1]);
  final tel = tm[0];
  if (gecikme <= 0) {
    sesCal(ad, vs, tel);
  } else {
    Future.delayed(Duration(milliseconds: gecikme), () => sesCal(ad, vs, tel));
  }
}

void gitarCal(Akor akor, List<String> olaylar, double seviye) {
  final v = _gitarDizilimi(akor);
  final n = v.length;
  for (final t in olaylar) {
    switch (t) {
      case 'p':
        _gitarNota(v[0], seviye, 0);
        break;
      case 'P':
        _gitarNota(v[n > 1 ? 1 : 0], seviye * 0.9, 0);
        break;
      case 'i':
        _gitarNota(v[n >= 3 ? n - 3 : 0], seviye * 0.85, 0);
        break;
      case 'm':
        _gitarNota(v[n >= 2 ? n - 2 : 0], seviye * 0.85, 0);
        break;
      case 'a':
        _gitarNota(v[n - 1], seviye * 0.85, 0);
        break;
      case 'c':
        for (final x in v) {
          _gitarNota(x, seviye * 0.8, 0);
        }
        break;
      case 'd':
        for (int j = 0; j < n; j++) {
          _gitarNota(v[j], seviye * 0.85, j * 4);
        }
        break;
      case 'u':
        final alt = n > 4 ? n - 4 : 0;
        int sira = 0;
        for (int j = n - 1; j >= alt; j--) {
          _gitarNota(v[j], seviye * 0.7, sira * 3);
          sira++;
        }
        break;
      case 'b':
        final ust = n < 3 ? n : 3;
        for (int j = 0; j < ust; j++) {
          _gitarNota(v[j], seviye * 0.9, j * 3);
        }
        break;
    }
  }
}
