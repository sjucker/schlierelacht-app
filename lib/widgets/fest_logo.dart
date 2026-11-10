import 'package:flutter/material.dart';

/// The festival logo (landing page, onboarding). Its lettering is black on a
/// transparent background, so in dark mode it sits on a white rounded card,
/// like a poster — on navy it would be unreadable.
class FestLogo extends StatelessWidget {
  const FestLogo({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset('assets/logo.png', height: height);
    if (Theme.of(context).brightness == Brightness.light) return logo;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Padding(padding: const EdgeInsets.all(16), child: logo),
      ),
    );
  }
}
