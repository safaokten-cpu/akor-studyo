import 'package:flutter/material.dart';
import 'ekran.dart';
import 'ses.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seslerHazirla();
  runApp(const AkorStudyo());
}

class AkorStudyo extends StatelessWidget {
  const AkorStudyo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: temaOlustur(),
      home: const AkorEkrani(),
    );
  }
}
