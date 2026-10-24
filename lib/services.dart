import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class AuthService {
  static final _fs = FirebaseFirestore.instance;

  /// Returns null on success, or an error message / key ('bad_invite', 'error_generic').
  static Future<String?> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    }
  }

  // Letters and digits without look-alikes (no 0/O, 1/I).
  static String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static Future<String> _createGroup(String uid) async {
    for (var i = 0; i < 6; i++) {
      final code = _newCode();
      try {
        // The rules only allow creating a group, never changing one,
        // so a code that already exists is refused and we try another.
        await _fs.collection('groups').doc(code).set({
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return code;
      } on FirebaseException {
        // try another code
      }
    }
    throw FirebaseException(
        plugin: 'cloud_firestore', message: 'Could not create a group code');
  }

  static Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required bool createGroup,
    String code = '',
  }) async {
    UserCredential cred;
    try {
      cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    }
    final uid = cred.user!.uid;
    try {
      final groupId = createGroup ? await _createGroup(uid) : code.trim().toUpperCase();
      // The rules refuse this if the group does not exist (wrong code).
      await _fs.collection('profiles').doc(uid).set({
        'name': name,
        'avatar': '🎬',
        'groupId': groupId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      await cred.user!.delete(); // remove the half-made account
      return createGroup ? 'error_generic' : 'bad_invite';
    }
    return null;
  }
}

class Db {
  static final _fs = FirebaseFirestore.instance;
  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  /// The signed-in user's group. Set by HomeShell as soon as the profile loads.
  static String groupId = '';

  static Stream<Profile?> profile(String id) => _fs
      .collection('profiles')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Profile.fromDoc(d) : null);

  /// Own profile document WITH metadata, so the app can tell when the server
  /// has really saved it (hasPendingWrites == false).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> myProfileDoc() =>
      _fs.collection('profiles').doc(uid).snapshots(includeMetadataChanges: true);

  static Stream<List<Profile>> profiles() => _fs
      .collection('profiles')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) => s.docs.map((d) => Profile.fromDoc(d)).toList());

  static Stream<QuerySnapshot<Map<String, dynamic>>> allEntries() => _fs
      .collection('entries')
      .where('groupId', isEqualTo: groupId)
      .snapshots(includeMetadataChanges: true);

  static Stream<QuerySnapshot<Map<String, dynamic>>> entriesForUser(String id) => _fs
      .collection('entries')
      .where('groupId', isEqualTo: groupId)
      .where('uid', isEqualTo: id)
      .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> entriesForTitle(
          TitleInfo info) =>
      _fs
          .collection('entries')
          .where('groupId', isEqualTo: groupId)
          .where('mediaType', isEqualTo: info.mediaType)
          .where('tmdbId', isEqualTo: info.tmdbId)
          .snapshots();

  static List<Entry> entriesFrom(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Entry.fromDoc(d)).toList();

  // Writes are saved on the phone first and sent when online. If the phone is
  // offline the commit does not finish, so we stop waiting after 3 seconds.
  static Future<void> _quick(Future<void> f) =>
      f.timeout(const Duration(seconds: 3), onTimeout: () {});

  static Future<void> saveEntry(Entry e,
      {required bool pin, required bool wasPinned}) {
    final batch = _fs.batch();
    batch.set(_fs.collection('entries').doc(e.id), {
      ...e.toMap(),
      'groupId': groupId,
    });
    final pRef = _fs.collection('profiles').doc(e.uid);
    if (pin) {
      // Only one "last watched" at a time: this replaces the old one.
      // The old show keeps its real list (watching / watched / dropped).
      batch.update(pRef, {'lastWatched': e.info.toMap()});
    } else if (wasPinned) {
      batch.update(pRef, {'lastWatched': FieldValue.delete()});
    }
    return _quick(batch.commit());
  }

  static Future<void> deleteEntry(Entry e, {required bool wasPinned}) {
    final batch = _fs.batch();
    batch.delete(_fs.collection('entries').doc(e.id));
    if (wasPinned) {
      batch.update(_fs.collection('profiles').doc(e.uid),
          {'lastWatched': FieldValue.delete()});
    }
    return _quick(batch.commit());
  }

  static Future<void> updateProfile({
    required String name,
    required int? age,
    required String favShow,
    required String avatar,
  }) {
    return _quick(_fs.collection('profiles').doc(uid).update({
      'name': name,
      'age': age ?? FieldValue.delete(),
      'favShow': favShow,
      'avatar': avatar,
    }));
  }
}

class Tmdb {
  static const _key = String.fromEnvironment('TMDB_KEY');
  static bool get hasKey => _key.isNotEmpty;
  static Map<int, String>? _genres;

  static Future<Map<int, String>> _genreMap() async {
    if (_genres != null) return _genres!;
    final map = <int, String>{};
    for (final type in ['movie', 'tv']) {
      final uri = Uri.https('api.themoviedb.org', '/3/genre/$type/list',
          {'api_key': _key, 'language': 'en-US'});
      final r = await http.get(uri).timeout(const Duration(seconds: 12));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map<String, dynamic>)['genres'] as List;
        for (final g in list) {
          map[(g['id'] as num).toInt()] = g['name'] as String;
        }
      }
    }
    if (map.isNotEmpty) _genres = map;
    return map;
  }

  static Future<List<TitleInfo>> search(String query) async {
    final uri = Uri.https('api.themoviedb.org', '/3/search/multi', {
      'api_key': _key,
      'query': query,
      'language': 'en-US',
      'include_adult': 'false',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('TMDB error ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final genres = await _genreMap();
    final out = <TitleInfo>[];
    for (final raw in (data['results'] as List)) {
      final m = raw as Map<String, dynamic>;
      final type = m['media_type'];
      if (type != 'movie' && type != 'tv') continue;
      final date = ((m['release_date'] ?? m['first_air_date']) as String?) ?? '';
      out.add(TitleInfo(
        mediaType: type as String,
        tmdbId: (m['id'] as num).toInt(),
        title: ((m['title'] ?? m['name']) as String?) ?? '',
        posterPath: m['poster_path'] as String?,
        overview: (m['overview'] as String?) ?? '',
        genres: ((m['genre_ids'] as List?) ?? const [])
            .map((id) => genres[(id as num).toInt()])
            .whereType<String>()
            .toList(),
        year: date.length >= 4 ? date.substring(0, 4) : '',
      ));
    }
    return out;
  }
}
