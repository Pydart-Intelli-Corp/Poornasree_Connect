# Play Store Assets Checklist

## 📱 Required Graphics

### 1. App Icon ✅
- **Size**: 512x512 px
- **Format**: PNG (32-bit)
- **Status**: Already configured in pubspec.yaml
- **Location**: `assets/images/flower.png`

### 2. Feature Graphic ⚠️ REQUIRED
- **Size**: 1024x500 px
- **Format**: PNG or JPEG
- **Purpose**: Main banner on Play Store
- **Content**: App name + key visual
- **Action**: Create this graphic

### 3. Phone Screenshots ⚠️ REQUIRED (Minimum 2)
- **Size**: 1080x1920 px (portrait) or 1920x1080 px (landscape)
- **Format**: PNG or JPEG
- **Quantity**: 2-8 screenshots
- **Recommended screens**:
  1. Login screen with OTP
  2. Dashboard (Society/BMC/Dairy)
  3. Machines list
  4. Machine details
  5. Reports screen
  6. Profile screen

### 4. Tablet Screenshots (Optional)
- **Size**: 1920x1200 px or 2560x1600 px
- **Format**: PNG or JPEG

### 5. Promo Video (Optional)
- **Platform**: YouTube
- **Length**: 30 seconds - 2 minutes
- **Content**: App walkthrough

---

## 📝 Store Listing Text

### App Name
```
Poornasree Connect
```

### Short Description (80 characters max)
```
Dairy equipment management for Poornasree Cloud system
```

### Full Description (4000 characters max)
```
Poornasree Connect - Mobile Dairy Management

Secure mobile application for Poornasree Equipments Cloud system, designed for dairy equipment management and monitoring.

KEY FEATURES:
✓ Email-based OTP Authentication
✓ Role-Based Access Control
✓ Real-time Machine Monitoring
✓ Bluetooth Device Integration
✓ Offline Data Collection
✓ PDF Report Generation
✓ Multi-language Support (English, Hindi, Malayalam)

USER ROLES:
• Admin - Full system access
• Dairy - Dairy facility management
• BMC - Bulk Milk Cooling Center operations
• Society - Farmer society coordination
• Farmer - Individual farmer access

SECURITY:
• JWT-based authentication
• Secure token storage
• OTP verification
• Role-based permissions

TECHNICAL FEATURES:
• Material Design 3 UI
• Offline capability
• Bluetooth connectivity
• Real-time synchronization
• Professional PDF reports

Perfect for dairy cooperatives, milk collection centers, and farmer societies managing equipment and operations.

Requires active Poornasree Cloud account.
```

---

## 🎨 How to Create Screenshots

### Method 1: From Emulator/Device
1. Run app: `flutter run --release`
2. Navigate to each screen
3. Take screenshots (Power + Volume Down on Android)
4. Transfer to computer

### Method 2: Using Flutter DevTools
```bash
flutter run --release
# Open DevTools
# Use screenshot feature
```

### Method 3: Using ADB
```bash
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

---

## 🎨 Feature Graphic Design Tips

### Content to Include:
- App name: "Poornasree Connect"
- Tagline: "Dairy Equipment Management"
- App icon/logo
- Key visual (dairy/equipment theme)
- Brand colors: #10b981 (emerald green)

### Tools to Create:
- Canva (easiest)
- Figma
- Adobe Photoshop
- GIMP (free)

### Template Dimensions:
- Width: 1024 px
- Height: 500 px
- Safe zone: Keep important content in center 924x400 px

---

## ✅ Pre-Upload Checklist

- [ ] App icon (512x512) - Already done ✅
- [ ] Feature graphic (1024x500) - CREATE THIS
- [ ] 2-8 phone screenshots - TAKE THESE
- [ ] Short description written
- [ ] Full description written
- [ ] Privacy policy URL ready
- [ ] Support email configured
- [ ] Content rating completed
- [ ] Target audience selected
- [ ] App category selected (Business)

---

## 📁 Recommended Folder Structure

```
P:\Poornasree_Connect\store_assets\
├── icon\
│   └── app_icon_512.png
├── feature_graphic\
│   └── feature_graphic_1024x500.png
├── screenshots\
│   ├── phone\
│   │   ├── 01_login.png
│   │   ├── 02_dashboard.png
│   │   ├── 03_machines.png
│   │   ├── 04_machine_details.png
│   │   ├── 05_reports.png
│   │   └── 06_profile.png
│   └── tablet\
│       └── (optional)
└── promo\
    └── video_link.txt
```

---

## 🚀 Next Steps

1. **Create feature graphic** (1024x500)
2. **Take screenshots** (minimum 2, recommended 6)
3. **Organize in store_assets folder**
4. **Proceed with Play Console upload**

---

## 📞 Design Resources

- [Material Design Guidelines](https://m3.material.io/)
- [Play Store Asset Guidelines](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Canva Templates](https://www.canva.com/)
- [Figma Community](https://www.figma.com/community)
