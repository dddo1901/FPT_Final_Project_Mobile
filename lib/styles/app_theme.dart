import 'package:flutter/material.dart';

/// Centralized design system (Blue Theme)
class AppTheme {
  // Core Palette
  static const Color darkBlue = Color(0xFF1E40AF);
  static const Color primary = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color ultraLightBlue = Color(0xFFE0F2FE);

  // Neutrals
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color surface = Colors.white;

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBlue, primary, lightBlue],
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, primary],
  );

  // Shadows
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(.05),
      spreadRadius: 1,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(.08),
      spreadRadius: 2,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  static const TextStyle body = TextStyle(fontSize: 14, color: textMedium);
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: .5,
    color: textMedium,
  );
  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  // Input Decoration
  static InputDecoration inputDecoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
    );
  }

  // Cards
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFF1F5F9)),
    boxShadow: softShadow,
  );

  static BoxDecoration elevatedCard() => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: mediumShadow,
  );

  // Buttons
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 3,
  );
  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary, width: 1.4),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  // Status colors
  static Color statusColor(String? status) {
    switch (status) {
      case 'PENDING':
      case 'NEW':
      case 'WAITING_PAYMENT':
        return warning;
      case 'APPROVED':
      case 'RESOLVED':
      case 'COMPLETED':
      case 'PAID':
      case 'DELIVERED':
        return success;
      case 'REJECTED':
      case 'CANCELLED':
        return danger;
      case 'IN_PROGRESS':
      case 'CONFIRMED':
      case 'DELIVERING':
        return primary;
      case 'PREPARING':
      case 'COOKING':
      case 'READY':
      case 'WAITING_FOR_SHIPPER':
        return info;
      default:
        return textMedium;
    }
  }

  static Widget buildStatusChip(String? status, {String? labelOverride}) {
    final color = statusColor(status);
    final text = labelOverride ?? status ?? 'UNKNOWN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: .5,
          color: color.darken(0.1),
        ),
      ),
    );
  }

  static Widget gradientBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(gradient: bgGradient),
      child: child,
    );
  }
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
