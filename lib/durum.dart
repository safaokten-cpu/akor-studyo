import 'package:flutter/material.dart';
import 'akor.dart';
import 'kalip.dart';
import 'katalog.dart';
import 'ses.dart';
import 'ses_motoru.dart';

const hucreSayisi = 16;
const enFazlaSayfa = 8;
const enFazlaParca = 6;

enum Durum { durdu, caliyor, duraklatildi }

// Uygulamanın tüm durumu ve çalma mantığı burada.
// Ekranlar sadece bunu okur ve buradaki fonksiyonları çağırır.
class StudyoDurumu extends ChangeNotifier {
  int ton = 2;
  final List<List<Akor?>> sayfalar = [List<Akor?>.filled(hucreSayisi, null)];
  int aktifSayfa = 0;
  int secili = 0;
  Durum durum = Durum.durdu;
  int calanIndex = -1;
  int _oynatmaNo = 0;
  bool _kapali = false;

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
  String secTur = varsayilanGitarTuru;
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
    super.dispose();
  }

  // ---------- Gitar türleri ----------

  String parcaTuruKodu(Parca p) =>
      _parcaTurleri[p] ?? (sesKatalogu[p.kalip.enstruman]?.first.kod ?? '');

  SesTuru gitarTuruAl(Parca p) =>
      sesTuruBul('gitar', parcaTuruKodu(p)) ?? gitarTurleri.first;

  bool yukleniyorMu(SesTuru t) => yukleniyor.contains(t.onek);

  // Sounds'ta tür seçilince: seç, sesleri yükle.
  void turSec(String kod) {
    secTur = kod;
    _bildir();
    _turuHazirla('gitar', kod);
  }

  // Loop Page'de bir parçanın türünü değiştirir.
  void parcaTurSec(Parca p, String kod) {
    _parcaTurleri[p] = kod;
    _bildir();
    _turuHazirla('gitar', kod);
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

  // Çalmadan önce parçalardaki gitar türlerinin yüklü olduğundan emin olur.
  Future<void> _calacakTurleriHazirla() async {
    for (final p in List<Parca>.of(parcalar)) {
      if (p.kalip.enstruman == 'gitar') {
        await _turuHazirla('gitar', parcaTuruKodu(p));
      }
    }
  }

  // Akor önizlemesinde hangi gitar türü duyulsun.
  SesTuru _onizlemeGitarTuru() {
    if (secEns == 'gitar') {
      return sesTuruBul('gitar', secTur) ?? gitarTurleri.first;
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

  void akorYerlestir(Akor a) {
    tablo[secili] = a;
    if (secili < hucreSayisi - 1) secili++;
    _bildir();
    aktifGitarTuru = _onizlemeGitarTuru();
    akorOnizle(a, secEns == 'davul' ? 'gitar' : secEns);
  }

  void hucreSec(int i) {
    secili = i;
    _bildir();
  }

  void hucreSil(int i) {
    tablo[i] = null;
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
    aktifSayfa = sayfalar.length - 1;
    secili = 0;
    _bildir();
  }

  void sayfaSilKesin() {
    if (sayfalar.length <= 1) return;
    sayfalar.removeAt(aktifSayfa);
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
    if (k.enstruman == 'gitar') {
      _parcaTurleri[p] = secTur;
    }
    parcalar.add(p);
    _bildir();
    if (k.enstruman == 'gitar') {
      _turuHazirla('gitar', secTur);
    }
  }

  // ---------- Çalma ----------

  Future<void> oynat() async {
    if (durum == Durum.caliyor) return;
    final benimNo = ++_oynatmaNo;
    // Seçilen türlerin sesleri yüklü değilse önce yüklenir (süre sayacı
    // henüz başlamadığı için tempoyu etkilemez).
    await _calacakTurleriHazirla();
    if (benimNo != _oynatmaNo || _kapali) return;
    int i = (durum == Durum.duraklatildi && calanIndex >= 0) ? calanIndex : 0;
    durum = Durum.caliyor;
    _bildir();
    final saat = Stopwatch()..start();
    double hedefMs = 0;
    while (benimNo == _oynatmaNo && !_kapali) {
      final son = sonDoluIndex();
      if (son < 0) break;
      if (i > son) i = 0;
      final akor = akorAl(i);
      final sayfa = i ~/ hucreSayisi;

      // Çalacak parçaların planı. Kutu süresi gitar/piyano kalıbının
      // uzunluğuna göre belirlenir (en uzun olan). Melodik parça yoksa
      // (sadece davul) kutu bir tam ölçü sürer.
      final planlar = <Parca, List<List<String>>>{};
      int enUzun = 0;
      for (final p in parcalar) {
        if (p.sessiz || !p.kalip.olcuVar(olcu.ad)) continue;
        final a = p.kalip.adimlar(olcu.ad);
        if (a.isEmpty) continue;
        planlar[p] = a;
        if (p.kalip.enstruman != 'davul' && a.length > enUzun) {
          enUzun = a.length;
        }
      }
      final slotlar = enUzun > 0 ? enUzun : olcu.slot;
      kutuSlot.value = slotlar;

      for (int adim = 0; adim < slotlar; adim++) {
        if (benimNo != _oynatmaNo || _kapali) return;
        // Önce ses: çizimden hiçbir şey sesi bekletmesin.
        if (akor != null) {
          planlar.forEach((p, adimlar) {
            // Kısa kalıp tekrar eder, uzun kalıp (davul) kutu boyunda kesilir.
            final olaylar = adimlar[adim % adimlar.length];
            if (olaylar.isEmpty) return;
            // Gitar parçası kendi türüyle çalsın.
            if (p.kalip.enstruman == 'gitar') {
              aktifGitarTuru = gitarTuruAl(p);
            }
            kalipAdimiCal(p.kalip, akor, olaylar, p.ses);
          });
        }
        adimNo.value = adim;
        // Kutu değişince sadece tabloyu yeniden çiz (tüm ekranı değil).
        if (adim == 0 && (calanIndex != i || aktifSayfa != sayfa)) {
          calanIndex = i;
          aktifSayfa = sayfa;
          tabloTik.value++;
        }
        hedefMs += 30000 / tempo;
        final bekle = (hedefMs - saat.elapsedMilliseconds).round();
        if (bekle > 0) {
          await Future.delayed(Duration(milliseconds: bekle));
        }
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
    adimNo.value = -1;
    kutuSlot.value = 0;
    durum = Durum.duraklatildi;
    _bildir();
  }

  void durdur() {
    _oynatmaNo++;
    adimNo.value = -1;
    kutuSlot.value = 0;
    durum = Durum.durdu;
    calanIndex = -1;
    _bildir();
  }
}
