import 'package:flutter/material.dart';

/// Paleta de cores oficial do Zoeira Car.
/// Tema escuro com laranja vibrante como cor primária.
class AppColors {
  AppColors._();

  // ── Primária ──
  static const Color primary = Color(0xFFFF6B00); // Laranja Zoeira
  static const Color primaryLight = Color(0xFFFF8C3A);
  static const Color primaryDark = Color(0xFFCC5500);

  // ── Fundo ──
  static const Color background = Color(0xFF0F0F0F); // Preto quase total
  static const Color surface = Color(0xFF1A1A1A); // Superfície elevada
  static const Color cardBackground = Color(0xFF1E1E1E);

  // ── Bordas ──
  static const Color cardBorder = Color(0xFF2A2A2A);

  // ── Texto ──
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textDisabled = Color(0xFF4A4A4A);

  // ── Veredito ──
  static const Color verdictGreen = Color(0xFF22C55E); // Recomenda
  static const Color verdictYellow = Color(0xFFF59E0B); // Ok se barato
  static const Color verdictRed = Color(0xFFEF4444); // Corre!
  static const Color verdictPurple = Color(0xFF8B5CF6); // Exclusivo

  // ── Shimmer ──
  static const Color shimmerBase = Color(0xFF252525);
  static const Color shimmerHighlight = Color(0xFF303030);
}
