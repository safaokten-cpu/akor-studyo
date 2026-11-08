import 'package:flutter/material.dart';

void main() => runApp(const AkorStudyo());

class AkorStudyo extends StatelessWidget {
  const AkorStudyo({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Akor Stüdyo çalışıyor!',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
