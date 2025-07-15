import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Professional custom button widget with various styles and states
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final IconData? icon;
  final double? iconSize;
  final bool isOutlined;
  final Color? borderColor;
  final double? borderWidth;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.padding,
    this.textStyle,
    this.icon,
    this.iconSize,
    this.isOutlined = false,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDisabled ? null : gradient,
              color: isDisabled
                  ? AppColors.textTertiary
                  : (gradient == null
                      ? (backgroundColor ?? AppColors.primary)
                      : null),
              borderRadius: BorderRadius.circular(borderRadius),
              border: isOutlined
                  ? Border.all(
                      color: isDisabled
                          ? AppColors.border
                          : (borderColor ?? AppColors.primary),
                      width: borderWidth ?? 1.5,
                    )
                  : null,
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: (gradient != null
                                ? AppColors.primary
                                : backgroundColor ?? AppColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Container(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: _getTextStyle(),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize ?? 20,
            color: _getTextColor(),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: _getTextStyle(),
          ),
        ],
      );
    }

    return Text(
      text,
      style: _getTextStyle(),
    );
  }

  TextStyle _getTextStyle() {
    return textStyle ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        );
  }

  Color _getTextColor() {
    if (!isEnabled || isLoading) {
      return AppColors.textSecondary;
    }

    if (isOutlined) {
      return textColor ?? AppColors.primary;
    }

    return textColor ?? Colors.white;
  }
}

/// Primary button with gradient
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      isEnabled: isEnabled,
      gradient: AppColors.primaryGradient,
      width: width,
      height: height,
      icon: icon,
    );
  }
}

/// Secondary button with outline style
class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      isEnabled: isEnabled,
      isOutlined: true,
      backgroundColor: Colors.transparent,
      width: width,
      height: height,
      icon: icon,
    );
  }
}

/// Success button with green gradient
class SuccessButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const SuccessButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      isEnabled: isEnabled,
      gradient: AppColors.successGradient,
      width: width,
      height: height,
      icon: icon,
    );
  }
}

/// Danger button with red gradient
class DangerButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      isEnabled: isEnabled,
      gradient: AppColors.errorGradient,
      width: width,
      height: height,
      icon: icon,
    );
  }
}

/// Small button variant
class SmallButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final LinearGradient? gradient;
  final IconData? icon;

  const SmallButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      isEnabled: isEnabled,
      gradient: gradient,
      height: 40,
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      icon: icon,
      iconSize: 16,
    );
  }
}

/// Large button variant
class LargeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final LinearGradient? gradient;
  final IconData? icon;

  const LargeButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      isEnabled: isEnabled,
      gradient: gradient,
      height: 64,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      icon: icon,
      iconSize: 24,
    );
  }
}
