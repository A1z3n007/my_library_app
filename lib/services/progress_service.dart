import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static String _pageKey(String bookId) => 'progress_page_$bookId';
  static String _totalKey(String bookId) => 'progress_total_$bookId';

  static Future<void> saveProgress({
    required String bookId,
    required int page,
    required int total,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_pageKey(bookId), page);
    await sp.setInt(_totalKey(bookId), total);
  }

  static Future<(int page, int total)> loadProgress(String bookId) async {
    final sp = await SharedPreferences.getInstance();
    final page = sp.getInt(_pageKey(bookId)) ?? 0;
    final total = sp.getInt(_totalKey(bookId)) ?? 0;
    return (page, total);
  }

  static Future<void> clearProgress(String bookId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_pageKey(bookId));
    await sp.remove(_totalKey(bookId));
  }
}
