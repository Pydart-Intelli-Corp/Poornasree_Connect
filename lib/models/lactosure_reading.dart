import '../services/shift_settings_service.dart';

class LactosureReading {
  final String milkType;
  final double fat;
  final double snf;
  final double clr;
  final double protein;
  final double lactose;
  final double salt;
  final double water;
  final double temperature;
  final String farmerId;
  final double quantity;
  final double totalAmount;
  final double rate;
  final double incentive;
  final String machineId;
  final DateTime? timestamp; // Reading timestamp from BLE data
  final String? shift; // Shift at time of reading (MR/EV) - stored to preserve original shift

  LactosureReading({
    required this.milkType,
    required this.fat,
    required this.snf,
    required this.clr,
    required this.protein,
    required this.lactose,
    required this.salt,
    required this.water,
    required this.temperature,
    required this.farmerId,
    required this.quantity,
    required this.totalAmount,
    required this.rate,
    required this.incentive,
    required this.machineId,
    this.timestamp,
    this.shift,
  });

  /// Parses BLE data string
  /// Format: LE3.36|A|CH1|F05.21|S12.58|C44.10|P04.60|L06.90|s01.04|W00.00|T20.00|I000100|Q00100.00|R00000.00|r000.00|i000.00|MM00201|D2026-01-05_10:28:12^@^@
  static LactosureReading? parse(String data) {
    try {
      print('🔵 [Parser] Raw data received: $data');
      print('🔵 [Parser] Data length: ${data.length} characters');

      // Remove trailing characters
      data = data.replaceAll(RegExp(r'\^@|\r|\n'), '').trim();
      print('🔵 [Parser] After cleanup: $data');

      // Split by pipe delimiter
      final parts = data.split('|');
      print('🔵 [Parser] Split into ${parts.length} parts');

      if (parts.length < 16) {
        print(
          '❌ [Parser] Invalid data - expected at least 16 parts, got ${parts.length}',
        );
        print('📄 [Parser] Parts: $parts');
        return null; // Invalid data
      }

      print('📋 [Parser] Parsing each field:');
      for (int i = 0; i < parts.length && i < 16; i++) {
        print('   [$i]: ${parts[i]}');
      }

      // Parse timestamp if available (parts[17]: D2026-01-05_10:28:12)
      DateTime? readingTimestamp;
      if (parts.length > 17) {
        try {
          final timestampStr = _extractValue(parts[17], 'D');
          // Format: 2026-01-05_10:28:12
          final cleanTimestamp = timestampStr.replaceAll('_', ' ');
          readingTimestamp = DateTime.tryParse(cleanTimestamp);
        } catch (e) {
          print('⚠️ [Parser] Could not parse timestamp: $e');
        }
      }
      
      // Determine shift at time of reading (preserve original shift even if settings change later)
      final effectiveTimestamp = readingTimestamp ?? DateTime.now();
      final shiftService = ShiftSettingsService();
      final currentShift = shiftService.getShiftForTime(effectiveTimestamp);
      
      final reading = LactosureReading(
        milkType: _extractValue(parts[2], 'CH'), // CH1
        fat: _parseDouble(_extractValue(parts[3], 'F')), // F05.21
        snf: _parseDouble(_extractValue(parts[4], 'S')), // S12.58
        clr: _parseDouble(_extractValue(parts[5], 'C')), // C44.10
        protein: _parseDouble(_extractValue(parts[6], 'P')), // P04.60
        lactose: _parseDouble(_extractValue(parts[7], 'L')), // L06.90
        salt: _parseDouble(_extractValue(parts[8], 's')), // s01.04
        water: _parseDouble(_extractValue(parts[9], 'W')), // W00.00
        temperature: _parseDouble(_extractValue(parts[10], 'T')), // T20.00
        farmerId: _extractValue(parts[11], 'I'), // I000100
        quantity: _parseDouble(_extractValue(parts[12], 'Q')), // Q00100.00
        totalAmount: _parseDouble(_extractValue(parts[13], 'R')), // R00000.00
        rate: _parseDouble(_extractValue(parts[14], 'r')), // r000.00
        incentive: _parseDouble(_extractValue(parts[15], 'i')), // i000.00
        machineId: parts.length > 16
            ? _extractValue(parts[16], 'MM')
            : '', // MM00201
        timestamp: effectiveTimestamp,
        shift: currentShift, // Store shift at time of reading
      );

      print('✅ [Parser] Successfully created LactosureReading object');
      return reading;
    } catch (e, stackTrace) {
      print('❌ [Parser] Error parsing lactosure data: $e');
      print('📍 [Parser] Stack trace: $stackTrace');
      return null;
    }
  }

  static String _extractValue(String part, String prefix) {
    return part.replaceFirst(prefix, '');
  }

  static double _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }

  String get milkTypeName {
    switch (milkType) {
      case '1':
        return 'Cow';
      case '2':
        return 'Buffalo';
      case '3':
        return 'Mixed';
      default:
        return 'Unknown';
    }
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() {
    // Debug: Print values being saved
    print('💾 [LactosureReading.toJson] Saving:');
    print('   fat: $fat, snf: $snf, clr: $clr');
    print('   protein: $protein, lactose: $lactose');
    print('   salt: $salt, water: $water, shift: $shift');
    
    return {
      'milkType': milkType,
      'fat': fat,
      'snf': snf,
      'clr': clr,
      'protein': protein,
      'lactose': lactose,
      'salt': salt,
      'water': water,
      'temperature': temperature,
      'farmerId': farmerId,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'rate': rate,
      'incentive': incentive,
      'machineId': machineId,
      'timestamp': timestamp?.toIso8601String(),
      'shift': shift, // Store shift with reading
    };
  }

  /// Create from JSON map
  factory LactosureReading.fromJson(Map<String, dynamic> json) {
    // Debug: Print JSON values being loaded
    print('📂 [LactosureReading.fromJson] Loading:');
    print('   JSON fat: ${json['fat']}, snf: ${json['snf']}, clr: ${json['clr']}');
    print('   JSON protein: ${json['protein']}, lactose: ${json['lactose']}');
    print('   JSON salt: ${json['salt']}, water: ${json['water']}, shift: ${json['shift']}');
    
    return LactosureReading(
      milkType: json['milkType'] ?? '',
      fat: (json['fat'] ?? 0).toDouble(),
      snf: (json['snf'] ?? 0).toDouble(),
      clr: (json['clr'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      lactose: (json['lactose'] ?? 0).toDouble(),
      salt: (json['salt'] ?? 0).toDouble(),
      water: (json['water'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      farmerId: json['farmerId'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      incentive: (json['incentive'] ?? 0).toDouble(),
      machineId: json['machineId'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
      shift: json['shift'], // Load stored shift
    );
  }
}
