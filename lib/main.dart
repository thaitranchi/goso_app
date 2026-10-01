import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'database/db_helper.dart';
import 'views/calculator_screen.dart';
import 'views/home_screen.dart';
import 'views/khach_hang_screen.dart';
import 'views/phieu_xuat_screen.dart';
import 'views/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');

  // Mở sẵn database để vào app không phải chờ, và để lỗi SQLite lộ ra sớm.
  try {
    await DbHelper.instance.db;
  } catch (e) {
    debugPrint('Không mở được database: $e');
  }

  runApp(const GoSoApp());
}

class GoSoApp extends StatelessWidget {
  const GoSoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider(create: (_) => DbHelper.instance)],
      child: MaterialApp(
        title: 'GỗSổ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.brown,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
        routes: {
          CalculatorScreen.route: (_) => const CalculatorScreen(),
          KhachHangScreen.route: (_) => const KhachHangScreen(),
          PhieuXuatScreen.route: (_) => const PhieuXuatScreen(),
          SettingsScreen.route: (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
