import 'dart:io';

import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/phieu_xuat.dart';
import '../utils/formatters.dart';

/// Kết nối máy in nhiệt K80/K58 qua Bluetooth Serial (SPP) và in phiếu xuất.
///
/// Chỉ hỗ trợ Android: iOS không mở API Bluetooth Classic cho ứng dụng thường.
class BluetoothPrintService {
  BluetoothPrintService._();

  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Chọn máy in đã ghép nối rồi kết nối. Trả về địa chỉ MAC hoặc null nếu hủy.
  static Future<String?> pickAndConnect(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!isSupported) {
      messenger.showSnackBar(
        const SnackBar(content: Text('In Bluetooth chỉ hỗ trợ trên Android.')),
      );
      return null;
    }

    final granted = await FlutterBluetoothSerial.ensurePermissions();
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cần cấp quyền Bluetooth để in phiếu.')),
      );
      return null;
    }

    var devices = await FlutterBluetoothSerial.getPairedDevices();
    if (devices.isEmpty) {
      // Máy in chưa ghép nối: thử quét các thiết bị lân cận.
      try {
        devices = await FlutterBluetoothSerial.scanDevices();
      } catch (_) {
        devices = const [];
      }
    }
    if (devices.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy máy in. Hãy bật Bluetooth và ghép nối máy in trước.',
          ),
        ),
      );
      return null;
    }

    if (!context.mounted) return null;
    final address = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Chọn máy in'),
        children: devices
            .map(
              (d) => SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(dialogContext, d['address'] ?? ''),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_outlined),
                  title: Text(
                    (d['name'] ?? '').trim().isEmpty
                        ? 'Máy in'
                        : d['name']!.trim(),
                  ),
                  subtitle: Text(d['address'] ?? ''),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (address == null || address.isEmpty) return null;

    final ok = await FlutterBluetoothSerial.connect(address);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không kết nối được máy in $address')),
      );
      return null;
    }
    return address;
  }

  /// Gửi nội dung phiếu xuất tới máy in theo chuẩn ESC/POS.
  ///
  /// Nội dung được bỏ dấu tiếng Việt vì máy in nhiệt giá rẻ không có bảng mã
  /// Unicode. Lệnh ESC/POS đều nằm trong dải ASCII nên truyền dưới dạng
  /// `String` vẫn ra đúng byte sau khi plugin encode.
  static Future<void> inPhieuXuat(
    PhieuXuat p, {
    String tenCuaHang = 'VỰA GỖ - GỖ SỔ',
    String diaChi = '',
    String soDienThoai = '',
  }) async {
    Future<void> raw(List<int> bytes) =>
        FlutterBluetoothSerial.write(String.fromCharCodes(bytes));

    Future<void> text(String s, {bool bold = false, bool large = false}) async {
      if (bold) await raw(const [_esc, 0x45, 0x01]);
      if (large) await raw(const [_esc, 0x21, 0x30]);
      await FlutterBluetoothSerial.write(Fmt.khongDau(s));
      if (large) await raw(const [_esc, 0x21, 0x00]);
      if (bold) await raw(const [_esc, 0x45, 0x00]);
    }

    const line = '--------------------------------\n';

    await raw(const [_esc, 0x40]); // ESC @ - khởi tạo máy in
    await raw(const [_esc, 0x61, 0x01]); // Căn giữa
    await text(tenCuaHang, bold: true, large: true);
    if (diaChi.isNotEmpty) await text('$diaChi\n');
    if (soDienThoai.isNotEmpty) await text('DT: $soDienThoai\n');
    await raw(const [_esc, 0x61, 0x00]); // Căn trái
    await text(line);
    await text('SO PHIEU: ${p.soPhieu}\n');
    if (p.ngayXuat != null) {
      await text('NGAY: ${Fmt.date(p.ngayXuat!)}\n');
    }
    await text('KHACH HANG: ${p.tenKhachHang}\n');
    if (p.dienThoaiKhachHang.isNotEmpty) {
      await text('DT: ${p.dienThoaiKhachHang}\n');
    }
    if (p.diaChiKhachHang.isNotEmpty) {
      await text('DC: ${p.diaChiKhachHang}\n');
    }
    await text(line);

    for (final it in p.items) {
      await text(it.loaiGo.label);
      await text(
        '  ${it.moTaKichThuoc} x ${it.soLuong} = ${Fmt.m3Print(it.theTichM3)}\n',
      );
      await text('  ${Fmt.money(it.donGia)}/m3 = ${Fmt.money(it.thanhTien)}\n');
    }
    await text(line);

    await text('TONG m3: ${Fmt.m3Print(p.tongTheTichM3)}\n', bold: true);
    await text('TONG TIEN: ${Fmt.money(p.tongTien)}\n', bold: true);
    await text('DA THANH TOAN: ${Fmt.money(p.daThanhToan)}\n');
    await text('HINH THUC TT: ${Fmt.khongDau(p.hinhThucThanhToan.label)}\n');
    await text('CON NO: ${Fmt.money(p.conNo)}\n', bold: true);

    if (p.ghiChu.isNotEmpty) {
      await text(line);
      await text('GHI CHU: ${p.ghiChu}\n');
    }

    await text('\n\n\n');
    await raw(const [_gs, 0x56, 0x41, 0x10]); // Cắt giấy
    await FlutterBluetoothSerial.disconnect();
  }
}
