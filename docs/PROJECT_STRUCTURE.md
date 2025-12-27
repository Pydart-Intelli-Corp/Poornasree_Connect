# Poornasree Connect - Project Structure

This document outlines the organized folder structure of the Poornasree Connect Flutter application.

## Directory Structure

```
lib/
├── main.dart                    # App entry point
├── index.dart                   # Main library exports
│
├── models/                      # Data models
│   ├── models.dart             # Barrel file
│   └── entities/               # Domain entities
│       ├── entities.dart       # Barrel file
│       └── user.dart           # User model
│
├── providers/                   # State management
│   ├── providers.dart          # Barrel file
│   └── auth/                   # Authentication providers
│       ├── auth.dart           # Barrel file
│       └── auth_provider.dart  # Auth state management
│
├── services/                    # Business logic layer
│   ├── services.dart           # Barrel file
│   ├── api/                    # API services
│   │   ├── api.dart            # Barrel file
│   │   ├── auth_service.dart   # Authentication API
│   │   └── dashboard_service.dart # Dashboard API
│   └── data/                   # Data services (future)
│
├── utils/                       # Utilities and configuration
│   ├── utils.dart              # Barrel file
│   ├── config/                 # Configuration files
│   │   ├── config.dart         # Barrel file
│   │   ├── api_config.dart     # API configuration
│   │   └── theme.dart          # App theme
│   └── constants/              # App constants
│       └── constants.dart      # Constants and messages
│
├── widgets/                     # Reusable UI components
│   ├── widgets.dart            # Barrel file
│   ├── ui/                     # Core UI components
│   │   ├── ui.dart             # Barrel file
│   │   ├── custom_button.dart  # Button component
│   │   ├── custom_text_field.dart # Text field component
│   │   ├── custom_snackbar.dart # Snackbar component
│   │   ├── flower_spinner.dart  # Loading spinner
│   │   ├── page_transition.dart # Page transitions
│   │   └── machine_card.dart   # Machine display card
│   └── screens/                # Screen-specific widgets
│       ├── screens.dart        # Barrel file
│       └── splash_screen.dart  # Splash screen widget
│
└── screens/                     # Application screens
    ├── screens.dart            # Barrel file
    ├── auth/                   # Authentication screens
    │   ├── auth.dart           # Barrel file
    │   ├── login_screen.dart   # Login interface
    │   └── otp_screen.dart     # OTP verification
    └── dashboard/              # Dashboard screens
        ├── dashboard.dart      # Barrel file
        ├── dashboard_screen.dart # Main dashboard
        └── farmer_dashboard_screen.dart # Farmer-specific dashboard
```

## Organization Principles

### 1. Barrel Files
Each directory contains a barrel file (e.g., `auth.dart`, `config.dart`) that exports all files in that directory, simplifying imports.

### 2. Hierarchical Imports
- Use relative imports within the same feature
- Use barrel imports for cross-feature dependencies
- Example: `import '../../utils/utils.dart';` instead of specific file imports

### 3. Feature-Based Organization
- Group related functionality together
- Separate concerns (UI, business logic, data)
- Keep dependencies unidirectional

### 4. Naming Conventions
- Use lowercase with underscores for file names
- Use descriptive names that indicate purpose
- Barrel files match their directory name

## Import Guidelines

### Good Practices
```dart
// Use barrel imports
import '../../utils/utils.dart';
import '../../providers/providers.dart';

// Keep imports organized
import 'package:flutter/material.dart';     // Flutter framework
import 'package:provider/provider.dart';   // External packages
import '../../utils/utils.dart';           // Internal utilities
import 'widgets.dart';                     // Local widgets
```

### Avoid
```dart
// Don't use deep imports when barrel exists
import '../../utils/config/theme.dart';
import '../../providers/auth/auth_provider.dart';
```

## Benefits of This Structure

1. **Maintainability**: Easy to locate and modify related code
2. **Scalability**: Simple to add new features without restructuring
3. **Clarity**: Clear separation of concerns and responsibilities
4. **Reusability**: Components are organized for easy reuse
5. **Testing**: Structure supports unit and integration testing

## Future Considerations

- Add `core/` directory for app-wide utilities
- Create `features/` directory for large feature modules
- Add `l10n/` for internationalization
- Include `data/` layer for repository pattern implementation