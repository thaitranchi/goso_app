import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/go_item.dart';
import '../models/khach_hang.dart';
import '../models/phieu_xuat.dart';
import '../services/bluetooth_service.dart';
import '../services/excel_service.dart';
import '../utils/formatters.dart';
import '../utils/volume_calculator.dart';
import 'khach_hang_screen.dart';

class PhieuXuatScreen extends StatefulWidget {
  const PhieuXuatScreen({super.key});

  static const route = '/phieu-xuat';

  @override
  State<PhieuXuatScreen> createState() => _PhieuXuatScreenState();
}

class _PhieuXuatScreenState extends State<PhieuXuatScreen> {
  int? _phieuId;
  KhachHang? _kh;
  final _items = <GoItem>[];
  final _soPhieuCtrl = TextEditingController();
  final _ghiChuCtrl = TextEditingController();
  final _daThanhToanCtrl = TextEditingController();
  bool _traDaDay = true;
  HinhThucThanhToan _hinhThuc = HinhThucThanhToan.tienMat;
  DateTime _ngay = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phieuId == null) {
      _phieuId = ModalRoute.of(context)?.settings.arguments as int?;
      if (_phieuId == null) _loading = false;
    }
    if (_phieuId != null && _loading) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final db = context.read<DbHelper>();
    final p = await db.getPhieuXuatById(_phieuId!);
    if (!mounted) return;
    if (p == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(p.items);
      _soPhieuCtrl.text = p.soPhieu;
      _ghiChuCtrl.text = p.ghiChu;
      // Phiếu cũ đã trả 0 đồng thì phải hiện "0", không được coi là trả đủ.
      _traDaDay = p.tongTien > 0 && p.daThanhToan >= p.tongTien;
      _daThanhToanCtrl.text = _traDaDay ? '' : p.daThanhToan.toStringAsFixed(0);
      _hinhThuc = p.hinhThucThanhToan;
      _ngay = p.ngayXuat ?? DateTime.now();
      _loading = false;
    });
    await _loadKhach(p.khachHangId);
  }

  Future<void> _loadKhach(int id) async {
    final db = context.read<DbHelper>();
    final kh = await db.getKhachHangById(id);
    if (mounted) setState(() => _kh = kh);
  }

  @override
  void dispose() {
    _soPhieuCtrl.dispose();
    _ghiChuCtrl.dispose();
    _daThanhToanCtrl.dispose();
    super.dispose();
  }

  double get _tongTheTich => _items.fold(0.0, (s, e) => s + e.theTichM3);
  double get _tongTien => _items.fold(0.0, (s, e) => s + e.thanhTien);

  double get _daThanhToan {
    if (_traDaDay) return _tongTien;
    final v = double.tryParse(_daThanhToanCtrl.text.trim());
    if (v != null) return v.clamp(0, _tongTien);
    return 0;
  }

  double get _conNo => (_tongTien - _daThanhToan).clamp(0, double.infinity);

  String _genSoPhieu() {
    final now = DateTime.now();
    return 'PX${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickKhach() async {
    final db = context.read<DbHelper>();
    final list = await db.getKhachHangs();
    if (!mounted) return;
    if (list.isEmpty) {
      final add = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Chưa có khách hàng'),
          content: const Text(
            'Bạn cần thêm ít nhất một khách hàng trước khi tạo phiếu xuất.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm ngay'),
            ),
          ],
        ),
      );
      if (add == true && mounted) {
        await Navigator.pushNamed(context, KhachHangScreen.route);
      }
      return;
    }

    final kh = await showDialog<KhachHang>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Chọn khách hàng'),
        children: list
            .map(
              (k) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, k),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(k.ten),
                  subtitle: k.dienThoai.isEmpty ? null : Text(k.dienThoai),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (kh != null && mounted) setState(() => _kh = kh);
  }

  Future<void> _addItem() async {
    final item = await showModalBottomSheet<GoItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddItemSheet(),
    );
    if (item != null && mounted) {
      setState(() => _items.add(item));
    }
  }

  Future<void> _save() async {
    if (_kh?.id == null) {
      _pickKhach();
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiếu chưa có dòng gỗ nào')),
      );
      return;
    }
    setState(() => _saving = true);
    final db = context.read<DbHelper>();
    final px = PhieuXuat(
      id: _phieuId,
      khachHangId: _kh!.id!,
      tenKhachHang: _kh!.ten,
      diaChiKhachHang: _kh!.diaChi,
      dienThoaiKhachHang: _kh!.dienThoai,
      soPhieu: _soPhieuCtrl.text.trim().isEmpty
          ? (_phieuId == null ? _genSoPhieu() : _soPhieuCtrl.text.trim())
          : _soPhieuCtrl.text.trim(),
      ngayXuat: _ngay,
      tongTheTichM3: _tongTheTich,
      tongTien: _tongTien,
      daThanhToan: _daThanhToan,
      conNo: _conNo,
      hinhThucThanhToan: _hinhThuc,
      ghiChu: _ghiChuCtrl.text.trim(),
      items: List.of(_items),
    );
    if (_phieuId == null) {
      final id = await db.insertPhieuXuatFull(px);
      _phieuId = id;
    } else {
      await db.updatePhieuXuatFull(px);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã lưu phiếu ${px.soPhieu}')));
    Navigator.pop(context);
  }

  Future<void> _print() async {
    final db = context.read<DbHelper>();
    if (_phieuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy lưu phiếu trước khi in')),
      );
      return;
    }
    final p = await db.getPhieuXuatById(_phieuId!);
    if (p == null || !mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (_) =>
          _InSheet(phieu: p, parentContext: context, khachHang: _kh),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phiếu xuất')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_phieuId == null ? 'Phiếu xuất mới' : 'Sửa phiếu'),
        actions: [
          IconButton(
            tooltip: 'In phiếu',
            icon: const Icon(Icons.print_outlined),
            onPressed: _print,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(_kh?.ten ?? 'Chọn khách hàng'),
                    subtitle: _kh == null
                        ? const Text('Chạm để chọn')
                        : Text(
                            [
                              if (_kh!.dienThoai.isNotEmpty) _kh!.dienThoai,
                              if (_kh!.diaChi.isNotEmpty) _kh!.diaChi,
                            ].join(' • '),
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickKhach,
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: Fmt.date(_ngay),
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Ngày xuất',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _ngay,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              locale: const Locale('vi', 'VN'),
                            );
                            if (d != null && mounted) setState(() => _ngay = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _soPhieuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Số phiếu',
                            hintText: 'tự sinh',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dòng gỗ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Thêm gỗ'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.forest_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      const Text('Chưa có dòng gỗ. Bấm "Thêm gỗ" để bắt đầu.'),
                    ],
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < _items.length; i++) ...[
                    ListTile(
                      title: Text(_items[i].moTa),
                      subtitle: Text(
                        '${Fmt.money(_items[i].donGia)}/m³ • ${Fmt.money(_items[i].thanhTien)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    ),
                    if (i < _items.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow('Tổng thể tích', Fmt.m3(_tongTheTich)),
                  _totalRow('Tổng tiền', Fmt.money(_tongTien)),
                  const SizedBox(height: 8),
                  Text(
                    'Hình thức thanh toán',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<HinhThucThanhToan>(
                    segments: [
                      for (final h in HinhThucThanhToan.values)
                        ButtonSegment(value: h, label: Text(h.label)),
                    ],
                    selected: {_hinhThuc},
                    onSelectionChanged: (s) =>
                        setState(() => _hinhThuc = s.first),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _traDaDay,
                    title: const Text('Đã trả đủ'),
                    onChanged: (v) => setState(() => _traDaDay = v),
                  ),
                  if (!_traDaDay) ...[
                    TextField(
                      controller: _daThanhToanCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Đã thanh toán (đ)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        helperText: 'Nhập 0 nếu chưa thu tiền',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _totalRow('Còn nợ', Fmt.money(_conNo), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ghiChuCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu phiếu'),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontWeight: bold ? FontWeight.bold : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Form nhập một dòng gỗ.
class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  LoaiGo _loai = LoaiGo.tron;
  final _dk = TextEditingController();
  final _day = TextEditingController();
  final _rong = TextEditingController();
  final _dai = TextEditingController();
  final _sl = TextEditingController(text: '1');
  final _donGia = TextEditingController();
  TheTich? _preview;
  String? _error;

  @override
  void dispose() {
    for (final c in [_dk, _day, _rong, _dai, _sl, _donGia]) {
      c.dispose();
    }
    super.dispose();
  }

  void _previewCalc() {
    setState(() {
      _error = null;
      try {
        final l = double.parse(_dai.text);
        final sl = int.tryParse(_sl.text) ?? 1;
        _preview = _loai == LoaiGo.tron
            ? VolumeCalculator.tron(
                duongKinhCm: double.parse(_dk.text),
                chieuDaiM: l,
                soLuong: sl,
              )
            : VolumeCalculator.xa(
                dayCm: double.parse(_day.text),
                rongCm: double.parse(_rong.text),
                chieuDaiM: l,
                soLuong: sl,
              );
      } catch (_) {
        _error = 'Vui lòng nhập đủ kích thước và số lượng > 0';
        _preview = null;
      }
    });
  }

  void _submit() {
    if (_preview == null) {
      _previewCalc();
      return;
    }
    final gia = double.tryParse(_donGia.text.trim()) ?? 0;
    final l = double.parse(_dai.text);
    final sl = int.tryParse(_sl.text) ?? 1;
    final item = _loai == LoaiGo.tron
        ? GoItem.tron(
            duongKinhCm: double.parse(_dk.text),
            chieuDaiM: l,
            soLuong: sl,
            theTichM3: _preview!.tongTheTich,
            donGia: gia,
          )
        : GoItem.xa(
            dayCm: double.parse(_day.text),
            rongCm: double.parse(_rong.text),
            chieuDaiM: l,
            soLuong: sl,
            theTichM3: _preview!.tongTheTich,
            donGia: gia,
          );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thêm dòng gỗ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<LoaiGo>(
              segments: const [
                ButtonSegment(
                  value: LoaiGo.tron,
                  label: Text('Tròn/Lóng'),
                  icon: Icon(Icons.circle_outlined),
                ),
                ButtonSegment(
                  value: LoaiGo.xa,
                  label: Text('Xẻ/Phôi'),
                  icon: Icon(Icons.crop_landscape),
                ),
              ],
              selected: {_loai},
              onSelectionChanged: (s) => setState(() => _loai = s.first),
            ),
            const SizedBox(height: 12),
            if (_loai == LoaiGo.tron)
              TextField(
                controller: _dk,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đường kính (cm)'),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _day,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Dày (cm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _rong,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rộng (cm)'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dai,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chiều dài (m)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _donGia,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Đơn giá (đ/m³)',
                prefixText: '₫',
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_preview != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1 thanh: ${Fmt.m3(_preview!.thetichMotThanh)}'),
                      Text(
                        'Tổng: ${Fmt.m3(_preview!.tongTheTich)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _preview == null ? _previewCalc : _submit,
                    child: Text(
                      _preview == null ? 'Tính m³' : 'Thêm vào phiếu',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet in phiếu qua Bluetooth hoặc xuất Excel.
class _InSheet extends StatelessWidget {
  const _InSheet({
    required this.phieu,
    required this.parentContext,
    this.khachHang,
  });

  final PhieuXuat phieu;

  /// Context của màn hình cha, dùng sau khi bottom sheet đã đóng.
  final BuildContext parentContext;

  final KhachHang? khachHang;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'In phiếu ${phieu.soPhieu}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              Fmt.dateTime(phieu.ngayXuat ?? DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _inBluetooth(phieu);
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('In qua Bluetooth (K80/K58)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ExcelService.exportPhieuXuatChiTiet(phieu);
              },
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Xuất Excel'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inBluetooth(PhieuXuat p) async {
    final messenger = ScaffoldMessenger.of(parentContext);
    try {
      final address = await BluetoothPrintService.pickAndConnect(parentContext);
      if (address == null) return;
      await BluetoothPrintService.inPhieuXuat(p);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã in phiếu qua máy in $address')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi in: $e')));
    }
  }
}
