# Google Play Store Upload Guide - Poornasree Connect

## 📋 Prerequisites Checklist

- [ ] Google Play Console account ($25 one-time fee)
- [ ] App signing key (keystore file)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (minimum 2, up to 8)
- [ ] Privacy policy URL
- [ ] App description and details

---

## 🔑 Step 1: Create Signing Key

### Generate Keystore File

```bash
cd P:\Poornasree_Connect\android\app

keytool -genkey -v -keystore poornasree-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias poornasree
```

**Important**: Save the passwords securely! You'll need:
- Keystore password
- Key password
- Alias: `poornasree`

### Create key.properties File

Create `P:\Poornasree_Connect\android\key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=poornasree
storeFile=poornasree-upload-key.jks
```

**⚠️ CRITICAL**: Add `key.properties` to `.gitignore` - NEVER commit this file!

---

## 🔧 Step 2: Configure Build Files

### Update android/app/build.gradle.kts

The signing configuration needs to be added. See the updated file below.

---

## 📱 Step 3: Build Release APK/AAB

### Build App Bundle (Recommended for Play Store)

```bash
cd P:\Poornasree_Connect
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

### Build APK (For testing)

```bash
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🎨 Step 4: Prepare Store Assets

### Required Graphics

1. **App Icon** (Already configured)
   - 512x512 PNG
   - No transparency
   - Location: Upload to Play Console

2. **Feature Graphic** (Required)
   - 1024x500 PNG
   - Showcases app on Play Store

3. **Screenshots** (Minimum 2)
   - Phone: 16:9 or 9:16 ratio
   - Recommended: 1080x1920 or 1920x1080
   - Take from different screens (Login, Dashboard, Machines)

4. **Promo Video** (Optional)
   - YouTube URL

---

## 📝 Step 5: App Store Listing

### App Details

**App Name**: Poornasree Connect

**Short Description** (80 chars max):
```
Dairy equipment management for Poornasree Cloud system
```

**Full Description** (4000 chars max):
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

### Categorization

- **Category**: Business
- **Tags**: dairy, equipment, management, agriculture, farming
- **Content Rating**: Everyone
- **Target Audience**: 18+

### Contact Details

- **Email**: your-support-email@domain.com
- **Website**: https://your-website.com
- **Privacy Policy**: https://your-website.com/privacy-policy

---

## 🚀 Step 6: Upload to Play Console

### Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click "Create app"
3. Fill in app details:
   - App name: Poornasree Connect
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free

### Complete Setup Checklist

#### 1. App Access
- [ ] All functionality available without restrictions
- [ ] Or provide test credentials if needed

#### 2. Ads
- [ ] Select "No, my app does not contain ads"

#### 3. Content Rating
- [ ] Complete questionnaire
- [ ] Select "Business" category

#### 4. Target Audience
- [ ] Age: 18 and over
- [ ] Appeal to children: No

#### 5. News App
- [ ] Select "No"

#### 6. COVID-19 Contact Tracing
- [ ] Select "No"

#### 7. Data Safety
- [ ] Complete data safety form
- [ ] Declare data collection:
   - Email address (for authentication)
   - User credentials (stored securely)
   - Machine data (business operations)

#### 8. Government Apps
- [ ] Select "No"

#### 9. Financial Features
- [ ] Select "No"

### Upload App Bundle

1. Go to "Production" → "Create new release"
2. Upload `app-release.aab`
3. Add release notes:

```
Version 1.0.0 - Initial Release

Features:
• Email-based OTP authentication
• Role-based dashboards
• Machine management
• Bluetooth device integration
• Offline data collection
• PDF report generation
• Multi-language support

Supported roles: Admin, Dairy, BMC, Society, Farmer
```

4. Review and rollout

---

## 🔒 Step 7: Privacy Policy (Required)

Create a privacy policy page and host it. Minimum content:

```markdown
# Privacy Policy - Poornasree Connect

Last updated: [DATE]

## Data Collection
We collect:
- Email address for authentication
- User credentials (encrypted)
- Machine operation data
- Location data (for machine tracking)

## Data Usage
- Authentication and authorization
- Service functionality
- Business operations

## Data Storage
- Secure cloud storage
- Encrypted transmission
- Local secure storage

## Third-Party Services
- None

## Contact
Email: your-email@domain.com
```

---

## ✅ Pre-Launch Checklist

- [ ] Keystore file created and backed up
- [ ] key.properties configured
- [ ] App bundle built successfully
- [ ] App tested on physical device
- [ ] All graphics prepared (icon, feature graphic, screenshots)
- [ ] Store listing completed
- [ ] Privacy policy published
- [ ] Content rating completed
- [ ] Data safety form completed
- [ ] Release notes written

---

## 🐛 Common Issues & Solutions

### Issue: "App not signed"
**Solution**: Ensure key.properties exists and build.gradle.kts is configured correctly

### Issue: "Version code already exists"
**Solution**: Increment version in pubspec.yaml (e.g., 1.0.0+2)

### Issue: "Missing permissions"
**Solution**: Check AndroidManifest.xml has all required permissions

### Issue: "App bundle too large"
**Solution**: Use `--split-per-abi` flag or enable ProGuard

---

## 📊 Post-Launch

### Monitor
- Crash reports in Play Console
- User reviews and ratings
- Installation statistics

### Update Process
1. Increment version in pubspec.yaml
2. Build new app bundle
3. Upload to Play Console
4. Add release notes
5. Rollout update

---

## 🔄 Version Management

Current version: `1.0.0+1`

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

To update:
```yaml
# pubspec.yaml
version: 1.0.1+2  # Increment for updates
```

---

## 📞 Support Resources

- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [App Signing Guide](https://developer.android.com/studio/publish/app-signing)

---

**Ready to publish? Follow steps 1-7 in order!**
