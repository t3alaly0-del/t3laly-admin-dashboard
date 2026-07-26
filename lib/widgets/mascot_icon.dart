import 'package:flutter/material.dart';

/// Same horn-mascot silhouette as the mobile app's MascotIcon — kept as a
/// separate small copy here rather than in `shared` since it's a UI widget,
/// not a model (the `shared` package stays pure-Dart, no Flutter widgets).
class MascotIcon extends StatelessWidget {
  final double size;
  const MascotIcon({super.key, this.size = 40});

@override
Widget build(BuildContext context) {
  return SizedBox(
    width: size,
    height: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/icon.png',
        fit: BoxFit.cover,
      ),
    ),
  );
}
}
