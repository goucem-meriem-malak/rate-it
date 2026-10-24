import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'l10n.dart';
import 'logo_data.dart';
import 'models.dart';
import 'screens/title_screen.dart';
import 'services.dart';
import 'theme.dart';

class PosterImage extends StatelessWidget {
  final String? path;
  final double width;
  final double height;
  const PosterImage(
      {super.key, required this.path, required this.width, required this.height});

  Widget _placeholder(BuildContext context) => Container(
        width: width,
        height: height,
        color: context.fieldFill,
        child: Icon(Icons.movie_outlined, color: context.muted),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: path == null
          ? _placeholder(context)
          : Image.network(
              'https://image.tmdb.org/t/p/w342$path',
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            ),
    );
  }
}

/// 5 stars. Tap a star to set it, tap the same star again to clear.
/// Always left-to-right, also in Arabic.
class StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  const StarRating({super.key, required this.value, this.onChanged, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final star = Icon(
            i < value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < value
                ? gold
                : (context.isDark ? const Color(0xFF3A3A44) : const Color(0xFFD5D5DB)),
          );
          if (onChanged == null) return star;
          return GestureDetector(
            onTap: () => onChanged!(value == i + 1 ? 0 : i + 1),
            child: Padding(padding: const EdgeInsets.all(3), child: star),
          );
        }),
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final String emoji;
  final double radius;
  const AvatarCircle({super.key, required this.emoji, this.radius = 20});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: context.pinkSoft,
        child: Text(emoji, style: TextStyle(fontSize: radius)),
      );
}

/// Avatar with a pink gradient ring and a name (Instagram "stories" style).
class StoryAvatar extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback onTap;
  const StoryAvatar(
      {super.key, required this.emoji, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [brand, Color(0xFFFF8DC7)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: context.page, shape: BoxShape.circle),
                child: AvatarCircle(emoji: emoji, radius: 26),
              ),
            ),
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class PosterItem {
  final TitleInfo info;
  final String subtitle;
  final int rating; // 0 = hide stars
  const PosterItem(this.info, this.subtitle, {this.rating = 0});
}

/// A titled row of posters that scrolls sideways.
class PosterSection extends StatelessWidget {
  final String title;
  final List<PosterItem> items;
  const PosterSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(t(context, 'empty_section'),
                style: TextStyle(color: context.muted)),
          )
        else
          SizedBox(
            height: 266,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TitleScreen(info: item.info))),
                  child: SizedBox(
                    width: 124,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosterImage(
                            path: item.info.posterPath, width: 124, height: 180),
                        const SizedBox(height: 8),
                        Text(item.info.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: context.muted)),
                        if (item.rating > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: StarRating(value: item.rating, size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Gives its builder one user's profile and all of that user's entries.
class UserDataBuilder extends StatefulWidget {
  final String uid;
  final Widget Function(BuildContext, Profile?, List<Entry>) builder;
  const UserDataBuilder({super.key, required this.uid, required this.builder});

  @override
  State<UserDataBuilder> createState() => _UserDataBuilderState();
}

class _UserDataBuilderState extends State<UserDataBuilder> {
  late final Stream<Profile?> _profile = Db.profile(widget.uid);
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _entries =
      Db.entriesForUser(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Profile?>(
      stream: _profile,
      builder: (context, ps) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _entries,
        builder: (context, es) => widget.builder(
          context,
          ps.data,
          es.hasData ? Db.entriesFrom(es.data!) : const <Entry>[],
        ),
      ),
    );
  }
}

/// Last watched / Watching / Watched / Dropped, stacked, each scrolling sideways.
class ProfileLists extends StatelessWidget {
  final Profile profile;
  final List<Entry> entries;
  const ProfileLists({super.key, required this.profile, required this.entries});

  @override
  Widget build(BuildContext context) {
    List<PosterItem> from(String list) {
      final l = entries.where((e) => e.list == list).toList()
        ..sort((a, b) => (b.updatedAt ?? DateTime.now())
            .compareTo(a.updatedAt ?? DateTime.now()));
      return [
        for (final e in l)
          PosterItem(e.info, '${e.info.year} · ${t(context, e.info.mediaType)}',
              rating: e.overall)
      ];
    }

    final lw = profile.lastWatched;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PosterSection(
          title: t(context, 'last_watched'),
          items: lw == null
              ? const []
              : [PosterItem(lw, '${lw.year} · ${t(context, lw.mediaType)}')],
        ),
        PosterSection(title: t(context, 'watching'), items: from('watching')),
        PosterSection(title: t(context, 'watched'), items: from('watched')),
        PosterSection(title: t(context, 'dropped'), items: from('dropped')),
      ],
    );
  }
}

/// The Rate It logo (embedded in logo_data.dart).
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      _logoBytes,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}

final Uint8List _logoBytes = base64Decode(kLogoBase64);

/// Launch screen: white background, the logo fades and pops in.
/// With animate: false it shows the finished state (used while a profile loads).
class SplashLoading extends StatefulWidget {
  final bool animate;
  const SplashLoading({super.key, this.animate = true});

  @override
  State<SplashLoading> createState() => _SplashLoadingState();
}

class _SplashLoadingState extends State<SplashLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.8, end: 1)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    final fade = CurvedAnimation(
        parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: const BrandLogo(size: 130)),
        ),
      ),
    );
  }
}
