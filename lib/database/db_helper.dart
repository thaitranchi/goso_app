import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/go_item.dart';
import '../models/khach_hang.dart';
import '../models/phieu_xuat.dart';
import '../models/thong_ke.dart';

class DbHelper {
  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();
  static Database? _db;

  static const int _version = 2;
  static const String _dbName = 'goso.db';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Web dùng tên database làm khóa trong IndexedDB, không dùng đường dẫn file.
  static Future<String> resolveDatabasePath() async {
    if (kIsWeb) return _dbName;
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, _dbName);
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      // Web chạy SQLite bằng WebAssembly nên phải đổi factory trước khi mở.
      databaseFactory = databaseFactoryFfiWeb;
    }
    final dbPath = await resolveDatabasePath();
    return openDatabase(
      dbPath,
      version: _version,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
  }

  /// Chỉ dùng cho test: gắn sẵn database vào singleton.
  @visibleForTesting
  static void debugUseDatabase(Database db) => _db = db;

  @visibleForTesting
  static Future<void> debugReset() async {
    final d = _db;
    _db = null;
    await d?.close();
  }

  /// Tạo toàn bộ bảng cho database mới.
  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS khach_hang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ten TEXT NOT NULL,
        dien_thoai TEXT,
        dia_chi TEXT,
        ghi_chu TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS phieu_xuat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        khach_hang_id INTEGER NOT NULL,
        so_phieu TEXT,
        ngay_xuat INTEGER,
        tong_the_tich_m3 REAL,
        tong_tien REAL,
        da_thanh_toan REAL,
        con_no REAL,
        hinh_thuc_thanh_toan TEXT NOT NULL DEFAULT 'tien_mat',
        ghi_chu TEXT,
        FOREIGN KEY (khach_hang_id) REFERENCES khach_hang (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS go_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phieu_xuat_id INTEGER NOT NULL,
        loai_go TEXT NOT NULL,
        duong_kinh_cm REAL,
        day_cm REAL,
        rong_cm REAL,
        chieu_dai_m REAL,
        so_luong INTEGER,
        the_tich_m3 REAL,
        don_gia REAL,
        thanh_tien REAL,
        FOREIGN KEY (phieu_xuat_id) REFERENCES phieu_xuat (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_px_kh ON phieu_xuat(khach_hang_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_gi_px ON go_item(phieu_xuat_id)',
    );
  }

  /// Nâng cấp schema cho database đã có dữ liệu.
  static Future<void> upgradeSchema(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute(
        "ALTER TABLE phieu_xuat ADD COLUMN hinh_thuc_thanh_toan "
        "TEXT NOT NULL DEFAULT 'tien_mat'",
      );
    }
  }

  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }

  // ===== Khách hàng =====
  Future<int> insertKhachHang(KhachHang kh) async {
    final d = await db;
    return d.insert('khach_hang', kh.toMap());
  }

  Future<int> updateKhachHang(KhachHang kh) async {
    final d = await db;
    return d.update(
      'khach_hang',
      kh.toMap(),
      where: 'id = ?',
      whereArgs: [kh.id],
    );
  }

  Future<int> deleteKhachHang(int id) async {
    final d = await db;
    return d.delete('khach_hang', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<KhachHang>> getKhachHangs({String? keyword}) async {
    final d = await db;
    String where = '1=1';
    List<Object?> args = [];
    if (keyword != null && keyword.isNotEmpty) {
      where += ' AND (ten LIKE ? OR dien_thoai LIKE ? OR dia_chi LIKE ?)';
      final k = '%$keyword%';
      args.addAll([k, k, k]);
    }
    final list = await d.rawQuery('''
      SELECT kh.*, 
             COALESCE((SELECT SUM(p.con_no) FROM phieu_xuat p WHERE p.khach_hang_id = kh.id), 0) AS du_no
      FROM khach_hang kh
      WHERE $where
      ORDER BY kh.ten COLLATE NOCASE ASC
      ''', args);
    return list.map((e) => KhachHang.fromMap(e)).toList();
  }

  Future<KhachHang?> getKhachHangById(int id) async {
    final d = await db;
    final list = await d.rawQuery(
      '''
      SELECT kh.*, 
             COALESCE((SELECT SUM(p.con_no) FROM phieu_xuat p WHERE p.khach_hang_id = kh.id), 0) AS du_no
      FROM khach_hang kh
      WHERE kh.id = ?
      ''',
      [id],
    );
    if (list.isEmpty) return null;
    return KhachHang.fromMap(list.first);
  }

  // ===== Phiếu xuất =====
  Future<int> insertPhieuXuatFull(PhieuXuat px) async {
    final d = await db;
    return d.transaction((txn) async {
      final pxId = await txn.insert('phieu_xuat', {
        'khach_hang_id': px.khachHangId,
        'so_phieu': px.soPhieu,
        'ngay_xuat': (px.ngayXuat ?? DateTime.now()).millisecondsSinceEpoch,
        'tong_the_tich_m3': px.tongTheTichM3,
        'tong_tien': px.tongTien,
        'da_thanh_toan': px.daThanhToan,
        'con_no': px.conNo,
        'hinh_thuc_thanh_toan': px.hinhThucThanhToan.dbValue,
      });

      for (final it in px.items) {
        await txn.insert('go_item', {...it.toMap(), 'phieu_xuat_id': pxId});
      }
      return pxId;
    });
  }

  Future<int> updatePhieuXuatFull(PhieuXuat px) async {
    if (px.id == null) return insertPhieuXuatFull(px);
    final d = await db;
    return d.transaction((txn) async {
      await txn.update(
        'phieu_xuat',
        {
          'khach_hang_id': px.khachHangId,
          'so_phieu': px.soPhieu,
          'ngay_xuat': (px.ngayXuat ?? DateTime.now()).millisecondsSinceEpoch,
          'tong_the_tich_m3': px.tongTheTichM3,
          'tong_tien': px.tongTien,
          'da_thanh_toan': px.daThanhToan,
          'con_no': px.conNo,
          'hinh_thuc_thanh_toan': px.hinhThucThanhToan.dbValue,
        },
        where: 'id = ?',
        whereArgs: [px.id],
      );
      await txn.delete(
        'go_item',
        where: 'phieu_xuat_id = ?',
        whereArgs: [px.id],
      );
      for (final it in px.items) {
        await txn.insert('go_item', {...it.toMap(), 'phieu_xuat_id': px.id});
      }
      return px.id!;
    });
  }

  Future<int> deletePhieuXuat(int id) async {
    final d = await db;
    return d.delete('phieu_xuat', where: 'id = ?', whereArgs: [id]);
  }

  Future<PhieuXuat?> getPhieuXuatById(int id) async {
    final d = await db;
    final pxs = await d.rawQuery(
      '''
      SELECT p.*, kh.ten, kh.dia_chi, kh.dien_thoai
      FROM phieu_xuat p
      INNER JOIN khach_hang kh ON kh.id = p.khach_hang_id
      WHERE p.id = ?
      ''',
      [id],
    );
    if (pxs.isEmpty) return null;
    final withItems = await _attachItems(d, [PhieuXuat.fromMap(pxs.first)]);
    return withItems.first;
  }

  /// [withItems] nạp luôn chi tiết hàng của từng phiếu (1 câu query cho cả danh sách).
  Future<List<PhieuXuat>> getPhieuXuats({
    int? khachHangId,
    String? keyword,
    bool withItems = true,
  }) async {
    final d = await db;
    String where = '1=1';
    List<Object?> args = [];
    if (khachHangId != null) {
      where += ' AND p.khach_hang_id = ?';
      args.add(khachHangId);
    }
    if (keyword != null && keyword.isNotEmpty) {
      where +=
          ' AND (p.so_phieu LIKE ? OR kh.ten LIKE ? OR kh.dien_thoai LIKE ?)';
      final k = '%$keyword%';
      args.addAll([k, k, k]);
    }
    final list = await d.rawQuery('''
      SELECT p.*, kh.ten, kh.dia_chi, kh.dien_thoai
      FROM phieu_xuat p
      INNER JOIN khach_hang kh ON kh.id = p.khach_hang_id
      WHERE $where
      ORDER BY p.ngay_xuat DESC, p.id DESC
      ''', args);
    final pxs = list.map((e) => PhieuXuat.fromMap(e)).toList();
    if (!withItems || pxs.isEmpty) return pxs;
    return _attachItems(d, pxs);
  }

  /// Gộp chi tiết hàng theo phiếu bằng một lần truy vấn, tránh N+1 query.
  Future<List<PhieuXuat>> _attachItems(
    DatabaseExecutor d,
    List<PhieuXuat> pxs,
  ) async {
    final ids = pxs.map((p) => p.id).whereType<int>().toList();
    if (ids.isEmpty) return pxs;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await d.rawQuery(
      'SELECT * FROM go_item WHERE phieu_xuat_id IN ($placeholders) ORDER BY id ASC',
      ids,
    );
    final byPhieu = <int, List<GoItem>>{};
    for (final row in rows) {
      final id = row['phieu_xuat_id'] as int?;
      if (id == null) continue;
      (byPhieu[id] ??= <GoItem>[]).add(GoItem.fromMap(row));
    }
    return [
      for (final p in pxs)
        if (p.id != null && byPhieu[p.id!] != null)
          p.copyWith(items: byPhieu[p.id!])
        else
          p,
    ];
  }

  Future<List<GoItem>> getGoItemsByPhieu(int phieuId) async {
    final d = await db;
    final list = await d.query(
      'go_item',
      where: 'phieu_xuat_id = ?',
      whereArgs: [phieuId],
      orderBy: 'id ASC',
    );
    return list.map((e) => GoItem.fromMap(e)).toList();
  }

  // ===== Thống kê =====
  /// Tổng hợp toàn bộ phiếu xuất, trong đó tách riêng phần của hôm nay.
  Future<ThongKe> getThongKe() async {
    final d = await db;
    final now = DateTime.now();
    final dauHom = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final ngayMai = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).millisecondsSinceEpoch;

    final rows = await d.rawQuery(
      '''
      SELECT
        COUNT(*) AS so_phieu,
        COALESCE(SUM(tong_the_tich_m3), 0) AS tong_the_tich,
        COALESCE(SUM(tong_tien), 0) AS tong_tien,
        COALESCE(SUM(da_thanh_toan), 0) AS tong_da_thu,
        COALESCE(SUM(con_no), 0) AS tong_no,
        COALESCE(SUM(CASE WHEN ngay_xuat >= ? AND ngay_xuat < ? THEN 1 ELSE 0 END), 0) AS so_phieu_hom_nay,
        COALESCE(SUM(CASE WHEN ngay_xuat >= ? AND ngay_xuat < ? THEN tong_the_tich_m3 ELSE 0 END), 0) AS the_tich_hom_nay,
        COALESCE(SUM(CASE WHEN ngay_xuat >= ? AND ngay_xuat < ? THEN tong_tien ELSE 0 END), 0) AS tien_hom_nay
      FROM phieu_xuat
      ''',
      [dauHom, ngayMai, dauHom, ngayMai, dauHom, ngayMai],
    );
    final kh = await d.rawQuery('SELECT COUNT(*) AS so_khach FROM khach_hang');
    final r = rows.first;
    return ThongKe(
      soPhieu: (r['so_phieu'] as num?)?.toInt() ?? 0,
      soKhach: ((kh.first['so_khach'] as num?)?.toInt()) ?? 0,
      tongTheTichM3: (r['tong_the_tich'] as num?)?.toDouble() ?? 0,
      tongTien: (r['tong_tien'] as num?)?.toDouble() ?? 0,
      tongDaThu: (r['tong_da_thu'] as num?)?.toDouble() ?? 0,
      tongNo: (r['tong_no'] as num?)?.toDouble() ?? 0,
      soPhieuHomNay: (r['so_phieu_hom_nay'] as num?)?.toInt() ?? 0,
      theTichHomNayM3: (r['the_tich_hom_nay'] as num?)?.toDouble() ?? 0,
      tienHomNay: (r['tien_hom_nay'] as num?)?.toDouble() ?? 0,
    );
  }

  // ===== Thanh toán (ghi nhận trả nợ) =====
  Future<int> thanhToan(int phieuXuatId, double soTienTra) async {
    if (soTienTra <= 0) return 0;
    final d = await db;
    return d.transaction((txn) async {
      final pxs = await txn.query(
        'phieu_xuat',
        where: 'id = ?',
        whereArgs: [phieuXuatId],
      );
      if (pxs.isEmpty) return 0;
      final tong = (pxs.first['tong_tien'] as num?)?.toDouble() ?? 0;
      final daTT = (pxs.first['da_thanh_toan'] as num?)?.toDouble() ?? 0;
      final khId = pxs.first['khach_hang_id'] as int;
      final daTTMoi = daTT + soTienTra;
      final conNoMoi = (tong - daTTMoi).clamp(0, double.infinity);
      await txn.update(
        'phieu_xuat',
        {'da_thanh_toan': daTTMoi, 'con_no': conNoMoi},
        where: 'id = ?',
        whereArgs: [phieuXuatId],
      );
      return khId;
    });
  }

  // ===== Sao lưu / Phục hồi =====
  /// Tạo bản sao file SQLite và trả về file trong thư mục tạm.
  Future<File> exportToFile() async {
    if (kIsWeb) {
      throw UnsupportedError('Sao lưu file .db chỉ hỗ trợ trên Android/iOS.');
    }
    // Chốt ghi trước khi copy để file backup đầy đủ.
    final d = await db;
    await d.rawQuery('PRAGMA wal_checkpoint(FULL)');

    final dbPath = await resolveDatabasePath();
    final dir = await getTemporaryDirectory();
    final fname = 'goso_${DateTime.now().millisecondsSinceEpoch}.db';
    final out = File(join(dir.path, fname));
    return File(dbPath).copy(out.path);
  }

  Future<String> getDatabasePath() => resolveDatabasePath();

  /// Ghi đè database bằng nội dung file sao lưu rồi mở lại.
  Future<void> importFromBytes(Uint8List bytes) async {
    if (kIsWeb) {
      await close();
      await databaseFactory.writeDatabaseBytes(_dbName, bytes);
      return;
    }
    final dbPath = await resolveDatabasePath();
    final dst = File(dbPath);
    if (await dst.exists()) {
      await dst.delete();
    }
    await dst.writeAsBytes(bytes, flush: true);
    await close();
  }
}
