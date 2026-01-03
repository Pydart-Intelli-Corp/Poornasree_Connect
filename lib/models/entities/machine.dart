/// Machine model for handling machine data from API
class Machine {
  final int id;
  final String machineId;
  final String machineType;
  final String status;
  final String? location;
  final bool isMasterMachine;
  final String? operatorName;
  final String? contactPhone;
  final String? installationDate;
  final String? notes;
  final int statusU; // User password status (0=downloaded, 1=pending)
  final int statusS; // Supervisor password status (0=downloaded, 1=pending)
  final String? userPassword; // User password value
  final String? supervisorPassword; // Supervisor password value
  final String? createdAt;
  final String? updatedAt;

  // Society info
  final String? societyName;
  final String? societyId;
  final int? societyDbId;
  final String? presidentName;
  final String? societyLocation;

  // BMC info
  final String? bmcName;
  final String? bmcId;

  // Dairy info
  final String? dairyName;
  final String? dairyId;

  // 30-day statistics
  final int totalCollections30d;
  final double totalQuantity30d;
  final double avgFat30d;
  final double avgSnf30d;

  // Rate chart info
  final String? chartDetails;
  final int activeChartsCount;

  // Correction info
  final String? correctionDetails;
  final int activeCorrectionsCount;

  // Machine image
  final String? imageUrl;

  // ESP32 Machine Statistics (from machine_statistics table)
  final int totalTests;
  final int dailyCleaning;
  final int weeklyCleaning;
  final int cleaningSkip;
  final int gain;
  final String? autoChannel;
  final String? machineVersion;
  final String? statisticsDate;
  final String? statisticsTime;

  Machine({
    required this.id,
    required this.machineId,
    required this.machineType,
    required this.status,
    this.location,
    this.isMasterMachine = false,
    this.operatorName,
    this.contactPhone,
    this.installationDate,
    this.notes,
    this.statusU = 0,
    this.statusS = 0,
    this.userPassword,
    this.supervisorPassword,
    this.createdAt,
    this.updatedAt,
    this.societyName,
    this.societyId,
    this.societyDbId,
    this.presidentName,
    this.societyLocation,
    this.bmcName,
    this.bmcId,
    this.dairyName,
    this.dairyId,
    this.totalCollections30d = 0,
    this.totalQuantity30d = 0.0,
    this.avgFat30d = 0.0,
    this.avgSnf30d = 0.0,
    this.chartDetails,
    this.activeChartsCount = 0,
    this.correctionDetails,
    this.activeCorrectionsCount = 0,
    this.imageUrl,
    this.totalTests = 0,
    this.dailyCleaning = 0,
    this.weeklyCleaning = 0,
    this.cleaningSkip = 0,
    this.gain = 0,
    this.autoChannel,
    this.machineVersion,
    this.statisticsDate,
    this.statisticsTime,
  });

  /// Create Machine from API JSON response
  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] ?? 0,
      machineId: json['machineId'] ?? json['machine_id'] ?? '',
      machineType: json['machineType'] ?? json['machine_type'] ?? '',
      status: json['status'] ?? 'inactive',
      location: json['location'],
      isMasterMachine:
          json['isMasterMachine'] == true || json['is_master_machine'] == 1,
      operatorName: json['operatorName'] ?? json['operator_name'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'],
      installationDate: json['installationDate'] ?? json['installation_date'],
      notes: json['notes'],
      statusU: _parseIntSafe(json['statusU'] ?? json['statusu']),
      statusS: _parseIntSafe(json['statusS'] ?? json['statuss']),
      userPassword: json['userPassword'] ?? json['user_password'],
      supervisorPassword:
          json['supervisorPassword'] ?? json['supervisor_password'],
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      societyName: json['societyName'] ?? json['society_name'],
      societyId: json['societyId'] ?? json['society_id']?.toString(),
      societyDbId: _parseIntSafe(json['societyDbId'] ?? json['society_db_id']),
      presidentName: json['presidentName'] ?? json['president_name'],
      societyLocation: json['societyLocation'] ?? json['society_location'],
      bmcName: json['bmcName'] ?? json['bmc_name'],
      bmcId: json['bmcId'] ?? json['bmc_id'],
      dairyName: json['dairyName'] ?? json['dairy_name'],
      dairyId: json['dairyId'] ?? json['dairy_id'],
      totalCollections30d: _parseIntSafe(
        json['totalCollections30d'] ?? json['total_collections_30d'],
      ),
      totalQuantity30d: _parseDoubleSafe(
        json['totalQuantity30d'] ?? json['total_quantity_30d'],
      ),
      avgFat30d: _parseDoubleSafe(json['avgFat30d'] ?? json['avg_fat_30d']),
      avgSnf30d: _parseDoubleSafe(json['avgSnf30d'] ?? json['avg_snf_30d']),
      chartDetails: json['chartDetails'] ?? json['chart_details'],
      activeChartsCount: _parseIntSafe(
        json['activeChartsCount'] ?? json['active_charts_count'],
      ),
      correctionDetails:
          json['correctionDetails'] ?? json['correction_details'],
      activeCorrectionsCount: _parseIntSafe(
        json['activeCorrectionsCount'] ?? json['active_corrections_count'],
      ),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      totalTests: _parseIntSafe(json['totalTests'] ?? json['total_test']),
      dailyCleaning: _parseIntSafe(
        json['dailyCleaning'] ?? json['daily_cleaning'],
      ),
      weeklyCleaning: _parseIntSafe(
        json['weeklyCleaning'] ?? json['weekly_cleaning'],
      ),
      cleaningSkip: _parseIntSafe(
        json['cleaningSkip'] ?? json['cleaning_skip'],
      ),
      gain: _parseIntSafe(json['gain']),
      autoChannel: json['autoChannel'] ?? json['auto_channel'],
      machineVersion: json['machineVersion'] ?? json['version'],
      statisticsDate: json['statisticsDate'] ?? json['statistics_date'],
      statisticsTime: json['statisticsTime'] ?? json['statistics_time'],
    );
  }

  /// Convert Machine to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineId': machineId,
      'machineType': machineType,
      'status': status,
      'location': location,
      'isMasterMachine': isMasterMachine,
      'operatorName': operatorName,
      'contactPhone': contactPhone,
      'installationDate': installationDate,
      'notes': notes,
      'statusU': statusU,
      'statusS': statusS,
      'userPassword': userPassword,
      'supervisorPassword': supervisorPassword,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'societyName': societyName,
      'societyId': societyId,
      'societyDbId': societyDbId,
      'presidentName': presidentName,
      'societyLocation': societyLocation,
      'bmcName': bmcName,
      'bmcId': bmcId,
      'dairyName': dairyName,
      'dairyId': dairyId,
      'totalCollections30d': totalCollections30d,
      'totalQuantity30d': totalQuantity30d,
      'avgFat30d': avgFat30d,
      'avgSnf30d': avgSnf30d,
      'chartDetails': chartDetails,
      'activeChartsCount': activeChartsCount,
      'correctionDetails': correctionDetails,
      'activeCorrectionsCount': activeCorrectionsCount,
      'imageUrl': imageUrl,
      'totalTests': totalTests,
      'dailyCleaning': dailyCleaning,
      'weeklyCleaning': weeklyCleaning,
      'cleaningSkip': cleaningSkip,
      'gain': gain,
      'autoChannel': autoChannel,
      'machineVersion': machineVersion,
      'statisticsDate': statisticsDate,
      'statisticsTime': statisticsTime,
    };
  }

  /// Parse rate chart details into pending and downloaded lists
  RateChartInfo parseChartDetails() {
    final List<ChartItem> pending = [];
    final List<ChartItem> downloaded = [];

    if (chartDetails == null || chartDetails!.isEmpty) {
      return RateChartInfo(pending: pending, downloaded: downloaded);
    }

    final charts = chartDetails!.split('|||');
    for (final chart in charts) {
      final parts = chart.split(':');
      if (parts.length >= 3) {
        final channel = parts[0];
        final fileName = parts[1];
        final status = parts[2];

        final chartItem = ChartItem(channel: channel, fileName: fileName);

        if (status == 'pending') {
          pending.add(chartItem);
        } else {
          downloaded.add(chartItem);
        }
      }
    }

    return RateChartInfo(pending: pending, downloaded: downloaded);
  }

  /// Parse correction details to get channels (Cow, Buffalo, Mix) with pending/downloaded status
  /// New format: "1,2:pending|||1,3:downloaded" where 1=Cow, 2=Buffalo, 3=Mix
  CorrectionInfo parseCorrectionDetails() {
    final Set<String> channels = {};
    final List<CorrectionItem> pending = [];
    final List<CorrectionItem> downloaded = [];

    if (correctionDetails != null && correctionDetails!.isNotEmpty) {
      // New format: "1,2,3:pending|||1,2:downloaded"
      // Each record has channels and status separated by ':'
      final records = correctionDetails!.split('|||');
      for (final record in records) {
        if (record.isEmpty) continue;

        final parts = record.split(':');
        if (parts.length >= 2) {
          // New format with status
          final channelPart = parts[0].trim();
          final status = parts[1].trim().toLowerCase();

          // Skip if channel part is empty
          if (channelPart.isEmpty) continue;

          final channelList = channelPart.split(',');

          for (final ch in channelList) {
            final trimmed = ch.trim();
            if (trimmed.isEmpty) continue;

            String? channelName;
            if (trimmed == '1') {
              channelName = 'Cow';
            } else if (trimmed == '2') {
              channelName = 'Buf';
            } else if (trimmed == '3') {
              channelName = 'Mix';
            }

            if (channelName != null) {
              channels.add(channelName);
              final item = CorrectionItem(channel: channelName, status: status);
              if (status == 'pending') {
                // Remove from downloaded if exists (pending takes priority)
                downloaded.removeWhere((d) => d.channel == channelName);
                // Only add if not already in pending
                if (!pending.any((p) => p.channel == channelName)) {
                  pending.add(item);
                }
              } else {
                // Only add to downloaded if NOT in pending list
                if (!pending.any((p) => p.channel == channelName)) {
                  // Also check if not already in downloaded
                  if (!downloaded.any((d) => d.channel == channelName)) {
                    downloaded.add(item);
                  }
                }
              }
            }
          }
        } else {
          // Legacy format without status (assume pending)
          final channelList = parts[0].split(',');
          for (final ch in channelList) {
            final trimmed = ch.trim();
            if (trimmed.isEmpty) continue;

            if (trimmed == '1') {
              channels.add('Cow');
              pending.add(CorrectionItem(channel: 'Cow', status: 'pending'));
            } else if (trimmed == '2') {
              channels.add('Buf');
              pending.add(CorrectionItem(channel: 'Buf', status: 'pending'));
            } else if (trimmed == '3') {
              channels.add('Mix');
              pending.add(CorrectionItem(channel: 'Mix', status: 'pending'));
            }
          }
        }
      }
    }

    return CorrectionInfo(
      pendingCount: activeCorrectionsCount,
      channels: channels.toList(),
      pending: pending,
      downloaded: downloaded,
    );
  }

  /// Get password status display info
  /// Logic based on statusU/statusS flags (password values may not be returned by API):
  /// - statusU/statusS = 1: Pending (password changed, waiting for ESP32 download) -> Yellow
  /// - statusU/statusS = 0: Downloaded/Synced (ESP32 has latest or no password set) -> Green
  PasswordStatusInfo getUserPasswordStatus() {
    if (statusU == 1) {
      return PasswordStatusInfo(
        text: 'User: Pending',
        statusType: PasswordStatusType.pending,
      );
    } else {
      // statusU = 0 means either downloaded or never set - show as OK
      return PasswordStatusInfo(
        text: 'User ✓',
        statusType: PasswordStatusType.downloaded,
      );
    }
  }

  PasswordStatusInfo getSupervisorPasswordStatus() {
    if (statusS == 1) {
      return PasswordStatusInfo(
        text: 'Supervisor: Pending',
        statusType: PasswordStatusType.pending,
      );
    } else {
      // statusS = 0 means either downloaded or never set - show as OK
      return PasswordStatusInfo(
        text: 'Supervisor ✓',
        statusType: PasswordStatusType.downloaded,
      );
    }
  }

  /// Legacy method for backward compatibility
  PasswordStatusInfo getPasswordStatusInfo() {
    final userStatus = getUserPasswordStatus();
    final supervisorStatus = getSupervisorPasswordStatus();

    if (userStatus.statusType == PasswordStatusType.downloaded &&
        supervisorStatus.statusType == PasswordStatusType.downloaded) {
      return PasswordStatusInfo(
        text: 'Both passwords downloaded',
        statusType: PasswordStatusType.both,
      );
    } else if (userStatus.statusType == PasswordStatusType.downloaded) {
      return PasswordStatusInfo(
        text: 'User password downloaded',
        statusType: PasswordStatusType.userOnly,
      );
    } else if (supervisorStatus.statusType == PasswordStatusType.downloaded) {
      return PasswordStatusInfo(
        text: 'Supervisor password downloaded',
        statusType: PasswordStatusType.supervisorOnly,
      );
    } else {
      return PasswordStatusInfo(
        text: 'No passwords set',
        statusType: PasswordStatusType.none,
      );
    }
  }

  /// Safe int parser
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Safe double parser
  static double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get formatted installation date
  String? get formattedInstallationDate {
    if (installationDate == null || installationDate!.isEmpty) return null;
    try {
      final date = DateTime.parse(installationDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return installationDate;
    }
  }
}

/// Rate chart info container
class RateChartInfo {
  final List<ChartItem> pending;
  final List<ChartItem> downloaded;

  RateChartInfo({required this.pending, required this.downloaded});
}

/// Single chart item
class ChartItem {
  final String channel;
  final String fileName;

  ChartItem({required this.channel, required this.fileName});
}

/// Single correction item with status
class CorrectionItem {
  final String channel;
  final String status; // 'pending' or 'downloaded'

  CorrectionItem({required this.channel, required this.status});
}

/// Password status types
enum PasswordStatusType {
  downloaded, // Status = 0, password exists -> Green
  pending, // Status = 1, password changed but not downloaded by ESP32 -> Yellow/Amber
  none, // No password set -> Red/Gray
  both, // Legacy: both downloaded
  userOnly, // Legacy: only user downloaded
  supervisorOnly, // Legacy: only supervisor downloaded
}

/// Password status info container
class PasswordStatusInfo {
  final String text;
  final PasswordStatusType statusType;

  PasswordStatusInfo({required this.text, required this.statusType});
}

/// Correction info container - now supports pending and downloaded lists like charts
class CorrectionInfo {
  final int pendingCount;
  final List<String> channels;
  final List<CorrectionItem> pending;
  final List<CorrectionItem> downloaded;

  CorrectionInfo({
    required this.pendingCount,
    this.channels = const [],
    this.pending = const [],
    this.downloaded = const [],
  });
}
