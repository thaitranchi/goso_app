import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/khach_hang.dart';
import '../models/phieu_xuat.dart';
import '../utils/formatters.dart';

/// Sổ nợ chi tiết của một khách hàng.
class SoNoScreen extends StatefulWidget {
  const SoNoScreen({super.key, required this.khachHang});

  final KhachHang khachHang;

  @override
  State<SoNoScreen> createState() => _SoNoScreenState();
}

class _SoNoScreenState extends State<SoNoScreen> {
  List<PhieuXuat> _phieuXuats = [];
  bool _loading = true;

  double get _tongNo => _phieuXuats.fold(0.0, (sum, p) => sum + p.conNo);
  double get _tongDaTT =>
      _phieuXuats.fold(0.0, (sum, p) => sum + p.daThanhToan);
  double get _tongTien => _phieuXuats.fold(0.0, (sum, p) => sum + p.tongTien);
  double get _tongTheTich =>
      _phieuXuats.fold(0.0, (sum, p) => sum + p.tongTheTichM3);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<DbHelper>();
    final list = await db.getPhieuXuats(khachHangId: widget.khachHang.id);
    if (!mounted) return;
    setState(() {
      _phieuXuats = list;
      _loading = false;
    });
  }

  Future<void> _ghiNhanTraNo(PhieuXuat p) async {
    final ctrl = TextEditingController();
    final soTien = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ghi nhận trả nợ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiếu: ${p.soPhieu}'),
            Text('Còn nợ: ${Fmt.money(p.conNo)}'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền trả (đ)',
                suffixText: 'đ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(
                ctrl.text.replaceAll('.', '').replaceAll(',', '.'),
              );
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Trả'),
          ),
        ],
      ),
    );
    if (soTien == null || !mounted) return;
    final db = context.read<DbHelper>();
    if (p.id != null) {
      await db.thanhToan(p.id!, soTien);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final kh = widget.khachHang;
    return Scaffold(
      appBar: AppBar(title: Text('Sổ nợ: ${kh.ten}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: _tongNo > 0.5
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG DƯ NỢ',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          Fmt.money(_tongNo),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _row('Tổng thể tích đã xuất', Fmt.m3(_tongTheTich)),
                        _row('Tổng giá trị phiếu', Fmt.money(_tongTien)),
                        _row('Đã thanh toán', Fmt.money(_tongDaTT)),
                        _row('Số phiếu', '${_phieuXuats.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lịch sử phiếu xuất',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_phieuXuats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Chưa có phiếu xuất nào')),
                  ),
                ..._phieuXuats.map((p) {
                  return Card(
                    child: ExpansionTile(
                      title: Text(p.soPhieu.isEmpty ? 'PX' : p.soPhieu),
                      subtitle: Text(
                        p.ngayXuat == null ? '' : Fmt.date(p.ngayXuat!),
                      ),
                      children: [
                        if (p.items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final it in p.items)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '• ${it.loaiGo.label}: ${it.moTaKichThuoc} x '
                                      '${it.soLuong} = ${Fmt.m3(it.theTichM3)} '
                                      '(${Fmt.money(it.thanhTien)})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _row('Tổng m³', Fmt.m3(p.tongTheTichM3)),
                              _row('Tổng tiền', Fmt.money(p.tongTien)),
                              _row('Đã thanh toán', Fmt.money(p.daThanhToan)),
                              _row('Hình thức TT', p.hinhThucThanhToan.label),
                              _row(
                                'Còn nợ',
                                Fmt.money(p.conNo),
                                bold: p.conNo > 0.5,
                              ),
                              if (p.ghiChu.isNotEmpty)
                                _row('Ghi chú', p.ghiChu),
                              if (p.conNo > 0.5)
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _ghiNhanTraNo(p),
                                    icon: const Icon(Icons.payments_outlined),
                                    label: const Text('Ghi nhận trả nợ'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
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
