import 'package:alma_desktop/app.dart';
import 'package:alma_desktop/core/config/desktop_window.dart';
import 'package:alma_desktop/core/config/injector_container.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDesktopWindow();
  await InjectorContainer.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
