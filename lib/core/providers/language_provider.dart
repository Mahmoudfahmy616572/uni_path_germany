import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _locale = _detectSystemLocale();
  }

  Locale _detectSystemLocale() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return systemLocale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  bool get isArabic => _locale.languageCode == 'ar';
}
