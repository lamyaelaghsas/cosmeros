import 'dart:math';

import 'package:flutter/material.dart';

import '../models/media.dart';
import '../theme/app_themes.dart';
import 'common.dart';

/// Le moment « waw » de l'accueil : ta planète au centre, tes dernières œuvres
/// en orbite autour, sous forme de petites planètes faites de leurs affiches.
class OrbitView extends StatefulWidget {
  final String name;
  final List<Media> items;
  final ValueChanged<Media> onTap;
  const OrbitView({super.key, required this.name, required this.items, required this.onTap});

  @override
  State<OrbitView> createState() => _OrbitViewState();
}

class _OrbitViewState extends State<OrbitView> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 80));

  static const _ringFactors = [0.46, 0.34, 0.22];
  static const _ringSpeeds = [1.0, 1.6, 2.4];

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

  Color _typeColor(CosmerosPalette p, MediaType t) => switch (t) {
        MediaType.film => p.accent,
        MediaType.serie => p.secondary,
        MediaType.album => p.text,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = w * 0.82;
      final center = Offset(w / 2, h / 2);
      final items = widget.items.take(6).toList();

      return SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final t = _anim.value * 2 * pi;
            final pulse = 0.5 + 0.5 * sin(t * 12);
            final children = <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingsPainter(
                    center: center,
                    radii: _ringFactors.map((f) => w * f).toList(),
                    colors: [
                      p.text.withValues(alpha: 0.14),
                      p.accent.withValues(alpha: 0.22),
                      p.secondary.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: center.dx - 36,
                top: center.dy - 36,
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(
                      color: p.secondary.withValues(alpha: 0.45 + 0.3 * pulse),
                      blurRadius: 30 + 22 * pulse,
                      spreadRadius: 4 + 8 * pulse,
                    ),
                  ]),
                  child: PlanetAvatar(name: widget.name, size: 72),
                ),
              ),
            ];

            for (var i = 0; i < items.length; i++) {
              final ring = i % 3;
              final rx = w * _ringFactors[ring];
              final ry = rx * 0.62;
              final angle = (i * 2.1) + t * _ringSpeeds[ring];
              final pos = Offset(center.dx + rx * cos(angle), center.dy + ry * sin(angle));
              final m = items[i];
              final color = _typeColor(p, m.type);
              children.add(Positioned(
                left: pos.dx - 22,
                top: pos.dy - 22,
                child: Semantics(
                  button: true,
                  label: '${m.typeLabel} : ${m.title}',
                  child: GestureDetector(
                    onTap: () => widget.onTap(m),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 14)],
                        color: p.surface,
                        image: m.imageUrl == null
                            ? null
                            : DecorationImage(image: NetworkImage(m.imageUrl!), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ));
            }
            return Stack(clipBehavior: Clip.none, children: children);
          },
        ),
      );
    });
  }
}

class _RingsPainter extends CustomPainter {
  final Offset center;
  final List<double> radii;
  final List<Color> colors;
  _RingsPainter({required this.center, required this.radii, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < radii.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colors[i];
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radii[i] * 2, height: radii[i] * 2 * 0.62),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.colors != colors || old.center != center;
}
