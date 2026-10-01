import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/phieu_xuat.dart';
import '../models/thong_ke.dart';
import '../utils/formatters.dart';
import 'calculator_screen.dart';
import 'khach_hang_screen.dart';
import 'phieu_xuat_screen.dart';
import 'settings_screen.dart';

/// Màn hình chính: ô tìm kiếm, thẻ thống kê và danh sách phiếu xuất.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  List<PhieuXuat> _phieuXuats = [];
  ThongKe _thongKe = ThongKe.empty;
  bool _loading = true;
  bool _showStats = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final db = context.read<DbHelper>();
    try {
      final list = await db.getPhieuXuats(keyword: _searchCtrl.text.trim());
      final tk = await db.getThongKe();
      if (!mounted) return;
      setState(() {
        _phieuXuats = list;
        _thongKe = tk;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GỗSổ'),
        actions: [
          IconButton(
            tooltip: 'Khách hàng',
            icon: const Icon(Icons.people_outline),
            onPressed: () =>
                Navigator.pushNamed(context, KhachHangScreen.route),
          ),
          IconButton(
            tooltip: 'Sao lưu & báo cáo',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, SettingsScreen.route),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm: Số phiếu, khách hàng, điện thoại...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
              ),
              onChanged: (_) => _load(),
              textInputAction: TextInputAction.search,
            ),
          ),
          _buildStats(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : _phieuXuats.isEmpty
                ? const Center(child: Text('Chưa có phiếu xuất nào'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: _phieuXuats.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _PhieuXuatTile(
                        px: _phieuXuats[i],
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            PhieuXuatScreen.route,
                            arguments: _phieuXuats[i].id,
                          );
                          _load();
                        },
                        onDeleted: () async {
                          final db = context.read<DbHelper>();
                          if (_phieuXuats[i].id != null) {
                            await db.deletePhieuXuat(_phieuXuats[i].id!);
                          }
                          _load();
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, PhieuXuatScreen.route);
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Phiếu xuất mới'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) async {
          if (idx == 1) {
            await Navigator.pushNamed(context, CalculatorScreen.route);
          } else if (idx == 2) {
            await Navigator.pushNamed(context, KhachHangScreen.route);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Phiếu xuất',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Tính m³',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Khách hàng',
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final tk = _thongKe;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Phiếu hôm nay',
                      value: '${tk.soPhieuHomNay}',
                      hint: Fmt.money(tk.tienHomNay),
                      icon: Icons.today_outlined,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'Tổng m³ đã xuất',
                      value: Fmt.m3(tk.tongTheTichM3),
                      hint: 'Hôm nay: ${Fmt.m3(tk.theTichHomNayM3)}',
                      icon: Icons.forest_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showStats)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Tổng công nợ',
                        value: Fmt.money(tk.tongNo),
                        hint: 'Đã thu ${Fmt.money(tk.tongDaThu)}',
                        icon: Icons.account_balance_wallet_outlined,
                        warn: tk.tongNo > 0.5,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Tổng giá trị',
                        value: Fmt.money(tk.tongTien),
                        hint: '${tk.soPhieu} phiếu • ${tk.soKhach} khách',
                        icon: Icons.savings_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _showStats = !_showStats),
              icon: Icon(
                _showStats ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(_showStats ? 'Ẩn thống kê' : 'Xem thống kê'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    this.warn = false,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 18, color: warn ? cs.error : cs.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            const Text('Không đọc được dữ liệu'),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhieuXuatTile extends StatelessWidget {
  const _PhieuXuatTile({
    required this.px,
    required this.onTap,
    required this.onDeleted,
  });

  final PhieuXuat px;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('px_${px.id ?? DateTime.now().microsecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa phiếu xuất'),
            content: Text('Xóa phiếu ${px.soPhieu} của ${px.tenKhachHang}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDeleted(),
      child: Card(
        child: ListTile(
          onTap: onTap,
          title: Text(
            '${px.soPhieu.isEmpty ? 'PX' : px.soPhieu} • ${px.tenKhachHang}',
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (px.ngayXuat != null) Text(Fmt.dateTime(px.ngayXuat!)),
              Text('${Fmt.m3(px.tongTheTichM3)} • ${Fmt.money(px.tongTien)}'),
              if (px.conNo > 0.5)
                Text(
                  'Còn nợ: ${Fmt.money(px.conNo)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
