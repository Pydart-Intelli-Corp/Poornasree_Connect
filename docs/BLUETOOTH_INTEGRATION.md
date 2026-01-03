# Bluetooth Integration - Lactosure-BLE Device Scanning

## Overview
This document describes the Bluetooth Low Energy (BLE) integration for detecting and displaying Lactosure-BLE devices in the Poornasree Connect mobile app.

## Implementation Summary

### 1. Permission Handling
**Package**: `permission_handler ^11.3.0`

**Required Permissions**:
- Android 12+: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`
- Android 11-: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_COARSE_LOCATION`

**Implementation Location**: 
- Service: `lib/services/bluetooth_service.dart`
- Startup: `lib/screens/splash/splash_screen.dart`

### 2. BluetoothService
**File**: `lib/services/bluetooth_service.dart`

**Key Methods**:
```dart
// Request all required permissions on app startup
Future<bool> requestPermissions()

// Check if permissions are granted
Future<bool> checkPermissions()

// Start scanning for Lactosure-BLE devices
Future<void> startScan()

// Stop scanning
Future<void> stopScan()
```

**Streams**:
- `deviceStream`: Stream of detected Lactosure-BLE devices
- `scanningStream`: Current scanning status

**Device Filtering**:
- Only devices with name "Lactosure-BLE" are included
- Auto-scan disabled by default (manual start required)

### 3. Splash Screen Integration
**File**: `lib/screens/splash/splash_screen.dart`

**Flow**:
1. Check authentication status
2. Request Bluetooth & Location permissions
3. Navigate to appropriate screen (Dashboard/Login)

**Code**:
```dart
// Request permissions after auth check
await BluetoothService().requestPermissions();
```

### 4. Dashboard Integration
**File**: `lib/screens/dashboard/dashboard_screen.dart`

**Features**:
- Background scanning starts when dashboard loads
- Bluetooth indicator shown only when Lactosure-BLE devices detected
- Automatic device list updates via stream listener
- Scanning stops when leaving dashboard (dispose)

**UI Behavior**:
- Conditional rendering: `if (_hasBluetoothDevices)`
- Green indicator with device name
- Scanning animation when active
- Positioned below dashboard header, above machines list

### 5. Android Manifest Configuration
**File**: `android/app/src/main/AndroidManifest.xml`

**Permissions Added**:
```xml
<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Android 11- -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
```

## User Flow

### App Startup
1. User opens app
2. Splash screen appears
3. Permission dialog shown (Bluetooth & Location)
4. User grants/denies permissions
5. Navigate to Dashboard (if authenticated)

### Dashboard Operation
1. Dashboard loads
2. Background BLE scanning starts automatically
3. If Lactosure-BLE found:
   - Green indicator appears below header
   - Shows "Lactosure-BLE Device Detected"
   - Scanning animation displayed
4. If no devices found:
   - No indicator shown
   - Scanning continues in background
5. On dashboard exit:
   - Scanning stops automatically

## Technical Notes

### Bluetooth State Management
- Permission check before every scan
- Graceful handling of denied permissions
- Auto-retry disabled (manual start required)
- Stream-based device updates for reactive UI

### Performance Considerations
- Scanning limited to dashboard screen only
- Device filtering reduces processing overhead
- Stream disposal prevents memory leaks
- Background scanning doesn't block UI

### Error Handling
- Permission denial: Silent fail, no scanning
- Bluetooth off: Service handles gracefully
- No devices: UI remains hidden

## Testing Checklist

### Permissions
- [ ] First launch shows permission dialog
- [ ] Permissions saved after grant
- [ ] App handles permission denial
- [ ] Settings deep-link works (if denied)

### Scanning
- [ ] Scanning starts on dashboard load
- [ ] Indicator appears when device found
- [ ] Indicator hides when no devices
- [ ] Scanning stops on dashboard exit

### UI/UX
- [ ] Indicator positioned correctly
- [ ] Scanning animation smooth
- [ ] No performance impact on machine list
- [ ] Pull-to-refresh works normally

### Device Detection
- [ ] Only Lactosure-BLE devices shown
- [ ] Multiple devices handled correctly
- [ ] Device disconnect updates UI
- [ ] Device reconnect updates UI

## Future Enhancements
- Device connection functionality
- Data synchronization with Lactosure-BLE
- Device detail screen
- Manual scan trigger button
- Bluetooth settings screen
- Device history/favorites

## Dependencies
```yaml
dependencies:
  flutter_blue_plus: ^2.1.0
  permission_handler: ^11.3.0
```

## Files Modified
1. `lib/services/bluetooth_service.dart` - Permission methods added
2. `lib/screens/splash/splash_screen.dart` - Permission request on startup
3. `lib/screens/dashboard/dashboard_screen.dart` - Background scanning & UI
4. `android/app/src/main/AndroidManifest.xml` - Bluetooth permissions
5. `pubspec.yaml` - Added permission_handler package

---
**Last Updated**: 2025-01-XX
**Version**: 1.0.0
