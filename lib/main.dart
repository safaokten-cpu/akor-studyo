import 'package:flutter/material.dart';
import 'akor.dart';

void main() => runApp(const AkorStudyo());

class AkorStudyo extends StatelessWidget {
  const AkorStudyo({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AkorEkrani());
  }
}

class AkorEkrani extends StatefulWidget {
  const AkorEkrani({super.key});
  @override
  State<AkorEkrani> createState() => _AkorEkraniState();
}

class _AkorEkraniState extends State<AkorEkrani> {
  int kok = 0;
  String tur = 'maj';

  @override
  Widget build(BuildContext context) {
    final sonuc = akorNotalari(kok, tur);
    return Scaffold(
      appBar: AppBar(title: const Text('Akor Stüdyo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kök nota:'),
            Wrap(
              spacing: 8,
              children: [
                for (int i = 0; i < 12; i++)
                  ChoiceChip(
                    label: Text(notalar[i]),
                    selected: kok == i,
                    onSelected: (_) => setState(() => kok = i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'maj', label: Text('Majör')),
                ButtonSegment(value: 'min', label: Text('Minör')),
              ],
              selected: {tur},
              onSelectionChanged: (s) => setState(() => tur = s.first),
            ),
            const SizedBox(height: 24),
            Text(
              'Akorun notaları: ${sonuc.join(' - ')}',
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
