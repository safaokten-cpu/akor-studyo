import 'package:flutter_soloud/flutter_soloud.dart';
import 'akor.dart';
import 'kalip.dart';

// Ses motoru: dosyaları yükler ve kanal kanal çalar.
// Hangi enstrümanın ne çaldığını gitar.dart, piyano.dart, davul.dart bilir.

// Ses dosyalarının nota aralığı (MIDI numarası).
const enAlcakNota = 48;
const enYuksekNota = 78;

// Kanallar: 0-5 gitar telleri, 6-11 piyano, 12 kick, 13 snare, 14 hihat.
final Map<String, AudioSource> _kaynaklar = {};
final List<SoundHandle?> _kanallar = List<SoundHandle?>.filled(15, null);
bool _hazir = false;

// Dosya adı: {enstruman}_{nota}_{oktav}, ör. gitar_mi_4.
String sesDosyaAdi(String ens, int m) => '${ens}_${notalar[m % 12]}_${m ~/ 12}';

List<String> _tumDosyalar() {
  final liste = <String>[];
  for (int m = enAlcakNota; m <= enYuksekNota; m++) {
    liste.add(sesDosyaAdi('gitar', m));
    liste.add(sesDosyaAdi('piyano', m));
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
