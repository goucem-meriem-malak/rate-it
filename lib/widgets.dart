import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'l10n.dart';
import 'logo_data.dart';
import 'models.dart';
import 'screens/title_screen.dart';
import 'services.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Glass building blocks
// ---------------------------------------------------------------------------

/// Soft pink glow behind every screen.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  Widget _orb(int argb, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [Color(argb), Color(argb & 0x00FFFFFF)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.page),
        Positioned(top: -140, right: -120, child: _orb(dark ? 0x59EC008C : 0x40FF5CAA, 380)),
        Positioned(bottom: -170, left: -150, child: _orb(dark ? 0x40FF4DA6 : 0x33EC008C, 430)),
        Positioned(top: 280, left: -210, child: _orb(dark ? 0x26FF80C0 : 0x2EFFB3D9, 330)),
        child,
      ],
    );
  }
}

/// A Scaffold that sits on the glass background.
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

/// A frosted panel. Set blur > 0 only where content scrolls behind it.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? tint;
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 22,
    this.blur = 0,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? context.glassFill,
        borderRadius: r,
        border: Border.all(color: context.glassBorder, width: 1),
      ),
      child: child,
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(color: context.glassShadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: blur > 0
          ? ClipRRect(
              borderRadius: r,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: box,
              ),
            )
          : box,
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NavItem(this.icon, this.selectedIcon, this.label);
}

/// Floating glass bottom bar.
class GlassNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  const GlassNavBar(
      {super.key, required this.index, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
        child: Glass(
          radius: 30,
          blur: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    label: items[i].label,
                    button: true,
                    selected: i == index,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: i == index ? context.pinkGlass : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          i == index ? items[i].selectedIcon : items[i].icon,
                          size: 26,
                          color: i == index ? brand : context.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer (loading placeholder)
// ---------------------------------------------------------------------------

class Shimmer extends StatefulWidget {
  final Widget child; // paint it in solid white; the shimmer colors it
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final base = dark ? const Color(0xFF2A2A31) : const Color(0xFFEBDDE5);
    final highlight = dark ? const Color(0xFF4A4A55) : const Color(0xFFFFFFFF);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.3, 0.5, 0.7],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _SlideGradient(_c.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double progress;
  const _SlideGradient(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}

/// Placeholder rows shown while a search is loading.
class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  Widget _box(double w, double h, double r) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r)),
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
        itemCount: 7,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              _box(52, 78, 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(190, 15, 8),
                    const SizedBox(height: 10),
                    _box(110, 12, 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Posters, stars, avatars
// ---------------------------------------------------------------------------

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: context.isDark ? const Color(0x40EC008C) : const Color(0x33EC008C),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: path == null
            ? _placeholder(context)
            : Image.network(
                'https://image.tmdb.org/t/p/w342$path',
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              ),
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
                : (context.isDark ? const Color(0xFF4A4A55) : const Color(0xFFD9CFD6)),
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(t(context, 'empty_section'),
                style: TextStyle(color: context.muted)),
          )
        else
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                        const SizedBox(height: 10),
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

// ---------------------------------------------------------------------------
// Logo and launch screen
// ---------------------------------------------------------------------------

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

/// Launch screen: the logo fades and pops in on the glass background.
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
    return GlassScaffold(
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: const BrandLogo(size: 130)),
        ),
      ),
    );
  }
}
