import 'dart:async';

import 'package:flutter/material.dart';

import '../models/media.dart';
import '../services/catalog_service.dart';
import '../services/db_service.dart';
import '../theme/app_themes.dart';
import '../widgets/common.dart';
import '../widgets/starfield.dart';
import 'media_detail_screen.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _catalog = CatalogService();
  final _db = DbService();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _members = false;
  bool _loading = false;
  List<Media> _media = [];
  List<Map<String, dynamic>> _users = [];
  MediaType? _filter;

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  Future<void> _run() async {
    final q = _ctrl.text;
    setState(() => _loading = true);
    try {
      if (_members) {
        final users = await _db.searchUsers(q);
        if (mounted) setState(() => _users = users);
      } else {
        final media = await _catalog.search(q);
        if (mounted) setState(() => _media = media);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final media = _filter == null ? _media : _media.where((m) => m.type == _filter).toList();

    return Starfield(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explorer', style: displayStyle(context, 24)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _members ? 'Un pseudo' : 'Un film, une série, un album',
                prefixIcon: Icon(Icons.search, color: p.muted),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ChoicePill(
                  label: 'Œuvres',
                  selected: !_members,
                  onTap: () {
                    setState(() => _members = false);
                    _run();
                  },
                ),
                const SizedBox(width: 8),
                ChoicePill(
                  label: 'Membres',
                  selected: _members,
                  onTap: () {
                    setState(() => _members = true);
                    _run();
                  },
                ),
                if (!_members) ...[
                  const SizedBox(width: 16),
                  for (final t in MediaType.values) ...[
                    ChoicePill(
                      label: switch (t) {
                        MediaType.film => 'Films',
                        MediaType.serie => 'Séries',
                        MediaType.album => 'Musique',
                      },
                      selected: _filter == t,
                      onTap: () => setState(() => _filter = _filter == t ? null : t),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ]),
            ),
            const SizedBox(height: 12),
            if (_loading) LinearProgressIndicator(color: p.accent, backgroundColor: Colors.transparent),
            Expanded(
              child: _members
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      children: _users.map((u) {
                        final name = (u['display_name'] ?? u['username']) as String;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PlanetAvatar(name: name, size: 40),
                          title: Text(name),
                          subtitle: Text('@${u['username']}', style: TextStyle(color: p.muted)),
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProfileScreen(userId: u['id'] as String))),
                        );
                      }).toList(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: media.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final m = media[i];
                        return GlassCard(
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => MediaDetailScreen(media: m))),
                          child: Row(children: [
                            MediaCover(media: m, width: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(m.metaLine, style: TextStyle(color: p.muted, fontSize: 13)),
                              ]),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
