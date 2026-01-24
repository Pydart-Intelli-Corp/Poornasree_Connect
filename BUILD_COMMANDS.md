# Poornasree Connect - Play Store Build Commands

## Step 1: Generate Keystore (One-time only)
```bash
cd android\app
keytool -genkey -v -keystore poornasree-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias poornasree
```

## Step 2: Create key.properties
Copy `android\key.properties.template` to `android\key.properties` and fill in your passwords

## Step 3: Build App Bundle (for Play Store)
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
Output: `build\app\outputs\bundle\release\app-release.aab`

## Step 4: Build APK (for testing)
```bash
flutter build apk --release
```
Output: `build\app\outputs\flutter-apk\app-release.apk`

## Step 5: Test Release Build
```bash
flutter install --release
```

## Verify Build
```bash
# Check version
flutter --version

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment for updates
```

## Common Issues

### Issue: Keystore not found
**Solution**: Ensure `poornasree-upload-key.jks` is in `android\app\` directory

### Issue: Build fails
**Solution**: 
```bash
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
flutter build appbundle --release
```

### Issue: Version conflict
**Solution**: Increment version number in pubspec.yaml

## File Locations
- Keystore: `android\app\poornasree-upload-key.jks`
- Key properties: `android\key.properties`
- App Bundle: `build\app\outputs\bundle\release\app-release.aab`
- APK: `build\app\outputs\flutter-apk\app-release.apk`
