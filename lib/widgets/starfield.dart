import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_themes.dart';

/// Fond étoilé qui scintille doucement. Se fige si l'utilisateur a réduit les animations.
class Starfield extends StatefulWidget {
  final Widget child;
  const Starfield({super.key, required this.child});

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _Star {
  final double x, y, r, phase;
  const _Star(this.x, this.y, this.r, this.phase);
}

class _StarfieldState extends State<Starfield> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rnd = Random(7);
    _stars = List.generate(
      90,
      (_) => _Star(rnd.nextDouble(), rnd.nextDouble(),
          rnd.nextDouble() < 0.85 ? 0.8 : 1.4, rnd.nextDouble()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(children: [
      Positioned.fill(
        child: ColoredBox(
          color: p.space,
          child: CustomPaint(painter: _StarPainter(_stars, _anim, p.text)),
        ),
      ),
      widget.child,
    ]);
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final Animation<double> anim;
  final Color color;

  _StarPainter(this.stars, this.anim, this.color) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in stars) {
      final twinkle = 0.5 + 0.5 * sin(2 * pi * (anim.value + s.phase));
      paint.color = color.withValues(alpha: 0.2 + 0.6 * twinkle);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
