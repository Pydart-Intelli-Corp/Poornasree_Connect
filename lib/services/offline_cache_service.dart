import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing offline cache of app data
/// Stores fetched data locally for offline access
class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  // Cache keys
  static const String _machinesKey = 'cache_machines';
  static const String _statisticsKey = 'cache_statistics';
  static const String _userProfileKey = 'cache_user_profile';
  static const String _societyDetailsKey = 'cache_society_details';
  static const String _lastSyncKey = 'cache_last_sync';
  static const String _farmersKey = 'cache_farmers';
  static const String _imagesCacheDir = 'machine_images';

  // ==================== MACHINE IMAGES ====================

  /// Get the directory for caching machine images
  Future<Directory> _getImageCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/$_imagesCacheDir');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// Cache a single machine image from URL
  Future<String?> cacheImage(String imageUrl, String machineId) async {
    try {
      final cacheDir = await _getImageCacheDir();
      final fileName = 'machine_$machineId.jpg';
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);
      
      // If already cached, return the path
      if (await file.exists()) {
        print('📂 [OfflineCache] Image already cached: $fileName');
        return filePath;
      }

      // Build full URL if relative
      String fullUrl = imageUrl;
      if (!imageUrl.startsWith('http')) {
        fullUrl = 'http://192.168.1.68:3000$imageUrl';
      }

      // Download and save the image
      print('⬇️ [OfflineCache] Downloading image for machine $machineId...');
      final response = await http.get(Uri.parse(fullUrl)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('💾 [OfflineCache] Cached image: $fileName');
        return filePath;
      } else {
        print('❌ [OfflineCache] Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error caching image: $e');
      return null;
    }
  }

  /// Cache all machine images from a list of machines
  Future<void> cacheAllMachineImages(List<dynamic> machines) async {
    int cached = 0;
    int skipped = 0;
    int failed = 0;

    for (final machine in machines) {
      final imageUrl = machine['imageUrl'] ?? machine['image_url'];
      final machineId = machine['id']?.toString() ?? machine['machine_id']?.toString();
      
      if (imageUrl == null || imageUrl.isEmpty || machineId == null) {
        skipped++;
        continue;
      }

      final result = await cacheImage(imageUrl, machineId);
      if (result != null) {
        cached++;
      } else {
        failed++;
      }
    }

    print('🖼️ [OfflineCache] Image caching complete: $cached cached, $skipped skipped, $failed failed');
  }

  /// Get cached image path for a machine
  Future<String?> getCachedImagePath(String machineId) async {
    try {
      final cacheDir = await _getImageCacheDir();
      final fileName = 'machine_$machineId.jpg';
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        return filePath;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error getting cached image path: $e');
    }
    return null;
  }

  /// Check if a machine image is cached
  Future<bool> hasImageCached(String machineId) async {
    final path = await getCachedImagePath(machineId);
    return path != null;
  }

  /// Clear all cached images
  Future<void> clearImageCache() async {
    try {
      final cacheDir = await _getImageCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('🧹 [OfflineCache] Cleared image cache');
      }
    } catch (e) {
      print('❌ [OfflineCache] Error clearing image cache: $e');
    }
  }

  // ==================== MACHINES ====================

  /// Cache machines list and their images
  Future<void> cacheMachines(List<dynamic> machines, {bool cacheImages = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_machinesKey, jsonEncode(machines));
      await _updateLastSync();
      print('💾 [OfflineCache] Cached ${machines.length} machines');
      
      // Cache images in background
      if (cacheImages) {
        cacheAllMachineImages(machines);  // Don't await - run in background
      }
    } catch (e) {
      print('❌ [OfflineCache] Error caching machines: $e');
    }
  }

  /// Get cached machines
  Future<List<dynamic>> getCachedMachines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_machinesKey);
      if (json != null) {
        final machines = jsonDecode(json) as List;
        print('📂 [OfflineCache] Loaded ${machines.length} cached machines');
        return machines;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error loading cached machines: $e');
    }
    return [];
  }

  /// Check if machines are cached
  Future<bool> hasCachedMachines() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_machinesKey);
  }

  // ==================== STATISTICS ====================

  /// Cache statistics data
  Future<void> cacheStatistics(Map<String, dynamic> statistics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statisticsKey, jsonEncode(statistics));
      await _updateLastSync();
      print('💾 [OfflineCache] Cached statistics');
    } catch (e) {
      print('❌ [OfflineCache] Error caching statistics: $e');
    }
  }

  /// Get cached statistics
  Future<Map<String, dynamic>?> getCachedStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_statisticsKey);
      if (json != null) {
        final stats = jsonDecode(json) as Map<String, dynamic>;
        print('📂 [OfflineCache] Loaded cached statistics');
        return stats;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error loading cached statistics: $e');
    }
    return null;
  }

  /// Check if statistics are cached
  Future<bool> hasCachedStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_statisticsKey);
  }

  // ==================== USER PROFILE ====================

  /// Cache user profile data
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, jsonEncode(profile));
      await _updateLastSync();
      print('💾 [OfflineCache] Cached user profile');
    } catch (e) {
      print('❌ [OfflineCache] Error caching user profile: $e');
    }
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_userProfileKey);
      if (json != null) {
        final profile = jsonDecode(json) as Map<String, dynamic>;
        print('📂 [OfflineCache] Loaded cached user profile');
        return profile;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error loading cached user profile: $e');
    }
    return null;
  }

  // ==================== SOCIETY DETAILS ====================

  /// Cache society details
  Future<void> cacheSocietyDetails(Map<String, dynamic> details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_societyDetailsKey, jsonEncode(details));
      await _updateLastSync();
      print('💾 [OfflineCache] Cached society details');
    } catch (e) {
      print('❌ [OfflineCache] Error caching society details: $e');
    }
  }

  /// Get cached society details
  Future<Map<String, dynamic>?> getCachedSocietyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_societyDetailsKey);
      if (json != null) {
        final details = jsonDecode(json) as Map<String, dynamic>;
        print('📂 [OfflineCache] Loaded cached society details');
        return details;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error loading cached society details: $e');
    }
    return null;
  }

  // ==================== FARMERS ====================

  /// Cache farmers list
  Future<void> cacheFarmers(List<dynamic> farmers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_farmersKey, jsonEncode(farmers));
      await _updateLastSync();
      print('💾 [OfflineCache] Cached ${farmers.length} farmers');
    } catch (e) {
      print('❌ [OfflineCache] Error caching farmers: $e');
    }
  }

  /// Get cached farmers
  Future<List<dynamic>> getCachedFarmers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_farmersKey);
      if (json != null) {
        final farmers = jsonDecode(json) as List;
        print('📂 [OfflineCache] Loaded ${farmers.length} cached farmers');
        return farmers;
      }
    } catch (e) {
      print('❌ [OfflineCache] Error loading cached farmers: $e');
    }
    return [];
  }

  // ==================== SYNC METADATA ====================

  /// Update last sync timestamp
  Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.tryParse(timestamp);
      }
    } catch (e) {
      print('❌ [OfflineCache] Error getting last sync time: $e');
    }
    return null;
  }

  /// Get formatted last sync time string
  Future<String> getLastSyncTimeFormatted() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return 'Never';
    
    final now = DateTime.now();
    final diff = now.difference(lastSync);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    return '${lastSync.day}/${lastSync.month}/${lastSync.year}';
  }

  /// Check if cache has any data
  Future<bool> hasAnyCache() async {
    return await hasCachedMachines() || await hasCachedStatistics();
  }

  // ==================== CLEAR CACHE ====================

  /// Clear all cached data including images
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_machinesKey);
      await prefs.remove(_statisticsKey);
      await prefs.remove(_userProfileKey);
      await prefs.remove(_societyDetailsKey);
      await prefs.remove(_farmersKey);
      await prefs.remove(_lastSyncKey);
      
      // Also clear cached images
      await clearImageCache();
      
      print('🧹 [OfflineCache] Cleared all cached data');
    } catch (e) {
      print('❌ [OfflineCache] Error clearing cache: $e');
    }
  }

  /// Clear cache on logout
  Future<void> clearOnLogout() async {
    await clearAllCache();
  }
}
