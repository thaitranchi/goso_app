import '../models/go_item.dart';
import '../models/khach_hang.dart';

/// Các cách thu tiền của một phiếu xuất.
enum HinhThucThanhToan {
  tienMat('tien_mat', 'Tiền mặt'),
  chuyenKhoan('chuyen_khoan', 'Chuyển khoản'),
  congNo('cong_no', 'Công nợ');

  const HinhThucThanhToan(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static HinhThucThanhToan fromDb(String? value) =>
      HinhThucThanhToan.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => HinhThucThanhToan.tienMat,
      );
}

/// Phiếu xuất kho gỗ.
class PhieuXuat {
  const PhieuXuat({
    this.id,
    required this.khachHangId,
    this.tenKhachHang = '',
    this.diaChiKhachHang = '',
    this.dienThoaiKhachHang = '',
    this.soPhieu = '',
    this.ngayXuat,
    this.tongTheTichM3 = 0,
    this.tongTien = 0,
    this.daThanhToan = 0,
    this.conNo = 0,
    this.hinhThucThanhToan = HinhThucThanhToan.tienMat,
    this.ghiChu = '',
    this.items = const [],
  });

  final int? id;
  final int khachHangId;
  final String tenKhachHang;
  final String diaChiKhachHang;
  final String dienThoaiKhachHang;
  final String soPhieu;
  final DateTime? ngayXuat;
  final double tongTheTichM3;
  final double tongTien;
  final double daThanhToan;
  final double conNo;
  final HinhThucThanhToan hinhThucThanhToan;
  final String ghiChu;
  final List<GoItem> items;

  PhieuXuat copyWith({
    int? id,
    int? khachHangId,
    String? tenKhachHang,
    String? diaChiKhachHang,
    String? dienThoaiKhachHang,
    String? soPhieu,
    DateTime? ngayXuat,
    double? tongTheTichM3,
    double? tongTien,
    double? daThanhToan,
    double? conNo,
    HinhThucThanhToan? hinhThucThanhToan,
    String? ghiChu,
    List<GoItem>? items,
  }) {
    return PhieuXuat(
      id: id ?? this.id,
      khachHangId: khachHangId ?? this.khachHangId,
      tenKhachHang: tenKhachHang ?? this.tenKhachHang,
      diaChiKhachHang: diaChiKhachHang ?? this.diaChiKhachHang,
      dienThoaiKhachHang: dienThoaiKhachHang ?? this.dienThoaiKhachHang,
      soPhieu: soPhieu ?? this.soPhieu,
      ngayXuat: ngayXuat ?? this.ngayXuat,
      tongTheTichM3: tongTheTichM3 ?? this.tongTheTichM3,
      tongTien: tongTien ?? this.tongTien,
      daThanhToan: daThanhToan ?? this.daThanhToan,
      conNo: conNo ?? this.conNo,
      hinhThucThanhToan: hinhThucThanhToan ?? this.hinhThucThanhToan,
      ghiChu: ghiChu ?? this.ghiChu,
      items: items ?? this.items,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'khach_hang_id': khachHangId,
    'so_phieu': soPhieu,
    'ngay_xuat': (ngayXuat ?? DateTime.now()).millisecondsSinceEpoch,
    'tong_the_tich_m3': tongTheTichM3,
    'tong_tien': tongTien,
    'da_thanh_toan': daThanhToan,
    'con_no': conNo,
    'hinh_thuc_thanh_toan': hinhThucThanhToan.dbValue,
    'ghi_chu': ghiChu,
  };

  factory PhieuXuat.fromMap(
    Map<String, Object?> map, {
    List<GoItem> items = const [],
    KhachHang? khachHang,
  }) {
    return PhieuXuat(
      id: map['id'] as int?,
      khachHangId: (map['khach_hang_id'] as int?) ?? 0,
      tenKhachHang: (map['ten'] as String?) ?? (khachHang?.ten ?? ''),
      diaChiKhachHang: (map['dia_chi'] as String?) ?? (khachHang?.diaChi ?? ''),
      dienThoaiKhachHang:
          (map['dien_thoai'] as String?) ?? (khachHang?.dienThoai ?? ''),
      soPhieu: (map['so_phieu'] as String?) ?? '',
      ngayXuat: map['ngay_xuat'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['ngay_xuat'] as int),
      tongTheTichM3: (map['tong_the_tich_m3'] as num?)?.toDouble() ?? 0,
      tongTien: (map['tong_tien'] as num?)?.toDouble() ?? 0,
      daThanhToan: (map['da_thanh_toan'] as num?)?.toDouble() ?? 0,
      conNo: (map['con_no'] as num?)?.toDouble() ?? 0,
      hinhThucThanhToan: HinhThucThanhToan.fromDb(
        map['hinh_thuc_thanh_toan'] as String?,
      ),
      ghiChu: (map['ghi_chu'] as String?) ?? '',
      items: items,
    );
  }
}
