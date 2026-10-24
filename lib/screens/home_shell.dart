import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _me = Db.myProfileDoc();
  bool _ready = false; // becomes true once the server has confirmed the profile

  Widget _centered(Widget child) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: Text(t(context, 'logout')),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _me,
      builder: (context, snap) {
        final d = snap.data;
        if (!_ready) {
          // Right after sign-up the profile exists on the phone before the server
          // has saved it. Reading data now would be refused, so we wait for the
          // server (hasPendingWrites == false).
          if (snap.hasError || d == null || !d.exists || d.metadata.hasPendingWrites) {
            return const SplashLoading(animate: false);
          }
          _ready = true;
        } else if (d == null || !d.exists) {
          return const SplashLoading(animate: false);
        }
        final p = Profile.fromDoc(d);
        if (p.groupId.isEmpty) {
          return _centered(Text(t(context, 'old_account'), textAlign: TextAlign.center));
        }
        Db.groupId = p.groupId; // must be set before the screens below read data
        final uid = Db.uid;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              const FeedScreen(),
              const SearchScreen(),
              ProfileScreen(uid: uid),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.hairline)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: t(context, 'feed')),
                NavigationDestination(
                    icon: const Icon(Icons.search_rounded),
                    selectedIcon: const Icon(Icons.search_rounded),
                    label: t(context, 'search')),
                NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: t(context, 'profile')),
              ],
            ),
          ),
        );
      },
    );
  }
}
