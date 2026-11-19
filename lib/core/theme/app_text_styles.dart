import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Luminous Atelier Typography System using Playfair Display & Plus Jakarta Sans.
class AppTextStyles {
  // Serif Editorial Tone (Playfair Display)
  static TextStyle displayLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.8,
      color: color,
    );
  }

  static TextStyle headlineLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle headlineMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle headlineSm({Color color = AppColors.onSurface}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
      color: color,
    );
  }

  // Modern Performance Sans (Plus Jakarta Sans)
  static TextStyle titleLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.33,
      letterSpacing: -0.18,
      color: color,
    );
  }

  static TextStyle titleMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.38,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle bodyLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.16,
      color: color,
    );
  }

  static TextStyle bodyMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextStyle bodySm({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.12,
      color: color,
    );
  }

  static TextStyle labelLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.28,
      letterSpacing: 0.28,
      color: color,
    );
  }

  static TextStyle labelMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.48,
      color: color,
    );
  }

  static TextStyle labelSm({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 1.4,
      letterSpacing: 0.6,
      color: color,
    );
  }

  // Price Architecture (PKR)
  static TextStyle priceLg({Color color = AppColors.primary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.4,
      color: color,
    );
  }

  static TextStyle priceMd({Color color = AppColors.primary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.33,
      letterSpacing: -0.15,
      color: color,
    );
  }
}
