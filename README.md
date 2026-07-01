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
  - Kelas : TI-SE 23 SH

## Demo Video

Lihat video demo aplikasi untuk melihat semua fitur dalam aksi!

**[Watch Full Demo on YouTube](https://youtu.be/3T_PeOEtE7w)**

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
https://github.com/Frientia/project_uas_my-catalog-be.git
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
│   ├── constants/        # Konstanta API dan pengaturan umum
│   ├── providers/        # Provider global seperti ThemeProvider
│   ├── routes/           # AppRouter dan AuthGuard
│   ├── services/         # Dio client, secure storage, pay service, biometric
│   ├── theme/            # Tema terang/gelap
│   └── widget/           # Widget umum dan lock screen
├── features/
│   ├── auth/             # Login, register, verify email
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── widgets/
│   ├── cart/             # Keranjang belanja
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── repositories/
│   ├── dashboard/        # Dashboard dan profil pengguna
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── order/            # Checkout, pesanan, payment flow
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
├── firebase_options.dart
├── flutter_biometric_kit.dart
├── main.dart
└── src/                 # Biometric service and exceptions
```

## 1. Authentication Flow (Akses Masuk & Keamanan)

Alur ini memastikan hanya pengguna yang memiliki token (JWT/Firebase) yang sah yang bisa masuk ke dalam aplikasi.

```text
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

## 2. Shopping & Order Creation Flow (Pembuatan Pesanan)

Ini adalah alur saat pengguna berbelanja di dalam aplikasi Toko Buku hingga tagihannya terbentuk di *database*.

```text
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

## 3. App-to-App Bridge Flow (Lompatan Deeplink Keluar)

Bagian paling krusial di mana Toko Buku memanggil E-Money untuk meminta pembayaran.

```text
1. Payment Pending Page (Toko Buku)
   (Membentuk URL skema khusus: bookpay://pay?merchant_id=...&amount=...&callback=...)
   ↓
2. URL Launcher / OS Android
   (Mengeksekusi intent, OS Android membuka aplikasi E-Money BookStore)
   ↓
3. Splash Screen (BookPay)
   (Sistem DeeplinkService menangkap URL tagihan dan menyimpannya di memori, sambil mengecek status Login user E-Money)
   ↓
4. Payment Confirmation Page (BookPay)
   (Aplikasi membaca memori tagihan dan menampilkan UI konfirmasi nominal ke pengguna)

```

## 4. Transaction Execution Flow (Proses Bayar E-Money)

Alur di dalam aplikasi E-Money saat memvalidasi otorisasi dan memotong saldo.

```text
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

## 5. Callback & Finalization Flow (Kembali ke Toko Buku)

Alur saat E-Money menendang pengguna kembali ke Toko Buku untuk menyelesaikan transaksi.

```text
1. OS Android
   (Mengeksekusi intent callback, membuka paksa kembali jendela Toko Buku)
   ↓
2. BookStorePayService (Toko Buku)
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

## 6. Logout Flow (Penutupan Sesi)

Alur ketika pengguna ingin mengakhiri sesinya dengan aman.

```text
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
```dart
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
```
## Products Endpoints
```dart
- `POST /api/products` - Menambahkan produk baru
- `GET /api/products` - Mendapatkan daftar produk
- `GET /api/profile` - Mendapatkan data profil user
- `GET /api/cart` - Mendapatkan data keranjang belanja
- `GET /api/orders` - Mendapatkan daftar pesanan
- `POST /api/orders/checkout` - Melakukan proses checkout

```
## Preview Tampilan Aplikasi

### Alur Autentikasi
| Tampilan 1 | Tampilan 2 | Tampilan 3 |
| --- | --- | --- |
| ![Login](https://github.com/user-attachments/assets/a008d82f-f217-40db-8933-f895f56a155f) | ![Register](https://github.com/user-attachments/assets/db175f36-2092-4537-bd2e-30af8d664e89) | ![Lupa Password](https://github.com/user-attachments/assets/9c95bd21-e306-4d9a-a6f7-b3637a2c110c) |
| Halaman Login | Halaman Register | Lupa Password |

---

### Beranda & Belanja
| Tampilan 1 | Tampilan 2 | Tampilan 3 |
| --- | --- | --- |
| ![Dashboard](https://github.com/user-attachments/assets/51a4409c-6351-4bcf-9286-c183c3d2034e) | ![Keranjang](https://github.com/user-attachments/assets/5b4a755e-1e48-4ea4-9c2c-3114b744d45d) | ![Checkout](https://github.com/user-attachments/assets/a638a4c3-a9d2-4bf0-a3ed-cf8b34110c55) |
| Dashboard / Utama | Keranjang Belanja | Checkout Pesanan |

---

### Transaksi & Pembayaran
| Tampilan 1 | Tampilan 2 | Tampilan 3 |
| --- | --- | --- |
| ![Selesaikan Pembayaran](https://github.com/user-attachments/assets/25daa7b9-301d-4b06-afd5-3ad2fbf4aac0) | ![PIN](https://github.com/user-attachments/assets/b07863f5-1228-4b65-9e16-4d7c26ba2558) | ![Pembayaran Sukses](https://github.com/user-attachments/assets/11b52eeb-9a67-4446-a22f-2153d48a6912) |
| Selesaikan Pembayaran | Input PIN Keamanan | Pembayaran Sukses |

---

### Status & Riwayat
| Tampilan 1 | Tampilan 2 | Tampilan 3 |
| --- | --- | --- |
| ![Pesanan Berhasil](https://github.com/user-attachments/assets/071ba1dd-8549-4b7c-95ec-bd4b4edacd7b) | ![Riwayat](https://github.com/user-attachments/assets/b963a846-7a3d-4469-a3e6-41334e88d68a) | ![Deeplink](https://github.com/user-attachments/assets/4063cb31-40a0-4c5b-a56c-afd299528d54) |
| Pesanan Berhasil | Riwayat Transaksi | Uji Coba Deeplink |

---

### Keamanan & Fitur Lainnya 
| Tampilan 1 | Tampilan 2 | Tampilan 3 |
| --- | --- | --- |
| ![Authentikator](https://github.com/user-attachments/assets/772fa7f0-dd5a-4ef4-89a4-b4ab6c048f97) | ![Akses Terbatas](https://github.com/user-attachments/assets/191da828-8e5b-434e-96e9-72bd44a4b4a0) | ![About](https://github.com/user-attachments/assets/b77522d9-18bf-403c-8f62-08515fe5dd81) |
| Setup Authenticator (2FA) | Akses Terbatas | Tentang Aplikasi |

---
```
```
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
