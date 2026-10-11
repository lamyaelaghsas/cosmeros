import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/media.dart';

/// Toutes les lectures / écritures Supabase de l'app.
class DbService {
  SupabaseClient get _c => Supabase.instance.client;
  String get uid => _c.auth.currentUser!.id;

  // ---------- Profils ----------

  Future<Map<String, dynamic>?> profile(String id) async =>
      await _c.from('profiles').select().eq('id', id).maybeSingle();

  Future<void> updateProfile(Map<String, dynamic> values) async {
    await _c.from('profiles').update(values).eq('id', uid);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String q) async {
    if (q.trim().isEmpty) return [];
    return await _c
        .from('profiles')
        .select('id, username, display_name')
        .ilike('username', '%${q.trim()}%')
        .limit(20);
  }

  /// Nombre d'œuvres vues / écoutées par type.
  Future<Map<MediaType, int>> counts(String userId) async {
    final rows = await _c
        .from('entries')
        .select('media(type)')
        .eq('user_id', userId)
        .eq('status', 'vu');
    final out = {for (final t in MediaType.values) t: 0};
    for (final r in rows) {
      final m = r['media'] as Map<String, dynamic>?;
      if (m == null) continue;
      final t = MediaType.values.byName(m['type'] as String);
      out[t] = out[t]! + 1;
    }
    return out;
  }

  // ---------- Œuvres et journal ----------

  Future<void> cacheMedia(Media m) async {
    await _c.from('media').upsert(m.toRow());
  }

  Future<Map<String, dynamic>?> myEntry(String mediaId) async => await _c
      .from('entries')
      .select()
      .eq('user_id', uid)
      .eq('media_id', mediaId)
      .maybeSingle();

  Future<void> saveEntry({
    required Media media,
    required String status, // 'vu' ou 'a_voir'
    double? rating,
    String? review,
  }) async {
    await cacheMedia(media);
    await _c.from('entries').upsert({
      'user_id': uid,
      'media_id': media.id,
      'status': status,
      'rating': rating,
      'review': (review == null || review.trim().isEmpty) ? null : review.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,media_id');
  }

  Future<void> deleteEntry(String mediaId) async {
    await _c.from('entries').delete().eq('user_id', uid).eq('media_id', mediaId);
  }

  Future<List<Media>> recentMedia(String userId, {int limit = 6}) async {
    final rows = await _c
        .from('entries')
        .select('media(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(limit);
    return rows
        .where((r) => r['media'] != null)
        .map((r) => Media.fromRow(r['media'] as Map<String, dynamic>))
        .toList();
  }

  // ---------- Fil d'actu ----------

  Future<List<Map<String, dynamic>>> feed() async {
    final ids = [...await followingIds(), uid];
    final blocked = (await blockedIds()).toSet();
    final rows = await _c
        .from('entries')
        .select('*, profiles(id, username, display_name), media(*), likes(count)')
        .inFilter('user_id', ids)
        .order('updated_at', ascending: false)
        .limit(50);
    return rows.where((r) => !blocked.contains(r['user_id'])).toList();
  }

  Future<Set<int>> myLikes(List<int> entryIds) async {
    if (entryIds.isEmpty) return {};
    final rows = await _c
        .from('likes')
        .select('entry_id')
        .eq('user_id', uid)
        .inFilter('entry_id', entryIds);
    return rows.map((r) => r['entry_id'] as int).toSet();
  }

  Future<void> setLike(int entryId, bool like) async {
    if (like) {
      await _c.from('likes').upsert({'user_id': uid, 'entry_id': entryId}, ignoreDuplicates: true);
    } else {
      await _c.from('likes').delete().eq('user_id', uid).eq('entry_id', entryId);
    }
  }

  // ---------- Abonnements ----------

  Future<List<String>> followingIds() async {
    final rows =
        await _c.from('follows').select('following_id').eq('follower_id', uid);
    return rows.map((r) => r['following_id'] as String).toList();
  }

  Future<bool> isFollowing(String id) async {
    final row = await _c
        .from('follows')
        .select('following_id')
        .eq('follower_id', uid)
        .eq('following_id', id)
        .maybeSingle();
    return row != null;
  }

  Future<void> setFollow(String id, bool follow) async {
    if (follow) {
      await _c.from('follows').upsert({'follower_id': uid, 'following_id': id}, ignoreDuplicates: true);
    } else {
      await _c
          .from('follows')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', id);
    }
  }

  // ---------- Favoris (la constellation) ----------

  Future<List<Media>> favorites(String userId) async {
    final rows = await _c
        .from('favorites')
        .select('position, media(*)')
        .eq('user_id', userId)
        .order('position');
    return rows
        .where((r) => r['media'] != null)
        .map((r) => Media.fromRow(r['media'] as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFavorite(String mediaId) async {
    final row = await _c
        .from('favorites')
        .select('media_id')
        .eq('user_id', uid)
        .eq('media_id', mediaId)
        .maybeSingle();
    return row != null;
  }

  Future<void> setFavorite(Media m, bool fav) async {
    if (fav) {
      await cacheMedia(m);
      await _c.from('favorites').upsert({
        'user_id': uid,
        'media_id': m.id,
        'position': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    } else {
      await _c.from('favorites').delete().eq('user_id', uid).eq('media_id', m.id);
    }
  }

  // ---------- Modération (obligatoire pour l'App Store) ----------

  Future<List<String>> blockedIds() async {
    final rows =
        await _c.from('blocks').select('blocked_id').eq('blocker_id', uid);
    return rows.map((r) => r['blocked_id'] as String).toList();
  }

  Future<void> block(String userId) async {
    await _c.from('blocks').upsert({'blocker_id': uid, 'blocked_id': userId}, ignoreDuplicates: true);
    await setFollow(userId, false);
  }

  Future<void> report({int? entryId, String? userId, required String reason}) async {
    await _c.from('reports').insert({
      'reporter_id': uid,
      'entry_id': entryId,
      'reported_user_id': userId,
      'reason': reason,
    });
  }
}
