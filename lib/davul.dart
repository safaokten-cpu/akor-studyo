import 'ses_motoru.dart';

// Davul: k = kick, s = snare, h = hi-hat.
void davulCal(List<String> olaylar, double seviye) {
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
