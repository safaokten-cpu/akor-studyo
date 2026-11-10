import 'package:flutter_soloud/flutter_soloud.dart';
import 'akor.dart';
import 'kalip.dart';

// Gitar açık telleri (Mi La Re Sol Si Mi), ses dosyalarının aralığına göre.
const _gitarTelleri = [52, 57, 62, 67, 71, 76];
const _enAlcak = 48;
const _enYuksek = 78;

// Kanallar: 0-5 gitar telleri, 6-11 piyano, 12 kick, 13 snare, 14 hihat.
final Map<String, AudioSource> _kaynaklar = {};
final List<SoundHandle?> _kanallar = List<SoundHandle?>.filled(15, null);
bool _hazir = false;
int _piyanoSira = 0;

String _dosyaAdi(String ens, int m) => '${ens}_${notalar[m % 12]}_${m ~/ 12}';

List<String> _tumDosyalar() {
  final liste = <String>[];
  for (int m = _enAlcak; m <= _enYuksek; m++) {
    liste.add(_dosyaAdi('gitar', m));
    liste.add(_dosyaAdi('piyano', m));
  }
  for (final d in davulSesleri) {
    liste.add('davul_$d');
  }
  return liste;
}

Future<void> seslerHazirla() async {
  try {
    await SoLoud.instance.init();
    _hazir = true;
  } catch (e) {
    return;
  }
  for (final ad in _tumDosyalar()) {
    try {
      _kaynaklar[ad] = await SoLoud.instance.loadAsset('assets/sesler/$ad.wav');
    } catch (e) {
      // Dosya yoksa atla, o ses sessiz kalır.
    }
  }
}

Future<void> _durdurGuvenli(SoundHandle h) async {
  try {
    await SoLoud.instance.stop(h);
  } catch (e) {
    // Ses zaten bitmişse sorun değil.
  }
}

void sesCal(String ad, double seviye, int kanal) {
  if (!_hazir) return;
  final kaynak = _kaynaklar[ad];
  if (kaynak == null) return;
  final eski = _kanallar[kanal];
  if (eski != null) {
    _durdurGuvenli(eski);
  }
  SoLoud.instance.play(kaynak, volume: seviye).then((h) {
    _kanallar[kanal] = h;
  });
}

// ---- Gitar: akoru gerçek tellere dizer ----
// Dönen liste: [tel, midi], alttan üste.
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
      if (p > _enYuksek) break;
      if (siniflar.contains(p % 12)) {
        sonuc.add([tel, p]);
        break;
      }
    }
  }
  return sonuc;
}

void _gitarNota(List<int> tm, double vs, int gecikme) {
  final ad = _dosyaAdi('gitar', tm[1]);
  final tel = tm[0];
  if (gecikme <= 0) {
    sesCal(ad, vs, tel);
  } else {
    Future.delayed(Duration(milliseconds: gecikme), () => sesCal(ad, vs, tel));
  }
}

void _gitarCal(Akor akor, List<String> olaylar, double seviye) {
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

// ---- Piyano: sol el bas, sağ el akor ----
class _Piyano {
  final int bas;
  final List<int> sag;
  _Piyano(this.bas, this.sag);
}

_Piyano _piyanoDizilimi(Akor a) {
  final sag = <int>[];
  for (final x in turBul(a.tur).aralik) {
    var p = 60 + a.kok + x;
    while (p > _enYuksek) {
      p -= 12;
    }
    sag.add(p);
  }
  sag.sort();
  return _Piyano(48 + a.kok, sag);
}

void _piyanoNota(int m, double vs) {
  if (m < _enAlcak || m > _enYuksek) return;
  final kanal = 6 + (_piyanoSira % 6);
  _piyanoSira++;
  sesCal(_dosyaAdi('piyano', m), vs, kanal);
}

void _piyanoCal(Akor akor, List<String> olaylar, double seviye) {
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

// ---- Davul ----
void _davulCal(List<String> olaylar, double seviye) {
  for (final t in olaylar) {
    if (t == 'k') {
      sesCal('davul_kick', seviye, 12);
    } else if (t == 's') {
      sesCal('davul_snare', seviye, 13);
    } else if (t == 'h') {
      sesCal('davul_hihat', seviye * 0.7, 14);
    }
  }
}

void kalipAdimiCal(Kalip k, Akor akor, List<String> olaylar, double seviye) {
  if (k.enstruman == 'davul') {
    _davulCal(olaylar, seviye);
  } else if (k.enstruman == 'piyano') {
    _piyanoCal(akor, olaylar, seviye);
  } else {
    _gitarCal(akor, olaylar, seviye);
  }
}

void akorOnizle(Akor akor, String enstruman) {
  if (enstruman == 'piyano') {
    _piyanoCal(akor, ['c'], 0.8);
  } else {
    _gitarCal(akor, ['d'], 0.8);
  }
}
