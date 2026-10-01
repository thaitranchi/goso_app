import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goso_app/database/db_helper.dart';
import 'package:goso_app/models/go_item.dart';
import 'package:goso_app/models/khach_hang.dart';
import 'package:goso_app/models/phieu_xuat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DbHelper db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final raw = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: DbHelper.createSchema,
        onUpgrade: DbHelper.upgradeSchema,
      ),
    );
    db = DbHelper.instance;
    DbHelper.debugUseDatabase(raw);
  });

  tearDown(() async => DbHelper.debugReset());

  Future<int> themKhach(String ten) =>
      db.insertKhachHang(KhachHang(ten: ten, dienThoai: '0900000000'));

  PhieuXuat phieu(
    int khId, {
    int? id,
    required double theTich,
    required double tien,
    required double daTT,
    required DateTime ngay,
    List<GoItem> items = const [],
  }) {
    return PhieuXuat(
      id: id,
      khachHangId: khId,
      soPhieu: 'PX${ngay.millisecondsSinceEpoch}',
      ngayXuat: ngay,
      tongTheTichM3: theTich,
      tongTien: tien,
      daThanhToan: daTT,
      conNo: (tien - daTT).clamp(0, double.infinity),
      items: items,
    );
  }

  test('insert phiếu kèm hàng, getPhieuXuats trả về đúng chi tiết', () async {
    final khId = await themKhach('Chủ xưởng An');
    await db.insertPhieuXuatFull(
      phieu(
        khId,
        theTich: 1.5,
        tien: 1500000,
        daTT: 0,
        ngay: DateTime.now(),
        items: [
          GoItem.tron(
            duongKinhCm: 20,
            chieuDaiM: 4,
            soLuong: 2,
            theTichM3: 0.753,
            donGia: 1000000,
          ),
        ],
      ),
    );

    final list = await db.getPhieuXuats();
    expect(list.length, 1);
    final px = list.first;
    expect(px.tenKhachHang, 'Chủ xưởng An');
    expect(px.items.length, 1);
    expect(px.items.first.loaiGo, LoaiGo.tron);
    expect(px.items.first.phieuXuatId, px.id);
    expect(px.conNo, 1500000);

    // withItems = false thì không nạp hàng.
    final khongItems = await db.getPhieuXuats(withItems: false);
    expect(khongItems.first.items, isEmpty);
  });

  test('dư nợ khách = tổng con_no của các phiếu', () async {
    final khId = await themKhach('Chủ B');
    await db.insertPhieuXuatFull(
      phieu(
        khId,
        theTich: 1,
        tien: 1000000,
        daTT: 400000,
        ngay: DateTime.now(),
      ),
    );
    await db.insertPhieuXuatFull(
      phieu(khId, theTich: 2, tien: 3000000, daTT: 0, ngay: DateTime.now()),
    );

    final khs = await db.getKhachHangs();
    expect(khs.single.duNo, closeTo(3600000, 0.01));
    expect((await db.getKhachHangById(khId))!.duNo, closeTo(3600000, 0.01));
  });

  test(
    'thanhToan giảm con_no và tăng da_thanh_toan, không vượt quá tổng',
    () async {
      final khId = await themKhach('Chủ C');
      final pxId = await db.insertPhieuXuatFull(
        phieu(khId, theTich: 1, tien: 1000000, daTT: 0, ngay: DateTime.now()),
      );

      await db.thanhToan(pxId, 300000);
      var px = await db.getPhieuXuatById(pxId);
      expect(px!.daThanhToan, closeTo(300000, 0.01));
      expect(px.conNo, closeTo(700000, 0.01));

      // Trả hơn số nợ thì con_no bằng 0, không âm.
      await db.thanhToan(pxId, 900000);
      px = await db.getPhieuXuatById(pxId);
      expect(px!.conNo, 0);
    },
  );

  test('updatePhieuXuatFull thay hết dòng hàng cũ', () async {
    final khId = await themKhach('Chủ D');
    final pxId = await db.insertPhieuXuatFull(
      phieu(
        khId,
        theTich: 1,
        tien: 500000,
        daTT: 0,
        ngay: DateTime.now(),
        items: [
          GoItem.xa(
            dayCm: 2,
            rongCm: 10,
            chieuDaiM: 4,
            soLuong: 1,
            theTichM3: 0.08,
            donGia: 500000,
          ),
          GoItem.xa(
            dayCm: 3,
            rongCm: 12,
            chieuDaiM: 4,
            soLuong: 1,
            theTichM3: 0.144,
            donGia: 500000,
          ),
        ],
      ),
    );
    expect((await db.getGoItemsByPhieu(pxId)).length, 2);

    await db.updatePhieuXuatFull(
      phieu(
        khId,
        id: pxId,
        theTich: 0.08,
        tien: 500000,
        daTT: 500000,
        ngay: DateTime.now(),
        items: [
          GoItem.xa(
            dayCm: 2,
            rongCm: 10,
            chieuDaiM: 4,
            soLuong: 1,
            theTichM3: 0.08,
            donGia: 500000,
          ),
        ],
      ),
    );

    final items = await db.getGoItemsByPhieu(pxId);
    expect(items.length, 1);
    final px = await db.getPhieuXuatById(pxId);
    expect(px!.hinhThucThanhToan, HinhThucThanhToan.tienMat);
  });

  test('lưu và đọc lại hình thức thanh toán', () async {
    final khId = await themKhach('Chủ E');
    final pxId = await db.insertPhieuXuatFull(
      phieu(
        khId,
        theTich: 1,
        tien: 1000,
        daTT: 0,
        ngay: DateTime.now(),
      ).copyWith(hinhThucThanhToan: HinhThucThanhToan.chuyenKhoan),
    );
    final px = await db.getPhieuXuatById(pxId);
    expect(px!.hinhThucThanhToan, HinhThucThanhToan.chuyenKhoan);
  });

  test('thống kê tách phiếu hôm nay và tổng công nợ', () async {
    final khId = await themKhach('Chủ F');
    final now = DateTime.now();
    final homQua = now.subtract(const Duration(days: 1));

    await db.insertPhieuXuatFull(
      phieu(khId, theTich: 1, tien: 1000000, daTT: 0, ngay: homQua),
    );
    await db.insertPhieuXuatFull(
      phieu(khId, theTich: 2, tien: 2000000, daTT: 500000, ngay: now),
    );

    final tk = await db.getThongKe();
    expect(tk.soPhieu, 2);
    expect(tk.soKhach, 1);
    expect(tk.tongTheTichM3, closeTo(3, 0.001));
    expect(tk.tongTien, closeTo(3000000, 0.01));
    expect(tk.tongDaThu, closeTo(500000, 0.01));
    expect(tk.tongNo, closeTo(2500000, 0.01));
    expect(tk.soPhieuHomNay, 1);
    expect(tk.theTichHomNayM3, closeTo(2, 0.001));
    expect(tk.tienHomNay, closeTo(2000000, 0.01));
  });

  test('tìm kiếm phiếu theo số phiếu và tên khách', () async {
    final khId = await themKhach('Chủ xưởng Hùng');
    await db.insertPhieuXuatFull(
      phieu(khId, theTich: 1, tien: 1000, daTT: 0, ngay: DateTime.now()),
    );

    expect(await db.getPhieuXuats(keyword: 'Hùng'), hasLength(1));
    expect(await db.getPhieuXuats(keyword: 'không có'), isEmpty);
    expect(await db.getPhieuXuats(khachHangId: khId), hasLength(1));
    expect(await db.getPhieuXuats(khachHangId: -1), isEmpty);
  });

  group('migration v1 -> v2', () {
    test('thêm cột hinh_thuc_thanh_toan cho database cũ', () async {
      final path = '${Directory.systemTemp.path}/goso_migration_test.db';
      final file = File(path);
      if (await file.exists()) await file.delete();

      // Tạo database đúng phiên bản 1.
      final v1 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE khach_hang (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ten TEXT NOT NULL, dien_thoai TEXT, dia_chi TEXT,
                ghi_chu TEXT, created_at INTEGER
              )
            ''');
            await db.execute('''
              CREATE TABLE phieu_xuat (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                khach_hang_id INTEGER NOT NULL,
                so_phieu TEXT, ngay_xuat INTEGER,
                tong_the_tich_m3 REAL, tong_tien REAL,
                da_thanh_toan REAL, con_no REAL, ghi_chu TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE go_item (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                phieu_xuat_id INTEGER NOT NULL, loai_go TEXT NOT NULL,
                duong_kinh_cm REAL, day_cm REAL, rong_cm REAL,
                chieu_dai_m REAL, so_luong INTEGER, the_tich_m3 REAL,
                don_gia REAL, thanh_tien REAL
              )
            ''');
            await db.insert('khach_hang', {'ten': 'Khách cũ'});
            await db.insert('phieu_xuat', {
              'khach_hang_id': 1,
              'so_phieu': 'PX-CU',
              'tong_tien': 700000.0,
              'da_thanh_toan': 0.0,
              'con_no': 700000.0,
            });
          },
        ),
      );
      await v1.close();

      // Mở lại ở version 2 để chạy onUpgrade.
      final v2 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: DbHelper.createSchema,
          onUpgrade: DbHelper.upgradeSchema,
        ),
      );
      final cols = await v2.rawQuery('PRAGMA table_info(phieu_xuat)');
      expect(cols.map((c) => c['name']), contains('hinh_thuc_thanh_toan'));

      final row = (await v2.query('phieu_xuat')).single;
      expect(row['hinh_thuc_thanh_toan'], 'tien_mat');
      final px = PhieuXuat.fromMap(row);
      expect(px.hinhThucThanhToan, HinhThucThanhToan.tienMat);
      await v2.close();
      await file.delete();
    });
  });
}
