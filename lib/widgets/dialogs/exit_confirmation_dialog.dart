import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/utils.dart';

/// Reusable exit confirmation dialog
/// Shows a warning before exiting the app
class ExitConfirmationDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;

  const ExitConfirmationDialog({
    super.key,
    this.title,
    this.message,
    this.confirmText,
    this.cancelText,
  });

  /// Show the exit confirmation dialog
  /// Returns true if user confirmed exit, false otherwise
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExitConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(SizeConfig.spaceRegular),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                size: SizeConfig.iconSizeHuge,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: SizeConfig.spaceRegular),

            // Title
            Text(
              title ?? context.tr('exit_app'),
              style: TextStyle(
                fontSize: SizeConfig.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.spaceMedium),

            // Message
            Text(
              message ?? context.tr('exit_app_message'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeRegular,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            SizedBox(height: SizeConfig.spaceLarge),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.spaceMedium,
                      ),
                      side: BorderSide(color: context.borderColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                      ),
                    ),
                    child: Text(
                      cancelText ?? context.tr('cancel'),
                      style: TextStyle(
                        fontSize: SizeConfig.fontSizeRegular,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.spaceMedium),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.spaceMedium,
                      ),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                      ),
                    ),
                    child: Text(
                      confirmText ?? context.tr('exit'),
                      style: TextStyle(
                        fontSize: SizeConfig.fontSizeRegular,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
