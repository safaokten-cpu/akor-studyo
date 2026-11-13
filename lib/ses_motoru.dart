import 'package:flutter_soloud/flutter_soloud.dart';
import 'akor.dart';
import 'kalip.dart';

// Ses motoru: dosyaları yükler ve kanal kanal çalar.
// Hangi enstrümanın ne çaldığını gitar.dart, piyano.dart, davul.dart bilir.
// Hangi türlerin olduğunu katalog.dart bilir.

// Ses dosyalarının nota aralığı (MIDI numarası).
const enAlcakNota = 48;
const enYuksekNota = 78;

// Kanallar: 0-5 gitar telleri (banka 0), 6-11 piyano, 12 kick, 13 snare,
// 14 hihat, 15-32 ek gitar bankaları (3 banka x 6 tel).
const _kanalSayisi = 33;
final Map<String, AudioSource> _kaynaklar = {};
final List<SoundHandle?> _kanallar =
    List<SoundHandle?>.filled(_kanalSayisi, null);
bool _hazir = false;

// Tür sesleri (clean, naylon...) seçilince yüklenir. Önek -> yükleme işi.
final Map<String, Future<void>> _yuklemeler = {};
final Set<String> _tamam = {};

// Dosya adı: {enstruman}_{nota}_{oktav}, ör. gitar_mi_4.
// Tür öneki de olur: gitar_clean_mi_4.
String sesDosyaAdi(String ens, int m) => '${ens}_${notalar[m % 12]}_${m ~/ 12}';

// Bir önekin tüm notalarının dosya adları.
List<String> _onekDosyalari(String onek) {
  final liste = <String>[];
  for (int m = enAlcakNota; m <= enYuksekNota; m++) {
    liste.add(sesDosyaAdi(onek, m));
  }
  return liste;
}

// Açılışta yüklenenler: akustik gitar, piyano, davul.
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

Future<void> _dosyalariYukle(List<String> adlar) async {
  for (final ad in adlar) {
    if (_kaynaklar.containsKey(ad)) continue;
    try {
      _kaynaklar[ad] = await SoLoud.instance.loadAsset('assets/sesler/$ad.wav');
    } catch (e) {
      // Dosya yoksa atla, o ses sessiz kalır.
    }
  }
}

Future<void> seslerHazirla() async {
  try {
    await SoLoud.instance.init();
    _hazir = true;
  } catch (e) {
    return;
  }
  // Aynı anda çalabilen ses sınırını yükselt (varsayılan 16, 4 gitar için az).
  // dynamic: kütüphane sürümünde bu fonksiyon yoksa derleme bozulmasın.
  try {
    (SoLoud.instance as dynamic).setMaxActiveVoiceCount(64);
  } catch (e) {
    // Sürüm desteklemiyorsa varsayılan kalır.
  }
  await _dosyalariYukle(_tumDosyalar());
  _tamam.addAll(['gitar', 'piyano']);
}

// Bu önekin sesleri yüklendi mi?
bool sesOnekiHazirMi(String onek) => _tamam.contains(onek);

// Bir türün seslerini yükler (ör. 'gitar_clean'). Zaten yüklüyse hemen döner,
// aynı anda iki kez istenirse tek yükleme yapılır.
Future<void> sesOnekiYukle(String onek) {
  if (!_hazir) return Future.value();
  if (_tamam.contains(onek)) return Future.value();
  return _yuklemeler.putIfAbsent(onek, () async {
    await _dosyalariYukle(_onekDosyalari(onek));
    _tamam.add(onek);
  });
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
