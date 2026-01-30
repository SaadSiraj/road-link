import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../constants/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double height;
  final double width;
  final FontWeight fontWeight;
  final double fontSize;
  final bool isDisabled;
  final Color? borderColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12,
    this.height = 50,
    this.width = double.infinity,
    this.fontWeight = FontWeight.w600,
    this.fontSize = 16,
    this.isDisabled = false,
    this.borderColor,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        widget.isDisabled
            ? AppColors.border
            : (widget.backgroundColor ?? AppColors.primary);
    final Color txtColor =
        widget.isDisabled
            ? AppColors.textSecondary
            : (widget.textColor ?? AppColors.background);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border:
                widget.borderColor != null
                    ? Border.all(color: widget.borderColor!, width: 1.5)
                    : null,
            boxShadow: [
              if (!widget.isDisabled)
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(right: 8.h, left: 10),
                  child: Icon(
                    widget.icon,
                    color: txtColor,
                    size: widget.fontSize + 2,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: txtColor,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
