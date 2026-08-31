import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class OptigoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool useGradient;
  final IconData? icon;
  final double? height;

  const OptigoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.useGradient = false,
    this.icon,
    this.height,
  });

  void _handleTap() {
    if (isLoading || onPressed == null) return;
    HapticFeedback.lightImpact();
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 52.0;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: effectiveHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : _handleTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: OptigoTheme.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
            ),
          ),
          child: _buildChild(context, OptigoTheme.primary),
        ),
      );
    }

    if (useGradient) {
      return Container(
        width: double.infinity,
        height: effectiveHeight,
        decoration: BoxDecoration(
          gradient: OptigoTheme.signatureBrandGradient,
          borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color: OptigoTheme.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : _handleTap,
            borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
            child: Center(
              child: _buildChild(context, Colors.white),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: OptigoTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
          ),
        ),
        child: _buildChild(context, Colors.white),
      ),
    );
  }

  Widget _buildChild(BuildContext context, Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: OptigoTheme.spacingSM),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.2,
      ),
    );
  }
}
