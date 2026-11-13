import 'akor.dart';

// Akor sitesinden kopyalanan yazıyı okur: akor satırlarını ve "Ritim:" satırını bulur.

const _harfKoklari = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};

// Yazılışlar -> uygulamadaki akor türü kodu.
const _ekler = <String, String>{
  '': 'maj',
  'maj': 'maj',
  'M': 'maj',
  'm': 'm',
  'min': 'm',
  '-': 'm',
  '7': '7',
  'maj7': 'maj7',
  'M7': 'maj7',
  'm7': 'm7',
  'min7': 'm7',
  '-7': 'm7',
  '6': '6',
  'm6': 'm6',
  'dim': 'dim',
  'o': 'dim',
  '°': 'dim',
  'dim7': 'dim7',
  'o7': 'dim7',
  '°7': 'dim7',
  'm7b5': 'm7b5',
  'ø': 'm7b5',
  'ø7': 'm7b5',
  'aug': 'aug',
  '+': 'aug',
  'sus2': 'sus2',
  'sus4': 'sus4',
  'sus': 'sus4',
  'add9': 'add9',
  '9': '9',
};

// "Dm", "F#m7", "Bb", "G7", "Am/C" gibi yazıyı Akor'a çevirir. Anlamazsa null.
Akor? akorCoz(String yazi) {
  var s = yazi.trim().replaceAll(RegExp(r'[()\[\]]'), '');
  final bolme = s.indexOf('/');
  if (bolme > 0) s = s.substring(0, bolme);
  if (s.isEmpty) return null;
  final harfKoku = _harfKoklari[s[0].toUpperCase()];
  if (harfKoku == null) return null;
  int kok = harfKoku;
  int i = 1;
  if (i < s.length) {
    final c = s[i];
    if (c == '#' || c == '♯') {
      kok += 1;
      i++;
    } else if (c == 'b' || c == '♭') {
      kok -= 1;
      i++;
    }
  }
  kok = ((kok % 12) + 12) % 12;
  final ek = s.substring(i);
  final tur = _ekler[ek] ?? _ekler[ek.toLowerCase()];
  if (tur == null) return null;
  return Akor(kok, tur);
}

// Sayı içeren ama listemizde olmayan akorlar (C11 gibi) de akor satırı sayılsın.
final _sayiliAkor = RegExp(
    r'^[A-G][#b♯♭]?[A-Za-z]*[0-9][A-Za-z0-9+#♯♭\-]*(/[A-G][#b♯♭]?)?$');

String _jetonTemizle(String j) =>
    j.trim().replaceAll(RegExp(r'^[(\[|,;]+|[)\]|,;]+$'), '');

bool _ayrac(String t) =>
    t == '-' ||
    t == '/' ||
    t == '.' ||
    t == '|' ||
    t == '||' ||
    t == '–' ||
    t == '—' ||
    RegExp(r'^[xX]\d+$').hasMatch(t);

bool _akorBenzeri(String t) {
  if (!RegExp(r'^[A-G]').hasMatch(t)) return false;
  return akorCoz(t) != null || _sayiliAkor.hasMatch(t);
}

// Satırdaki her şey akorsa akor adlarını döndürür, değilse null (söz satırı).
List<String>? _akorSatiri(String satir) {
  var jetonlar = satir.trim().split(RegExp(r'\s+'));
  // "Intro: Am G" gibi başlıklı satırlarda başlığı at.
  if (jetonlar.length > 1 && jetonlar.first.endsWith(':')) {
    jetonlar = jetonlar.sublist(1);
  }
  final sonuc = <String>[];
  for (final j in jetonlar) {
    final t = _jetonTemizle(j);
    if (t.isEmpty || _ayrac(t)) continue;
    if (!_akorBenzeri(t)) return null;
    sonuc.add(t);
  }
  return sonuc.isEmpty ? null : sonuc;
}

// Türkçe İ/I/ı karışıklığını giderip küçük harfe çevirir.
String _ritimNorm(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    if (c == 'İ' || c == 'I' || c == 'ı') {
      b.write('i');
    } else {
      b.write(c.toLowerCase());
    }
  }
  return b.toString();
}

// "P İ M A İ M İ" veya "pimaimi" -> "p i m a i m i". Okunacak harf yoksa null.
// p = baş parmak, i/m/a = parmaklar, nokta = boşluk. Büyük P de baş parmaktır.
String? ritimTemizle(String ham) {
  final n = _ritimNorm(ham);
  final liste = <String>[];
  for (final c in n.split('')) {
    if (c == 'p' || c == 'i' || c == 'm' || c == 'a' || c == '.') {
      liste.add(c);
    }
  }
  return liste.isEmpty ? null : liste.join(' ');
}

bool _ritimSatiriMi(String satir) {
  final n = _ritimNorm(satir).replaceAll(RegExp(r'\s'), '');
  return n.startsWith('ritim');
}

String? _ritimDeseni(String satir) {
  var n = _ritimNorm(satir).replaceAll(RegExp(r'\s'), '');
  if (!n.startsWith('ritim')) return null;
  n = n.substring(5).replaceAll(RegExp(r'[:\-|]'), '');
  for (final c in n.split('')) {
    if (!(c == 'p' || c == 'i' || c == 'm' || c == 'a' || c == '.')) {
      return null;
    }
  }
  return ritimTemizle(n);
}

class YaziSonucu {
  final List<String> akorlar;
  final String? ritim;
  const YaziSonucu(this.akorlar, this.ritim);
}

// Yapıştırılan metni okur: akor adları sırayla, ritim varsa deseni.
YaziSonucu yaziyiOku(String metin) {
  final akorlar = <String>[];
  String? ritim;
  for (final ham in metin.split(RegExp(r'\r?\n'))) {
    final satir = ham.trim();
    if (satir.isEmpty) continue;
    if (_ritimSatiriMi(satir)) {
      ritim ??= _ritimDeseni(satir);
      continue;
    }
    final a = _akorSatiri(satir);
    if (a != null) akorlar.addAll(a);
  }
  return YaziSonucu(akorlar, ritim);
}

class AkorListesi {
  final List<Akor> akorlar;
  final List<String> hatali;
  const AkorListesi(this.akorlar, this.hatali);
}

// Boşlukla ayrılmış akor yazısını Akor listesine çevirir, anlaşılmayanları ayırır.
AkorListesi akorlariCoz(String metin) {
  final akorlar = <Akor>[];
  final hatali = <String>[];
  for (final j in metin.split(RegExp(r'\s+'))) {
    final t = _jetonTemizle(j);
    if (t.isEmpty || _ayrac(t)) continue;
    final a = akorCoz(t);
    if (a == null) {
      hatali.add(t);
    } else {
      akorlar.add(a);
    }
  }
  return AkorListesi(akorlar, hatali);
}
