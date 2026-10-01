import 'package:flutter_test/flutter_test.dart';

import 'package:goso_app/models/go_item.dart';
import 'package:goso_app/models/khach_hang.dart';
import 'package:goso_app/models/phieu_xuat.dart';
import 'package:goso_app/utils/volume_calculator.dart';

void main() {
  group('GoItem', () {
    test('GoItem.tron tính thành tiền = m3 * đơn giá', () {
      final t = VolumeCalculator.tron(
        duongKinhCm: 20,
        chieuDaiM: 4,
        soLuong: 2,
      );
      final item = GoItem.tron(
        duongKinhCm: 20,
        chieuDaiM: 4,
        soLuong: 2,
        theTichM3: t.tongTheTich,
        donGia: 1_000_000,
      );
      expect(item.loaiGo, LoaiGo.tron);
      expect(item.laGoiTron, isTrue);
      expect(item.theTichM3, closeTo(0.251327412, 1e-8));
      expect(item.thanhTien, closeTo(t.tongTheTich * 1_000_000, 1e-6));
      expect(item.moTaKichThuoc, 'D20 x L4m');
    });

    test('GoItem.xa mô tả kích thước đúng', () {
      final t = VolumeCalculator.xa(
        dayCm: 5,
        rongCm: 20,
        chieuDaiM: 4,
        soLuong: 1,
      );
      final item = GoItem.xa(
        dayCm: 5,
        rongCm: 20,
        chieuDaiM: 4,
        soLuong: 1,
        theTichM3: t.tongTheTich,
        donGia: 2_000_000,
      );
      expect(item.laGoiTron, isFalse);
      expect(item.moTaKichThuoc, '5 x 20 x L4m');
      expect(item.thanhTien, closeTo(80_000, 1e-6));
    });

    test('round-trip qua map giữ nguyên dữ liệu', () {
      final item = GoItem.tron(
        id: 7,
        phieuXuatId: 3,
        duongKinhCm: 25,
        chieuDaiM: 5,
        soLuong: 4,
        theTichM3: 2.5,
        donGia: 900_000,
      );
      final back = GoItem.fromMap(item.toMap());
      expect(back.id, 7);
      expect(back.phieuXuatId, 3);
      expect(back.loaiGo, LoaiGo.tron);
      expect(back.duongKinhCm, 25);
      expect(back.chieuDaiM, 5);
      expect(back.soLuong, 4);
      expect(back.theTichM3, 2.5);
      expect(back.thanhTien, closeTo(2.5 * 900_000, 1e-6));
    });
  });

  group('KhachHang', () {
    test('round-trip qua map', () {
      final kh = KhachHang(
        id: 1,
        ten: 'Xưởng Minh Phát',
        dienThoai: '0901234567',
        diaChi: 'Đồng Nai',
        ghiChu: 'trả cuối tháng',
        duNo: 5_000_000,
      );
      final back = KhachHang.fromMap(kh.toMap());
      expect(back.id, 1);
      expect(back.ten, 'Xưởng Minh Phát');
      expect(back.dienThoai, '0901234567');
      expect(back.diaChi, 'Đồng Nai');
      expect(back.ghiChu, 'trả cuối tháng');
      // du_no là cột tính toán, fromMap chỉ lấy khi truy vấn có alias du_no.
      expect(
        KhachHang.fromMap({...kh.toMap(), 'du_no': 5_000_000}).coDuNo,
        isTrue,
      );
    });
  });

  group('PhieuXuat', () {
    test('round-trip qua map kèm thông tin khách', () {
      final px = PhieuXuat(
        id: 9,
        khachHangId: 2,
        soPhieu: 'PX20260101-0930',
        ngayXuat: DateTime(2026, 1, 1, 9, 30),
        tongTheTichM3: 3.5,
        tongTien: 7_000_000,
        daThanhToan: 2_000_000,
        conNo: 5_000_000,
        ghiChu: 'giao tại bãi',
      );
      final back = PhieuXuat.fromMap(
        px.toMap(),
        khachHang: KhachHang(
          id: 2,
          ten: 'Chủ xưởng Hùng',
          dienThoai: '0987654321',
          diaChi: 'Bình Phước',
        ),
      );
      expect(back.id, 9);
      expect(back.khachHangId, 2);
      expect(back.soPhieu, 'PX20260101-0930');
      expect(back.ngayXuat, DateTime(2026, 1, 1, 9, 30));
      expect(back.tenKhachHang, 'Chủ xưởng Hùng');
      expect(back.dienThoaiKhachHang, '0987654321');
      expect(back.tongTheTichM3, 3.5);
      expect(back.daThanhToan, 2_000_000);
      expect(back.conNo, 5_000_000);
      expect(back.ghiChu, 'giao tại bãi');
    });
  });
}
