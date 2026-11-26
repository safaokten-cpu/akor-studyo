// Davul stilleri
//
// Her stil bir "üretici"dir: ölçünün vuruş gruplarını alır
// (4/4 = [2,2,2,2], 6/8 = [3,3], 7/8 = [2,2,3] ...) ve o ölçüye uygun deseni
// yazar. Böylece her stil 10 ölçünün hepsinde çalışır, ölçü değişince davul
// susmaz.
//
// Desen dili: her kelime bir 8'lik nota. '.' = sus, '+' = aynı anda.
//   k = kick              s = snare           e = hayalet snare (çok hafif)
//   h = hi-hat            r = ride            c = crash
//   x = splash            m = marakas
//   1 = küçük tom   2 = orta tom   3 = büyük tom   4 = floor tom
// Kitte olmayan ses (Standart kitte tom, ride, crash gibi) davul.dart'ta
// yedek sesle çalınır.
//
// Yeni stil eklemek için: bir üretici fonksiyon yaz, en alttaki
// davulStilleri listesine bir satır ekle. Başka dosyaya dokunmaya gerek yok.

class DavulStili {
  final String ad;
  final String tarz;
  final String Function(List<int> gruplar) uret;
  const DavulStili(this.ad, this.tarz, this.uret);
}

// Bir ölçünün adımlarını (8'likler) tutan küçük tahta.
class _Izgara {
  final List<int> g;
  final List<int> bas;
  final List<List<String>> t;
  _Izgara._(this.g, this.bas, this.t);

  factory _Izgara(List<int> g) {
    final bas = <int>[];
    var s = 0;
    for (final x in g) {
      bas.add(s);
      s += x;
    }
    return _Izgara._(
        g, bas, List<List<String>>.generate(s, (_) => <String>[]));
  }

  int get n => g.length;
  int get slot => t.length;

  // Aynı ses aynı adıma iki kez yazılmaz.
  void ekle(int i, String ses) {
    if (i < 0 || i >= slot) return;
    if (!t[i].contains(ses)) t[i].add(ses);
  }

  void hepsineEkle(String ses) {
    for (int i = 0; i < slot; i++) {
      ekle(i, ses);
    }
  }

  // Bir adımdaki her şeyi silip yerine tek ses koyar.
  void degistir(int i, String ses) {
    if (i < 0 || i >= slot) return;
    t[i] = [ses];
  }

  String desen() => t.map((e) => e.isEmpty ? '.' : e.join('+')).join(' ');
}

// 4/4 gibi dört eşit vuruşlu ölçü mü?
bool _dortDord(List<int> g) => g.length == 4 && g.every((x) => x == 2);

// Vuruş gruplarına kick/snare dağılımı.
// 2 grup: k s | 3 grup: k s s | 4 grup: k s k s | 5 grup: k s k k s
List<String> _roller(int n) {
  switch (n) {
    case 2:
      return ['k', 's'];
    case 3:
      return ['k', 's', 's'];
    case 4:
      return ['k', 's', 'k', 's'];
    default:
      return ['k', 's', 'k', 'k', 's'];
  }
}

String _rol(List<String> r, int gi) => r[gi % r.length];

// Snare'in düştüğü grup (yarım zaman ve hafif stiller için).
int _snareGrubu(int n) => n.isEven ? n ~/ 2 : n - 1;

// ------------------------------------------------------------------
// ROCK ve POP
// ------------------------------------------------------------------

// Temel rock/pop: her 8'likte zil, gruplara kick-snare.
// 4/4 rockta 3. vuruşun "ve"sine ekstra kick (ekKick).
String _rockUret(List<int> g, String zil,
    {bool ekKick = false, bool crash = false}) {
  final z = _Izgara(g);
  z.hepsineEkle(zil);
  final r = _roller(z.n);
  for (int gi = 0; gi < z.n; gi++) {
    z.ekle(z.bas[gi], _rol(r, gi));
  }
  if (ekKick && _dortDord(g)) z.ekle(z.bas[2] + 1, 'k');
  if (crash) {
    z.t[0].remove(zil);
    z.ekle(0, 'c');
  }
  return z.desen();
}

String _rockTemel(List<int> g) => _rockUret(g, 'h', ekKick: true);
String _rockRide(List<int> g) => _rockUret(g, 'r', ekKick: true);
String _rockNakarat(List<int> g) =>
    _rockUret(g, 'r', ekKick: true, crash: true);
String _popTemel(List<int> g) => _rockUret(g, 'h');

// Yarım zaman: kick birde, snare ölçünün ortasında.
String _rockYarim(List<int> g) {
  final z = _Izgara(g);
  z.hepsineEkle('h');
  z.ekle(0, 'k');
  z.ekle(z.bas[_snareGrubu(z.n)], 's');
  return z.desen();
}

// Pop senkop: 4/4'te kick 3. vuruşun "ve"sine kayar.
String _popSenkop(List<int> g) {
  if (!_dortDord(g)) return _popTemel(g);
  final z = _Izgara(g);
  z.hepsineEkle('h');
  z.ekle(0, 'k');
  z.ekle(2, 's');
  z.ekle(5, 'k');
  z.ekle(6, 's');
  return z.desen();
}

// Disko: her vuruşta kick, çift vuruşlarda snare, aralarda hi-hat.
String _popDisko(List<int> g) {
  final z = _Izgara(g);
  z.hepsineEkle('h');
  for (int gi = 0; gi < z.n; gi++) {
    final b = z.bas[gi];
    z.t[b].remove('h');
    z.ekle(b, 'k');
    if (gi.isOdd) z.ekle(b, 's');
  }
  return z.desen();
}

// ------------------------------------------------------------------
// AKUSTİK
// ------------------------------------------------------------------

// Hafif: sadece vuruş başlarında kick, snare ve hi-hat.
String _akustikHafif(List<int> g) {
  final z = _Izgara(g);
  final sg = _snareGrubu(z.n);
  for (int gi = 0; gi < z.n; gi++) {
    z.ekle(z.bas[gi], gi == 0 ? 'k' : (gi == sg ? 's' : 'h'));
  }
  return z.desen();
}

// Marakas her 8'likte, kick birde, hafif snare ortada.
String _akustikMarakas(List<int> g) {
  final z = _Izgara(g);
  z.hepsineEkle('m');
  z.ekle(0, 'k');
  z.ekle(z.bas[_snareGrubu(z.n)], 'e');
  return z.desen();
}

// ------------------------------------------------------------------
// COUNTRY
// ------------------------------------------------------------------

// Boom-chick: kick ve snare sırayla, başka ses yok.
String _countryBoom(List<int> g) {
  final z = _Izgara(g);
  final r = _roller(z.n);
  for (int gi = 0; gi < z.n; gi++) {
    z.ekle(z.bas[gi], _rol(r, gi));
  }
  return z.desen();
}

// Tren ritmi: her 8'likte hafif snare (hayalet), vuruş başlarında kick/snare.
String _countryTren(List<int> g) {
  final z = _Izgara(g);
  z.hepsineEkle('e');
  final r = _roller(z.n);
  for (int gi = 0; gi < z.n; gi++) {
    z.degistir(z.bas[gi], _rol(r, gi));
  }
  return z.desen();
}

// ------------------------------------------------------------------
// VALS, MARŞ, BOLERO
// ------------------------------------------------------------------

// Vals: bas - pa - pa. zil verilirse her 8'likte çalar.
String _vals(List<int> g, {String? zil}) {
  final z = _Izgara(g);
  if (zil != null) z.hepsineEkle(zil);
  for (int gi = 0; gi < z.n; gi++) {
    z.ekle(z.bas[gi], gi == 0 ? 'k' : 's');
  }
  return z.desen();
}

String _valsSade(List<int> g) => _vals(g);
String _valsHihat(List<int> g) => _vals(g, zil: 'h');

// Marş: kick ve snare vuruş başlarında sırayla, aralar snare ile dolar.
String _mars(List<int> g) {
  final z = _Izgara(g);
  var gi = 0;
  for (int i = 0; i < z.slot; i++) {
    if (z.bas.contains(i)) {
      z.ekle(i, gi.isEven ? 'k' : 's');
      gi++;
    } else {
      z.ekle(i, 's');
    }
  }
  return z.desen();
}

// Bolero: sürekli zil, kick 1. ve 4. adımda, snare son grubun başında.
String _bolero(List<int> g, String zil) {
  final z = _Izgara(g);
  z.hepsineEkle(zil);
  z.ekle(0, 'k');
  z.ekle(3, 'k');
  z.ekle(z.bas[z.n - 1], 's');
  return z.desen();
}

String _boleroTemel(List<int> g) => _bolero(g, 'h');
String _boleroMarakas(List<int> g) => _bolero(g, 'm');

// ------------------------------------------------------------------
// JAZZ
// ------------------------------------------------------------------

// Swing: ride vuruş başlarında, çift vuruşlarda "ding-a" ve ayakla hi-hat.
// 8'lik ızgarada üçleme hissi yaklaşık verilir.
// 4/4: ride 1, 2, 2-ve, 3, 4, 4-ve. Hi-hat 2 ve 4'te. Kick hafifçe birde.
String _jazzSwing(List<int> g) {
  final z = _Izgara(g);
  for (int gi = 0; gi < z.n; gi++) {
    final b = z.bas[gi];
    z.ekle(b, 'r');
    if (g[gi] == 3) {
      z.ekle(b + 1, 'r');
      z.ekle(b + 2, 'r');
    } else if (gi.isOdd && g[gi] >= 2) {
      z.ekle(b + 1, 'r');
    }
    if (gi.isOdd) z.ekle(b, 'h');
  }
  z.ekle(0, 'k');
  return z.desen();
}

// Hafif jazz (balad): ride sadece vuruş başlarında.
String _jazzHafif(List<int> g) {
  final z = _Izgara(g);
  for (int gi = 0; gi < z.n; gi++) {
    final b = z.bas[gi];
    z.ekle(b, 'r');
    if (gi.isOdd) z.ekle(b, 'h');
  }
  z.ekle(0, 'k');
  return z.desen();
}

// ------------------------------------------------------------------
// TÜRK USULLERİ (düm = kick, tek = snare)
// ------------------------------------------------------------------
// D = düm (kuvvetli), T = tek (hafif), nokta = sus. Uzayan vuruşların
// devamı nokta olarak yazılır.
// Kaynaklar: klasik Türk müziği usul tarifleri (Düyek, Yürük semai, Semai,
// Nim sofyan, Türk aksağı) ve aksak usul şemaları (Devr-i Turan, Aksak).
const _usulTablosu = <String, String>{
  '2,2': 'D . T .', // Nim sofyan (2): düm tek
  '2,2,2': 'D . T . T .', // Semai (3): düm tek tek
  '2,2,2,2': 'D T . T D . T .', // Düyek (8): düm te-ek tek dü-üm te-ek
  '3,3': 'D T T D T .', // Yürük semai (6): düm tek tek düm te-ek
  '2,3': 'D . T . T', // Türk aksağı (5): dü-üm te-ek tek
  '2,2,3': 'D . T . T . .', // Devr-i Turan (7, 2+2+3)
  '2,2,2,3': 'D . T . T . T . .', // Aksak (9, 2+2+2+3)
};

String _dumTek(String d) => d
    .split(' ')
    .map((x) => x == 'D' ? 'k' : (x == 'T' ? 's' : x))
    .join(' ');

// Tablodaki ölçüler için gerçek usul, diğerleri (5/4, 10/8, 12/8) için
// aynı mantıkla üretilir: ilk vuruş ve (4+ grupta) ortadaki vuruş düm,
// diğer vuruş başları tek.
String _usul(List<int> g) {
  final tablo = _usulTablosu[g.join(',')];
  if (tablo != null) return _dumTek(tablo);
  final z = _Izgara(g);
  for (int gi = 0; gi < z.n; gi++) {
    final dum = gi == 0 || (z.n >= 4 && gi == z.n ~/ 2);
    z.ekle(z.bas[gi], dum ? 'k' : 's');
  }
  return z.desen();
}

// Sofyan (4 vuruş, 4/4'te): dü-üm te ke. Diğer ölçülerde usul tablosu.
String _sofyan(List<int> g) =>
    g.join(',') == '2,2,2,2' ? 'k . . . s . e .' : _usul(g);

// Aynı usul, kick/snare yerine büyük tom (düm) ve küçük tom (tek).
String _usulTom(List<int> g) => _usul(g)
    .split(' ')
    .map((x) => x == 'k' ? '3' : (x == 's' ? '1' : x))
    .join(' ');

// ------------------------------------------------------------------
// STİL LİSTESİ (Sounds'ta görünen sıra bu sıradır)
// ------------------------------------------------------------------
// Dikkat: Pop - Temel listede ilk Pop stilidir, uygulama onu varsayılan
// davul olarak açar.
final List<DavulStili> davulStilleri = [
  // Rock
  DavulStili('Rock – Temel', 'Rock', _rockTemel),
  DavulStili('Rock – Yarım zaman', 'Rock', _rockYarim),
  DavulStili('Rock – Ride', 'Rock', _rockRide),
  DavulStili('Rock – Nakarat (crash)', 'Rock', _rockNakarat),
  // Pop
  DavulStili('Pop – Temel', 'Pop', _popTemel),
  DavulStili('Pop – Senkop', 'Pop', _popSenkop),
  DavulStili('Pop – Disko', 'Pop', _popDisko),
  // Akustik
  DavulStili('Akustik – Hafif', 'Akustik', _akustikHafif),
  DavulStili('Akustik – Marakas', 'Akustik', _akustikMarakas),
  // Country
  DavulStili('Country – Boom-chick', 'Country', _countryBoom),
  DavulStili('Country – Tren ritmi', 'Country', _countryTren),
  // Vals
  DavulStili('Vals – Sade', 'Vals', _valsSade),
  DavulStili('Vals – Hi-hat', 'Vals', _valsHihat),
  // Marş
  DavulStili('Marş – Temel', 'Marş', _mars),
  // Bolero
  DavulStili('Bolero – Temel', 'Bolero', _boleroTemel),
  DavulStili('Bolero – Marakas', 'Bolero', _boleroMarakas),
  // Jazz
  DavulStili('Jazz – Swing', 'Jazz', _jazzSwing),
  DavulStili('Jazz – Hafif', 'Jazz', _jazzHafif),
  // Türk
  DavulStili('Türk – Usul (düm-tek)', 'Türk', _usul),
  DavulStili('Türk – Sofyan', 'Türk', _sofyan),
  DavulStili('Türk – Usul (tom)', 'Türk', _usulTom),
];
