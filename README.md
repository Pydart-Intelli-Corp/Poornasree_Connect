# Poornasree Connect Mobile App

Flutter mobile application for Poornasree Equipments Cloud system.

## Features

- **Email-based OTP Login**: Secure authentication using email and OTP
- **Role-Based Access**: Different dashboards for Admin, Dairy, BMC, Society, and Farmer roles
- **Machines Management**: View and manage machines based on user role
- **Material Design 3**: Modern UI matching the web application theme
- **Secure Storage**: Token and user data stored securely

## User Roles

| Role | Dashboard Features |
|------|-------------------|
| **Society** | View machines in their society |
| **BMC** | View all machines under their BMC |
| **Dairy** | View all machines under their dairy |
| **Farmer** | Placeholder dashboard (no machine access) |

## Setup

### Prerequisites
- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile deployment)
- Backend API running at configured URL

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Configure API endpoint in `lib/utils/api_config.dart`:
```dart
static const String baseUrl = 'http://your-backend-url:3000';
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── user_model.dart
├── providers/                # State management
│   └── auth_provider.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── otp_screen.dart
│   ├── dashboard_screen.dart
│   └── farmer_dashboard_screen.dart
├── services/                 # API services
│   ├── auth_service.dart
│   └── dashboard_service.dart
├── utils/                    # Utilities
│   ├── theme.dart
│   └── api_config.dart
└── widgets/                  # Reusable widgets
    └── machine_card.dart
```

## API Endpoints

- `POST /api/external/auth/send-otp` - Send OTP to email
- `POST /api/external/auth/verify-otp` - Verify OTP and login
- `GET /api/external/auth/dashboard` - Get dashboard data
- `GET /api/external/auth/machines` - Get machines list
- `POST /api/external/auth/logout` - Logout user

## Theme

The app uses Material Design 3 with an emerald green color scheme matching the web application:
- Primary Color: #10b981 (Emerald Green)
- Secondary Color: #14b8a6 (Teal)
- Accent Colors: Blue, Purple, Amber

## Development

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

### Running Tests
```bash
flutter test
```

## Security

- Tokens stored securely using `flutter_secure_storage`
- OTP expires in 10 minutes
- Email validation before OTP request
- JWT-based authentication

## License

Copyright © 2025 Poornasree Equipments
