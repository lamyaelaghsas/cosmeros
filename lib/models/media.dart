enum MediaType { film, serie, album }

class Media {
  /// Identifiant stable : "tmdb:movie:157336", "tmdb:tv:95396", "deezer:album:302127".
  final String id;
  final MediaType type;
  final String title;
  final String? subtitle; // artiste pour un album
  final String? year;
  final String? imageUrl;
  final String? overview;

  const Media({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.year,
    this.imageUrl,
    this.overview,
  });

  factory Media.fromRow(Map<String, dynamic> r) => Media(
        id: r['id'] as String,
        type: MediaType.values.byName(r['type'] as String),
        title: r['title'] as String,
        subtitle: r['subtitle'] as String?,
        year: r['year'] as String?,
        imageUrl: r['image_url'] as String?,
        overview: r['overview'] as String?,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'year': year,
        'image_url': imageUrl,
        'overview': overview,
      };

  bool get isAlbum => type == MediaType.album;

  String get typeLabel => switch (type) {
        MediaType.film => 'Film',
        MediaType.serie => 'Série',
        MediaType.album => 'Album',
      };

  String get doneLabel => isAlbum ? 'Écouté' : 'Vu';
  String get laterLabel => isAlbum ? 'À écouter' : 'À voir';

  String get metaLine => [
        typeLabel,
        if (year != null) year!,
        if (subtitle != null) subtitle!,
      ].join(', ');
}
