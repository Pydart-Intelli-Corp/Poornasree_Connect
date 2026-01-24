import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';

/// A dialog for displaying entity details (BMC, Dairy)
class EntityDetailsDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> details;
  final String? token;
  final String? entityId;
  final String entityType;

  const EntityDetailsDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
    this.token,
    this.entityId,
    required this.entityType,
  });

  /// Static method to show the entity details dialog with loading
  static Future<void> show(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Map<String, dynamic> details,
    String? token,
  }) async {
    // Determine entity type
    final entityType = title.toLowerCase().contains('bmc') ? 'bmc' : 'dairy';
    final entityId = details['ID']?.toString();

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              Text(
                'Loading details...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    // Fetch full details from API
    Map<String, dynamic> fullDetails = details;
    if (token != null && entityId != null) {
      try {
        final response = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/external/entity/$entityType/$entityId',
          ),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final apiData = data['data'];
            fullDetails = {
              'Name': apiData['name'],
              if (entityType == 'bmc') 'BMC ID': apiData['bmc_id'],
              if (entityType == 'dairy') 'Dairy ID': apiData['dairy_id'],
              'Email': apiData['email'],
              'Location': apiData['location'],
              if (apiData['contact_phone'] != null)
                'Contact Phone': apiData['contact_phone'],
              if (entityType == 'dairy' && apiData['president_name'] != null)
                'President': apiData['president_name'],
              'Status': apiData['status']?.toString().toUpperCase(),
              if (entityType == 'bmc' && apiData['dairy_name'] != null) ...{
                'Dairy Name': apiData['dairy_name'],
                if (apiData['dairy_location'] != null)
                  'Dairy Location': apiData['dairy_location'],
                if (apiData['dairy_contact'] != null)
                  'Dairy Contact': apiData['dairy_contact'],
              },
            };
          }
        }
      } catch (e) {
        print('Error fetching entity details: $e');
      }
    }

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // Show details dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => EntityDetailsDialog(
          title: title,
          icon: icon,
          details: fullDetails,
          token: token,
          entityId: entityId,
          entityType: entityType,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SizeConfig.spaceRegular)),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.spaceLarge),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SizeConfig.spaceSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(SizeConfig.spaceSmall + 2),
                  ),
                  child: Icon(icon, size: SizeConfig.iconSizeLarge + 4, color: AppTheme.primaryGreen),
                ),
                SizedBox(width: SizeConfig.spaceSmall + 2),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.spaceLarge),

            // Details
            Container(
              padding: EdgeInsets.all(SizeConfig.spaceRegular),
              decoration: BoxDecoration(
                color: AppTheme.darkBg2,
                borderRadius: BorderRadius.circular(SizeConfig.spaceSmall + 2),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: details.entries
                    .where(
                      (e) => e.value != null && e.value.toString().isNotEmpty,
                    )
                    .map(
                      (entry) =>
                          _buildDetailRow(entry.key, entry.value.toString()),
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: SizeConfig.spaceRegular),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.spaceMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeRegular,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.spaceSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeRegular,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.spaceSmall + 2),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeRegular,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
