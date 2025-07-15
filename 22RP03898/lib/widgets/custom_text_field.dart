import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Professional custom text field widget with various styles and validation
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool expands;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double borderWidth;
  final Color? fillColor;
  final bool filled;
  final bool showCursor;
  final String? counterText;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.expands = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical = TextAlignVertical.center,
    this.contentPadding,
    this.height,
    this.borderRadius = 12.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderWidth = 1.5,
    this.fillColor,
    this.filled = true,
    this.showCursor = true,
    this.counterText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
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

  void _onChanged(String value) {
    setState(() {
      _hasError = false;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _hasError
                  ? AppColors.error
                  : (_isFocused ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (_hasError ? AppColors.error : AppColors.primary)
                          .withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            validator: (value) {
              final error = widget.validator?.call(value);
              setState(() {
                _hasError = error != null;
              });
              return error;
            },
            onChanged: _onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            expands: widget.expands,
            textAlign: widget.textAlign,
            textAlignVertical: widget.textAlignVertical,
            showCursor: widget.showCursor,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              helperText: widget.helperText,
              helperStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              errorText: widget.errorText,
              errorStyle: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _getIconColor(),
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              contentPadding: widget.contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: widget.height != null ? 0 : 16,
                  ),
              filled: widget.filled,
              fillColor: _getFillColor(),
              border: _getBorder(),
              enabledBorder: _getBorder(),
              focusedBorder: _getFocusedBorder(),
              errorBorder: _getErrorBorder(),
              focusedErrorBorder: _getErrorBorder(),
              disabledBorder: _getDisabledBorder(),
              counterText: widget.counterText,
              counterStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getIconColor() {
    if (!widget.enabled) {
      return AppColors.textTertiary;
    }
    if (_hasError) {
      return AppColors.error;
    }
    if (_isFocused) {
      return AppColors.primary;
    }
    return AppColors.textSecondary;
  }

  Color _getFillColor() {
    if (!widget.enabled) {
      return AppColors.borderLight;
    }
    if (_hasError) {
      return AppColors.error.withValues(alpha: 0.05 * 255);
    }
    if (_isFocused) {
      return AppColors.primary.withValues(alpha: 0.05 * 255);
    }
    return widget.fillColor ?? AppColors.surface;
  }

  OutlineInputBorder _getBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.borderColor ?? AppColors.border,
        width: widget.borderWidth,
      ),
    );
  }

  OutlineInputBorder _getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.focusedBorderColor ?? AppColors.primary,
        width: widget.borderWidth + 0.5,
      ),
    );
  }

  OutlineInputBorder _getErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.errorBorderColor ?? AppColors.error,
        width: widget.borderWidth + 0.5,
      ),
    );
  }

  OutlineInputBorder _getDisabledBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: AppColors.border,
        width: widget.borderWidth,
      ),
    );
  }
}

/// Email text field with validation
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;

  const EmailTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText ?? 'Email Address',
      hintText: hintText ?? 'Enter your email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
      enabled: enabled,
    );
  }
}

/// Password text field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;

  const PasswordTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      labelText: widget.labelText ?? 'Password',
      hintText: widget.hintText ?? 'Enter your password',
      prefixIcon: Icons.lock_outlined,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
    );
  }
}

/// Phone number text field with formatting
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;

  const PhoneTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText ?? 'Phone Number',
      hintText: hintText ?? 'Enter your phone number',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
      enabled: enabled,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

/// Search text field with search icon
class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: Icons.search,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      borderRadius: 25,
      filled: true,
      fillColor: AppColors.borderLight,
    );
  }
}
