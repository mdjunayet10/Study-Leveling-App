import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static final appTitle = GoogleFonts.cinzelDecorative(
    textStyle: const TextStyle(
      fontSize: 37,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
      height: 1.02,
      color: AppColors.textPrimary,
    ),
  );

  static const title = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static const header = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  static const subheader = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const small = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const timer = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static const timerLarge = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 50,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static const label = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );
}
