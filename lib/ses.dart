import 'akor.dart';
import 'davul.dart';
import 'gitar.dart';
import 'kalip.dart';
import 'piyano.dart';

export 'ses_motoru.dart' show seslerHazirla;

// Hangi parçanın hangi enstrümana gideceğini belirler.
void kalipAdimiCal(Kalip k, Akor akor, List<String> olaylar, double seviye) {
  if (k.enstruman == 'davul') {
    davulCal(olaylar, seviye);
  } else if (k.enstruman == 'piyano') {
    piyanoCal(akor, olaylar, seviye);
  } else {
    gitarCal(akor, olaylar, seviye);
  }
}

void akorOnizle(Akor akor, String enstruman) {
  if (enstruman == 'piyano') {
    piyanoCal(akor, ['c'], 0.8);
  } else {
    gitarCal(akor, ['d'], 0.8);
  }
}
