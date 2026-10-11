import 'package:flutter/material.dart';

import '../models/media.dart';
import '../services/db_service.dart';
import '../theme/app_themes.dart';
import '../widgets/common.dart';
import '../widgets/orbit_view.dart';
import '../widgets/starfield.dart';
import 'media_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onExplore;
  const HomeScreen({super.key, required this.onExplore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DbService();
  String _name = '';
  List<Media> _orbit = [];
  List<Map<String, dynamic>> _feed = [];
  Set<int> _liked = {};
  Set<int> _likedAtLoad = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _db.profile(_db.uid),
        _db.recentMedia(_db.uid),
        _db.feed(),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      final feed = results[2] as List<Map<String, dynamic>>;
      final liked = await _db.myLikes(feed.map((e) => e['id'] as int).toList());
      if (!mounted) return;
      setState(() {
        _name = (profile?['display_name'] ?? profile?['username'] ?? '') as String;
        _orbit = results[1] as List<Media>;
        _feed = feed;
        _liked = liked;
        _likedAtLoad = {...liked};
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger ton univers. Tire vers le bas pour réessayer.';
      });
    }
  }

  Future<void> _openMedia(Media m) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MediaDetailScreen(media: m)));
    _load();
  }

  Future<void> _toggleLike(Map<String, dynamic> entry) async {
    final id = entry['id'] as int;
    final like = !_liked.contains(id);
    setState(() {
      if (like) {
        _liked.add(id);
      } else {
        _liked.remove(id);
      }
    });
    try {
      await _db.setLike(id, like);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (like) {
          _liked.remove(id);
        } else {
          _liked.add(id);
        }
      });
      showSnack(context, "Le j'aime n'a pas été enregistré.");
    }
  }

  Future<void> _moderate(Map<String, dynamic> entry, String action) async {
    final userId = entry['user_id'] as String;
    if (action == 'block') {
      await _db.block(userId);
      if (mounted) showSnack(context, 'Membre bloqué. Tu ne verras plus son activité.');
      _load();
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Signaler cette critique'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Explique le problème'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Signaler')),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    await _db.report(entryId: entry['id'] as int, userId: userId, reason: reason);
    if (mounted) showSnack(context, 'Signalement envoyé.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Starfield(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: p.accent,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Text('COSMEROS', style: displayStyle(context, 22, weight: FontWeight.w700).copyWith(letterSpacing: 4)),
              const SizedBox(height: 20),
              Text('Ce qui gravite autour de toi',
                  textAlign: TextAlign.center, style: displayStyle(context, 21)),
              const SizedBox(height: 8),
              if (_loading)
                const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))
              else ...[
                OrbitView(name: _name, items: _orbit, onTap: _openMedia),
                if (_orbit.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(children: [
                      Text('Ton orbite est vide pour l\'instant.',
                          style: TextStyle(color: p.muted)),
                      const SizedBox(height: 10),
                      ChoicePill(label: 'Ajouter une première œuvre', selected: true, onTap: widget.onExplore),
                    ]),
                  ),
              ],
              Text('Transmissions', style: displayStyle(context, 16)),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: TextStyle(color: p.muted))
              else if (!_loading && _feed.isEmpty)
                Text("Personne ici pour l'instant. Cherche des membres dans Explorer et suis-les pour voir leur activité.",
                    style: TextStyle(color: p.muted, height: 1.4))
              else
                ..._feed.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransmissionCard(
                        entry: e,
                        isMine: e['user_id'] == _db.uid,
                        liked: _liked.contains(e['id']),
                        countDelta: (_liked.contains(e['id']) ? 1 : 0) - (_likedAtLoad.contains(e['id']) ? 1 : 0),
                        onLike: () => _toggleLike(e),
                        onMedia: _openMedia,
                        onModerate: (a) => _moderate(e, a),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransmissionCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isMine;
  final bool liked;
  final int countDelta;
  final VoidCallback onLike;
  final ValueChanged<Media> onMedia;
  final ValueChanged<String> onModerate;

  const _TransmissionCard({
    required this.entry,
    required this.isMine,
    required this.liked,
    required this.countDelta,
    required this.onLike,
    required this.onMedia,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mediaRow = entry['media'] as Map<String, dynamic>?;
    if (mediaRow == null) return const SizedBox.shrink();
    final media = Media.fromRow(mediaRow);
    final profile = entry['profiles'] as Map<String, dynamic>? ?? {};
    final name = (profile['display_name'] ?? profile['username'] ?? 'membre') as String;
    final rating = (entry['rating'] as num?)?.toDouble();
    final review = entry['review'] as String?;
    final done = entry['status'] == 'vu';
    final verb = done ? (media.isAlbum ? 'a écouté' : 'a vu') : (media.isAlbum ? 'veut écouter' : 'veut voir');
    final likeCounts = entry['likes'] as List?;
    final likeCount = (likeCounts != null && likeCounts.isNotEmpty) ? (likeCounts.first['count'] as int? ?? 0) : 0;

    return GlassCard(
      onTap: () => onMedia(media),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MediaCover(media: media, width: 58),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: profile['id'] as String))),
                child: Row(children: [
                  PlanetAvatar(name: name, size: 22),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
              const SizedBox(width: 4),
              Flexible(child: Text(verb, style: TextStyle(color: p.muted, fontSize: 13), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Text(media.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (rating != null) ...[
              const SizedBox(height: 4),
              StarRating(value: rating, size: 16),
            ],
            if (review != null) ...[
              const SizedBox(height: 6),
              Text(review, maxLines: 4, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text.withValues(alpha: 0.82), height: 1.4)),
            ],
            Row(children: [
              IconButton(
                onPressed: onLike,
                tooltip: liked ? "Je n'aime plus" : "J'aime",
                icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: liked ? p.accent : p.muted, size: 20),
              ),
              Text('${likeCount + countDelta}',
                  style: TextStyle(color: p.muted, fontSize: 13)),
              const Spacer(),
              if (!isMine)
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  icon: Icon(Icons.more_horiz, color: p.muted),
                  onSelected: onModerate,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'report', child: Text('Signaler')),
                    PopupMenuItem(value: 'block', child: Text('Bloquer ce membre')),
                  ],
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
