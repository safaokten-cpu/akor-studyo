import 'package:audioplayers/audioplayers.dart';
import 'akor.dart';
import 'kalip.dart';

final List<AudioPlayer> _havuz =
    List.generate(24, (_) => AudioPlayer());
int _sira = 0;

Future<void> sesCal(String dosya, double seviye) async {
  final p = _havuz[_sira];
  _sira = (_sira + 1) % _havuz.length;
  try {
    await p.stop();
    await p.setVolume(seviye);
    await p.play(AssetSource('sesler/$dosya.wav'));
  } catch (e) {
    // Dosya yoksa sessiz kal.
  }
}

void akorOnizle(Akor akor, String enstruman) {
  final tonlar = akor.sesleri(3);
  for (int n = 0; n < tonlar.length; n++) {
    final t = tonlar[n];
    Future.delayed(
      Duration(milliseconds: n * 90),
      () => sesCal('${enstruman}_${t.nota}_${t.oktav}', 0.8),
    );
  }
}

void kalipAdimiCal(Kalip k, Akor akor, List<int> olaylar, double seviye) {
  if (k.enstruman == 'davul') {
    for (final o in olaylar) {
      sesCal('davul_${davulSesleri[o]}', seviye);
    }
    return;
  }
  final tonlar = akor.sesleri(3);
  final secilen = <NotaSesi>[];
  for (final o in olaylar) {
    if (o == hepsiKodu) {
      secilen.addAll(tonlar);
    } else {
      final t = tonlar[o % tonlar.length];
      secilen.add(NotaSesi(t.nota, t.oktav + o ~/ tonlar.length));
    }
  }
  final aralik = k.enstruman == 'gitar' ? 18 : 0;
  for (int n = 0; n < secilen.length; n++) {
    final s = secilen[n];
    final dosya = '${k.enstruman}_${s.nota}_${s.oktav}';
    if (aralik == 0) {
      sesCal(dosya, seviye);
    } else {
      Future.delayed(
        Duration(milliseconds: n * aralik),
        () => sesCal(dosya, seviye),
      );
    }
  }
}
