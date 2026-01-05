import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class ReusableTextField extends StatefulWidget {
  final String? label;

  final String? hintText;

  final TextEditingController? controller;

  final TextInputType keyboardType;

  final bool obscureText;

  final IconData? prefixIcon;

  final IconData? suffixIcon;

  final VoidCallback? onSuffixTap;

  final String? Function(String?)? validator;

  final TextInputAction textInputAction;

  final void Function(String)? onChanged;

  final void Function(String)? onSubmitted;

  final FocusNode? focusNode;

  final String? helperText;

  final int? maxLength;

  final int? maxLines;

  final int? minLines;

  final bool enabled;

  final bool readOnly;

  final bool showClearButton;

  final bool autoTogglePasswordVisibility;

  final bool required;

  final double? borderRadius;

  final Color? fillColor;

  final Color? textColor;

  final Color? prefixIconColor;

  final Color? suffixIconColor;

  const ReusableTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.helperText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.showClearButton = true,
    this.autoTogglePasswordVisibility = true,
    this.required = false,
    this.borderRadius,
    this.fillColor,
    this.textColor,
    this.prefixIconColor,
    this.suffixIconColor,
  }) : assert(
         label != null || hintText != null,
         'Either label or hintText must be provided',
       );

  @override
  State<ReusableTextField> createState() => _ReusableTextFieldState();
}

class _ReusableTextFieldState extends State<ReusableTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _obscureText = false;
  bool _isFocused = false;
  bool _hasText = false;

  bool get _isPasswordField => widget.obscureText;
  bool get _isControlled => widget.controller != null;
  bool get _shouldShowPasswordToggle =>
      _isPasswordField &&
      widget.autoTogglePasswordVisibility &&
      widget.enabled &&
      !widget.readOnly &&
      widget.suffixIcon == null;

  bool get _shouldShowClearButton =>
      widget.showClearButton &&
      _hasText &&
      widget.enabled &&
      !widget.readOnly &&
      widget.suffixIcon == null &&
      !_isPasswordField;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.obscureText;
    _hasText = _controller.text.isNotEmpty;

    _focusNode.addListener(_onFocusChange);

    if (!_isControlled) {
      _controller.addListener(_onTextChange);
    } else if (widget.controller != null) {
      widget.controller!.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (!_isControlled) {
      _controller.removeListener(_onTextChange);
      _controller.dispose();
    } else if (widget.controller != null) {
      widget.controller!.removeListener(_onTextChange);
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    setState(() {
      _hasText =
          (_isControlled ? widget.controller?.text : _controller.text)
              ?.isNotEmpty ??
          false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _clearText() {
    if (_isControlled) {
      widget.controller?.clear();
    } else {
      _controller.clear();
    }
    widget.onChanged?.call('');
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon == null) return null;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8),
      child: Icon(
        widget.prefixIcon,
        color:
            widget.prefixIconColor ??
            (_isFocused ? AppColors.primary : AppColors.textSecondary),
        size: 22,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return GestureDetector(
        onTap: widget.onSuffixTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            widget.suffixIcon,
            color: widget.suffixIconColor ?? AppColors.textSecondary,
            size: 22,
          ),
        ),
      );
    }

    if (_shouldShowPasswordToggle) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _isFocused ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
        onPressed: _togglePasswordVisibility,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        splashRadius: 20,
      );
    }

    if (_shouldShowClearButton) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          icon: const Icon(
            Icons.clear_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: _clearText,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? 20.0;
    final fillColor = widget.fillColor ?? AppColors.cardBackground;
    final textColor = widget.textColor ?? AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow:
                _isFocused
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                    : [],
          ),
          child: TextFormField(
            controller: _isControlled ? widget.controller : _controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: _isPasswordField ? _obscureText : false,
            validator: widget.validator,
            onChanged: (value) {
              _onTextChange();
              widget.onChanged?.call(value);
            },
            onFieldSubmitted: widget.onSubmitted,
            onTap:
                widget.readOnly
                    ? () {
                      _focusNode.unfocus();
                    }
                    : null,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              fontSize: 15,
              color: widget.enabled ? textColor : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              labelText:
                  widget.label != null
                      ? widget.required
                          ? '${widget.label} *'
                          : widget.label
                      : null,
              labelStyle: TextStyle(
                color: _isFocused ? AppColors.primary : AppColors.textSecondary,
                fontSize: 15,
              ),
              floatingLabelStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              floatingLabelBehavior:
                  widget.label != null
                      ? FloatingLabelBehavior.auto
                      : FloatingLabelBehavior.never,
              helperText: widget.helperText,
              helperMaxLines: 2,
              helperStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
              counterText: widget.maxLength != null ? null : null,
              counterStyle:
                  widget.maxLength != null
                      ? TextStyle(color: AppColors.textSecondary, fontSize: 11)
                      : null,
              filled: true,
              fillColor:
                  widget.enabled ? fillColor : fillColor.withOpacity(0.5),
              prefixIcon: _buildPrefixIcon(),
              suffixIcon: _buildSuffixIcon(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 12 : 16,
                vertical:
                    widget.maxLines != null && widget.maxLines! > 1 ? 16 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              errorMaxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}
