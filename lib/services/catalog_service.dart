import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/media.dart';

/// Recherche d'œuvres : films et séries via TMDB, albums via Deezer.
class CatalogService {
  static const _tmdb = 'https://api.themoviedb.org/3';
  static const _tmdbImg = 'https://image.tmdb.org/t/p/w500';

  Future<List<Media>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final results = await Future.wait([_searchTmdb(q), _searchDeezer(q)]);
    return [...results[0], ...results[1]];
  }

  /// La « Fréquence » d'un film ou d'une série : sa bande originale côté musique.
  Future<List<Media>> soundtrackFor(Media m) async {
    if (m.isAlbum) return [];
    final albums = await _searchDeezer('${m.title} soundtrack', limit: 4);
    return albums;
  }

  Future<List<Media>> _searchTmdb(String q) async {
    if (Config.tmdbApiKey.isEmpty) return [];
    final uri = Uri.parse('$_tmdb/search/multi').replace(queryParameters: {
      'api_key': Config.tmdbApiKey,
      'query': q,
      'language': 'fr-FR',
      'include_adult': 'false',
    });
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final rows = (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
      final out = <Media>[];
      for (final r in rows) {
        final kind = r['media_type'];
        if (kind != 'movie' && kind != 'tv') continue;
        final isMovie = kind == 'movie';
        final date = (isMovie ? r['release_date'] : r['first_air_date']) as String?;
        final poster = r['poster_path'] as String?;
        out.add(Media(
          id: 'tmdb:$kind:${r['id']}',
          type: isMovie ? MediaType.film : MediaType.serie,
          title: ((isMovie ? r['title'] : r['name']) as String?) ?? 'Sans titre',
          year: (date != null && date.length >= 4) ? date.substring(0, 4) : null,
          imageUrl: poster == null ? null : '$_tmdbImg$poster',
          overview: r['overview'] as String?,
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<List<Media>> _searchDeezer(String q, {int limit = 15}) async {
    final uri = Uri.parse('https://api.deezer.com/search/album')
        .replace(queryParameters: {'q': q, 'limit': '$limit'});
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final rows = (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
      return rows.map((a) {
        final artist = a['artist'] as Map<String, dynamic>?;
        return Media(
          id: 'deezer:album:${a['id']}',
          type: MediaType.album,
          title: (a['title'] as String?) ?? 'Sans titre',
          subtitle: artist?['name'] as String?,
          imageUrl: (a['cover_xl'] as String?) ?? (a['cover_big'] as String?),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
