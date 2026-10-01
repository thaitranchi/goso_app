import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../utils/volume_calculator.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static const route = '/calculator';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tính m³ ngoài bãi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gỗ tròn / lóng', icon: Icon(Icons.circle_outlined)),
              Tab(text: 'Gỗ xẻ / phôi', icon: Icon(Icons.crop_landscape)),
            ],
          ),
        ),
        // Mỗi tab một StatefulWidget riêng để không dùng chung TextEditingController.
        body: const TabBarView(
          children: [
            KeyedSubtree(key: Key('tab-tron'), child: _TronTab()),
            KeyedSubtree(key: Key('tab-xa'), child: _XaTab()),
          ],
        ),
      ),
    );
  }
}

class _TronTab extends StatefulWidget {
  const _TronTab();

  @override
  State<_TronTab> createState() => _TronTabState();
}

class _TronTabState extends State<_TronTab> {
  final _dkCtrl = TextEditingController();
  final _daiCtrl = TextEditingController();
  final _slCtrl = TextEditingController(text: '1');

  TheTich? _result;
  String? _error;

  @override
  void dispose() {
    _dkCtrl.dispose();
    _daiCtrl.dispose();
    _slCtrl.dispose();
    super.dispose();
  }

  void _calc() {
    setState(() {
      _error = null;
      try {
        _result = VolumeCalculator.tron(
          duongKinhCm: double.parse(_dkCtrl.text),
          chieuDaiM: double.parse(_daiCtrl.text),
          soLuong: int.tryParse(_slCtrl.text) ?? 1,
        );
      } catch (_) {
        _error =
            'Vui lòng nhập đường kính (cm), chiều dài (m), số lượng hợp lệ';
        _result = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NumberField(controller: _dkCtrl, label: 'Đường kính (cm)'),
        _NumberField(controller: _daiCtrl, label: 'Chiều dài (m)'),
        _NumberField(controller: _slCtrl, label: 'Số lượng (cây/thanh)'),
        FilledButton(onPressed: _calc, child: const Text('Tính m³')),
        const SizedBox(height: 24),
        _ResultCard(result: _result, error: _error),
        Text(
          'Công thức: V = π × (D/200)² × L',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _XaTab extends StatefulWidget {
  const _XaTab();

  @override
  State<_XaTab> createState() => _XaTabState();
}

class _XaTabState extends State<_XaTab> {
  final _dayCtrl = TextEditingController();
  final _rongCtrl = TextEditingController();
  final _daiCtrl = TextEditingController();
  final _slCtrl = TextEditingController(text: '1');

  TheTich? _result;
  String? _error;

  @override
  void dispose() {
    _dayCtrl.dispose();
    _rongCtrl.dispose();
    _daiCtrl.dispose();
    _slCtrl.dispose();
    super.dispose();
  }

  void _calc() {
    setState(() {
      _error = null;
      try {
        _result = VolumeCalculator.xa(
          dayCm: double.parse(_dayCtrl.text),
          rongCm: double.parse(_rongCtrl.text),
          chieuDaiM: double.parse(_daiCtrl.text),
          soLuong: int.tryParse(_slCtrl.text) ?? 1,
        );
      } catch (_) {
        _error = 'Vui lòng nhập dày, rộng (cm), chiều dài (m), số lượng hợp lệ';
        _result = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NumberField(controller: _dayCtrl, label: 'Dày (cm)'),
        _NumberField(controller: _rongCtrl, label: 'Rộng (cm)'),
        _NumberField(controller: _daiCtrl, label: 'Chiều dài (m)'),
        _NumberField(controller: _slCtrl, label: 'Số lượng (thanh)'),
        FilledButton(onPressed: _calc, child: const Text('Tính m³')),
        const SizedBox(height: 24),
        _ResultCard(result: _result, error: _error),
        Text(
          'Công thức: V = (Dày/100) × (Rộng/100) × L',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.error});

  final TheTich? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
      );
    }
    final r = result;
    if (r == null) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thể tích 1 thanh: ${Fmt.m3(r.thetichMotThanh)}'),
            const SizedBox(height: 6),
            Text('Số lượng: ${Fmt.soLuong.format(r.soLuong)}'),
            const SizedBox(height: 6),
            Text(
              'TỔNG: ${Fmt.m3(r.tongTheTich)}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
