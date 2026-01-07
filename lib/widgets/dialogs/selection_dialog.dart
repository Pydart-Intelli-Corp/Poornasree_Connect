import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/utils.dart';

/// Reusable selection dialog with radio buttons
class SelectionDialog<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<SelectionItem<T>> items;
  final T? selectedValue;
  final IconData? icon;

  const SelectionDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.selectedValue,
    this.icon,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<SelectionItem<T>> items,
    T? selectedValue,
    IconData? icon,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SelectionDialog<T>(
        title: title,
        subtitle: subtitle,
        items: items,
        selectedValue: selectedValue,
        icon: icon,
      ),
    );
  }

  @override
  State<SelectionDialog<T>> createState() => _SelectionDialogState<T>();
}

class _SelectionDialogState<T> extends State<SelectionDialog<T>> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.icon != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.items.map((item) {
                    return RadioListTile<T>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          if (item.icon != null) ...[
                            Icon(
                              item.icon,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedValue == item.value
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: item.value,
                      groupValue: _selectedValue,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (value) {
                        setState(() => _selectedValue = value);
                        Navigator.pop(context, value);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(AppLocalizations().tr('cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selection item for the dialog
class SelectionItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SelectionItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}
