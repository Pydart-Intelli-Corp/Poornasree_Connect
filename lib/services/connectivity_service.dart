import 'dart:async';
import 'dart:io';

/// Service to check network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller for connectivity changes
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  // Current connectivity status
  bool _isConnected = true;
  bool _isChecking = false;

  // Getters
  bool get isConnected => _isConnected;
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Check if device has internet connectivity
  /// Uses DNS lookup to verify actual internet access
  Future<bool> checkConnectivity() async {
    if (_isChecking) return _isConnected;
    
    _isChecking = true;
    
    try {
      // Try to lookup google.com to verify internet connectivity
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (_isConnected != connected) {
        _isConnected = connected;
        _connectivityController.add(_isConnected);
        print('🌐 [Connectivity] Status changed: ${_isConnected ? "Online" : "Offline"}');
      }
      
      _isChecking = false;
      return _isConnected;
    } on SocketException catch (_) {
      if (_isConnected != false) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
        print('🌐 [Connectivity] Status changed: Offline (SocketException)');
      }
      _isChecking = false;
      return false;
    } on TimeoutException catch (_) {
      if (_isConnected != false) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
        print('🌐 [Connectivity] Status changed: Offline (Timeout)');
      }
      _isChecking = false;
      return false;
    } catch (e) {
      print('🌐 [Connectivity] Error checking connectivity: $e');
      _isChecking = false;
      return _isConnected;
    }
  }

  /// Start periodic connectivity checking
  Timer? _periodicTimer;
  
  void startPeriodicCheck({Duration interval = const Duration(seconds: 30)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) => checkConnectivity());
    // Also check immediately
    checkConnectivity();
  }

  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Force refresh connectivity status
  Future<bool> refresh() async {
    return await checkConnectivity();
  }

  /// Dispose resources
  void dispose() {
    _periodicTimer?.cancel();
    _connectivityController.close();
  }
}
