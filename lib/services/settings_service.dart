import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kFontSize = 'reader_font_size';
  static const _kLineHeight = 'reader_line_height';
  static const _kAmoled = 'reader_amoled';

  static Future<double> getFontSize() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_kFontSize) ?? 18.0;
  }

  static Future<double> getLineHeight() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_kLineHeight) ?? 1.5;
  }

  static Future<bool> getAmoled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kAmoled) ?? false;
  }

  static Future<void> setFontSize(double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kFontSize, v);
  }

  static Future<void> setLineHeight(double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kLineHeight, v);
  }

  static Future<void> setAmoled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAmoled, v);
  }
}
