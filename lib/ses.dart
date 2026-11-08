import 'package:audioplayers/audioplayers.dart';

Future<void> notaCal(String enstruman, String nota, int oktav) async {
  final oynatici = AudioPlayer();
  oynatici.onPlayerComplete.listen((_) => oynatici.dispose());
  try {
    await oynatici.play(
      AssetSource('sesler/${enstruman}_${nota}_$oktav.wav'),
    );
  } catch (e) {
    await oynatici.dispose();
  }
}

Future<void> akorCal(String enstruman, List<String> notalar) async {
  for (final nota in notalar) {
    await notaCal(enstruman, nota, 3);
    await Future.delayed(const Duration(milliseconds: 120));
  }
}
