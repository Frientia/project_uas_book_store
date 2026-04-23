# Book Store App - Flutter Application

<div align="center">
<url>
  <img width="300" height="301" alt="Institut Teknologi dan Bisnis Bina Sarana Global" src="https://github.com/user-attachments/assets/1e84f66a-135b-4cf2-b07a-b2a9098ce119" width="200"/>
  </div>
<div align="center">
Institut Teknologi dan Bisnis Bina Sarana Global <br>
FAKULTAS TEKNOLOGI INFORMASI & KOMUNIKASI 
<br>
https://global.ac.id/
  </div>

  ##  Project UTS
  - Nim : 1123150114
  - Nama : Muhamad Yajid Rizky
  - Mata Kuliah : Aplikasi Mobile
  - Kelas : TI-SE 23 M 

## Demo Video

Lihat video demo aplikasi untuk melihat semua fitur dalam aksi!

**[Watch Full Demo on YouTube](https://youtu.be/wDitUemQItw)**

Alternative link: **[Google Drive Demo]()**

## Built With

- **[Flutter](https://flutter.dev/)** - UI Framework
- **[Dart](https://dart.dev/)** - Programming Language
- **[Firebase](https://firebase.google.com/)** - Authentication
- **[Golang](https://go.dev/)** - Backend Service
- **[MySql](http://mysql.com/)** - Backend Database
- **[Provider](https://pub.dev/packages/provider)** - State Management


## Getting Started

### Prerequisites

Pastikan Anda sudah menginstall:
- Flutter SDK (3.16.0 or higher)
- Go (Golang): Versi stabil terbaru untuk kebutuhan backend.
- MySQL: Sebagai sistem manajemen basis data relasional.
- Dart SDK (3.2.0 or higher)
- Android Studio / VS Code
- Git

### Installation Flutter

1. Clone repository
```bash
git clone https://github.com/Frientia/project_mobile_UTS.git
cd project_mobile_UTS
```

2. Install dependencies
```bash
flutter pub get
```

3. Setup Firebase
```bash
# Download google-services.json dari Firebase Console
# Place in android/app/
cp path/to/google-services.json android/app/
```

5. Run aplikasi
```bash
flutter run
```

### Installation Golang (Backend)

0. Link Backend Repo
```bash
https://github.com/Frientia/my-firebase-backend.git
```
1. Clone repository
```bash
git clone https://github.com/Frientia/my-firebase-backend.git
cd my-firebase-backend
```

2. Install dependencies
```bash
go mod tidy
```

3. Setup Firebase
```bash
# Download adminSDk dari Firebase
# Place in root project
cp path/to/firebase-service-account.json
```
4. Setup local server
```bash
# Copy .env.example secara manual, atau
cp .env.example .env
# pada terminal
```

### Build APK 

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK by ABI
flutter build apk --split-per-abi
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # (Baru) Tempat simpan String, warna, atau ukuran statis
│   ├── routes/             # (Pindahkan logika navigasi dari main.dart ke sini)
│   ├── services/           # (Baru) Logic Firebase Auth
│   └── theme/              # (Baru) Tema warna aplikasi
│
├── features/
│   ├── auth/               # Modul Login & Register
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/      # login_page.dart, register_page.dart
│   │       └── widgets/    # auth_header.dart, custom_button.dart dll
│   │
│   ├── dashboard/          # Modul Utama (Dashboard)
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── pages/      # dashboard.dart
│   
├── firebase_options.dart
└── main.dart

```

## Authentication Flow

```
1. Splash Loading (Auto-login check)
   ↓
2. Login Screen / Register Screen
   ↓
3. Home Screen (Dashboard)
```


## 📝 API Documentation

## Authentication Endpoints
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.



## Acknowledgments

- [Flutter Community](https://flutter.dev/community) - For amazing packages
- [Firebase](https://firebase.google.com/) - For backend services
- [Flaticon](https://www.flaticon.com/) - For app icons
- [Unsplash](https://unsplash.com/) - For placeholder images



---
<div align="center">
  <p>© 2026 Book Store App. All rights reserved.</p>
</div>
