import 'package:flutter/material.dart';

/// Design Tokens untuk Tema:
/// "Modern Institutional White — Oceanic Blue, Teal & Amber"
class AppColors {
  // --- Token Desain Resmi (Sesuai Spesifikasi PRD) ---
  static const Color colorBg = Color(0xFFF5F8FC);
  static const Color colorSurface = Color(0xFFFFFFFF);
  static const Color colorBorder = Color(0xFFE8EEF5);
  static const Color colorPrimary = Color(0xFF1769D2);
  static const Color colorPrimaryHover = Color(0xFF1258B5);
  static const Color colorPrimarySoft = Color(0xFFE8F2FF);
  static const Color colorSecondary = Color(0xFF10B8B5);
  static const Color colorSecondaryStrong = Color(0xFF087F83);
  static const Color colorSecondarySoft = Color(0xFFE6FAF9);
  static const Color colorAccent = Color(0xFFFFAB38);
  static const Color colorAccentWarm = Color(0xFFF07832);
  static const Color colorAccentSoft = Color(0xFFFFF7ED);
  static const Color colorText = Color(0xFF1D2939);
  static const Color colorTextMuted = Color(0xFF66758A);
  static const Color colorTextInverse = Color(0xFFFFFFFF);

  // --- Aliases & Kompatibilitas Sistem Tema Lama ---
  static const Color primaryBlue = colorPrimary;
  static const Color accentBlue = Color(0xFF388BFD);
  static const Color darkBlue = Color(0xFF0F366A);
  static const Color splashBlue = colorPrimarySoft;

  // Transisi brand: elemen yang sebelumnya menggunakan primaryRed dialihkan ke Oceanic Blue
  static const Color primaryRed = colorPrimary;
  static const Color primaryRedDark = colorPrimaryHover;

  // Latar dan Permukaan
  static const Color background = colorBg;
  static const Color cardBackground = colorSurface;
  static const Color surface = colorSurface;
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color lightRedBackground = colorPrimarySoft;
  static const Color lightBlueBackground = colorPrimarySoft;

  // Borders & Pembatas
  static const Color border = colorBorder;
  static const Color borderFocused = colorPrimary;
  static const Color borderDark = Color(0xFFD0DCEB);

  // Tipografi
  static const Color textPrimary = colorText;
  static const Color textSecondary = colorTextMuted;
  static const Color textMuted = Color(0xFF98A2B3);
  static const Color textOnPrimary = colorTextInverse;

  // Neutrals (Slate scale yang diselaraskan dengan Oceanic Blue)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF0F4F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Status & Semantik Terstandarisasi
  static const Color error = Color(0xFFDC2626);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color success = Color(0xFF16A34A);
  static const Color successBackground = Color(0xFFF0FDF4);
  static const Color warning = colorAccentWarm;
  static const Color warningBackground = colorAccentSoft;
  static const Color info = colorPrimary;
  static const Color infoBackground = colorPrimarySoft;
}
