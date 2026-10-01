import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/go_item.dart';
import '../models/phieu_xuat.dart';
import '../utils/formatters.dart';

/// Xuất báo cáo Excel (.xlsx) rồi chia sẻ qua hệ thống.
class ExcelService {
  ExcelService._();

  static const _sheetName = 'PhieuXuat';

  static void _set(Sheet sheet, int row, int col, CellValue? value) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      value,
    );
  }

  static CellValue? _text(String? v) => v == null ? null : TextCellValue(v);

  static CellValue? _num(num? v) {
    if (v == null) return null;
    if (v is int) return IntCellValue(v);
    if (v == v.roundToDouble()) return IntCellValue(v.toInt());
    return DoubleCellValue(v.toDouble());
  }

  /// Danh sách phiếu xuất.
  static Future<void> exportPhieuXuats(List<PhieuXuat> list) async {
    final excel = Excel.createExcel();
    final sheet = excel[_sheetName];

    final header = [
      'STT',
      'Số phiếu',
      'Ngày xuất',
      'Khách hàng',
      'Điện thoại',
      'Địa chỉ',
      'Tổng m³',
      'Tổng tiền (đ)',
      'Đã TT (đ)',
      'Còn nợ (đ)',
      'Hình thức TT',
      'Ghi chú',
    ];
    for (int c = 0; c < header.length; c++) {
      _set(sheet, 0, c, TextCellValue(header[c]));
    }

    for (int i = 0; i < list.length; i++) {
      final p = list[i];
      final r = i + 1;
      _set(sheet, r, 0, IntCellValue(i + 1));
      _set(sheet, r, 1, _text(p.soPhieu));
      _set(sheet, r, 2, _text(p.ngayXuat == null ? '' : Fmt.date(p.ngayXuat!)));
      _set(sheet, r, 3, _text(p.tenKhachHang));
      _set(sheet, r, 4, _text(p.dienThoaiKhachHang));
      _set(sheet, r, 5, _text(p.diaChiKhachHang));
      _set(sheet, r, 6, _num(p.tongTheTichM3));
      _set(sheet, r, 7, _num(p.tongTien));
      _set(sheet, r, 8, _num(p.daThanhToan));
      _set(sheet, r, 9, _num(p.conNo));
      _set(sheet, r, 10, _text(p.hinhThucThanhToan.label));
      _set(sheet, r, 11, _text(p.ghiChu));
    }

    for (int c = 0; c < header.length; c++) {
      sheet.setColumnAutoFit(c);
    }

    final name = 'go_so_phieu_xuat_${Fmt.tenFile.format(DateTime.now())}.xlsx';
    await _save(excel, name);
  }

  /// Chi tiết một phiếu xuất.
  static Future<void> exportPhieuXuatChiTiet(PhieuXuat p) async {
    final excel = Excel.createExcel();
    final sheet = excel[_sheetName];

    int r = 0;
    void info(String label, String? value) {
      _set(sheet, r, 0, TextCellValue(label));
      _set(sheet, r, 1, _text(value));
      r++;
    }

    info('Số phiếu', p.soPhieu);
    info('Ngày xuất', p.ngayXuat == null ? '' : Fmt.date(p.ngayXuat!));
    info('Khách hàng', p.tenKhachHang);
    info('Điện thoại', p.dienThoaiKhachHang);
    info('Địa chỉ', p.diaChiKhachHang);
    r++; // dòng trống

    final header = [
      'STT',
      'Loại gỗ',
      'Kích thước',
      'Số lượng',
      'm³',
      'Đơn giá (đ/m³)',
      'Thành tiền (đ)',
    ];
    for (int c = 0; c < header.length; c++) {
      _set(sheet, r, c, TextCellValue(header[c]));
    }
    r++;

    for (int i = 0; i < p.items.length; i++) {
      final it = p.items[i];
      _set(sheet, r, 0, IntCellValue(i + 1));
      _set(sheet, r, 1, TextCellValue(it.loaiGo.label));
      _set(sheet, r, 2, _text(_kichThuoc(it)));
      _set(sheet, r, 3, IntCellValue(it.soLuong));
      _set(sheet, r, 4, _num(it.theTichM3));
      _set(sheet, r, 5, _num(it.donGia));
      _set(sheet, r, 6, _num(it.thanhTien));
      r++;
    }

    r++;
    void total(String label, num? value) {
      _set(sheet, r, 5, TextCellValue(label));
      _set(sheet, r, 6, _num(value));
      r++;
    }

    total('Tổng m³', p.tongTheTichM3);
    total('Tổng tiền', p.tongTien);
    total('Đã TT', p.daThanhToan);
    total('Còn nợ', p.conNo);
    info('Hình thức thanh toán', p.hinhThucThanhToan.label);
    if (p.ghiChu.isNotEmpty) {
      info('Ghi chú', p.ghiChu);
    }

    for (int c = 0; c < header.length; c++) {
      sheet.setColumnAutoFit(c);
    }

    final soPhieu = p.soPhieu.isEmpty ? 'phieu' : p.soPhieu;
    final name = 'go_so_${soPhieu}_${Fmt.tenFile.format(DateTime.now())}.xlsx';
    await _save(excel, name);
  }

  static String _kichThuoc(GoItem it) {
    if (it.laGoiTron) {
      return 'D${_s(it.duongKinhCm ?? 0)} x L${_s(it.chieuDaiM)}m';
    }
    return '${_s(it.dayCm ?? 0)} x ${_s(it.rongCm ?? 0)} x L${_s(it.chieuDaiM)}m';
  }

  static String _s(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  static Future<void> _save(Excel excel, String fileName) async {
    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) return;
    final dir = await getTemporaryDirectory();
    final file = File(join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'GỗSổ - Xuất Excel'),
    );
  }
}
