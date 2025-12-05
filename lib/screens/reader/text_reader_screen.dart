import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../models/book_item.dart';
import '../../models/bookmark_item.dart';
import '../../services/db_service.dart';
import '../../services/settings_service.dart';

class TextReaderScreen extends StatefulWidget {
  final BookItem book;
  const TextReaderScreen({super.key, required this.book});

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  late PageController _pageController;

  bool _loading = true;
  List<String> _pages = [];

  int _currentPage = 0;
  int _totalPages = 0;

  double _fontSize = 18;
  double _lineHeight = 1.5;
  bool _amoled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await DBService.instance.addHistoryOpen(widget.book.id);

    _fontSize = await SettingsService.getFontSize();
    _lineHeight = await SettingsService.getLineHeight();
    _amoled = await SettingsService.getAmoled();

    final text = await _loadText(widget.book);
    _pages = _paginate(text, _fontSize, _lineHeight);

    _totalPages = _pages.length;
    _currentPage = widget.book.lastPage.clamp(
      0,
      _totalPages == 0 ? 0 : _totalPages - 1,
    );

    setState(() => _loading = false);

    if (_totalPages > 0) {
      _pageController.jumpToPage(_currentPage);
      await _saveProgress();
    }
  }

  Future<String> _loadText(BookItem book) async {
    if (book.type == 'txt') {
      // На всякий случай: если попадётся cp1251-текст,
      // можно будет добавить переключатель кодировки позже.
      return File(book.filePath).readAsString();
    }
    if (book.type == 'docx') {
      return _extractDocxText(book.filePath);
    }
    return '';
  }

  Future<String> _extractDocxText(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final file = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => ArchiveFile('', 0, []),
      );

      if (file.name.isEmpty) return '';

      // ✅ Ключевой фикс: корректная декодировка UTF-8
      final dynamic content = file.content;

      List<int> raw;
      if (content is Uint8List) {
        raw = content;
      } else if (content is List<int>) {
        raw = content;
      } else {
        raw = <int>[];
      }

      final xmlStr = utf8.decode(raw, allowMalformed: true);
      final doc = XmlDocument.parse(xmlStr);

      // ✅ Более читабельно: собираем текст по абзацам
      final buffer = StringBuffer();

      for (final p in doc.findAllElements('w:p')) {
        final line = p.findAllElements('w:t').map((e) => e.text).join();
        final cleaned = line.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleaned.isNotEmpty) {
          buffer.writeln(cleaned);
          buffer.writeln();
        }
      }

      final result = buffer.toString().trim();
      return result;
    } catch (_) {
      return '';
    }
  }

  List<String> _paginate(String text, double fontSize, double lineHeight) {
    final t = text.trim();
    if (t.isEmpty) return [''];

    final base = 900.0;
    final kFont = 18.0 / fontSize;
    final kLine = 1.5 / lineHeight;

    final charsPerPage = (base * kFont * kLine).clamp(450.0, 1400.0).round();

    final chunks = <String>[];
    int i = 0;

    while (i < t.length) {
      final end = (i + charsPerPage < t.length) ? i + charsPerPage : t.length;
      chunks.add(t.substring(i, end));
      i = end;
    }

    return chunks;
  }

  Future<void> _saveProgress() async {
    await DBService.instance.updateProgress(
      bookId: widget.book.id,
      lastPage: _currentPage,
      totalPages: _totalPages,
    );
  }

  String _currentSnippet() {
    if (_pages.isEmpty) return '';
    final pageText = _pages[_currentPage].trim();
    if (pageText.isEmpty) return 'Страница ${_currentPage + 1}';
    return pageText.length <= 120
        ? pageText
        : '${pageText.substring(0, 120)}...';
  }

  Future<void> _toggleBookmark() async {
    final exists = await DBService.instance.hasBookmark(
      bookId: widget.book.id,
      page: _currentPage,
    );

    if (exists) {
      final List<BookmarkItem> list = await DBService.instance
          .getBookmarksForBook(widget.book.id);

      final matches = list.where((b) => b.page == _currentPage).toList();
      if (matches.isNotEmpty) {
        await DBService.instance.removeBookmark(matches.first.id);
      }
    } else {
      await DBService.instance.addBookmark(
        bookId: widget.book.id,
        page: _currentPage,
        snippet: _currentSnippet(),
      );
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Заметка'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Твоя заметка...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (text == null || text.isEmpty) return;

    await DBService.instance.addNote(
      bookId: widget.book.id,
      page: _currentPage,
      text: text,
    );
  }

  Future<void> _openSettings() async {
    double tempFont = _fontSize;
    double tempLine = _lineHeight;
    bool tempAmoled = _amoled;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Настройки чтения',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Размер шрифта'),
                      const Spacer(),
                      Text(tempFont.toStringAsFixed(0)),
                    ],
                  ),
                  Slider(
                    value: tempFont,
                    min: 14,
                    max: 26,
                    divisions: 12,
                    onChanged: (v) => setModal(() => tempFont = v),
                  ),
                  Row(
                    children: [
                      const Text('Межстрочный'),
                      const Spacer(),
                      Text(tempLine.toStringAsFixed(2)),
                    ],
                  ),
                  Slider(
                    value: tempLine,
                    min: 1.2,
                    max: 2.0,
                    divisions: 8,
                    onChanged: (v) => setModal(() => tempLine = v),
                  ),
                  SwitchListTile(
                    value: tempAmoled,
                    onChanged: (v) => setModal(() => tempAmoled = v),
                    title: const Text('AMOLED black'),
                    subtitle: const Text('Чистый чёрный фон в читалке'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Применить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;

    _fontSize = tempFont;
    _lineHeight = tempLine;
    _amoled = tempAmoled;

    await SettingsService.setFontSize(_fontSize);
    await SettingsService.setLineHeight(_lineHeight);
    await SettingsService.setAmoled(_amoled);

    final text = await _loadText(widget.book);
    _pages = _paginate(text, _fontSize, _lineHeight);
    _totalPages = _pages.length;
    _currentPage = _currentPage.clamp(
      0,
      _totalPages == 0 ? 0 : _totalPages - 1,
    );

    if (!mounted) return;
    setState(() {});
    if (_totalPages > 0) {
      _pageController.jumpToPage(_currentPage);
      await _saveProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _amoled
        ? Colors.black
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            tooltip: 'Заметка',
            onPressed: _loading ? null : _addNote,
            icon: const Icon(Icons.note_add_outlined),
          ),
          IconButton(
            tooltip: 'Настройки',
            onPressed: _loading ? null : _openSettings,
            icon: const Icon(Icons.text_fields_outlined),
          ),
          FutureBuilder<bool>(
            future: DBService.instance.hasBookmark(
              bookId: widget.book.id,
              page: _currentPage,
            ),
            builder: (context, snap) {
              final marked = snap.data == true;
              return IconButton(
                tooltip: 'Закладка',
                onPressed: _loading ? null : _toggleBookmark,
                icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pages.isEmpty
          ? const Center(child: Text('Файл пустой или не удалось прочитать.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                              )
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / _pages.length,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentPage + 1 < _pages.length
                            ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                              )
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Стр. ${_currentPage + 1} / ${_pages.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.book.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) async {
                      setState(() => _currentPage = i);
                      await _saveProgress();
                    },
                    itemBuilder: (_, i) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        child: Text(
                          _pages[i],
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: _lineHeight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
