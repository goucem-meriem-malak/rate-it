import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _entries = Db.allEntries();
  late final Stream<List<Profile>> _profiles = Db.profiles();

  // Group entries by title; subtitle = names of the people behind it;
  // rating = average of their overall stars.
  List<PosterItem> _group(Iterable<Entry> es, Map<String, String> names,
      {int minPeople = 1}) {
    final map = <String, List<Entry>>{};
    for (final e in es) {
      map.putIfAbsent(e.info.key, () => []).add(e);
    }
    final out = <PosterItem>[];
    for (final list in map.values) {
      final people = list.map((e) => e.uid).toSet();
      if (people.length < minPeople) continue;
      final rated = list.where((e) => e.overall > 0).map((e) => e.overall).toList();
      final int avg =
          rated.isEmpty ? 0 : (rated.reduce((a, b) => a + b) / rated.length).round();
      out.add(PosterItem(
          list.first.info, people.map((u) => names[u] ?? '?').join(', '),
          rating: avg));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'app_name'),
            style: const TextStyle(
                color: brand, fontWeight: FontWeight.w900, fontSize: 26)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _entries,
        builder: (context, es) {
          if (es.hasError) return Center(child: Text('${es.error}'));
          if (!es.hasData) return const Center(child: CircularProgressIndicator());
          return StreamBuilder<List<Profile>>(
            stream: _profiles,
            builder: (context, ps) {
              if (!ps.hasData) return const Center(child: CircularProgressIndicator());
              final entries = Db.entriesFrom(es.data!);
              final profiles = ps.data!;
              final names = {for (final p in profiles) p.uid: p.name};
              final me = Db.uid;
              final watchedByMe = {
                for (final e in entries)
                  if (e.uid == me && e.list == 'watched') e.info.key
              };
              final others = entries.where((e) => e.uid != me);

              final lastWatched = [
                for (final p in profiles)
                  if (p.lastWatched != null) PosterItem(p.lastWatched!, p.name)
              ];
              // 4-5 stars from at least 2 friends, and I have not watched it.
              final must = _group(
                  others.where((e) =>
                      e.overall >= 4 && e.suggest && !watchedByMe.contains(e.info.key)),
                  names,
                  minPeople: 2);
              // Anyone's 5 stars (unless they flagged "do not suggest").
              final favs =
                  _group(entries.where((e) => e.overall == 5 && e.suggest), names);
              // 2-3 stars from friends that I have not watched.
              final meh = _group(
                  others.where((e) =>
                      e.overall >= 2 &&
                      e.overall <= 3 &&
                      e.suggest &&
                      !watchedByMe.contains(e.info.key)),
                  names);
              // 1 star or "do not suggest", from anyone.
              final avoid =
                  _group(entries.where((e) => e.overall == 1 || !e.suggest), names);

              final members = [...profiles]..sort((a, b) => a.uid == me
                  ? -1
                  : b.uid == me
                      ? 1
                      : a.name.compareTo(b.name));

              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final p = members[i];
                        return StoryAvatar(
                          emoji: p.avatar,
                          name: p.uid == me ? t(context, 'you') : p.name,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProfileScreen(uid: p.uid))),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  if (es.data!.metadata.isFromCache)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Text(t(context, 'offline_note'),
                          style: TextStyle(fontSize: 12, color: context.muted)),
                    ),
                  PosterSection(title: t(context, 'last_watched'), items: lastWatched),
                  PosterSection(title: t(context, 'must_watch'), items: must),
                  PosterSection(title: t(context, 'favorites'), items: favs),
                  PosterSection(title: t(context, 'meh'), items: meh),
                  PosterSection(title: t(context, 'avoid'), items: avoid),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
