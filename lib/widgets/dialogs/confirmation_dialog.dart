import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../l10n/app_localizations.dart';

/// Reusable confirmation dialog with Material Design 3 styling
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SizeConfig.spaceRegular)),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: EdgeInsets.all(SizeConfig.spaceSmall + 2),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: SizeConfig.iconSizeHuge,
                  color: iconColor ?? AppTheme.primaryGreen,
                ),
              ),
              SizedBox(height: SizeConfig.spaceRegular),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.spaceSmall + 2),
            Text(
              message,
              style: TextStyle(fontSize: SizeConfig.fontSizeRegular, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.spaceLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: AppTheme.borderDark),
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.spaceMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                      ),
                    ),
                    child: Text(cancelText ?? AppLocalizations().tr('cancel')),
                  ),
                ),
                SizedBox(width: SizeConfig.spaceSmall + 2),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? Colors.red.shade600
                          : AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.spaceMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                      ),
                    ),
                    child: Text(confirmText ?? AppLocalizations().tr('confirm')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}