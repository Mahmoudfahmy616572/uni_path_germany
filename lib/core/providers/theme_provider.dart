import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.system;

  bool get isDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;
}
