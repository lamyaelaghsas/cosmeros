import 'package:flutter/material.dart';

import '../models/media.dart';
import '../services/catalog_service.dart';
import '../services/db_service.dart';
import '../theme/app_themes.dart';
import '../widgets/common.dart';
import '../widgets/starfield.dart';

class MediaDetailScreen extends StatefulWidget {
  final Media media;
  const MediaDetailScreen({super.key, required this.media});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  final _db = DbService();
  final _catalog = CatalogService();
  final _review = TextEditingController();

  String? _status; // 'vu', 'a_voir' ou null
  double? _rating;
  bool _favorite = false;
  bool _saving = false;
  List<Media> _soundtrack = [];

  Media get m => widget.media;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entry = await _db.myEntry(m.id);
      final fav = await _db.isFavorite(m.id);
      if (!mounted) return;
      setState(() {
        _status = entry?['status'] as String?;
        _rating = (entry?['rating'] as num?)?.toDouble();
        _review.text = (entry?['review'] as String?) ?? '';
        _favorite = fav;
      });
    } catch (_) {
      // Œuvre jamais enregistrée : rien à charger.
    }
    final st = await _catalog.soundtrackFor(m);
    if (mounted) setState(() => _soundtrack = st);
  }

  Future<void> _save() async {
    final status = _status ?? (_rating != null || _review.text.trim().isNotEmpty ? 'vu' : null);
    if (status == null) {
      showSnack(context, 'Choisis « ${m.doneLabel} » ou « ${m.laterLabel} » avant d\'enregistrer.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _db.saveEntry(media: m, status: status, rating: _rating, review: _review.text);
      if (!mounted) return;
      setState(() => _status = status);
      showSnack(context, 'Enregistré dans ton orbite.');
    } catch (_) {
      if (mounted) showSnack(context, "L'enregistrement a échoué. Réessaie.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final next = !_favorite;
    setState(() => _favorite = next);
    try {
      await _db.setFavorite(m, next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favorite = !next);
      showSnack(context, "Le favori n'a pas été enregistré.");
    }
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Starfield(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Row(children: [
                IconButton(
                  tooltip: 'Retour',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const Spacer(),
                IconButton(
                  tooltip: _favorite ? 'Retirer de ma constellation' : 'Ajouter à ma constellation',
                  onPressed: _toggleFavorite,
                  icon: Icon(_favorite ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                      color: _favorite ? p.accent : p.text),
                ),
              ]),
              const SizedBox(height: 8),
              Center(child: MediaCover(media: m, width: m.isAlbum ? 200 : 150, glow: true)),
              const SizedBox(height: 28),
              Text(m.title, textAlign: TextAlign.center, style: displayStyle(context, 26, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(m.metaLine, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
              const SizedBox(height: 16),
              Center(child: StarRating(value: _rating, onChanged: (v) => setState(() => _rating = v))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ChoicePill(
                    label: m.doneLabel,
                    selected: _status == 'vu',
                    onTap: () => setState(() => _status = _status == 'vu' ? null : 'vu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoicePill(
                    label: m.laterLabel,
                    selected: _status == 'a_voir',
                    onTap: () => setState(() => _status = _status == 'a_voir' ? null : 'a_voir'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _review,
                maxLines: 4,
                minLines: 2,
                maxLength: 5000,
                decoration: const InputDecoration(hintText: 'Ta critique (facultatif)'),
              ),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: p.accent, foregroundColor: p.space, shape: const StadiumBorder()),
                  child: Text(_saving ? 'Enregistrement…' : 'Enregistrer',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              if (m.overview != null && m.overview!.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Synopsis', style: displayStyle(context, 15)),
                const SizedBox(height: 8),
                Text(m.overview!, style: TextStyle(color: p.text.withValues(alpha: 0.85), height: 1.5)),
              ],
              if (_soundtrack.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Fréquence', style: displayStyle(context, 15)),
                const SizedBox(height: 4),
                Text('Côté musique', style: TextStyle(color: p.muted, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _soundtrack.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final a = _soundtrack[i];
                      return GestureDetector(
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => MediaDetailScreen(media: a))),
                        child: SizedBox(
                          width: 110,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            MediaCover(media: a, width: 110),
                            const SizedBox(height: 6),
                            Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _db.deleteEntry(m.id);
                      if (!mounted) return;
                      setState(() {
                        _status = null;
                        _rating = null;
                        _review.clear();
                      });
                    },
                    child: Text('Retirer de mon journal', style: TextStyle(color: p.muted)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
