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
│       └── khach_hang_screen.dart
├── pubspec.yaml                # Khai báo thư viện & dependencies
└── README.md
