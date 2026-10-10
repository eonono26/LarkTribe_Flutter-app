import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LarkTribe mobile design system — "Obsidian Atelier".
///
/// Editorial minimalism: porcelain canvas, deep obsidian ink, champagne-gold
/// accents used sparingly, hairline rules instead of shadows, Bodoni Moda
/// display serif over Inter micro-copy. Radii follow the Stitch mockups
/// (4 / 8 / 12 px, pills only for chips and status badges).
class AppColors {
  // Core
  static const ink = Color(0xFF111111);
  static const inkHover = Color(0xFF27272A);
  static const inkSoft = Color(0xFF444748);
  static const paper = Color(0xFFF9F9F9); // page canvas (surface)
  static const white = Color(0xFFFFFFFF); // card canvas
  static const subtext = Color(0xFF71717A); // warm slate
  static const outline = Color(0xFF747878);

  // Surfaces / rules
  static const surfaceLow = Color(0xFFF3F3F3); // inputs, quiet panels
  static const surface = Color(0xFFEEEEEE); // tab tracks, disabled buttons
  static const surfaceHigh = Color(0xFFE8E8E8);
  static const line = Color(0xFFE4E4E7);
  static const hairline = Color(0xFFF4F4F5);

  // Champagne gold family
  static const gold = Color(0xFFC5A880);
  static const goldDeep = Color(0xFF725B38); // eyebrow text on light
  static const goldTint = Color(0xFFFBEBD3); // peach pill / notice fill
  static const goldOnDark = Color(0xFFFEDEB2);

  // Status
  static const error = Color(0xFFBA1A1A);
  static const errorTint = Color(0xFFFFDAD6);
  static const success = Color(0xFF2F6B4A);
  static const live = Color(0xFF1B7F4B);

  // ---- Legacy aliases (kept so older widgets keep compiling) ----
  static const mist = surfaceLow;
  static const mist2 = surface;
  static const stone300 = line;
  static const stone400 = Color(0xFFB9B9BD);
  static const stone800 = Color(0xFF292929);
  static const stone900 = Color(0xFF181818);
  static const stone950 = Color(0xFF000000);
  static const accent = goldDeep;
  static const accentDark = Color(0xFF584323);
  static const accentTint = goldTint;
  static const olive = Color(0xFF65715D);
  static const oliveTint = Color(0xFFE7ECE3);
  static const signal = goldDeep;
  static const signalDark = Color(0xFF584323);
  static const flag = error;
  static const warning = Color(0xFFB7791F);

  static const deptWomen = Color(0xFF7C5540);
  static const deptMen = Color(0xFF3C4650);
  static const deptKids = Color(0xFF65715D);
  static const deptBeauty = Color(0xFF8A6873);
  static const deptMaternity = Color(0xFF8B7160);
  static const deptHome = Color(0xFF746B60);

  static Color departmentColor(String slug) {
    switch (slug) {
      case 'women':
        return deptWomen;
      case 'men':
        return deptMen;
      case 'kids':
        return deptKids;
      case 'beauty':
        return deptBeauty;
      case 'maternity':
        return deptMaternity;
      case 'home-lifestyle':
        return deptHome;
      default:
        return ink;
    }
  }
}

class AppRadii {
  static const none = 0.0;
  static const xs = 4.0; // inputs, small buttons (Tailwind `rounded`)
  static const sm = 8.0; // tab tracks, chips-in-panels (`rounded-lg`)
  static const md = 12.0; // panels (`rounded-xl`)
  static const lg = 12.0;
  static const pill = 999.0;
}

/// Shadows are almost never used — depth comes from tonal layering and
/// hairlines. These exist only for transient floating surfaces.
class AppShadows {
  static const xs = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1)),
  ];
  static const sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 30, offset: Offset(0, 8)),
  ];
  static const md = [
    BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 10)),
  ];
}

class AppText {
  /// Currency / numerals: Inter Medium with tabular figures.
  static TextStyle price(double size,
      {Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Type scale from the Obsidian Atelier spec. Bodoni Moda for editorial
/// headlines (never forced to all-caps by default), Inter for everything
/// functional. Micro-labels are always uppercase + tracked at the call site.
class AppType {
  static TextStyle display(Color c) => GoogleFonts.bodoniModa(
      fontSize: 40, fontWeight: FontWeight.w400, height: 1.2, letterSpacing: -0.8, color: c);
  static TextStyle headlineLg(Color c) => GoogleFonts.bodoniModa(
      fontSize: 32, fontWeight: FontWeight.w400, height: 1.19, letterSpacing: -0.32, color: c);
  static TextStyle headlineLgMobile(Color c) => GoogleFonts.bodoniModa(
      fontSize: 26, fontWeight: FontWeight.w400, height: 1.23, letterSpacing: -0.26, color: c);
  static TextStyle headlineMd(Color c) => GoogleFonts.bodoniModa(
      fontSize: 22, fontWeight: FontWeight.w500, height: 1.27, color: c);
  static TextStyle headlineSm(Color c) => GoogleFonts.bodoniModa(
      fontSize: 18, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.18, color: c);

  static TextStyle bodyLg(Color c) => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, height: 1.62, letterSpacing: -0.16, color: c);
  static TextStyle bodyMd(Color c) => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, height: 1.57, color: c);
  static TextStyle bodySm(Color c) => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.12, color: c);

  /// 11px / 600 / 0.14em — uppercase at the call site.
  static TextStyle labelCaps(Color c) => GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, height: 1.27, letterSpacing: 1.54, color: c);
  /// 10px / 600 / 0.18em — badges and eyebrows.
  static TextStyle labelBadge(Color c) => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 1.8, color: c);
  static TextStyle labelMdSpec(Color c) => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w500, height: 1.38, letterSpacing: 0.26, color: c);

  // ---- Legacy names (mapped onto the new scale) ----
  static TextStyle displayLg(Color c) => headlineLg(c);
  static TextStyle labelLg(Color c) => labelCaps(c);
  static TextStyle labelMd(Color c) => labelCaps(c).copyWith(fontSize: 10.5);
  static TextStyle labelSm(Color c) => labelBadge(c);
}

ThemeData buildAppTheme() {
  final bodyTheme = GoogleFonts.interTextTheme();

  OutlineInputBorder border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.goldDeep,
      onSecondary: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: Colors.white,
    ),
    fontFamily: bodyTheme.bodyMedium?.fontFamily,
    textTheme: bodyTheme.copyWith(
      headlineLarge: AppType.headlineLg(AppColors.ink),
      headlineMedium: AppType.headlineLgMobile(AppColors.ink),
      titleLarge: AppType.headlineMd(AppColors.ink),
      titleMedium: AppType.headlineSm(AppColors.ink),
      bodyLarge: AppType.bodyLg(AppColors.ink),
      bodyMedium: AppType.bodyMd(AppColors.ink),
      bodySmall: AppType.bodySm(AppColors.subtext),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: AppType.labelCaps(AppColors.ink),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.subtext,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppType.labelCaps(Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: AppType.labelCaps(AppColors.ink),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        textStyle: AppType.labelCaps(AppColors.ink),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLow,
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppColors.ink),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppType.bodyMd(AppColors.inkSoft.withOpacity(.4)),
      labelStyle: AppType.labelCaps(AppColors.subtext),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: const BorderSide(color: AppColors.hairline),
      ),
      margin: EdgeInsets.zero,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.ink,
      labelStyle: AppType.bodySm(AppColors.ink),
      secondaryLabelStyle: AppType.bodySm(Colors.white),
      shape: const StadiumBorder(),
      side: const BorderSide(color: AppColors.line),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: AppType.bodyMd(Colors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      titleTextStyle: AppType.headlineMd(AppColors.ink),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        side: const BorderSide(color: AppColors.line),
      ),
      textStyle: AppType.labelCaps(AppColors.ink),
    ),
  );
}
