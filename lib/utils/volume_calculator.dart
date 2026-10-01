import 'dart:math' as math;

/// Ket qua tinh toan the tich go.
class TheTich {
  const TheTich({
    required this.thetichMotThanh,
    required this.soLuong,
    required this.tongTheTich,
  });

  /// The tich cua mot thanh (m3).
  final double thetichMotThanh;

  /// So thanh / so cay.
  final int soLuong;

  /// Tong the tich cua ca lo (m3).
  final double tongTheTich;
}

/// Cong thuc tinh toan the tich gỗ ngoai bai.
///
/// Vong tron: V = pi * (D / 200)^2 * L
/// Vong xa:  V = (day / 100) * (rong / 100) * L
class VolumeCalculator {
  VolumeCalculator._();

  static const double _pi = math.pi;

  /// Gỗ tròn / gỗ lóng.
  ///
  /// [duongKinhCm] đường kính (cm), [chieuDaiM] chiều dài (m), [soLuong] số cây.
  static TheTich tron({
    required double duongKinhCm,
    required double chieuDaiM,
    int soLuong = 1,
  }) {
    assert(duongKinhCm > 0, 'duongKinhCm phai lon hon 0');
    assert(chieuDaiM > 0, 'chieuDaiM phai lon hon 0');
    assert(soLuong > 0, 'soLuong phai lon hon 0');
    final banKinhM = duongKinhCm / 200;
    final motThanh = _pi * banKinhM * banKinhM * chieuDaiM;
    return TheTich(
      thetichMotThanh: motThanh,
      soLuong: soLuong,
      tongTheTich: motThanh * soLuong,
    );
  }

  /// Gỗ xẻ / phôi.
  ///
  /// [dayCm] dày (cm), [rongCm] rộng (cm), [chieuDaiM] dài (m), [soLuong] số thanh.
  static TheTich xa({
    required double dayCm,
    required double rongCm,
    required double chieuDaiM,
    int soLuong = 1,
  }) {
    assert(dayCm > 0, 'dayCm phai lon hon 0');
    assert(rongCm > 0, 'rongCm phai lon hon 0');
    assert(chieuDaiM > 0, 'chieuDaiM phai lon hon 0');
    assert(soLuong > 0, 'soLuong phai lon hon 0');
    final motThanh = (dayCm / 100) * (rongCm / 100) * chieuDaiM;
    return TheTich(
      thetichMotThanh: motThanh,
      soLuong: soLuong,
      tongTheTich: motThanh * soLuong,
    );
  }
}
