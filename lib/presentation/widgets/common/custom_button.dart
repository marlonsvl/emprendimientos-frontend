import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final Widget? icon;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          textColor ?? theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : (icon ?? const SizedBox.shrink()),
              label: Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textColor ?? theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor ?? theme.colorScheme.primary,
                side: BorderSide(
                  color: backgroundColor ?? theme.colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          textColor ?? theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : (icon ?? const SizedBox.shrink()),
              label: Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textColor ?? theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? theme.colorScheme.primary,
                foregroundColor: textColor ?? theme.colorScheme.onPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}