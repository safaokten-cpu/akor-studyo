import 'katalog.dart';
import 'ses_motoru.dart';

// Davul: her harf bir ses (harflerin anlamı davul_stilleri.dart'ta):
// k=kick s=snare e=hayalet snare h=hi-hat r=ride c=crash x=splash m=marakas
// 1=küçük tom 2=orta tom 3=büyük tom 4=floor tom
//
// Hangi kitin çaldığı (Standart, Rock, Jazz) katalog.dart'taki
// aktifDavulTuru ile belirlenir. Dosya adı: {onek}_{ses}.wav
// Ör. davul_rock_kick.wav, davul_jazz_ride.wav, davul_kick.wav (Standart).

class _DavulSesi {
  final String ad;
  final int kanal;
  final double seviye;
  const _DavulSesi(this.ad, this.kanal, this.seviye);
}

// Kanallar: 12-14 eskiden beri kick/snare/hihat. 33-40 yeni sesler.
const _sesler = <String, _DavulSesi>{
  'k': _DavulSesi('kick', 12, 1.0),
  's': _DavulSesi('snare', 13, 1.0),
  'e': _DavulSesi('snare', 13, 0.3),
  'h': _DavulSesi('hihat', 14, 0.7),
  'r': _DavulSesi('ride', 33, 0.75),
  'c': _DavulSesi('crash', 34, 0.9),
  'x': _DavulSesi('splash', 35, 0.8),
  'm': _DavulSesi('marakas', 36, 0.65),
  '1': _DavulSesi('tom_kucuk', 37, 0.9),
  '2': _DavulSesi('tom_orta', 38, 0.9),
  '3': _DavulSesi('tom_buyuk', 39, 0.9),
  '4': _DavulSesi('tom_floor', 40, 0.9),
};

// Kitte yoksa (ör. Standart kitte ride, crash, tom) çalınacak yedek ses.
const _yedekler = <String, String>{
  'r': 'h',
  'c': 'h',
  'x': 'h',
  'm': 'h',
  '1': 's',
  '2': 's',
  '3': 'k',
  '4': 'k',
};

void davulCal(List<String> olaylar, double seviye) {
  final onek = aktifDavulTuru.onek;
  final kit = aktifDavulTuru.seviye;
  for (final t in olaylar) {
    var harf = t;
    var ses = _sesler[harf];
    while (ses != null && !sesYuklu('${onek}_${ses.ad}')) {
      final yedek = _yedekler[harf];
      if (yedek == null) {
        ses = null;
        break;
      }
      harf = yedek;
      ses = _sesler[harf];
    }
    if (ses == null) continue;
    sesCal('${onek}_${ses.ad}', seviye * kit * ses.seviye, ses.kanal);
  }
}
