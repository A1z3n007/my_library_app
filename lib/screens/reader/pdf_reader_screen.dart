import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../models/book_item.dart';
import '../../models/bookmark_item.dart';
import '../../services/db_service.dart';
import '../../services/settings_service.dart';

class PdfReaderScreen extends StatefulWidget {
  final BookItem book;
  const PdfReaderScreen({super.key, required this.book});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _amoled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await DBService.instance.addHistoryOpen(widget.book.id);
    _amoled = await SettingsService.getAmoled();

    setState(() {
      _currentPage = widget.book.lastPage;
      _totalPages = widget.book.totalPages;
    });
  }

  Future<void> _saveProgress() async {
    await DBService.instance.updateProgress(
      bookId: widget.book.id,
      lastPage: _currentPage,
      totalPages: _totalPages,
    );
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
        snippet: 'PDF • страница ${_currentPage + 1}',
      );
    }

    if (!mounted) return;
    setState(() {});
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
          FutureBuilder<bool>(
            future: DBService.instance.hasBookmark(
              bookId: widget.book.id,
              page: _currentPage,
            ),
            builder: (context, snap) {
              final marked = snap.data == true;
              return IconButton(
                tooltip: 'Закладка',
                onPressed: _toggleBookmark,
                icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border),
              );
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.book.filePath,
        enableSwipe: true,
        swipeHorizontal: false, // вертикально для манхвы-слайдов
        autoSpacing: false,
        pageFling: true,
        defaultPage: _currentPage,
        onRender: (pages) async {
          if (pages != null) {
            setState(() => _totalPages = pages);
            await _saveProgress();
          }
        },
        onPageChanged: (page, total) async {
          if (page == null) return;
          setState(() {
            _currentPage = page;
            _totalPages = total ?? _totalPages;
          });
          await _saveProgress();
        },
        onError: (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF ошибка: $e')));
        },
        onPageError: (page, e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Страница $page: $e')));
        },
      ),
    );
  }
}
