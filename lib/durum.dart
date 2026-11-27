import 'package:flutter/material.dart';
import 'akor.dart';
import 'kalip.dart';
import 'katalog.dart';
import 'ses.dart';
import 'ses_motoru.dart';

const hucreSayisi = 16;
const enFazlaSayfa = 24;
const enFazlaParca = 6;

enum Durum { durdu, caliyor, duraklatildi }

// Akor kutusuna seçilebilen arpej desenleri: kalıp listesindeki tüm gitar
// arpejleri, tekrarsız ve adım sayısına göre sıralı.
List<String> _arpejHavuzuUret() {
  final kume = <String>{};
  for (final k in kaliplar) {
    if (k.enstruman != 'gitar' || !k.ad.startsWith('Arpej')) continue;
    kume.addAll(k.desenler.values);
  }
  final liste = kume.toList();
  liste.sort((a, b) {
    final c = a.split(' ').length.compareTo(b.split(' ').length);
    return c != 0 ? c : a.compareTo(b);
  });
  return liste;
}

final List<String> arpejHavuzu = _arpejHavuzuUret();

final List<int> arpejAdimSayilari = (arpejHavuzu
        .map((x) => x.split(' ').length)
        .toSet()
        .toList()
      ..sort());

// Akora özel desenden, parçanın enstrümanına uygun geçici kalıp üretir.
Kalip _ozelKalip(Kalip temel, String desen) => Kalip(
      'Özel $desen',
      temel.enstruman,
      temel.tarz,
      {for (final o in olculer) o.ad: desen},
    );

// Elle yazılan deseni kontrol eder. 'pima' gibi bitişik yazılırsa harfleri
// ayırır. Geçersizse null döner.
String? desenTemizle(String ham) {
  var t = ham.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return null;
  if (!t.contains(' ') && !t.contains('+')) {
    t = t.split('').join(' ');
  }
  final kelimeler = t.split(' ');
  if (kelimeler.length > 16) return null;
  final gecerli = RegExp(r'^(\.|[pPimacdubh](\+[pPimacdubh])*)$');
  for (final k in kelimeler) {
    if (!gecerli.hasMatch(k)) return null;
  }
  return kelimeler.join(' ');
}

// Uygulamanın tüm durumu ve çalma mantığı burada.
// Ekranlar sadece bunu okur ve buradaki fonksiyonları çağırır.
class StudyoDurumu extends ChangeNotifier {
  int ton = 2;
  final List<List<Akor?>> sayfalar = [List<Akor?>.filled(hucreSayisi, null)];
  // Her akor kutusunun kendi arpej deseni. null = parçanın kendi kalıbı çalar.
  // sayfalar ile aynı şekilde tutulur (aynı sayfa sayısı, aynı kutu sayısı).
  final List<List<String?>> desenler = [List<String?>.filled(hucreSayisi, null)];

  // En son kaydedilen ya da açılan şarkının adı (Kaydet penceresinde hazır gelir).
  String sonSarkiAdi = '';
  int aktifSayfa = 0;
  int secili = 0;
  Durum durum = Durum.durdu;
  int calanIndex = -1;
  int _oynatmaNo = 0;
  bool _kapali = false;

  // Çalarken bir akor kutusuna dokunulunca çalma oraya atlar (-1 = istek yok).
  int _atlaHedef = -1;
  // Play'e basınca 3-2-1 geri sayım (her saniye bir tık) çalınsın mı?
  bool geriSayimAcik = true;
  // Geri sayım sırasında ekranda görünen sayı (0 = geri sayım yok).
  final ValueNotifier<int> geriSayim = ValueNotifier<int>(0);

  // Hafif bildirimciler: çalarken tüm ekranı değil, sadece ilgili kısmı çizdirir.
  final ValueNotifier<int> adimNo = ValueNotifier<int>(-1);
  final ValueNotifier<int> kutuSlot = ValueNotifier<int>(0);
  final ValueNotifier<int> tabloTik = ValueNotifier<int>(0);

  int tempo = 100;
  Olcu olcu = olculer[2];
  final List<Parca> parcalar = [
    Parca(kaliplar
        .firstWhere((k) => k.enstruman == 'gitar' && k.ad == 'Strum')),
    Parca(kaliplar
        .firstWhere((k) => k.enstruman == 'davul' && k.tarz == 'Pop')),
  ];
  String secEns = 'gitar';
  String secTarz = 'Tümü';
  Kalip? secKalip;

  // Sounds ekranında seçili gitar türü ve her parçanın kendi türü.
  // Her enstrüman için Sounds'ta seçili tür/kit (gitar türü, davul kiti).
  final Map<String, String> secTurler = {
    'gitar': varsayilanGitarTuru,
    'davul': varsayilanDavulTuru,
  };
  String get secTur => secTurler[secEns] ?? '';
  final Expando<String> _parcaTurleri = Expando<String>();
  // Şu an yüklenmekte olan türlerin önekleri.
  final Set<String> yukleniyor = {};

  List<Akor?> get tablo => sayfalar[aktifSayfa];
  bool get tabloBos => tablo.every((a) => a == null);

  void _bildir() {
    if (!_kapali) notifyListeners();
  }

  @override
  void dispose() {
    _kapali = true;
    _oynatmaNo++;
    adimNo.dispose();
    kutuSlot.dispose();
    tabloTik.dispose();
    geriSayim.dispose();
    super.dispose();
  }

  // ---------- Gitar türleri ----------

  String parcaTuruKodu(Parca p) =>
      _parcaTurleri[p] ?? (sesKatalogu[p.kalip.enstruman]?.first.kod ?? '');

  SesTuru gitarTuruAl(Parca p) =>
      sesTuruBul('gitar', parcaTuruKodu(p)) ?? gitarTurleri.first;

  SesTuru davulTuruAl(Parca p) =>
      sesTuruBul('davul', parcaTuruKodu(p)) ?? davulTurleri.first;

  // Parçanın türü/kiti (Loop Page menüsü için, her enstrümanda çalışır).
  SesTuru? parcaTuru(Parca p) {
    final liste = sesKatalogu[p.kalip.enstruman];
    if (liste == null || liste.isEmpty) return null;
    return sesTuruBul(p.kalip.enstruman, parcaTuruKodu(p)) ?? liste.first;
  }

  bool yukleniyorMu(SesTuru t) => yukleniyor.contains(t.onek);

  // Sounds'ta tür/kit seçilince: seç, sesleri yükle.
  void turSec(String kod) {
    secTurler[secEns] = kod;
    // Davulda kit seçimi çalan davul parçalarına da uygulanır (genelde tek davul var).
    if (secEns == 'davul') {
      for (final p in parcalar) {
        if (p.kalip.enstruman == 'davul') _parcaTurleri[p] = kod;
      }
    }
    _bildir();
    _turuHazirla(secEns, kod);
  }

  // Seçili türün yüklenemeyen ses dosyaları (yoksa boş liste).
  List<String> eksikSesler(SesTuru t) => sesEksikleri(t.onek);

  // Loop Page'de bir parçanın türünü/kitini değiştirir.
  void parcaTurSec(Parca p, String kod) {
    _parcaTurleri[p] = kod;
    _bildir();
    _turuHazirla(p.kalip.enstruman, kod);
  }

  Future<void> _turuHazirla(String ens, String kod) async {
    final t = sesTuruBul(ens, kod);
    if (t == null || sesOnekiHazirMi(t.onek)) return;
    yukleniyor.add(t.onek);
    _bildir();
    await sesOnekiYukle(t.onek);
    yukleniyor.remove(t.onek);
    _bildir();
  }

  // Çalmadan önce parçalardaki tür/kit seslerinin yüklü olduğundan emin olur.
  Future<void> _calacakTurleriHazirla() async {
    for (final p in List<Parca>.of(parcalar)) {
      final ens = p.kalip.enstruman;
      if (sesKatalogu.containsKey(ens)) {
        await _turuHazirla(ens, parcaTuruKodu(p));
      }
    }
  }

  // Akor önizlemesinde hangi gitar türü duyulsun.
  SesTuru _onizlemeGitarTuru() {
    if (secEns == 'gitar') {
      return sesTuruBul('gitar', secTurler['gitar'] ?? '') ??
          gitarTurleri.first;
    }
    for (final p in parcalar) {
      if (p.kalip.enstruman == 'gitar' && !p.sessiz) return gitarTuruAl(p);
    }
    return gitarTurleri.first;
  }

  // ---------- Ton, akor, tablo ----------

  void tonSec(int i) {
    ton = i;
    _bildir();
  }

  // Transpoze: tablodaki tüm akorları (bütün sayfalar) yarım ses kaydırır,
  // tonu da aynı miktarda değiştirir. Akor türleri ve seçili arpejler aynen kalır.
  void transpoze(int yarimSes) {
    final k = ((yarimSes % 12) + 12) % 12;
    if (k == 0) return;
    for (final sayfa in sayfalar) {
      for (int i = 0; i < sayfa.length; i++) {
        final a = sayfa[i];
        if (a != null) sayfa[i] = Akor((a.kok + k) % 12, a.tur);
      }
    }
    ton = (ton + k) % 12;
    tabloTik.value++;
    _bildir();
  }

  void akorYerlestir(Akor a) {
    tablo[secili] = a;
    if (secili < hucreSayisi - 1) secili++;
    _bildir();
    aktifGitarTuru = _onizlemeGitarTuru();
    akorOnizle(a, secEns == 'davul' ? 'gitar' : secEns);
  }

  // atla: true ise çalarken bu kutuya dokunmak çalmayı oradan sürdürür
  // (akor varsa). Duraklatılmışken Play oradan başlar.
  void hucreSec(int i, {bool atla = true}) {
    secili = i;
    final genel = aktifSayfa * hucreSayisi + i;
    if (atla && akorAl(genel) != null) {
      if (durum == Durum.caliyor) {
        _atlaHedef = genel;
      } else if (durum == Durum.duraklatildi) {
        calanIndex = genel;
        tabloTik.value++;
      }
    }
    _bildir();
  }

  void hucreSil(int i) {
    tablo[i] = null;
    desenler[aktifSayfa][i] = null;
    _bildir();
  }

  // ---------- Akora özel arpej ----------

  String? desenAl(int sayfa, int hucre) {
    if (sayfa < 0 || sayfa >= desenler.length) return null;
    return desenler[sayfa][hucre];
  }

  void desenAyarla(int sayfa, int hucre, String? desen) {
    if (sayfa < 0 || sayfa >= desenler.length) return;
    desenler[sayfa][hucre] = (desen == null || desen.isEmpty) ? null : desen;
    _bildir();
  }

  void sayfaGit(int s) {
    if (s < 0 || s >= sayfalar.length) return;
    aktifSayfa = s;
    secili = 0;
    _bildir();
  }

  void sayfaEkle() {
    if (sayfalar.length >= enFazlaSayfa) return;
    sayfalar.add(List<Akor?>.filled(hucreSayisi, null));
    desenler.add(List<String?>.filled(hucreSayisi, null));
    aktifSayfa = sayfalar.length - 1;
    secili = 0;
    _bildir();
  }

  void sayfaSilKesin() {
    if (sayfalar.length <= 1) return;
    sayfalar.removeAt(aktifSayfa);
    desenler.removeAt(aktifSayfa);
    if (aktifSayfa >= sayfalar.length) aktifSayfa = sayfalar.length - 1;
    secili = 0;
    _bildir();
  }

  int sonDoluIndex() {
    for (int s = sayfalar.length - 1; s >= 0; s--) {
      for (int k = hucreSayisi - 1; k >= 0; k--) {
        if (sayfalar[s][k] != null) return s * hucreSayisi + k;
      }
    }
    return -1;
  }

  Akor? akorAl(int i) {
    final s = i ~/ hucreSayisi;
    if (s >= sayfalar.length) return null;
    return sayfalar[s][i % hucreSayisi];
  }

  // ---------- Yazıdan yükleme ----------

  // Yazıdan okunan akorları tabloya sırayla dizer (sayfa dolunca yeni sayfa açar).
  // Ritim verilmişse ilk gitar parçasının kalıbını onunla değiştirir.
  // Tabloya yerleşen akor sayısını döndürür.
  int yaziUygula(List<Akor> akorlar, String? ritim, bool temizle) {
    durdur();
    const toplam = enFazlaSayfa * hucreSayisi;
    int yerlesen = 0;
    if (akorlar.isNotEmpty) {
      int baslangic = 0;
      if (temizle) {
        sayfalar.clear();
        sayfalar.add(List<Akor?>.filled(hucreSayisi, null));
        desenler.clear();
        desenler.add(List<String?>.filled(hucreSayisi, null));
      } else {
        baslangic = sonDoluIndex() + 1;
      }
      for (final a in akorlar) {
        final idx = baslangic + yerlesen;
        if (idx >= toplam) break;
        final s = idx ~/ hucreSayisi;
        while (sayfalar.length <= s) {
          sayfalar.add(List<Akor?>.filled(hucreSayisi, null));
          desenler.add(List<String?>.filled(hucreSayisi, null));
        }
        sayfalar[s][idx % hucreSayisi] = a;
        desenler[s][idx % hucreSayisi] = null;
        yerlesen++;
      }
      aktifSayfa =
          (baslangic ~/ hucreSayisi).clamp(0, sayfalar.length - 1).toInt();
      secili = 0;
      tabloTik.value++;
    }
    if (ritim != null && ritim.isNotEmpty) {
      _ritmiGitaraUygula(ritim);
    }
    _bildir();
    return yerlesen;
  }

  // İlk gitar parçasının kalıbını yazıdan gelen ritimle değiştirir.
  // Parçanın sesi, susturma durumu ve gitar türü korunur.
  // Ritmin adım sayısına uyan ölçü varsa ölçü de ona çevrilir
  // (7 adım -> 7/8 gibi), böylece davul gibi diğer parçalar tam oturur.
  void _ritmiGitaraUygula(String desen) {
    final kalip = Kalip(
      'Yazıdan ${desen.replaceAll(' ', '')}',
      'gitar',
      'Akustik',
      {for (final o in olculer) o.ad: desen},
    );
    final yeni = Parca(kalip);
    final eskiNo = parcalar.indexWhere((p) => p.kalip.enstruman == 'gitar');
    String tur = secTurler['gitar'] ?? varsayilanGitarTuru;
    if (eskiNo >= 0) {
      final eski = parcalar[eskiNo];
      tur = parcaTuruKodu(eski);
      yeni.ses = eski.ses;
      yeni.sessiz = eski.sessiz;
      _parcaTurleri[eski] = null;
      parcalar[eskiNo] = yeni;
    } else if (parcalar.length < enFazlaParca) {
      parcalar.add(yeni);
    } else {
      return;
    }
    _parcaTurleri[yeni] = tur;
    _turuHazirla('gitar', tur);
    _olcuyuRitmeUydur(desen.split(' ').length);
  }

  // Mevcut ölçü ritme uyuyorsa dokunmaz. Uymuyorsa tam eşleşen ölçüyü
  // (adım sayısı = ölçü), yoksa yarım ölçü adayını seçer.
  void _olcuyuRitmeUydur(int adim) {
    final adaylar = olcuAdaylari(adim);
    if (adaylar.isEmpty || adaylar.contains(olcu.ad)) return;
    String secilen = adaylar.first;
    for (final o in olculer) {
      if (o.slot == adim && adaylar.contains(o.ad)) {
        secilen = o.ad;
        break;
      }
    }
    olcu = olculer.firstWhere((o) => o.ad == secilen);
  }

  // ---------- Şarkı kaydetme ve açma ----------

  // Şarkının her şeyini (akorlar, arpejler, ton, tempo, ölçü, parçalar)
  // JSON'a çevrilebilir bir haritaya koyar.
  Map<String, dynamic> sarkiVerisi() => {
        'ton': ton,
        'tempo': tempo,
        'olcu': olcu.ad,
        'sayfalar': [
          for (final s in sayfalar)
            [
              for (final a in s) a == null ? null : {'k': a.kok, 't': a.tur},
            ],
        ],
        'desenler': [
          for (final s in desenler) List<String?>.from(s),
        ],
        'parcalar': [
          for (final p in parcalar)
            {
              'ens': p.kalip.enstruman,
              'tarz': p.kalip.tarz,
              'ad': p.kalip.ad,
              'd': p.kalip.desenler,
              'ses': p.ses,
              'sessiz': p.sessiz,
              'tur': parcaTuruKodu(p),
            },
        ],
      };

  // Kaydedilmiş şarkıyı açar. Bozuk ya da eksik kısımlar atlanır.
  void sarkiYukle(Map<String, dynamic> v) {
    durdur();

    final yeniTon = (v['ton'] as num?)?.toInt();
    if (yeniTon != null) ton = ((yeniTon % 12) + 12) % 12;
    final yeniTempo = (v['tempo'] as num?)?.toInt();
    if (yeniTempo != null) tempo = yeniTempo.clamp(60, 180).toInt();
    final olcuAd = v['olcu']?.toString();
    for (final o in olculer) {
      if (o.ad == olcuAd) olcu = o;
    }

    // Akorlar ve her akorun arpej deseni
    final yeniSayfalar = <List<Akor?>>[];
    final yeniDesenler = <List<String?>>[];
    final hamSayfalar = v['sayfalar'];
    final hamDesenler = v['desenler'];
    if (hamSayfalar is List) {
      for (int s = 0; s < hamSayfalar.length && s < enFazlaSayfa; s++) {
        final sayfa = List<Akor?>.filled(hucreSayisi, null);
        final desen = List<String?>.filled(hucreSayisi, null);
        final ham = hamSayfalar[s];
        if (ham is List) {
          for (int i = 0; i < ham.length && i < hucreSayisi; i++) {
            final a = ham[i];
            if (a is Map) {
              final kok = (a['k'] as num?)?.toInt();
              final tur = a['t']?.toString();
              if (kok != null &&
                  kok >= 0 &&
                  kok < 12 &&
                  tur != null &&
                  akorTurleri.any((t) => t.kod == tur)) {
                sayfa[i] = Akor(kok, tur);
              }
            }
          }
        }
        if (hamDesenler is List && s < hamDesenler.length) {
          final hd = hamDesenler[s];
          if (hd is List) {
            for (int i = 0; i < hd.length && i < hucreSayisi; i++) {
              final x = hd[i];
              if (x is String && x.isNotEmpty && sayfa[i] != null) {
                desen[i] = x;
              }
            }
          }
        }
        yeniSayfalar.add(sayfa);
        yeniDesenler.add(desen);
      }
    }
    if (yeniSayfalar.isEmpty) {
      yeniSayfalar.add(List<Akor?>.filled(hucreSayisi, null));
      yeniDesenler.add(List<String?>.filled(hucreSayisi, null));
    }
    sayfalar
      ..clear()
      ..addAll(yeniSayfalar);
    desenler
      ..clear()
      ..addAll(yeniDesenler);

    // Parçalar (gitar, piyano, davul): kalıbın kendisi kaydedildiği için
    // sonradan kalıp listesi değişse bile şarkı aynı çalar.
    final hamParcalar = v['parcalar'];
    if (hamParcalar is List) {
      parcalar.clear();
      for (final h in hamParcalar) {
        if (parcalar.length >= enFazlaParca) break;
        if (h is! Map) continue;
        final ens = h['ens']?.toString() ?? '';
        if (!enstrumanAdlari.containsKey(ens)) continue;
        final hd = h['d'];
        if (hd is! Map) continue;
        final haritasi = <String, String>{
          for (final e in hd.entries) e.key.toString(): e.value.toString(),
        };
        if (haritasi.isEmpty) continue;
        final p = Parca(Kalip(
          h['ad']?.toString() ?? 'Özel',
          ens,
          h['tarz']?.toString() ?? 'Akustik',
          haritasi,
        ));
        p.ses = (h['ses'] as num?)?.toDouble() ?? 0.8;
        p.sessiz = h['sessiz'] == true;
        final tur = h['tur']?.toString();
        if (tur != null && sesTuruBul(ens, tur) != null) {
          _parcaTurleri[p] = tur;
          _turuHazirla(ens, tur);
        }
        parcalar.add(p);
      }
    }

    aktifSayfa = 0;
    secili = 0;
    calanIndex = -1;
    tabloTik.value++;
    _bildir();
  }

  // ---------- Loop Page ----------

  void olcuSec(Olcu o) {
    olcu = o;
    _bildir();
  }

  void tempoAyarla(int v) {
    tempo = v.clamp(60, 180).toInt();
    _bildir();
  }

  void parcaSessizDegistir(Parca p) {
    p.sessiz = !p.sessiz;
    _bildir();
  }

  void parcaSesAyarla(Parca p, double v) {
    p.ses = v;
    _bildir();
  }

  void parcaSil(int p) {
    if (p < 0 || p >= parcalar.length) return;
    _parcaTurleri[parcalar[p]] = null;
    parcalar.removeAt(p);
    _bildir();
  }

  // ---------- Sounds ----------

  void enstrumanSec(String e) {
    secEns = e;
    // Seçili tarzın bu enstrümanda kalıbı yoksa Tümü'ne dön.
    if (secTarz != 'Tümü' &&
        !kaliplar.any((k) => k.enstruman == e && k.tarz == secTarz)) {
      secTarz = 'Tümü';
    }
    secKalip = null;
    _bildir();
  }

  void tarzSec(String t) {
    secTarz = t;
    _bildir();
  }

  void kalipSec(Kalip? k) {
    secKalip = k;
    _bildir();
  }

  void parcaEkle(Kalip k) {
    if (parcalar.length >= enFazlaParca) return;
    final p = Parca(k);
    final ens = k.enstruman;
    final kod = secTurler[ens];
    if (kod != null) {
      _parcaTurleri[p] = kod;
    }
    parcalar.add(p);
    _bildir();
    if (kod != null) {
      _turuHazirla(ens, kod);
    }
  }

  // Sounds'taki Arpej penceresinden: seçilen ya da yazılan desenle yeni bir
  // gitar/piyano parçası ekler. Desen her ölçüde aynı çalar, akor kutusunun
  // süresi desenin uzunluğuna uyar.
  void arpejParcaEkle(String desen) {
    if (parcalar.length >= enFazlaParca) return;
    final ens = secEns == 'davul' ? 'gitar' : secEns;
    final ad = desen.replaceAll(' ', '');
    parcaEkle(Kalip(
      'Arpej $ad',
      ens,
      'Akustik',
      {for (final o in olculer) o.ad: desen},
    ));
  }

  // ---------- Çalma ----------

  void geriSayimDegistir() {
    geriSayimAcik = !geriSayimAcik;
    _bildir();
  }

  // Saat'e göre hedef zamana (milisaniye) kadar bekler. Önce kaba bekleme
  // yapar, son birkaç milisaniyeyi sık sık kontrol ederek bekler. Böylece
  // vuruşlar zamanlayıcının gecikmesinden etkilenmez, ritim eşit akar.
  Future<void> _hedefeKadarBekle(Stopwatch saat, double hedefMs) async {
    final kalan = hedefMs - saat.elapsedMicroseconds / 1000.0;
    if (kalan > 12) {
      await Future.delayed(Duration(milliseconds: (kalan - 8).floor()));
    }
    while (saat.elapsedMicroseconds / 1000.0 < hedefMs) {
      await Future.delayed(Duration.zero);
    }
  }

  // 3-2-1: her saniye bir tık sesi (standart kitin hi-hat sesi) ve ekranda sayı.
  // Geri sayım bitince true döner. Arada durdurulursa false döner.
  Future<bool> _geriSayimCal(int benimNo) async {
    final saat = Stopwatch()..start();
    for (int n = 3; n >= 1; n--) {
      if (benimNo != _oynatmaNo || _kapali) return false;
      geriSayim.value = n;
      sesCal('davul_hihat', 1.0, 14);
      await _hedefeKadarBekle(saat, (4 - n) * 1000.0);
    }
    if (benimNo != _oynatmaNo || _kapali) return false;
    geriSayim.value = 0;
    return true;
  }

  Future<void> oynat() async {
    if (durum == Durum.caliyor) return;
    final benimNo = ++_oynatmaNo;
    // Seçilen türlerin sesleri yüklü değilse önce yüklenir (süre sayacı
    // henüz başlamadığı için tempoyu etkilemez).
    await _calacakTurleriHazirla();
    if (benimNo != _oynatmaNo || _kapali) return;
    final son0 = sonDoluIndex();
    if (son0 < 0) return;
    int i = (durum == Durum.duraklatildi && calanIndex >= 0) ? calanIndex : 0;
    if (i > son0) i = 0;
    _atlaHedef = -1;
    durum = Durum.caliyor;
    // Başlangıç kutusu geri sayım sırasında da görünsün.
    calanIndex = i;
    aktifSayfa = i ~/ hucreSayisi;
    tabloTik.value++;
    _bildir();
    if (geriSayimAcik) {
      final devam = await _geriSayimCal(benimNo);
      if (!devam) return;
    }
    final saat = Stopwatch()..start();
    double hedefMs = 0;
    // Davulun kendi ölçü sayacı: akor kutusu değişince başa dönmez, davul
    // ölçüsü kesintisiz akar. Başlangıçta, atlamada ve döngü başında sıfırlanır.
    int davulSayac = 0;
    while (benimNo == _oynatmaNo && !_kapali) {
      final son = sonDoluIndex();
      if (son < 0) break;
      if (i > son) {
        i = 0;
        davulSayac = 0;
      }
      final akor = akorAl(i);
      final sayfa = i ~/ hucreSayisi;
      // Bu akor kutusuna özel arpej seçilmişse melodik parçalar onu çalar.
      final ozelDesen = desenAl(sayfa, i % hucreSayisi);

      // Çalacak parçaların planı. Kutu süresi gitar/piyano kalıbının
      // uzunluğuna göre belirlenir (en uzun olan). Melodik parça yoksa
      // (sadece davul) kutu bir tam ölçü sürer.
      final planlar = <Parca, List<List<String>>>{};
      final calKaliplari = <Parca, Kalip>{};
      int enUzun = 0;
      for (final p in parcalar) {
        if (p.sessiz) continue;
        Kalip kalip = p.kalip;
        if (ozelDesen != null && kalip.enstruman != 'davul') {
          kalip = _ozelKalip(kalip, ozelDesen);
        }
        if (!kalip.olcuVar(olcu.ad)) continue;
        final a = kalip.adimlar(olcu.ad);
        if (a.isEmpty) continue;
        planlar[p] = a;
        calKaliplari[p] = kalip;
        if (kalip.enstruman != 'davul' && a.length > enUzun) {
          enUzun = a.length;
        }
      }
      final slotlar = enUzun > 0 ? enUzun : olcu.slot;
      kutuSlot.value = slotlar;

      bool atla = false;
      for (int adim = 0; adim < slotlar; adim++) {
        if (benimNo != _oynatmaNo || _kapali) return;
        // Çalarken bir kutuya dokunulduysa bu vuruşta oraya atla.
        if (_atlaHedef >= 0) {
          atla = true;
          break;
        }
        // Önce ses: çizimden hiçbir şey sesi bekletmesin.
        // Davul her vuruşta önce çalınır, ritim sabit kalsın.
        if (akor != null) {
          for (final davulTuru in const [true, false]) {
            planlar.forEach((p, adimlar) {
              final davulParca = p.kalip.enstruman == 'davul';
              if (davulParca != davulTuru) return;
              // Davul kendi ölçü sayacıyla, diğerleri kutunun adımıyla çalar.
              final sira = davulParca ? davulSayac : adim;
              final olaylar = adimlar[sira % adimlar.length];
              if (olaylar.isEmpty) return;
              // Gitar parçası kendi türüyle çalsın.
              if (p.kalip.enstruman == 'gitar') {
                aktifGitarTuru = gitarTuruAl(p);
              } else if (davulParca) {
                aktifDavulTuru = davulTuruAl(p);
              }
              kalipAdimiCal(calKaliplari[p]!, akor, olaylar, p.ses);
            });
          }
        }
        adimNo.value = adim;
        // Kutu değişince sadece tabloyu yeniden çiz (tüm ekranı değil).
        if (adim == 0 && (calanIndex != i || aktifSayfa != sayfa)) {
          calanIndex = i;
          aktifSayfa = sayfa;
          tabloTik.value++;
        }
        davulSayac++;
        hedefMs += 30000 / tempo;
        await _hedefeKadarBekle(saat, hedefMs);
      }
      if (atla) {
        i = _atlaHedef;
        _atlaHedef = -1;
        davulSayac = 0;
        continue;
      }
      i++;
    }
    if (benimNo == _oynatmaNo && !_kapali) {
      adimNo.value = -1;
      kutuSlot.value = 0;
      durum = Durum.durdu;
      calanIndex = -1;
      _bildir();
    }
  }

  void duraklat() {
    if (durum != Durum.caliyor) return;
    _oynatmaNo++;
    _atlaHedef = -1;
    geriSayim.value = 0;
    adimNo.value = -1;
    kutuSlot.value = 0;
    durum = Durum.duraklatildi;
    _bildir();
  }

  void durdur() {
    _oynatmaNo++;
    _atlaHedef = -1;
    geriSayim.value = 0;
    adimNo.value = -1;
    kutuSlot.value = 0;
    durum = Durum.durdu;
    calanIndex = -1;
    _bildir();
  }
}
