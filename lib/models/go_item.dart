/// Loại gỗ: tròn (gỗ tròn, gỗ lóng) hoặc xẻ (gỗ xẻ, phôi).
enum LoaiGo {
  tron('tron', 'Gỗ tròn / lóng'),
  xa('xa', 'Gỗ xẻ / phôi');

  const LoaiGo(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static LoaiGo fromDb(String? value) => LoaiGo.values.firstWhere(
    (e) => e.dbValue == value,
    orElse: () => LoaiGo.tron,
  );
}

/// Một dòng gỗ trong phiếu xuất kho.
class GoItem {
  const GoItem({
    this.id,
    this.phieuXuatId,
    required this.loaiGo,
    this.duongKinhCm,
    this.dayCm,
    this.rongCm,
    required this.chieuDaiM,
    required this.soLuong,
    required this.theTichM3,
    required this.donGia,
    required this.thanhTien,
  });

  final int? id;
  final int? phieuXuatId;
  final LoaiGo loaiGo;

  /// Đường kính (cm) - chỉ dùng cho gỗ tròn.
  final double? duongKinhCm;

  /// Dày (cm) - chỉ dùng cho gỗ xẻ.
  final double? dayCm;

  /// Rộng (cm) - chỉ dùng cho gỗ xẻ.
  final double? rongCm;

  final double chieuDaiM;
  final int soLuong;

  /// Tổng thể tích của dòng (m3).
  final double theTichM3;

  /// Đơn giá (đ/m3).
  final double donGia;

  final double thanhTien;

  bool get laGoiTron => loaiGo == LoaiGo.tron;

  /// Mô tả kích thước để in trên phiếu.
  String get moTaKichThuoc {
    if (laGoiTron) {
      return 'D${_so(duongKinhCm ?? 0)} x L${_so(chieuDaiM)}m';
    }
    return '${_so(dayCm ?? 0)} x ${_so(rongCm ?? 0)} x L${_so(chieuDaiM)}m';
  }

  String get moTa => '${loaiGo.label} | $moTaKichThuoc x $soLuong';

  factory GoItem.tron({
    int? id,
    int? phieuXuatId,
    required double duongKinhCm,
    required double chieuDaiM,
    required int soLuong,
    required double theTichM3,
    required double donGia,
  }) {
    return GoItem(
      id: id,
      phieuXuatId: phieuXuatId,
      loaiGo: LoaiGo.tron,
      duongKinhCm: duongKinhCm,
      chieuDaiM: chieuDaiM,
      soLuong: soLuong,
      theTichM3: theTichM3,
      donGia: donGia,
      thanhTien: theTichM3 * donGia,
    );
  }

  factory GoItem.xa({
    int? id,
    int? phieuXuatId,
    required double dayCm,
    required double rongCm,
    required double chieuDaiM,
    required int soLuong,
    required double theTichM3,
    required double donGia,
  }) {
    return GoItem(
      id: id,
      phieuXuatId: phieuXuatId,
      loaiGo: LoaiGo.xa,
      dayCm: dayCm,
      rongCm: rongCm,
      chieuDaiM: chieuDaiM,
      soLuong: soLuong,
      theTichM3: theTichM3,
      donGia: donGia,
      thanhTien: theTichM3 * donGia,
    );
  }

  GoItem copyWith({
    int? id,
    int? phieuXuatId,
    LoaiGo? loaiGo,
    double? duongKinhCm,
    double? dayCm,
    double? rongCm,
    double? chieuDaiM,
    int? soLuong,
    double? theTichM3,
    double? donGia,
    double? thanhTien,
  }) {
    return GoItem(
      id: id ?? this.id,
      phieuXuatId: phieuXuatId ?? this.phieuXuatId,
      loaiGo: loaiGo ?? this.loaiGo,
      duongKinhCm: duongKinhCm ?? this.duongKinhCm,
      dayCm: dayCm ?? this.dayCm,
      rongCm: rongCm ?? this.rongCm,
      chieuDaiM: chieuDaiM ?? this.chieuDaiM,
      soLuong: soLuong ?? this.soLuong,
      theTichM3: theTichM3 ?? this.theTichM3,
      donGia: donGia ?? this.donGia,
      thanhTien: thanhTien ?? this.thanhTien,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    if (phieuXuatId != null) 'phieu_xuat_id': phieuXuatId,
    'loai_go': loaiGo.dbValue,
    'duong_kinh_cm': duongKinhCm,
    'day_cm': dayCm,
    'rong_cm': rongCm,
    'chieu_dai_m': chieuDaiM,
    'so_luong': soLuong,
    'the_tich_m3': theTichM3,
    'don_gia': donGia,
    'thanh_tien': thanhTien,
  };

  factory GoItem.fromMap(Map<String, Object?> map) => GoItem(
    id: map['id'] as int?,
    phieuXuatId: map['phieu_xuat_id'] as int?,
    loaiGo: LoaiGo.fromDb(map['loai_go'] as String?),
    duongKinhCm: (map['duong_kinh_cm'] as num?)?.toDouble(),
    dayCm: (map['day_cm'] as num?)?.toDouble(),
    rongCm: (map['rong_cm'] as num?)?.toDouble(),
    chieuDaiM: (map['chieu_dai_m'] as num?)?.toDouble() ?? 0,
    soLuong: (map['so_luong'] as num?)?.toInt() ?? 0,
    theTichM3: (map['the_tich_m3'] as num?)?.toDouble() ?? 0,
    donGia: (map['don_gia'] as num?)?.toDouble() ?? 0,
    thanhTien: (map['thanh_tien'] as num?)?.toDouble() ?? 0,
  );

  static String _so(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
