import 'akor.dart';
import 'ses_motoru.dart';

// Piyano: sol el bas, sağ el akor.
int _piyanoSira = 0;

class _Piyano {
  final int bas;
  final List<int> sag;
  _Piyano(this.bas, this.sag);
}

_Piyano _piyanoDizilimi(Akor a) {
  final sag = <int>[];
  for (final x in turBul(a.tur).aralik) {
    var p = 60 + a.kok + x;
    while (p > enYuksekNota) {
      p -= 12;
    }
    sag.add(p);
  }
  sag.sort();
  return _Piyano(48 + a.kok, sag);
}

void _piyanoNota(int m, double vs) {
  if (m < enAlcakNota || m > enYuksekNota) return;
  final kanal = 6 + (_piyanoSira % 6);
  _piyanoSira++;
  sesCal(sesDosyaAdi('piyano', m), vs, kanal);
}

void piyanoCal(Akor akor, List<String> olaylar, double seviye) {
  final d = _piyanoDizilimi(akor);
  final sag = d.sag;
  final n = sag.length;
  for (final t in olaylar) {
    switch (t) {
      case 'p':
        _piyanoNota(d.bas, seviye);
        break;
      case 'P':
        _piyanoNota(d.bas + 7, seviye * 0.9);
        break;
      case 'i':
        _piyanoNota(sag[0], seviye * 0.85);
        break;
      case 'm':
        _piyanoNota(sag[n > 1 ? 1 : 0], seviye * 0.85);
        break;
      case 'a':
        _piyanoNota(sag[n - 1], seviye * 0.85);
        break;
      case 'c':
        _piyanoNota(d.bas, seviye);
        for (final x in sag) {
          _piyanoNota(x, seviye * 0.8);
        }
        break;
      case 'h':
        for (final x in sag) {
          _piyanoNota(x, seviye * 0.8);
        }
        break;
    }
  }
}
