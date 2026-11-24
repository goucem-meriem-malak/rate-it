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
  Color get page => isDark ? const Color(0xFF0B0A0E) : const Color(0xFFFFF7FB);
  Color get muted => isDark ? const Color(0xFF9B9BA7) : const Color(0xFF737380);
  Color get hairline => isDark ? const Color(0xFF2B2B32) : const Color(0xFFEAEAEE);
  Color get fieldFill => isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1E6EC);
  Color get pinkSoft => isDark ? const Color(0xFF3B1428) : const Color(0xFFFDE7F1);
  // Glass: translucent fill, bright edge, soft pink glow.
  Color get glassFill => isDark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF);
  Color get glassBorder => isDark ? const Color(0x26FFFFFF) : const Color(0xFFFFFFFF);
  Color get glassShadow => isDark ? const Color(0x33000000) : const Color(0x1AEC008C);
  Color get pinkGlass => isDark ? const Color(0x40EC008C) : const Color(0x26EC008C);
}

/// Rounded glass text-field look. Colors come from the current theme.
InputDecoration fieldDec(BuildContext context,
    {String? label, String? hint, Widget? prefix, Widget? suffix}) {
  final edge = context.isDark ? const Color(0x26FFFFFF) : const Color(0x33EC008C);
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: context.glassFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: b(edge, 1),
    enabledBorder: b(edge, 1),
    focusedBorder: b(brand, 1.5),
  );
}

ThemeData buildTheme(Locale locale, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? const Color(0xFF0B0A0E) : const Color(0xFFFFF7FB);
  final ink = dark ? const Color(0xFFF3F3F6) : const Color(0xFF111111);
  final field = dark ? const Color(0xFF1E1E24) : const Color(0xFFF1E6EC);
  final line = dark ? const Color(0xFF2B2B32) : const Color(0xFFEAEAEE);
  final soft = dark ? const Color(0xFF3B1428) : const Color(0xFFFDE7F1);
  final glass = dark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF);
  final glassLine = dark ? const Color(0x26FFFFFF) : const Color(0xFFFFFFFF);
  final pinkGlass = dark ? const Color(0x40EC008C) : const Color(0x26EC008C);
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
      backgroundColor: Colors.transparent,
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
        elevation: 6,
        shadowColor: const Color(0x66EC008C),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: glass,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: glassLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
      backgroundColor: glass,
      selectedColor: pinkGlass,
      side: BorderSide(color: glassLine),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: ink),
      checkmarkColor: brand,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: glass,
        selectedBackgroundColor: pinkGlass,
        foregroundColor: ink,
        selectedForegroundColor: ink,
        side: BorderSide(color: glassLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
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
