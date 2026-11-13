import 'package:flutter/material.dart';
import 'tema.dart';

// Birkaç yerde kullanılan küçük ortak parçalar.

Widget yatayStrip(List<Widget> cocuklar) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: cocuklar),
  );
}

Widget altBaslik(String yazi) {
  return Text(
    yazi,
    style: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 13, color: renkToprakAcik),
  );
}

Widget secChip(String yazi, bool secildi, VoidCallback f, {Widget? avatar}) {
  return ChoiceChip(
    avatar: avatar,
    label: Text(yazi),
    selected: secildi,
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    onSelected: (_) => f(),
  );
}

Widget kucukIkon(IconData ikon, VoidCallback? f) {
  return IconButton(
    onPressed: f,
    icon: Icon(ikon),
    iconSize: 22,
    color: renkToprak,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
  );
}

Widget kucukSlider(
  BuildContext context, {
  required double value,
  required double min,
  required double max,
  int? divisions,
  required ValueChanged<double> onChanged,
}) {
  return SizedBox(
    height: 26,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        activeTrackColor: renkYaprak,
        inactiveTrackColor: renkKenar,
        thumbColor: renkYaprak,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    ),
  );
}

Widget pilli(IconData ikon, String yazi) {
  return Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: renkKart,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: renkKenar),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 13, color: renkYaprak),
        const SizedBox(width: 4),
        Text(yazi,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
      ],
    ),
  );
}

// Açılır kapanır kart (Ton ve Akorlar, Loop Page, Sounds).
class KartKabugu extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final List<Widget> cocuklar;
  final bool acik;

  const KartKabugu({
    super.key,
    required this.baslik,
    required this.ikon,
    required this.cocuklar,
    this.acik = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: renkKart,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: renkKenar),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ExpansionTile(
          initiallyExpanded: acik,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          iconColor: renkYaprak,
          collapsedIconColor: renkYaprak,
          textColor: renkToprak,
          collapsedTextColor: renkToprak,
          leading: Icon(ikon, color: renkYaprak, size: 22),
          title: Text(
            baslik,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: cocuklar,
        ),
      ),
    );
  }
}
