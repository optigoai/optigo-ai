import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OptigoPillVariant {
  success, // Green: Good / Optimal / Replied / Top 3 / Growth
  warning, // Amber: Attention / Moderate / Pending / Medium
  error,   // Red: Urgent / Critical / Declining / Unanswered
  neutral, // Slate/Blue-Gray: Info / Standard / Category
}

/// Unified OptigoPill component
/// Strict 4-semantic color system used identically across the entire application.
class OptigoPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final OptigoPillVariant variant;
  final VoidCallback? onTap;
  final bool isSelected;
  final double fontSize;

  const OptigoPill({
    super.key,
    required this.label,
    this.icon,
    this.variant = OptigoPillVariant.neutral,
    this.onTap,
    this.isSelected = false,
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case OptigoPillVariant.success:
        bg = isSelected ? const Color(0xFF10B981) : const Color(0xFFECFDF5);
        border = isSelected ? const Color(0xFF059669) : const Color(0xFFA7F3D0);
        text = isSelected ? Colors.white : const Color(0xFF059669);
        break;
      case OptigoPillVariant.warning:
        bg = isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFFFBEB);
        border = isSelected ? const Color(0xFFD97706) : const Color(0xFFFDE68A);
        text = isSelected ? Colors.white : const Color(0xFFD97706);
        break;
      case OptigoPillVariant.error:
        bg = isSelected ? const Color(0xFFEF4444) : const Color(0xFFFEF2F2);
        border = isSelected ? const Color(0xFFDC2626) : const Color(0xFFFECACA);
        text = isSelected ? Colors.white : const Color(0xFFDC2626);
        break;
      case OptigoPillVariant.neutral:
        bg = isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9);
        border = isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0);
        text = isSelected ? Colors.white : const Color(0xFF475569);
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: text,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      );
    }

    return content;
  }
}
