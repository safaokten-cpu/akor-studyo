import 'package:flutter/material.dart';
import 'durum.dart';
import 'kalip.dart';
import 'ortak.dart';
import 'tema.dart';

// Sounds'taki Arpej düğmesinin penceresi: adım sayısına göre hazır desenler
// ya da elle yazılan desen. Seçilince o enstrümanın yeni parçası olarak eklenir.
void arpejPenceresiAc(BuildContext context, StudyoDurumu d) {
  final mesaj = ScaffoldMessenger.maybeOf(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: renkKart,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ArpejPenceresi(d, mesaj),
  );
}

class _ArpejPenceresi extends StatefulWidget {
  final StudyoDurumu d;
  final ScaffoldMessengerState? mesaj;
  const _ArpejPenceresi(this.d, this.mesaj);

  @override
  State<_ArpejPenceresi> createState() => _ArpejPenceresiDurumu();
}

class _ArpejPenceresiDurumu extends State<_ArpejPenceresi> {
  final TextEditingController _yazi = TextEditingController();
  late int _adim;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _adim = arpejAdimSayilari.contains(widget.d.olcu.slot)
        ? widget.d.olcu.slot
        : arpejAdimSayilari.first;
  }

  @override
  void dispose() {
    _yazi.dispose();
    super.dispose();
  }

  void _sec(String desen) {
    widget.d.arpejParcaEkle(desen);
    Navigator.pop(context);
    widget.mesaj?.showSnackBar(
      SnackBar(
        content: Text('Arpej parçalara eklendi: ${desen.replaceAll(' ', '')}'),
      ),
    );
  }

  void _yazidanUygula() {
    final desen = desenTemizle(_yazi.text);
    if (desen == null) {
      setState(() => _hata =
          'Desen okunamadı. p i m a gibi yaz (harfler: p P i m a c d u b h, nokta = boşluk).');
      return;
    }
    _sec(desen);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final ens = d.secEns == 'davul' ? 'gitar' : d.secEns;
    final liste = [
      for (final x in arpejHavuzu)
        if (x.split(' ').length == _adim) x,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${enstrumanAdlari[ens] ?? ''} için arpej',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            altBaslik('Adım sayısı:'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final n in arpejAdimSayilari)
                  secChip('$n', _adim == n, () => setState(() => _adim = n)),
              ],
            ),
            const SizedBox(height: 10),
            altBaslik('Desenler:'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final x in liste) secChip(x, false, () => _sec(x)),
              ],
            ),
            const SizedBox(height: 12),
            altBaslik('Kendin yaz:'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yazi,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'pima ya da p i m a',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _yazidanUygula,
                  child: const Text('Uygula'),
                ),
              ],
            ),
            if (_hata != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _hata!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
