import 'package:flutter/material.dart';

import '../models/media.dart';
import '../theme/app_themes.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.text.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.text.withValues(alpha: 0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Affiche (2:3) pour films et séries, pochette carrée pour les albums.
class MediaCover extends StatelessWidget {
  final Media media;
  final double width;
  final bool glow;
  const MediaCover({super.key, required this.media, required this.width, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final height = media.isAlbum ? width : width * 1.5;
    final placeholder = Container(
      color: p.surface,
      alignment: Alignment.center,
      child: Icon(media.isAlbum ? Icons.album_outlined : Icons.movie_outlined, color: p.muted),
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.accent.withValues(alpha: glow ? 0.9 : 0.25)),
        boxShadow: glow
            ? [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 36)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: media.imageUrl == null
            ? placeholder
            : Image.network(media.imageUrl!,
                fit: BoxFit.cover,
                semanticLabel: media.title,
                errorBuilder: (_, __, ___) => placeholder),
      ),
    );
  }
}

/// Note en étoiles. Toucher l'étoile déjà sélectionnée enlève la note.
class StarRating extends StatelessWidget {
  final double? value;
  final ValueChanged<double?>? onChanged;
  final double size;
  const StarRating({super.key, this.value, this.onChanged, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        final filled = v >= n;
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? p.accent : p.muted.withValues(alpha: 0.6),
          shadows: filled ? [Shadow(color: p.accent, blurRadius: 10)] : null,
        );
        if (onChanged == null) return star;
        return Semantics(
          button: true,
          label: '$n étoile${n > 1 ? 's' : ''}',
          child: InkResponse(
            onTap: () => onChanged!(v == n ? null : n.toDouble()),
            radius: size * 0.8,
            child: Padding(padding: const EdgeInsets.all(4), child: star),
          ),
        );
      }),
    );
  }
}

/// L'avatar planète, avec l'initiale du membre.
class PlanetAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ring;
  const PlanetAvatar({super.key, required this.name, this.size = 36, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final planet = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: p.planet,
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: displayStyle(context, size * 0.38, weight: FontWeight.w700, color: p.space),
      ),
    );
    if (!ring) return planet;
    return SizedBox(
      width: size * 1.7,
      height: size * 1.15,
      child: Stack(alignment: Alignment.center, children: [
        planet,
        Transform.rotate(
          angle: -0.28,
          child: Container(
            width: size * 1.7,
            height: size * 0.32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.elliptical(size * 0.85, size * 0.16)),
              border: Border.all(color: p.accent, width: 2),
            ),
          ),
        ),
      ]),
    );
  }
}

class ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChoicePill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.accent : p.text.withValues(alpha: 0.05),
      shape: StadiumBorder(
          side: BorderSide(color: selected ? p.accent : p.text.withValues(alpha: 0.16))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: selected ? p.space : p.text,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
