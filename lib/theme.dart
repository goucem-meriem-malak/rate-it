import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const brand = Color(0xFFEC008C); // pink from the app icon
const gold = brand; // star color (name kept so other files keep working)

/// Light, dark, or follow the phone.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

Future<void> setThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme', mode.name);
}

ThemeMode themeModeFromName(String? name) => ThemeMode.values
    .firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

/// Colors that change between light and dark. Use as context.muted, etc.
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get page => Theme.of(this).scaffoldBackgroundColor;
  Color get muted => isDark ? const Color(0xFF9B9BA7) : const Color(0xFF737380);
  Color get hairline => isDark ? const Color(0xFF2B2B32) : const Color(0xFFEAEAEE);
  Color get fieldFill => isDark ? const Color(0xFF1E1E24) : const Color(0xFFF4F4F7);
  Color get pinkSoft => isDark ? const Color(0xFF3B1428) : const Color(0xFFFDE7F1);
}

/// Rounded text-field look (like Instagram). The fill color comes from the theme.
InputDecoration fieldDec({String? label, String? hint, Widget? prefix}) {
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: c == Colors.transparent ? BorderSide.none : BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: b(Colors.transparent, 0),
    enabledBorder: b(Colors.transparent, 0),
    focusedBorder: b(brand, 1.5),
  );
}

ThemeData buildTheme(Locale locale, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? const Color(0xFF0E0E11) : Colors.white;
  final ink = dark ? const Color(0xFFF3F3F6) : const Color(0xFF111111);
  final field = dark ? const Color(0xFF1E1E24) : const Color(0xFFF4F4F7);
  final line = dark ? const Color(0xFF2B2B32) : const Color(0xFFEAEAEE);
  final soft = dark ? const Color(0xFF3B1428) : const Color(0xFFFDE7F1);
  final mutedColor = dark ? const Color(0xFF9B9BA7) : const Color(0xFF737380);

  final scheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: brightness,
  ).copyWith(
    primary: brand,
    onPrimary: Colors.white,
    surface: bg,
    onSurface: ink,
    surfaceContainerHighest: field,
    surfaceContainerHigh: dark ? const Color(0xFF1A1A1F) : Colors.white,
    secondaryContainer: soft,
    onSecondaryContainer: ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    dividerColor: line,
  );
  final isAr = locale.languageCode == 'ar';
  final textTheme = (isAr
          ? GoogleFonts.cairoTextTheme(base.textTheme)
          : GoogleFonts.interTextTheme(base.textTheme))
      .apply(bodyColor: ink, displayColor: ink);

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: ink,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800, color: ink, fontSize: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brand,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: field,
      selectedColor: soft,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: ink),
      checkmarkColor: brand,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 58,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
        (states) => IconThemeData(
          size: 28,
          color: states.contains(WidgetState.selected) ? ink : mutedColor,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
  );
}
