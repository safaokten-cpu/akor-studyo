const enstrumanAdlari = {
  'gitar': 'Gitar',
  'piyano': 'Piyano',
  'davul': 'Davul',
};

const davulSesleri = ['kick', 'snare', 'hihat'];

const tarzlar = ['Rock', 'Pop', 'Akustik', 'Country'];

// Bir ölçü = 8'lik nota sayısı. gruplar = vuruş grupları.
class Olcu {
  final String ad;
  final List<int> gruplar;
  const Olcu(this.ad, this.gruplar);
  int get slot => gruplar.fold<int>(0, (a, b) => a + b);
}

const olculer = [
  Olcu('2/4', [2, 2]),
  Olcu('3/4', [2, 2, 2]),
  Olcu('4/4', [2, 2, 2, 2]),
  Olcu('5/4', [2, 2, 2, 2, 2]),
  Olcu('6/8', [3, 3]),
  Olcu('7/8', [2, 2, 3]),
  Olcu('12/8', [3, 3, 3, 3]),
];

// Desen yazımı: her kelime bir 8'lik nota. '.' = sessizlik, '+' = aynı anda.
// Gitar/piyano: p=bas, P=ikinci bas, i/m/a=parmaklar, c=tüm akor,
// h=sağ el akoru (piyano), d=aşağı strum, u=yukarı strum, b=bas teller (rock).
// Davul: k=kick, s=snare, h=hihat.
class Kalip {
  final String ad;
  final String enstruman;
  final String tarz;
  final Map<String, String> desenler;
  const Kalip(this.ad, this.enstruman, this.tarz, this.desenler);

  String get etiket => '${enstrumanAdlari[enstruman]}.$ad';

  bool olcuVar(String olcu) => desenler.containsKey(olcu);

  List<List<String>> adimlar(String olcu) {
    final d = desenler[olcu];
    if (d == null) return const [];
    return d
        .split(' ')
        .map((t) => t == '.' ? <String>[] : t.split('+'))
        .toList();
  }
}

class Parca {
  final Kalip kalip;
  double ses = 0.8;
  bool sessiz = false;
  Parca(this.kalip);
}

// ---- Arpej aileleri ----
const _arpA = {
  '2/4': 'p i m a',
  '4/4': 'p i m a p i m a',
};
const _arpB = {
  '3/4': 'p i m a m i',
  '6/8': 'p i m a m i',
  '12/8': 'p i m a m i p i m a m i',
};
const _arpC = {
  '7/8': 'p i m i a m i',
};
const _arpD = {
  '5/4': 'p i m a m i p i m a',
};
// Rock: başparmak sürekli bas çalar.
const _arpRock = {
  '2/4': 'p i p m',
  '3/4': 'p i p m p a',
  '4/4': 'p i p m p i p a',
  '5/4': 'p i p m p i p m p a',
  '6/8': 'p i m p m i',
  '7/8': 'p i p m p i m',
  '12/8': 'p i m p i m p i m p i m',
};
// Pop: başparmak ve yüzük parmağı birlikte başlar (yayılan).
const _arpPop = {
  '2/4': 'p+a i m i',
  '3/4': 'p+a i m i m i',
  '4/4': 'p+a i m i p+a i m i',
  '5/4': 'p+a i m i m p+a i m i m',
  '6/8': 'p+a i m i m i',
  '7/8': 'p+a i m i p+a m i',
  '12/8': 'p+a i m i m i p+a i m i m i',
};

List<Kalip> _klasikArpejler(String ens, String tarz) => [
      Kalip('Arpej p-i-m-a', ens, tarz, _arpA),
      Kalip('Arpej p-i-m-a-m-i', ens, tarz, _arpB),
      Kalip('Arpej p-i-m-i-a-m-i', ens, tarz, _arpC),
      Kalip('Arpej 5/4', ens, tarz, _arpD),
    ];

String _davulUret(String tip, List<int> g) {
  final n = g.length;
  final slot = g.fold<int>(0, (a, b) => a + b);
  final bas = <int>[];
  var s = 0;
  for (final x in g) {
    bas.add(s);
    s += x;
  }
  final roller = n == 2
      ? ['k', 's']
      : n == 3
          ? ['k', 's', 's']
          : n == 4
              ? ['k', 's', 'k', 's']
              : ['k', 's', 'k', 'k', 's'];
  final t = List<List<String>>.generate(slot, (_) => <String>[]);
  if (tip == 'rock' || tip == 'pop') {
    for (int i = 0; i < slot; i++) {
      t[i].add('h');
    }
    for (int gi = 0; gi < n; gi++) {
      t[bas[gi]].add(roller[gi]);
    }
    if (tip == 'rock' && n == 4 && g[2] > 1) {
      t[bas[2] + 1].add('k');
    }
  } else if (tip == 'hafif') {
    final snareGrup = n.isEven ? n ~/ 2 : n - 1;
    for (int gi = 0; gi < n; gi++) {
      if (gi == 0) {
        t[bas[gi]].add('k');
      } else if (gi == snareGrup) {
        t[bas[gi]].add('s');
      } else {
        t[bas[gi]].add('h');
      }
    }
  } else {
    for (int i = 0; i < slot; i++) {
      if (i.isEven) {
        t[i].add('k');
        t[i].add('h');
      } else {
        t[i].add('s');
      }
    }
  }
  return t.map((e) => e.isEmpty ? '.' : e.join('+')).join(' ');
}

Map<String, String> _davulDesenleri(String tip) => {
      for (final o in olculer) o.ad: _davulUret(tip, o.gruplar),
    };

final List<Kalip> kaliplar = [
  // ---- Gitar ----
  Kalip('Rock vuruş', 'gitar', 'Rock', {
    '2/4': 'b b b b',
    '3/4': 'b b b b b b',
    '4/4': 'b b b b b b b b',
    '5/4': 'b b b b b b b b b b',
    '6/8': 'b . b b . b',
    '7/8': 'b b b b b b b',
    '12/8': 'b . b b . b b . b b . b',
  }),
  Kalip('Arpej bas ağırlıklı', 'gitar', 'Rock', _arpRock),
  ..._klasikArpejler('gitar', 'Rock'),
  Kalip('Strum', 'gitar', 'Pop', {
    '2/4': 'd . d u',
    '3/4': 'd . d u . u',
    '4/4': 'd . d u . u d u',
    '5/4': 'd . d u . u d . d u',
    '6/8': 'd . . d . u',
    '7/8': 'd . d . d u u',
    '12/8': 'd . . d . u d . . d . u',
  }),
  Kalip('Arpej yayılan', 'gitar', 'Pop', _arpPop),
  ..._klasikArpejler('gitar', 'Pop'),
  ..._klasikArpejler('gitar', 'Akustik'),
  Kalip('Bas-akor', 'gitar', 'Country', {
    '2/4': 'p . c .',
    '3/4': 'p . c . c .',
    '4/4': 'p . c . P . c .',
    '5/4': 'p . c . c . P . c .',
    '6/8': 'p . c P . c',
    '7/8': 'p . c . P . c',
    '12/8': 'p . c P . c p . c P . c',
  }),
  Kalip('Travis', 'gitar', 'Country', {
    '2/4': 'p i P m',
    '3/4': 'p i P m p i',
    '4/4': 'p i P m p i P m',
    '5/4': 'p i P m p i P m p i',
    '6/8': 'p i m P i m',
    '7/8': 'p i P m p i m',
    '12/8': 'p i m P i m p i m P i m',
  }),
  ..._klasikArpejler('gitar', 'Country'),
  // ---- Piyano ----
  Kalip('Sinkop', 'piyano', 'Rock', {
    '2/4': 'c . . c',
    '3/4': 'c . . c . c',
    '4/4': 'c . . c . . c .',
    '5/4': 'c . . c . . c . c .',
    '6/8': 'c . . . c .',
    '7/8': 'c . . c . c .',
    '12/8': 'c . . c . . c . . . c .',
  }),
  Kalip('Arpej bas ağırlıklı', 'piyano', 'Rock', _arpRock),
  ..._klasikArpejler('piyano', 'Rock'),
  Kalip('Blok akor', 'piyano', 'Pop', {
    '2/4': 'c . h .',
    '3/4': 'c . h . h .',
    '4/4': 'c . h . c . h .',
    '5/4': 'c . h . h . c . h .',
    '6/8': 'c . . h . .',
    '7/8': 'c . h . c . h',
    '12/8': 'c . . h . . c . . h . .',
  }),
  Kalip('Arpej yayılan', 'piyano', 'Pop', _arpPop),
  ..._klasikArpejler('piyano', 'Pop'),
  ..._klasikArpejler('piyano', 'Akustik'),
  Kalip('Ritim', 'piyano', 'Country', {
    '2/4': 'p . h .',
    '3/4': 'p . h . h .',
    '4/4': 'p . h . P . h .',
    '5/4': 'p . h . h . P . h .',
    '6/8': 'p . h P . h',
    '7/8': 'p . h . P . h',
    '12/8': 'p . h P . h p . h P . h',
  }),
  ..._klasikArpejler('piyano', 'Country'),
  // ---- Davul ----
  Kalip('Rock', 'davul', 'Rock', _davulDesenleri('rock')),
  Kalip('Pop', 'davul', 'Pop', _davulDesenleri('pop')),
  Kalip('Hafif', 'davul', 'Akustik', _davulDesenleri('hafif')),
  Kalip('Tren ritmi', 'davul', 'Country', _davulDesenleri('tren')),
];
