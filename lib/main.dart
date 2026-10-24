import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Firestore keeps a local copy of data on Android by default = offline reading,
  // and writes made offline are sent automatically later.
  final prefs = await SharedPreferences.getInstance();
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  appLocale.value = Locale(prefs.getString('lang') ?? (device == 'ar' ? 'ar' : 'en'));
  appThemeMode.value = themeModeFromName(prefs.getString('theme'));
  runApp(const RateItApp());
}

class RateItApp extends StatelessWidget {
  const RateItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) => ValueListenableBuilder<Locale>(
        valueListenable: appLocale,
        builder: (context, locale, _) => MaterialApp(
          title: 'Rate It',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(locale, Brightness.light),
          darkTheme: buildTheme(locale, Brightness.dark),
          themeMode: mode,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Shows the logo splash for at least 1.6 seconds, then fades into
/// the login screen or the app.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _minTimeDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _minTimeDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final ready = _minTimeDone && snap.connectionState != ConnectionState.waiting;
        final Widget child = !ready
            ? const SplashLoading(key: ValueKey('splash'))
            : snap.data == null
                ? const AuthScreen(key: ValueKey('auth'))
                : const HomeShell(key: ValueKey('home'));
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: child,
        );
      },
    );
  }
}
