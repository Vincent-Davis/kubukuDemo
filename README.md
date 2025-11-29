# KuBuku - Smart Business Transaction Management App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

KuBuku is a comprehensive Flutter mobile application designed to help small and medium businesses manage their daily transactions, inventory, and business analytics with AI-powered features.

## 🚀 Features

### 🔐 Authentication
- Secure user registration and login
- JWT-based authentication with token persistence
- User profile management
- Automatic session handling

### 📊 Transaction Management
- AI-powered transaction parsing from natural language
- Smart transaction validation with auto-correction
- Real-time transaction recording
- Comprehensive transaction history

### 🏪 Inventory Management
- Product catalog with detailed information
- Stock tracking and inventory updates
- Product form with image support
- Real-time stock synchronization

### 📈 Business Analytics
- Daily and weekly revenue statistics
- Premium reports with advanced analytics
- AI-generated business insights
- Performance metrics and trends

### 🤖 AI Features
- Smart chat assistant for business queries
- Natural language transaction processing
- Business opportunity recommendations
- Intelligent transaction type detection

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.9.2 or higher
- **Dart SDK**: Version 3.9.2 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **Git** for version control

### Check Your Environment

```bash
flutter doctor
```

## 🔧 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/anthef/kubuku-mobile.git
cd kubuku-mobile
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Development Environment

#### Android Setup
1. Open Android Studio
2. Install Android SDK (API level 21 or higher)
3. Create an Android Virtual Device (AVD) or connect a physical device

#### iOS Setup (macOS only)
1. Install Xcode from App Store
2. Open Xcode and agree to license
3. Install iOS Simulator or connect a physical iOS device

### 4. Run the Application

#### For Android:
```bash
flutter run -d android
```

#### For iOS:
```bash
flutter run -d ios
```

#### For Web (Development):
```bash
flutter run -d chrome
```

## 🏗️ Build for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Google Play)
```bash
flutter build appbundle --release
```

### iOS (macOS only)
```bash
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app_module/              # Data models and structures
├── controller/              # State management controllers
├── models/                  # Data models
├── presentation/            # Authentication UI
├── screens/                 # App screens
├── services/                # API and business logic services
├── theme/                   # App theming and styling
└── widgets/                 # Reusable UI components
```