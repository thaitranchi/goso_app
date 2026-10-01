import 'package:flutter_test/flutter_test.dart';

import 'package:goso_app/utils/volume_calculator.dart';

void main() {
  group('VolumeCalculator.tron', () {
    test('tính đúng theo V = pi * (D/200)^2 * L', () {
      final r = VolumeCalculator.tron(
        duongKinhCm: 20,
        chieuDaiM: 4,
        soLuong: 1,
      );
      // V = pi * 0.1^2 * 4 = 0.12566...
      expect(r.thetichMotThanh, closeTo(0.125663706, 1e-8));
      expect(r.tongTheTich, closeTo(0.125663706, 1e-8));
    });

    test('nhân theo số lượng', () {
      final r = VolumeCalculator.tron(
        duongKinhCm: 30,
        chieuDaiM: 6,
        soLuong: 10,
      );
      const mot = 3.141592653589793 * 0.15 * 0.15 * 6;
      expect(r.soLuong, 10);
      expect(r.thetichMotThanh, closeTo(mot, 1e-8));
      expect(r.tongTheTich, closeTo(mot * 10, 1e-7));
    });

    test('đường kính bằng 0 bị chặn', () {
      expect(
        () => VolumeCalculator.tron(duongKinhCm: 0, chieuDaiM: 4),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('VolumeCalculator.xa', () {
    test('tính đúng theo (day/100) * (rong/100) * L', () {
      final r = VolumeCalculator.xa(
        dayCm: 5,
        rongCm: 20,
        chieuDaiM: 4,
        soLuong: 1,
      );
      expect(r.thetichMotThanh, closeTo(0.04, 1e-9));
      expect(r.tongTheTich, closeTo(0.04, 1e-9));
    });

    test('nhân theo số thanh', () {
      final r = VolumeCalculator.xa(
        dayCm: 4,
        rongCm: 10,
        chieuDaiM: 5,
        soLuong: 25,
      );
      expect(r.tongTheTich, closeTo(0.02 * 25, 1e-9));
    });
  });
}
