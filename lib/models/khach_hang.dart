/// Khách hàng (chủ xưởng mộc) của vựa gỗ.
class KhachHang {
  const KhachHang({
    this.id,
    required this.ten,
    this.dienThoai = '',
    this.diaChi = '',
    this.ghiChu = '',
    this.ngayTao,
    this.duNo = 0,
  });

  final int? id;
  final String ten;
  final String dienThoai;
  final String diaChi;
  final String ghiChu;
  final DateTime? ngayTao;

  /// Dư nợ hiện tại (đ) - tính từ tổng phiếu xuất trừ phần đã thanh toán.
  final double duNo;

  bool get coDuNo => duNo > 0.5;

  KhachHang copyWith({
    int? id,
    String? ten,
    String? dienThoai,
    String? diaChi,
    String? ghiChu,
    DateTime? ngayTao,
    double? duNo,
  }) {
    return KhachHang(
      id: id ?? this.id,
      ten: ten ?? this.ten,
      dienThoai: dienThoai ?? this.dienThoai,
      diaChi: diaChi ?? this.diaChi,
      ghiChu: ghiChu ?? this.ghiChu,
      ngayTao: ngayTao ?? this.ngayTao,
      duNo: duNo ?? this.duNo,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'ten': ten,
    'dien_thoai': dienThoai,
    'dia_chi': diaChi,
    'ghi_chu': ghiChu,
    'created_at': (ngayTao ?? DateTime.now()).millisecondsSinceEpoch,
  };

  factory KhachHang.fromMap(Map<String, Object?> map) => KhachHang(
    id: map['id'] as int?,
    ten: (map['ten'] as String?) ?? '',
    dienThoai: (map['dien_thoai'] as String?) ?? '',
    diaChi: (map['dia_chi'] as String?) ?? '',
    ghiChu: (map['ghi_chu'] as String?) ?? '',
    ngayTao: map['created_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    duNo: (map['du_no'] as num?)?.toDouble() ?? 0,
  );
}
