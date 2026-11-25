import 'package:flutter/material.dart';

import 'package:jameel/shared/styles/app_design.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onSaved,
    this.maxLines = 1,
    this.hint,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final int maxLines;
  final String? hint;
  final TextInputAction? textInputAction;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final border = context.borderColor;
    final muted = context.mutedColor;
    return TextFormField(
      controller: controller,
      validator: validator,
      onSaved: onSaved,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      style: TextStyle(fontSize: 15.5, color: context.inkColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: icon == null ? null : Icon(icon, size: 21),
        prefixIconColor: muted,
        suffixIcon: suffix,
        filled: true,
        fillColor: context.surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(border),
        enabledBorder: _border(border),
        focusedBorder: _border(AppColors.primary, 1.6),
        errorBorder: _border(AppColors.primary),
        focusedErrorBorder: _border(AppColors.primary, 1.6),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled ? AppShadows.brand : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
