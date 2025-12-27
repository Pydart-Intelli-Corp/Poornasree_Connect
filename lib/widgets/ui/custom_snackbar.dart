import 'package:flutter/material.dart';
import 'flower_spinner.dart';

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    String? submessage,
    bool isLoading = false,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 4),
    double? progress,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320, minWidth: 280),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isError
                    ? Colors.red.withOpacity(0.3)
                    : isSuccess
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isLoading)
                      const FlowerSpinner(size: 20)
                    else if (isError)
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      )
                    else if (isSuccess)
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade600,
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isError
                                      ? Colors.red.shade700
                                      : isSuccess
                                          ? Colors.green.shade700
                                          : null,
                                ),
                          ),
                          if (submessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              submessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static void showLoading(
    BuildContext context, {
    required String message,
    String submessage = 'Please wait...',
    double? progress,
  }) {
    show(
      context,
      message: message,
      submessage: submessage,
      isLoading: true,
      progress: progress,
      duration: const Duration(minutes: 5), // Long duration for loading
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? submessage,
  }) {
    show(
      context,
      message: message,
      submessage: submessage,
      isError: true,
      duration: const Duration(seconds: 6),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? submessage,
  }) {
    show(
      context,
      message: message,
      submessage: submessage,
      isSuccess: true,
      duration: const Duration(seconds: 4),
    );
  }
}