import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/db_helper.dart';
import '../services/excel_service.dart';

/// Sao lưu / phục hồi cơ sở dữ liệu và xuất báo cáo Excel.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const route = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final db = context.read<DbHelper>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu & Báo cáo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Báo cáo Excel', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('Xuất danh sách phiếu xuất'),
                  subtitle: const Text(
                    'File .xlsx, chia sẻ qua Zalo/Email/...',
                  ),
                  onTap: _busy ? null : () => _exportAll(db),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sao lưu dữ liệu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Sao lưu ra file .db'),
                  subtitle: const Text('Chỉ hỗ trợ trên Android/iOS'),
                  onTap: _busy ? null : () => _backup(db),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Phục hồi từ file .db'),
                  subtitle: const Text('Ghi đè toàn bộ dữ liệu hiện tại'),
                  onTap: _busy ? null : () => _restore(db),
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Toàn bộ dữ liệu nằm trên máy, không gửi đi đâu cả. '
                'Hãy sao lưu định kỳ để tránh mất dữ liệu khi cài lại ứng dụng.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAll(DbHelper db) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final list = await db.getPhieuXuats();
      if (list.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Chưa có phiếu xuất để xuất')),
        );
        return;
      }
      await ExcelService.exportPhieuXuats(list);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi xuất Excel: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup(DbHelper db) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await db.exportToFile();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'GỗSổ - Sao lưu dữ liệu'),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi sao lưu: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(DbHelper db) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Phục hồi dữ liệu'),
        content: const Text(
          'Toàn bộ dữ liệu hiện tại sẽ bị thay thế bằng file sao lưu. Bạn có chắc?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chọn file'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.pickFile(type: FileType.any);
      if (picked == null) return;
      await db.importFromBytes(await picked.readAsBytes());
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã phục hồi dữ liệu')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi phục hồi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
