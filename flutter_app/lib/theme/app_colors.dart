import 'package:flutter/material.dart';

/// Deep navy fantasy palette for Study Leveling.
class AppColors {
  static const background = Color(0xFF050B1E);
  static const backgroundAlt = Color(0xFF071226);
  static const backgroundDeep = Color(0xFF020817);

  static const primary = Color(0xFF2F80ED);
  static const primaryDark = Color(0xFF0B1733);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryGlow = Color(0xFF2563EB);

  static const secondary = Color(0xFF22D3EE);
  static const accent = Color(0xFF22D3EE);
  static const accentBright = Color(0xFF67E8F9);
  static const accentSoft = Color(0xFF38BDF8);

  static const card = Color(0xFF0B1733);
  static const cardElevated = Color(0xFF102044);
  static const cardMuted = Color(0xFF07152B);
  static const divider = Color(0xFF243B63);
  static const border = Color(0xFF243B63);

  static const textPrimary = Color(0xFFEAF2FF);
  static const textSecondary = Color(0xFFA9B8D8);
  static const textMuted = Color(0xFF7F93BD);

  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFFBBF24);
  static const info = Color(0xFF60A5FA);

  static const xp = Color(0xFFFACC15);
  static const coin = Color(0xFFFFB547);
  static const level = Color(0xFF67E8F9);
  static const mana = Color(0xFFA78BFA);

  static const easy = success;
  static const medium = warning;
  static const hard = error;

  static const gold = Color(0xFFFFD166);
  static const silver = Color(0xFFD7DEE8);
  static const bronze = Color(0xFFD08A4E);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      backgroundDeep,
      background,
      Color(0xFF061A33),
      backgroundAlt,
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[cardElevated, card, cardMuted],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryLight, primary, primaryGlow],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[primary, accent, secondary],
  );
}
