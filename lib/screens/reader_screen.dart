import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/progress_service.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController _pageController;

  List<String> _pages = [];
  bool _loading = true;

  int _currentPage = 0;

  // Для учебного проекта — простая пагинация по символам.
  // Можно потом заменить на более умную под размер экрана/шрифта.
  static const int _charsPerPage = 900;

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

  List<String> _paginate(String text) {
    final t = text.trim();
    if (t.isEmpty) return [''];

    final chunks = <String>[];
    int i = 0;

    while (i < t.length) {
      final end = (i + _charsPerPage < t.length) ? i + _charsPerPage : t.length;
      chunks.add(t.substring(i, end));
      i = end;
    }

    return chunks;
  }

  Future<void> _init() async {
    _pages = _paginate(widget.book.content);

    final (savedPage, savedTotal) = await ProgressService.loadProgress(
      widget.book.id,
    );

    // если контент поменялся, но прогресс старый — аккуратно подрежем
    final total = _pages.length;
    int start = savedPage;

    if (savedTotal != 0 && savedTotal != total) {
      // попытка сохранить пропорцию
      final ratio = savedPage / savedTotal;
      start = (ratio * total).floor();
    }

    if (start < 0) start = 0;
    if (start >= total) start = total - 1;

    setState(() {
      _currentPage = start;
      _loading = false;
    });

    _pageController.jumpToPage(_currentPage);

    await ProgressService.saveProgress(
      bookId: widget.book.id,
      page: _currentPage,
      total: total,
    );
  }

  Future<void> _save() async {
    await ProgressService.saveProgress(
      bookId: widget.book.id,
      page: _currentPage,
      total: _pages.length,
    );
  }

  Future<void> _goToPageDialog() async {
    final controller = TextEditingController(text: '${_currentPage + 1}');

    final page = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Перейти на страницу'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '1..${_pages.length}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final raw = controller.text.trim();
                final val = int.tryParse(raw);
                if (val == null) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context, val);
              },
              child: const Text('Перейти'),
            ),
          ],
        );
      },
    );

    if (page == null) return;

    int target = page - 1;
    if (target < 0) target = 0;
    if (target >= _pages.length) target = _pages.length - 1;

    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_currentPage + 1 >= _pages.length) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _prev() {
    if (_currentPage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            tooltip: 'Перейти на страницу',
            onPressed: _loading ? null : _goToPageDialog,
            icon: const Icon(Icons.pin_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // прогресс/навигация
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _prev,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _pages.isEmpty
                              ? 0
                              : (_currentPage + 1) / _pages.length,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      IconButton(
                        onPressed: _next,
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
                        book.country,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // страницы
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) async {
                      setState(() => _currentPage = i);
                      await _save();
                    },
                    itemBuilder: (context, i) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        child: Text(
                          _pages[i],
                          style: const TextStyle(fontSize: 18, height: 1.5),
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
