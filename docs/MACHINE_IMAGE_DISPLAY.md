# Machine Image Display in Android App

## Overview
Machine cards in the Flutter app now display machine images on the right side of the card header, next to the status badge.

## Changes Made

### 1. Machine Model Updated
**File**: `lib/models/entities/machine.dart`

Added `imageUrl` field:
```dart
// Machine image
final String? imageUrl;
```

- Added to constructor parameters
- Added to `fromJson()` factory (supports both `imageUrl` and `image_url`)
- Added to `toJson()` method

### 2. Machine Card Updated
**File**: `lib/widgets/ui/machine_card.dart`

Added image display in header:
- **Size**: 70x70 pixels
- **Position**: Right side, between machine info and status badge
- **Border**: Rounded corners (10px) with grey border
- **Features**:
  - Shows image from network URL
  - Error handling with fallback icon
  - Loading indicator while image loads
  - Only displays if `imageUrl` is not null/empty

### 3. Backend API Updated
**File**: `src/app/api/external/auth/machines/route.ts`

Updated all machine queries to include `image_url`:
- Added `machineImageJoin` - LEFT JOIN with `machinetype` table
- Added `machineFieldsWithImage` - includes `mt.image_url`
- Updated queries for all entity types:
  - ✅ Admin
  - ✅ Society
  - ✅ BMC
  - ✅ Dairy

## Image Display Behavior

### When Image Exists:
```
┌─────────────────────────────────────────────┐
│ [Icon] Machine Name [Master]  [Image] [Status] │
│        Machine Type                         │
└─────────────────────────────────────────────┘
```

### When No Image:
```
┌─────────────────────────────────────────────┐
│ [Icon] Machine Name [Master]        [Status] │
│        Machine Type                         │
└─────────────────────────────────────────────┘
```

## Image Specifications

### Display Properties:
- **Width**: 70px
- **Height**: 70px
- **Border Radius**: 10px
- **Border**: 1px solid grey[300]
- **Shadow**: Subtle black shadow (0.05 opacity, 4px blur)
- **Fit**: Cover (maintains aspect ratio)

### Error Handling:
- Falls back to grey background with "image not supported" icon
- Loading state shows circular progress indicator

### Network Image:
- Loads from provided URL (usually `/uploads/machines/...`)
- Progressive loading with indicator
- Cached by Flutter's image cache

## Testing

### To Test:
1. Upload an image for a machine type via Super Admin panel
2. Open the Flutter app
3. Navigate to machines list
4. Verify image appears on the right side of machine card

### Test Cases:
- ✅ Machine with image displays correctly
- ✅ Machine without image shows no image placeholder
- ✅ Image loading shows progress indicator
- ✅ Failed image load shows error icon
- ✅ Layout remains responsive with/without image

## API Response Format

The machines API now returns:
```json
{
  "id": 1,
  "machine_id": "M001",
  "machine_type": "ECOD",
  "status": "active",
  "image_url": "/uploads/machines/machine-1-1735634400000.jpg",
  ...
}
```

## Notes

- Images are fetched from the main `machinetype` table via LEFT JOIN
- All machine types with the same `machine_type` share the same image
- Image URLs are relative paths (e.g., `/uploads/machines/...`)
- Flutter's `Image.network()` handles full URL construction
- No changes needed to existing machine data - images are optional

## Future Enhancements

Potential improvements:
1. Add image caching strategy
2. Implement image zoom on tap
3. Add image placeholder for better UX
4. Support multiple images per machine type
5. Add image carousel for machine types

---

**Status**: ✅ Implemented and Ready
**Date**: December 31, 2025
**Version**: 1.0
