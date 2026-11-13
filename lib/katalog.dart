// Katalog: enstrüman -> tür -> o türün kendi ayarları.
// Yeni bir gitar ya da piyano türü eklemek için sadece buraya satır eklenir,
// sesler_*.zip dosyası depoya yüklenir (build.yml'e dokunmaya gerek yok).

class SesTuru {
  // Programın içinde kullanılan kısa ad (ör. 'clean').
  final String kod;
  // Ekranda görünen ad.
  final String ad;
  // Ses dosyalarının öneki. Dosya adı: {onek}_{nota}_{oktav}.wav
  // Ör. önek 'gitar_clean' -> gitar_clean_mi_4.wav
  final String onek;
  // Türün ses seviyesi çarpanı (1.0 = olduğu gibi).
  final double seviye;
  // Strum (d/u/b) sırasında teller arası gecikme, milisaniye.
  final double strumMs;

  const SesTuru({
    required this.kod,
    required this.ad,
    required this.onek,
    this.seviye = 1.0,
    this.strumMs = 4,
  });
}

// Akustik gitar eskiden beri 'gitar_...' öneki ile duruyor, adı değişmedi.
const gitarTurleri = <SesTuru>[
  SesTuru(kod: 'akustik', ad: 'Akustik', onek: 'gitar'),
  SesTuru(kod: 'clean', ad: 'Clean', onek: 'gitar_clean'),
  SesTuru(kod: 'naylon', ad: 'Naylon', onek: 'gitar_naylon', strumMs: 5),
  SesTuru(
    kod: 'distortion',
    ad: 'Distortion',
    onek: 'gitar_distortion',
    seviye: 0.8,
    strumMs: 3,
  ),
];

// Piyano şimdilik tek tür. Çeşitleri sonra aynı şekilde buraya eklenecek.
const piyanoTurleri = <SesTuru>[
  SesTuru(kod: 'standart', ad: 'Piyano', onek: 'piyano'),
];

const sesKatalogu = <String, List<SesTuru>>{
  'gitar': gitarTurleri,
  'piyano': piyanoTurleri,
};

const varsayilanGitarTuru = 'akustik';

// O an çalınan gitar parçasının türü. durum.dart her gitar parçasını çalmadan
// hemen önce bunu ayarlar, gitar.dart ses dosyasını buradan seçer.
SesTuru aktifGitarTuru = gitarTurleri.first;

SesTuru? sesTuruBul(String ens, String kod) {
  final liste = sesKatalogu[ens];
  if (liste == null) return null;
  for (final t in liste) {
    if (t.kod == kod) return t;
  }
  return null;
}

// Bu enstrümanda seçilebilecek birden fazla tür var mı?
bool turSecimiVar(String ens) => (sesKatalogu[ens]?.length ?? 0) > 1;
