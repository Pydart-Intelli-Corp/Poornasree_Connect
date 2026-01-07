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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title ?? context.tr('exit_app'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message ?? context.tr('exit_app_message'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: context.borderColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelText ?? context.tr('cancel'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmText ?? context.tr('exit'),
                      style: const TextStyle(
                        fontSize: 14,
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
