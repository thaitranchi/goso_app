import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/khach_hang.dart';
import '../utils/formatters.dart';
import 'so_no_screen.dart';

class KhachHangScreen extends StatefulWidget {
  const KhachHangScreen({super.key});

  static const route = '/khach-hang';

  @override
  State<KhachHangScreen> createState() => _KhachHangScreenState();
}

class _KhachHangScreenState extends State<KhachHangScreen> {
  final _ctrl = TextEditingController();
  List<KhachHang> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<DbHelper>();
    final list = await db.getKhachHangs(keyword: _ctrl.text.trim());
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  Future<void> _edit({KhachHang? kh}) async {
    final result = await showDialog<KhachHang>(
      context: context,
      builder: (_) => _KhachHangDialog(kh: kh),
    );
    if (result == null || !mounted) return;
    final db = context.read<DbHelper>();
    if (result.id == null) {
      await db.insertKhachHang(result);
    } else {
      await db.updateKhachHang(result);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => _edit(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm tên, điện thoại, địa chỉ...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    _load();
                  },
                ),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                ? const Center(child: Text('Chưa có khách hàng'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: _list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final kh = _list[i];
                        return Card(
                          child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SoNoScreen(khachHang: kh),
                                ),
                              );
                              _load();
                            },
                            leading: CircleAvatar(
                              child: Text(
                                kh.ten.isNotEmpty
                                    ? kh.ten[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(kh.ten),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (kh.dienThoai.isNotEmpty) Text(kh.dienThoai),
                                if (kh.coDuNo)
                                  Text(
                                    'Dư nợ: ${Fmt.money(kh.duNo)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(kh: kh),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm khách hàng'),
      ),
    );
  }
}

class _KhachHangDialog extends StatefulWidget {
  const _KhachHangDialog({this.kh});

  final KhachHang? kh;

  @override
  State<_KhachHangDialog> createState() => _KhachHangDialogState();
}

class _KhachHangDialogState extends State<_KhachHangDialog> {
  late final _ten = TextEditingController(text: widget.kh?.ten ?? '');
  late final _dt = TextEditingController(text: widget.kh?.dienThoai ?? '');
  late final _dc = TextEditingController(text: widget.kh?.diaChi ?? '');
  late final _gc = TextEditingController(text: widget.kh?.ghiChu ?? '');

  @override
  void dispose() {
    for (final c in [_ten, _dt, _dc, _gc]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final ten = _ten.text.trim();
    if (ten.isEmpty) return;
    Navigator.pop(
      context,
      KhachHang(
        id: widget.kh?.id,
        ten: ten,
        dienThoai: _dt.text.trim(),
        diaChi: _dc.text.trim(),
        ghiChu: _gc.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.kh == null ? 'Thêm khách hàng' : 'Sửa khách hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ten,
              decoration: const InputDecoration(labelText: 'Tên *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dt,
              decoration: const InputDecoration(labelText: 'Điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dc,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gc,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
