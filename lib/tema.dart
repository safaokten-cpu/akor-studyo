import 'package:flutter/material.dart';
import 'akor.dart';

// ---- Doğa paleti ----
// Gökyüzü, çayır, toprak, deniz ve sonbahar yaprağı.
const renkGok = Color(0xFFD5E7EC); // sabah gökyüzü
const renkCayir = Color(0xFFE6EDD3); // çayır
const renkKrem = Color(0xFFF4F1DE); // kuru ot
const renkKum = Color(0xFFE3E6CC); // boş kutu
const renkKart = Color(0xB3FFFFFF);
const renkKenar = Color(0xFFB9BF98);
const renkToprak = Color(0xFF3E2C1F); // yazı
const renkToprakAcik = Color(0xFF7A6248); // ikincil yazı
const renkYaprak = Color(0xFF4F7F36);
const renkCimen = Color(0xFF8DB255);
const renkCimenAcik = Color(0xFFCFE0A6);
const renkDeniz = Color(0xFF2B7A86);
const renkSonbahar = Color(0xFFE0A32E);
const renkKutuk = Color(0xFF8B5E3C);

// Her akor kökü için doğadan bir renk.
const kokRenkleri = [
  Color(0xFF5B8C3E), // C  yaprak
  Color(0xFF8DB255), // C# taze çimen
  Color(0xFF2F7F86), // D  deniz
  Color(0xFF7FB7D9), // D# gök
  Color(0xFFE0A32E), // E  sonbahar sarısı
  Color(0xFFB5792F), // F  kuru yaprak
  Color(0xFF8B5E3C), // F# ağaç kabuğu
  Color(0xFF6B8E4E), // G  zeytin
  Color(0xFF4F9DA6), // G# turkuaz
  Color(0xFFD98B2B), // A  kehribar
  Color(0xFF9C7A55), // A# toprak
  Color(0xFF5E8CB0), // B  derin gök
];

Color akorRengi(Akor? a) => a == null ? renkKenar : kokRenkleri[a.kok % 12];

Color yaziRengi(Color zemin) =>
    zemin.computeLuminance() > 0.42 ? renkToprak : Colors.white;

IconData ensIkon(String e) => e == 'gitar'
    ? Icons.music_note
    : e == 'piyano'
        ? Icons.piano
        : Icons.graphic_eq;

Color ensRenk(String e) => e == 'gitar'
    ? renkSonbahar
    : e == 'piyano'
        ? renkDeniz
        : renkKutuk;

ThemeData temaOlustur() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: renkKrem,
    colorScheme: ColorScheme.fromSeed(
      seedColor: renkYaprak,
      brightness: Brightness.light,
    ).copyWith(surface: renkKrem, onSurface: renkToprak),
    chipTheme: const ChipThemeData(
      backgroundColor: renkKum,
      selectedColor: renkCimenAcik,
      side: BorderSide(color: renkKenar),
      labelStyle: TextStyle(
          fontSize: 12.5, color: renkToprak, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(
          fontSize: 12.5, color: renkToprak, fontWeight: FontWeight.w600),
      padding: EdgeInsets.symmetric(horizontal: 2),
    ),
  );
}
