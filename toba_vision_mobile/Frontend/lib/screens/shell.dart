import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'detection/detection_screen.dart';
import 'finance/finance_screen.dart';
import 'harvest/harvest_screen.dart';
import 'home_screen.dart';
import 'weather/weather_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  Widget _page() {
    switch (_index) {
      case 1:
        return DetectionScreen(onBack: () => _go(0));
      case 2:
        return const FinanceScreen();
      case 3:
        return const HarvestScreen();
      case 4:
        return const WeatherScreen();
      default:
        return HomeScreen(onNavigate: _go);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _page()),
      bottomNavigationBar: AppBottomNav(index: _index, onTap: _go),
    );
  }
}
