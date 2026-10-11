import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/media.dart';
import '../services/db_service.dart';
import '../theme/app_themes.dart';
import '../widgets/common.dart';
import '../widgets/starfield.dart';
import 'media_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isTab; // true quand c'est l'onglet Profil (pas de bouton retour)
  const ProfileScreen({super.key, required this.userId, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DbService();
  Map<String, dynamic>? _profile;
  Map<MediaType, int> _counts = {};
  List<Media> _favorites = [];
  bool _following = false;
  bool _loading = true;

  bool get _isMe => widget.userId == _db.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _db.profile(widget.userId),
      _db.counts(widget.userId),
      _db.favorites(widget.userId),
      if (!_isMe) _db.isFollowing(widget.userId),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _counts = results[1] as Map<MediaType, int>;
      _favorites = results[2] as List<Media>;
      if (!_isMe) _following = results[3] as bool;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final next = !_following;
    setState(() => _following = next);
    try {
      await _db.setFollow(widget.userId, next);
    } catch (_) {
      if (mounted) setState(() => _following = !next);
    }
  }

  Future<void> _link(OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.linkIdentity(provider, redirectTo: Config.authRedirect);
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  Future<void> _pickTheme(CosmerosTheme t) async {
    context.read<ThemeController>().set(t);
    try {
      await _db.updateProfile({'theme': t.name});
    } catch (_) {
      if (mounted) showSnack(context, "Le thème n'a pas été sauvegardé sur ton compte.");
    }
  }

  Future<void> _edit() async {
    final name = TextEditingController(text: _profile?['display_name'] as String? ?? '');
    final bio = TextEditingController(text: _profile?['bio'] as String? ?? '');
    final insta = TextEditingController(text: _profile?['instagram'] as String? ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom affiché')),
          const SizedBox(height: 12),
          TextField(controller: bio, maxLength: 160, decoration: const InputDecoration(labelText: 'Bio')),
          const SizedBox(height: 4),
          TextField(
            controller: insta,
            decoration: const InputDecoration(labelText: 'Instagram', prefixText: '@'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer le profil'),
            ),
          ),
        ]),
      ),
    );
    if (saved == true) {
      await _db.updateProfile({
        'display_name': name.text.trim().isEmpty ? null : name.text.trim(),
        'bio': bio.text.trim().isEmpty ? null : bio.text.trim(),
        'instagram': insta.text.trim().replaceAll('@', '').isEmpty ? null : insta.text.trim().replaceAll('@', ''),
      });
      _load();
    }
  }

  Widget _stat(String label, int n) {
    final p = context.palette;
    return Column(children: [
      Text('$n', style: displayStyle(context, 18)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = context.watch<ThemeController>().theme;
    final identities = Supabase.instance.client.auth.currentUser?.identities ?? [];
    bool linked(String provider) => identities.any((i) => i.provider == provider);

    final username = _profile?['username'] as String? ?? '';
    final name = (_profile?['display_name'] as String?) ?? username;
    final bio = _profile?['bio'] as String?;
    final insta = _profile?['instagram'] as String?;

    return Scaffold(
      body: Starfield(
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  children: [
                    Row(children: [
                      if (!widget.isTab)
                        IconButton(
                          tooltip: 'Retour',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      const Spacer(),
                      if (_isMe) ...[
                        IconButton(tooltip: 'Modifier le profil', onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                          tooltip: 'Se déconnecter',
                          onPressed: () => Supabase.instance.client.auth.signOut(),
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 8),
                    Center(child: PlanetAvatar(name: name, size: 88, ring: true)),
                    const SizedBox(height: 14),
                    Text(name, textAlign: TextAlign.center, style: displayStyle(context, 22)),
                    Text('@$username', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                    if (bio != null) ...[
                      const SizedBox(height: 8),
                      Text(bio, textAlign: TextAlign.center, style: TextStyle(color: p.text.withValues(alpha: 0.85))),
                    ],
                    const SizedBox(height: 14),
                    Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                      if (_isMe) ...[
                        _LinkChip(label: 'Spotify', linked: linked('spotify'), onTap: () => _link(OAuthProvider.spotify)),
                        _LinkChip(label: 'X', linked: linked('twitter'), onTap: () => _link(OAuthProvider.twitter)),
                      ],
                      if (insta != null) _LinkChip(label: '@$insta', linked: true, onTap: null),
                    ]),
                    if (!_isMe) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ChoicePill(
                          label: _following ? 'Abonné·e' : 'Suivre',
                          selected: !_following,
                          onTap: _toggleFollow,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _stat('Films', _counts[MediaType.film] ?? 0),
                        _stat('Séries', _counts[MediaType.serie] ?? 0),
                        _stat('Albums', _counts[MediaType.album] ?? 0),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    Text('Constellation', style: displayStyle(context, 15)),
                    const SizedBox(height: 10),
                    if (_favorites.isEmpty)
                      Text(
                        _isMe
                            ? 'Ajoute tes œuvres préférées avec l\'icône étoile sur leur fiche.'
                            : 'Pas encore de favoris.',
                        style: TextStyle(color: p.muted),
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _favorites.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => MediaDetailScreen(media: _favorites[i]))),
                            child: MediaCover(media: _favorites[i], width: _favorites[i].isAlbum ? 100 : 96),
                          ),
                        ),
                      ),
                    if (_isMe) ...[
                      const SizedBox(height: 24),
                      Text('Ton thème', style: displayStyle(context, 15)),
                      const SizedBox(height: 10),
                      Row(
                        children: CosmerosTheme.values.map((t) {
                          final tp = t.palette;
                          final selected = t == current;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: selected ? p.accent.withValues(alpha: 0.1) : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: selected ? p.accent : p.text.withValues(alpha: 0.12)),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _pickTheme(t),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            center: const Alignment(-0.3, -0.4),
                                            colors: tp.planet,
                                            stops: const [0, 0.5, 1],
                                          ),
                                          border: Border.all(color: tp.muted.withValues(alpha: 0.5)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(t.label,
                                          style: TextStyle(fontSize: 12, color: selected ? p.text : p.muted)),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final String label;
  final bool linked;
  final VoidCallback? onTap;
  const _LinkChip({required this.label, required this.linked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.text.withValues(alpha: 0.05),
      shape: StadiumBorder(side: BorderSide(color: p.text.withValues(alpha: 0.14))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: linked ? null : onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (linked)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              ),
            Text(linked ? label : 'Relier $label', style: const TextStyle(fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
