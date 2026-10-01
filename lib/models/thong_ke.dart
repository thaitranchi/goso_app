/// Số liệu tổng hợp cho màn hình chính.
class ThongKe {
  const ThongKe({
    this.soPhieu = 0,
    this.soKhach = 0,
    this.tongTheTichM3 = 0,
    this.tongTien = 0,
    this.tongDaThu = 0,
    this.tongNo = 0,
    this.soPhieuHomNay = 0,
    this.theTichHomNayM3 = 0,
    this.tienHomNay = 0,
  });

  final int soPhieu;
  final int soKhach;
  final double tongTheTichM3;
  final double tongTien;
  final double tongDaThu;
  final double tongNo;
  final int soPhieuHomNay;
  final double theTichHomNayM3;
  final double tienHomNay;

  static const empty = ThongKe();
}
