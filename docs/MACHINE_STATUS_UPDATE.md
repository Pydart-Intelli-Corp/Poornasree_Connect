# Machine Status Update Feature - Implementation Guide

## Overview
This document describes the implementation of the machine status update functionality in the Flutter mobile app, matching the web app's capabilities.

## Implementation Date
December 27, 2024

---

## Features Added

### 1. Flutter Mobile App

#### **Machine Service** (`lib/services/api/machine_service.dart`)
Created a new service to handle machine API operations:

- **`updateMachineStatus()`**: Updates a single machine's status
  - Parameters: `machineId`, `status`, `token`
  - Endpoint: `PUT /api/external/auth/machines`
  - Body: `{ id: machineId, status: status }`
  
- **`bulkUpdateStatus()`**: Updates multiple machines' status at once
  - Parameters: `machineIds[]`, `status`, `token`
  - Endpoint: `PUT /api/external/auth/machines`
  - Body: `{ bulkStatusUpdate: true, machineIds: [...], status: status }`

#### **Machine Card Updates** (`lib/widgets/ui/machine_card.dart`)
Enhanced the machine card widget with interactive status management:

1. **Interactive Status Badge**
   - Made status badge clickable with `GestureDetector`
   - Added dropdown arrow icon to indicate interactivity
   - Tap opens status selection dialog

2. **Status Selection Dialog** (`_showStatusDialog()`)
   - Shows all available status options with radio buttons
   - Status options: Active, Inactive, Maintenance, Suspended
   - Each option displayed with corresponding color and icon
   - Current status pre-selected

3. **Status Update Logic** (`_updateMachineStatus()`)
   - Shows loading spinner during API call
   - Retrieves auth token from secure storage
   - Calls `MachineService.updateMachineStatus()`
   - Handles success/error responses
   - Shows snackbar with result message

4. **Token Management** (`_getStoredToken()`)
   - Retrieves authentication token from `FlutterSecureStorage`
   - Key: `'auth_token'`

5. **User Feedback** (`_showSnackBar()`)
   - Success: Green snackbar with checkmark
   - Error: Red snackbar with error icon
   - Auto-dismisses after 3 seconds

### 2. Backend API

#### **External Auth Machines Endpoint** (`src/app/api/external/auth/machines/route.ts`)
Added `PUT` method to support status updates from mobile app:

- **Endpoint**: `PUT /api/external/auth/machines`
- **Authentication**: Bearer token required
- **Request Body**:
  ```json
  {
    "id": 123,
    "status": "active"
  }
  ```

- **Response**:
  ```json
  {
    "success": true,
    "message": "Machine status updated successfully",
    "data": {
      "id": 123,
      "status": "active",
      "updatedBy": "admin",
      "updatedAt": "2024-12-27T10:30:00.000Z"
    }
  }
  ```

- **Permission System**:
  - **Admin**: Can update any machine in their schema
  - **Dairy**: Can update machines in societies under their BMCs
  - **BMC**: Can update machines in their societies
  - **Society**: Can update their own machines only
  - **Farmer**: No permission (403 error)

- **Validation**:
  - Checks token validity and entity type
  - Validates status value (must be: active, inactive, maintenance, suspended)
  - Verifies machine exists and user has access
  - Returns 404 if machine not found or access denied

---

## Status Options

| Status | Color | Icon | Description |
|--------|-------|------|-------------|
| **Active** | Green | ✓ check_circle | Machine is operational |
| **Inactive** | Red | ✗ cancel | Machine is not working |
| **Maintenance** | Amber | 🔧 build_circle | Under maintenance |
| **Suspended** | Orange | ⏸ pause_circle_filled | Temporarily suspended |

---

## User Flow

```
1. User opens machine list screen
   ↓
2. User taps on status badge of a machine
   ↓
3. Dialog opens with 4 status options
   ↓
4. User selects new status (different from current)
   ↓
5. Dialog closes, loading spinner shows
   ↓
6. API call to update status
   ↓
7. Loading spinner closes
   ↓
8. Success/error snackbar appears
   ↓
9. (On success) Machine list should refresh to show new status
```

---

## Technical Details

### Dependencies Added
- **Flutter Secure Storage**: For token management
- **Provider**: For accessing AuthProvider
- **HTTP**: For API calls

### API Configuration
The endpoint is configured in `lib/utils/config/api_config.dart`:
```dart
static String get machines => '$baseUrl/api/external/auth/machines';
```

### Authentication Flow
1. Token stored in `FlutterSecureStorage` with key `'auth_token'`
2. Retrieved when updating machine status
3. Sent in `Authorization: Bearer <token>` header
4. Backend verifies token and entity permissions

### Error Handling

**Flutter App**:
- Network errors caught and shown in snackbar
- Invalid token → "Authentication token not found" error
- API errors → Shows message from API response

**Backend API**:
- 401: Authentication required / Invalid token
- 403: Permission denied
- 404: Machine not found or access denied
- 400: Invalid status value
- 500: Server error

---

## Files Modified/Created

### Flutter App
1. ✅ **Created**: `lib/services/api/machine_service.dart`
2. ✅ **Modified**: `lib/services/api/api.dart` (added export)
3. ✅ **Modified**: `lib/widgets/ui/machine_card.dart` (added status update UI)

### Backend
1. ✅ **Modified**: `src/app/api/external/auth/machines/route.ts` (added PUT method)

---

## Testing Checklist

### Mobile App Testing
- [ ] Status badge shows dropdown arrow icon
- [ ] Tapping status badge opens dialog
- [ ] Dialog shows all 4 status options
- [ ] Current status is pre-selected
- [ ] Selecting same status closes dialog (no API call)
- [ ] Selecting different status triggers API call
- [ ] Loading spinner appears during API call
- [ ] Success snackbar shows on successful update
- [ ] Error snackbar shows on failure
- [ ] Token retrieval works correctly
- [ ] Works for all user roles (Admin, Dairy, BMC, Society)

### Backend Testing
- [ ] PUT endpoint responds to requests
- [ ] Authentication token validation works
- [ ] Permission system enforces role-based access
- [ ] Status validation rejects invalid values
- [ ] Machine existence check works
- [ ] Database update executes successfully
- [ ] Response format matches expected structure
- [ ] CORS headers included for mobile app

### Integration Testing
- [ ] End-to-end status update flow works
- [ ] Status changes reflect in database
- [ ] Multiple users can update different machines simultaneously
- [ ] Status changes visible after app refresh
- [ ] Network errors handled gracefully
- [ ] Token expiration handled properly

---

## Future Enhancements

1. **Real-time Updates**
   - Implement WebSocket or Firebase for live status updates
   - Show status changes made by other users in real-time

2. **Status Change History**
   - Track who changed status and when
   - Show audit log in machine details

3. **Bulk Operations**
   - Allow selecting multiple machines
   - Update status for all selected machines at once

4. **Offline Support**
   - Queue status updates when offline
   - Sync when connection restored

5. **Notifications**
   - Send notifications when machine status changes
   - Alert relevant users about critical status changes

---

## Comparison with Web App

| Feature | Web App | Mobile App | Status |
|---------|---------|------------|--------|
| Status dropdown | ✅ Dropdown menu | ✅ Dialog | ✅ Implemented |
| Status options | ✅ 4 options | ✅ 4 options | ✅ Matching |
| Loading indicator | ✅ Spinner | ✅ Flower Spinner | ✅ Enhanced |
| Success/error feedback | ✅ Toast | ✅ Snackbar | ✅ Implemented |
| Permission-based | ✅ Yes | ✅ Yes | ✅ Matching |
| Bulk updates | ✅ Yes | ⚠️ API ready | 🔄 UI pending |

---

## Notes

1. **Parent Screen Refresh**: Currently, the machine list needs manual refresh after status update. Consider implementing:
   - Callback function passed from parent
   - State management (Provider/Bloc) to auto-refresh
   - Pull-to-refresh gesture

2. **Token Expiration**: The app should handle token expiration gracefully:
   - Refresh token mechanism
   - Redirect to login if token invalid
   - Show appropriate error message

3. **Bulk Update UI**: The API supports bulk updates, but the UI implementation is pending. This should be added in the machine list screen with multi-select functionality.

---

## Support

For issues or questions regarding this feature:
1. Check error logs in terminal/console
2. Verify API endpoint configuration
3. Ensure auth token is valid
4. Check user role permissions

## Version History

- **v1.0.0** (Dec 27, 2024): Initial implementation
  - Single machine status update
  - Permission-based access control
  - UI matching web app design
