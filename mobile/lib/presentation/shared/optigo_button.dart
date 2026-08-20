import 'package:flutter/material.dart';
import '../../app/theme.dart';

class OptigoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const OptigoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
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

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
