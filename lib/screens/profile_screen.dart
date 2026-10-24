import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

const _avatars = ['🎬', '🍿', '📺', '🎭', '🦊', '🐼', '🐱', '🦁', '🌙', '⭐', '👾', '🧠'];

class ProfileScreen extends StatelessWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  bool get _isMe => uid == Db.uid;

  Future<void> _edit(BuildContext context, Profile p) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: p),
    );
    if (result == null) return;
    await Db.updateProfile(
      name: result['name'] as String,
      age: result['age'] as int?,
      favShow: result['favShow'] as String,
      avatar: result['avatar'] as String,
    );
  }

  Widget _count(BuildContext context, String number, String label) => Expanded(
        child: Column(
          children: [
            Text(number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.muted)),
          ],
        ),
      );

  Widget _line(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$label  ', style: TextStyle(color: context.muted)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ])),
      );

  @override
  Widget build(BuildContext context) {
    return UserDataBuilder(
      uid: uid,
      builder: (context, p, entries) {
        if (p == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }
        final watched = entries.where((e) => e.list == 'watched').toList();
        final watchingCount = entries.where((e) => e.list == 'watching').length;
        final droppedCount = entries.where((e) => e.list == 'dropped').length;
        Entry? top;
        for (final e in watched) {
          if (e.overall > 0 && (top == null || e.overall > top.overall)) top = e;
        }
        final genreCount = <String, int>{};
        for (final e in watched) {
          for (final g in e.info.genres) {
            genreCount[g] = (genreCount[g] ?? 0) + 1;
          }
        }
        var topGenre = '-';
        var best = 0;
        genreCount.forEach((g, c) {
          if (c > best) {
            best = c;
            topGenre = g;
          }
        });
        final isAr = Localizations.localeOf(context).languageCode == 'ar';

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              if (_isMe)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: t(context, 'edit_profile'),
                  onPressed: () => _edit(context, p),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    AvatarCircle(emoji: p.avatar, radius: 40),
                    const SizedBox(width: 12),
                    _count(context, '${watched.length}', t(context, 'watched')),
                    _count(context, '$watchingCount', t(context, 'watching')),
                    _count(context, '$droppedCount', t(context, 'dropped')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (p.age != null) _line(context, t(context, 'age'), '${p.age}'),
                    _line(context, t(context, 'fav_show'), p.favShow.isEmpty ? '-' : p.favShow),
                    _line(context, t(context, 'top_rated'), top?.info.title ?? '-'),
                    _line(context, t(context, 'top_genre'), topGenre),
                  ],
                ),
              ),
              if (_isMe && p.groupId.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: context.pinkSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t(context, 'group_code'),
                                style: TextStyle(fontSize: 12, color: context.muted)),
                            Text(p.groupId,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4)),
                            const SizedBox(height: 2),
                            Text(t(context, 'share_code_hint'),
                                style: TextStyle(fontSize: 12, color: context.muted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: p.groupId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t(context, 'copied'))));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              ProfileLists(profile: p, entries: entries),
              if (_isMe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(t(context, 'appearance'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable: appThemeMode,
                          builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                  value: ThemeMode.system,
                                  label: Text(t(context, 'theme_system'))),
                              ButtonSegment(
                                  value: ThemeMode.light,
                                  label: Text(t(context, 'theme_light'))),
                              ButtonSegment(
                                  value: ThemeMode.dark,
                                  label: Text(t(context, 'theme_dark'))),
                            ],
                            selected: {mode},
                            onSelectionChanged: (s) => setThemeMode(s.first),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(t(context, 'language'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'en', label: Text('English')),
                            ButtonSegment(value: 'ar', label: Text('العربية')),
                          ],
                          selected: {isAr ? 'ar' : 'en'},
                          onSelectionChanged: (s) => setAppLanguage(s.first),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: Text(t(context, 'logout')),
                      ),
                      const SizedBox(height: 20),
                      Text(t(context, 'tmdb_notice'),
                          style: TextStyle(fontSize: 11, color: context.muted)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final Profile profile;
  const _EditProfileDialog({required this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _age = TextEditingController(text: widget.profile.age?.toString() ?? '');
  late final _fav = TextEditingController(text: widget.profile.favShow);
  late String _avatar = widget.profile.avatar;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _fav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      surfaceTintColor: Colors.transparent,
      title: Text(t(context, 'edit_profile')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in _avatars)
                  GestureDetector(
                    onTap: () => setState(() => _avatar = a),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: a == _avatar ? brand : context.pinkSoft,
                      child: Text(a, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: fieldDec(label: t(context, 'name'))),
            const SizedBox(height: 10),
            TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: fieldDec(label: t(context, 'age'))),
            const SizedBox(height: 10),
            TextField(
                controller: _fav,
                decoration: fieldDec(label: t(context, 'fav_show'))),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(context, 'cancel'))),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, {
              'name': name,
              'age': int.tryParse(_age.text.trim()),
              'favShow': _fav.text.trim(),
              'avatar': _avatar,
            });
          },
          child: Text(t(context, 'save')),
        ),
      ],
    );
  }
}
