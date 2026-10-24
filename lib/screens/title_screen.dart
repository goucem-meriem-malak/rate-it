import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';
import 'entry_edit_screen.dart';
import 'profile_screen.dart';

/// Details of one show/movie + what every friend thinks about it.
class TitleScreen extends StatefulWidget {
  final TitleInfo info;
  const TitleScreen({super.key, required this.info});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _entries =
      Db.entriesForTitle(widget.info);
  late final Stream<List<Profile>> _profiles = Db.profiles();

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _entries,
        builder: (context, es) {
          final entries = es.hasData ? Db.entriesFrom(es.data!) : <Entry>[];
          return StreamBuilder<List<Profile>>(
            stream: _profiles,
            builder: (context, ps) {
              final byUid = {for (final p in ps.data ?? <Profile>[]) p.uid: p};
              final me = Db.uid;
              final mine = entries.where((e) => e.uid == me).firstOrNull;
              final ordered = [
                if (mine != null) mine,
                ...entries.where((e) => e.uid != me),
              ];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosterImage(path: info.posterPath, width: 120, height: 180),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(info.title,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${info.year} · ${t(context, info.mediaType)}',
                                style: TextStyle(color: context.muted)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final g in info.genres)
                                  Chip(
                                      label: Text(g),
                                      visualDensity: VisualDensity.compact),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (info.overview.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(info.overview, style: const TextStyle(height: 1.4)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: Icon(mine == null ? Icons.add : Icons.edit_outlined),
                    label: Text(t(context, mine == null ? 'add_to_my_list' : 'edit_my_entry')),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EntryEditScreen(info: info, existing: mine)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(t(context, 'friends_say'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (ordered.isEmpty)
                    Text(t(context, 'nobody_yet'), style: TextStyle(color: context.muted))
                  else
                    for (final e in ordered) _EntryCard(entry: e, profile: byUid[e.uid]),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Entry entry;
  final Profile? profile;
  const _EntryCard({required this.entry, required this.profile});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isMe = e.uid == Db.uid;
    final criteria = <String, int>{
      'acting': e.acting,
      'cinematography': e.cinematography,
      'plot': e.plot,
      'aesthetic': e.aesthetic,
      'sound': e.sound,
    }..removeWhere((_, v) => v == 0);
    final name = profile?.name ?? '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProfileScreen(uid: e.uid))),
            child: Row(
              children: [
                AvatarCircle(emoji: profile?.avatar ?? '🎬', radius: 16),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(isMe ? '$name (${t(context, 'you')})' : name,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Chip(
                    label: Text(t(context, e.list)),
                    visualDensity: VisualDensity.compact),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (e.overall > 0) StarRating(value: e.overall, size: 22),
              const Spacer(),
              Icon(e.suggest ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
                  size: 18, color: context.muted),
              const SizedBox(width: 4),
              Text(t(context, e.suggest ? 'suggest' : 'do_not_suggest'),
                  style: TextStyle(color: context.muted, fontSize: 13)),
            ],
          ),
          if (criteria.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final c in criteria.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(t(context, c.key),
                            style: const TextStyle(fontSize: 13))),
                    StarRating(value: c.value, size: 14),
                  ],
                ),
              ),
          ],
          if (e.review.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(e.review, style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    );
  }
}
