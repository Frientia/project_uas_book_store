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

  ##  Project UAS
  - Nim : 1123150114
  - Nama : Muhamad Yajid Rizky
  - Mata Kuliah : Aplikasi Mobile
  - Kelas : TI-SE 23 M 

## Demo Video

Lihat video demo aplikasi untuk melihat semua fitur dalam aksi!

**[Watch Full Demo on YouTube]()**

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
git clone https://github.com/Frientia/project_uas_book_store.git
cd project_uas_book_store
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
git clone https://github.com/Frientia/project_uas_my-catalog-be.git
cd project_uas_my-catalog-be
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

### 1. Authentication Flow (Akses Masuk & Keamanan)

Alur ini memastikan hanya pengguna yang memiliki token (JWT/Firebase) yang sah yang bisa masuk ke dalam aplikasi.

```
1. Splash Screen
   (Sistem membaca memori HP untuk mencari Token sesi sebelumnya)
   ↓
2. Auth Guard / BLoC Checker
   (Memvalidasi apakah token ada dan email sudah terverifikasi)
   ↓
   ├─ Jika Kosong/Tidak Valid ➔ 3a. Login / Register Screen
   ├─ Jika Belum Verifikasi   ➔ 3b. Verify Email Screen
   └─ Jika Valid & Sukses     ➔ 3c. Home Screen (Dashboard)

```

### 2. Shopping & Order Creation Flow (Pembuatan Pesanan)

Ini adalah alur saat pengguna berbelanja di dalam aplikasi Toko Buku hingga tagihannya terbentuk di *database*.

```
1. Home Screen (Dashboard)
   (Mencari dan memilih buku, misal: Atomic Habits)
   ↓
2. Cart Page
   (Mengecek daftar belanjaan dan total harga)
   ↓
3. Checkout Page
   (Mengisi alamat pengiriman dan memilih metode pembayaran 'BookPay')
   ↓
4. Order Provider (Backend API Call)
   (Aplikasi menembak API untuk membuat pesanan dengan status 'pending')
   ↓
5. Payment Pending Page
   (Menampilkan UI Menunggu, dan memulai Polling 5 detik sekali ke Server)

```

### 3. App-to-App Bridge Flow (Lompatan Deeplink Keluar)

Bagian paling krusial di mana Toko Buku memanggil E-Money untuk meminta pembayaran.

```
1. Payment Pending Page (Toko Buku)
   (Membentuk URL skema khusus: bookpay://pay?merchant_id=...&amount=...&callback=...)
   ↓
2. URL Launcher / OS Android
   (Mengeksekusi intent, OS Android membuka aplikasi Dompet Kampus)
   ↓
3. Splash Screen (BookPay)
   (Sistem DeeplinkService menangkap URL tagihan dan menyimpannya di memori, sambil mengecek status Login user E-Money)
   ↓
4. Payment Confirmation Page (BookPay)
   (Aplikasi membaca memori tagihan dan menampilkan UI konfirmasi nominal ke pengguna)

```

### 4. Transaction Execution Flow (Proses Bayar E-Money)

Alur di dalam aplikasi E-Money saat memvalidasi otorisasi dan memotong saldo.

```
1. Payment Confirmation Page (BookPay)
   (Pengguna menekan tombol "Bayar")
   ↓
2. OTP / 2FA Verification
   (Pengguna memasukkan kode keamanan dari Firebase/Email/TOTP)
   ↓
3. Payment Bloc (Backend API Call)
   (Menembak API E-Money untuk memotong saldo. Jika gagal ➔ Notifikasi Error)
   ↓
4. Payment Success Listener
   (Menerima respons 200 OK dari Server)
   ↓
5. Callback Execution
   (Mengeksekusi URL titipan: bookstore://payment-callback?status=success&reference=INV-...)

```

### 5. Callback & Finalization Flow (Kembali ke Toko Buku)

Alur saat E-Money menendang pengguna kembali ke Toko Buku untuk menyelesaikan transaksi.

```
1. OS Android
   (Mengeksekusi intent callback, membuka paksa kembali jendela Toko Buku)
   ↓
2. GlobalInstitutePayService (Toko Buku)
   (Menangkap parameter status=success dari URL yang masuk)
   ↓
3. Payment Pending Page
   (Mencocokkan nomor Invoice. Jika cocok ➔ Hentikan Polling 5 detik)
   ↓
4. Order Provider (Update Status)
   (Menembak API untuk mengubah status pesanan dari 'pending' menjadi 'paid')
   ↓
5. Order Success Page
   (Menampilkan struk bukti pembelian berhasil)

```

### 6. Logout Flow (Penutupan Sesi)

Alur ketika pengguna ingin mengakhiri sesinya dengan aman.

```
1. Home Screen (Dashboard)
   ↓
2. Profile Page
   (Pengguna menekan tombol "Keluar / Logout")
   ↓
3. Auth Provider / Bloc
   (Menghapus seluruh Token Firebase/JWT dari penyimpanan lokal HP)
   ↓
4. Auth Guard Listener
   (Otomatis mendeteksi state berubah menjadi Unauthenticated)
   ↓
5. Login Screen
   (Mengembalikan pengguna ke titik awal dan menutup akses menu utama)

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
