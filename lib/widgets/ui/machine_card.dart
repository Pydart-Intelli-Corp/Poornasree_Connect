import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class MachineCard extends StatelessWidget {
  final Map<String, dynamic> machine;

  const MachineCard({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final String machineName = machine['name'] ?? machine['machine_name'] ?? 'Unknown Machine';
    final String machineId = machine['id']?.toString() ?? machine['machine_id']?.toString() ?? 'N/A';
    final String status = machine['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    final String? location = machine['location'];
    final String? type = machine['type'] ?? machine['machine_type'];
    final String? serialNumber = machine['serial_number'] ?? machine['serialNumber'];

    // Determine status color
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'inactive':
      case 'offline':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'maintenance':
        statusColor = AppTheme.primaryAmber;
        statusIcon = Icons.build_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to machine detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing details for $machineName'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Machine Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Machine Name and ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machineName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $machineId',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Machine Details
              Row(
                children: [
                  if (type != null) ...[
                    Expanded(
                      child: _buildInfoItem(
                        Icons.category_outlined,
                        'Type',
                        type,
                      ),
                    ),
                  ],
                  if (location != null) ...[
                    Expanded(
                      child: _buildInfoItem(
                        Icons.location_on_outlined,
                        'Location',
                        location,
                      ),
                    ),
                  ],
                ],
              ),
              
              if (serialNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.qr_code,
                  'Serial Number',
                  serialNumber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
