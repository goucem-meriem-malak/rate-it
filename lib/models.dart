import 'package:cloud_firestore/cloud_firestore.dart';

class TitleInfo {
  final String mediaType; // 'movie' or 'tv'
  final int tmdbId;
  final String title;
  final String? posterPath;
  final String overview;
  final List<String> genres;
  final String year;

  const TitleInfo({
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.overview = '',
    this.genres = const [],
    this.year = '',
  });

  String get key => '${mediaType}_$tmdbId';

  Map<String, dynamic> toMap() => {
        'mediaType': mediaType,
        'tmdbId': tmdbId,
        'title': title,
        'posterPath': posterPath,
        'overview': overview,
        'genres': genres,
        'year': year,
      };

  factory TitleInfo.fromMap(Map<String, dynamic> m) => TitleInfo(
        mediaType: (m['mediaType'] as String?) ?? 'movie',
        tmdbId: (m['tmdbId'] as num).toInt(),
        title: (m['title'] as String?) ?? '',
        posterPath: m['posterPath'] as String?,
        overview: (m['overview'] as String?) ?? '',
        genres: ((m['genres'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        year: (m['year'] as String?) ?? '',
      );
}

int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

class Entry {
  final String uid;
  final TitleInfo info;
  final String list; // watching | watched | dropped
  final int overall, acting, cinematography, plot, aesthetic, sound; // 0 = not rated
  final String review;
  final bool suggest;
  final DateTime? updatedAt;

  const Entry({
    required this.uid,
    required this.info,
    required this.list,
    this.overall = 0,
    this.acting = 0,
    this.cinematography = 0,
    this.plot = 0,
    this.aesthetic = 0,
    this.sound = 0,
    this.review = '',
    this.suggest = true,
    this.updatedAt,
  });

  String get id => '${uid}_${info.key}';

  Map<String, dynamic> toMap() => {
        'uid': uid,
        ...info.toMap(),
        'list': list,
        'overall': overall,
        'acting': acting,
        'cinematography': cinematography,
        'plot': plot,
        'aesthetic': aesthetic,
        'sound': sound,
        'review': review,
        'suggest': suggest,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Entry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Entry(
      uid: (m['uid'] as String?) ?? '',
      info: TitleInfo.fromMap(m),
      list: (m['list'] as String?) ?? 'watching',
      overall: _i(m['overall']),
      acting: _i(m['acting']),
      cinematography: _i(m['cinematography']),
      plot: _i(m['plot']),
      aesthetic: _i(m['aesthetic']),
      sound: _i(m['sound']),
      review: (m['review'] as String?) ?? '',
      suggest: (m['suggest'] as bool?) ?? true,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Profile {
  final String uid;
  final String name;
  final String avatar; // an emoji
  final String favShow;
  final String groupId;
  final int? age;
  final TitleInfo? lastWatched;

  const Profile({
    required this.uid,
    required this.name,
    this.avatar = '🎬',
    this.favShow = '',
    this.groupId = '',
    this.age,
    this.lastWatched,
  });

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final lw = m['lastWatched'];
    return Profile(
      uid: d.id,
      name: (m['name'] as String?) ?? '',
      avatar: (m['avatar'] as String?) ?? '🎬',
      favShow: (m['favShow'] as String?) ?? '',
      groupId: (m['groupId'] as String?) ?? '',
      age: (m['age'] as num?)?.toInt(),
      lastWatched: lw is Map<String, dynamic> ? TitleInfo.fromMap(lw) : null,
    );
  }
}
