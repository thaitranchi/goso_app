# 🪵 GỗSổ (GoSo App) - Phần Mềm Quản Lý Vựa Gỗ Nội Bộ

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20iPadOS-green.svg)
![Database](https://img.shields.io/badge/database-SQLite-orange.svg)
![Offline](https://img.shields.io/badge/network-100%25%20Offline-red.svg)

> **GỗSổ** là ứng dụng di động chạy độc lập (Local First), giúp các chủ vựa gỗ, xưởng xẻ tràm/cao su tính toán thể tích m³ gỗ tròn/xẻ, quản lý xuất nhập kho và ghi chép công nợ ngay tại bãi mà không cần kết nối Internet hay Server Cloud.

---

## 🚀 FEATURE HIGHLIGHTS (TÍNH NĂNG NỔI BẬT)

- 📏 **Tính m³ tự động ngoài bãi:**
  - *Gỗ tròn / Gỗ lóng:* Nhập đường kính $D$ (cm) và chiều dài $L$ (m) $\rightarrow$ Tự động tính $V = \pi \times (D / 200)^2 \times L$.
  - *Gỗ xẻ / Phôi:* Nhập Dày $\times$ Rộng $\times$ Dài $\times$ Số lượng thanh $\rightarrow$ Tự quy đổi m³.
- 🧾 **In phiếu xuất kho qua Bluetooth:** Kết nối trực tiếp với máy in nhiệt cầm tay khổ K80/K58 tại bãi gỗ mà không cần Wifi.
- 📒 **Sổ nợ gối đầu:** Theo dõi dư nợ chi tiết từng chủ xưởng mộc, tự cộng dồn dư nợ khi xuất hàng.
- 🔒 **An toàn 100% Offline (Local Database):** Toàn bộ dữ liệu nằm trên điện thoại/tablet, không lo rò rỉ hay mất kết nối mạng.
- 📦 **Sao lưu đơn giản:** Xuất/Nhập cơ sở dữ liệu SQLite hoặc xuất báo cáo ra file Excel để lưu trữ ngoài.

---

## 📂 PROJECT STRUCTURE (CẤU TRÚC THƯ MỤC FLUTTER)

```text
goso_app/
├── assets/
│   ├── icons/                  # Logo & Icon ứng dụng
│   └── fonts/                  # Font tiếng Việt tối ưu màn hình ngoài trời
├── lib/
│   ├── main.dart               # Điểm khởi chạy ứng dụng
│   ├── models/                 # Các Model dữ liệu
│   │   ├── khach_hang.dart
│   │   ├── go_item.dart
│   │   └── phieu_xuat.dart
│   ├── database/               # Quản lý SQLite nội bộ
│   │   └── db_helper.dart
│   ├── services/               # Dịch vụ kết nối máy in Bluetooth & Excel
│   │   ├── bluetooth_service.dart
│   │   └── excel_service.dart
│   └── views/                  # Giao diện người dùng (UI)
│       ├── home_screen.dart
│       ├── calculator_screen.dart
│       ├── phieu_xuat_screen.dart
│       ├── khach_hang_screen.dart
│       ├── so_no_screen.dart   # Sổ nợ & ghi thu từng khách
│       └── settings_screen.dart # Sao lưu / phục hồi / xuất Excel
├── pubspec.yaml                # Khai báo thư viện & dependencies
└── README.md

---

## 🛠 CÀI ĐẶT & CHẠY DỰ ÁN

```bash
flutter pub get                 # Cài thư viện
flutter run                     # Chạy thử trên máy đang kết nối
flutter test                    # Chạy unit test
flutter analyze                 # Kiểm tra lỗi static analysis
flutter build apk --release     # Đóng gói bản cài Android
flutter build web               # Bản web (SQLite chạy bằng WebAssembly)
```

### Ghi chú kỹ thuật

- **Yêu cầu:** Flutter 3.47+ / Dart 3.13+, Android SDK 36 (hoặc Xcode 15+ cho iOS).
- **Bluetooth:** dùng plugin `bluetooth_serial_android` (Bluetooth cổng SPP), nên tính năng in phiếu chỉ chạy trên Android. Trên iOS cần dùng SDK máy in tương thới với External accessory/MFi.
- **Máy in:** gửi mã ESC/POS 58mm, chữ được bỏ dấu tự động để tương thích font của máy in K58/K80.
- **Công thức m³** nằm trong `lib/utils/volume_calculator.dart` và có unit test đi kèm.
- **Sao lưu:** xuất file `.db` chia sẻ qua Zalo/Email; phục hồi bằng cách chọn lại file `.db` (ghi đè dữ liệu hiện tại).
- **Lưu ý build:** nếu gặp lỗi `Could not close incremental caches` khi build Android trên Windows, đã bật sẵn `kotlin.incremental=false` trong `android/gradle.properties`.

### Icon & màn hình khởi động (splash)

Icon và splash đã được sinh sẵn từ `assets/icons/icon.png` (1024x1024) và `assets/icons/branding.png`:
Android `mipmap-*`, `drawable-*/android12splash`, `values-v31/styles.xml` (nền `#2e7d32`), iOS `AppIcon.appiconset`, web `web/icons/` + `web/splash/`.

```bash
flutter pub run flutter_launcher_icons          # sinh lại icon
# Sinh lại splash (cần cài tạm vì plugin 2.4.4 làm hỏng AAR metadata của AGP mới):
flutter pub add --dev flutter_native_splash
flutter pub run flutter_native_splash:create
flutter pub remove flutter_native_splash
```

### Font tiếng Việt

App đang dùng font hệ thống (Roboto trên Android, SF Pro trên iOS) — cả hai đều hiển thị đầy đủ dấu tiếng Việt.
Nếu muốn font lớn dễ đọc ngoài trời (ví dụ Be Vietnam Pro), bỏ file `.ttf` vào `assets/fonts/` rồi khai báo `fonts:` trong `pubspec.yaml` và đặt `fontFamily` trong theme.
