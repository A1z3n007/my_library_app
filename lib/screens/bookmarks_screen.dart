import 'package:flutter/material.dart';

import '../models/book_item.dart';
import '../models/bookmark_item.dart';
import '../services/db_service.dart';
import 'reader/reader_router.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _loading = true;
  List<BookmarkItem> _bookmarks = [];
  Map<String, BookItem> _booksById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final books = await DBService.instance.getBooks();
    final bm = await DBService.instance.getAllBookmarks();

    _booksById = {for (final b in books) b.id: b};

    if (!mounted) return;
    setState(() {
      _bookmarks = bm;
      _loading = false;
    });
  }

  Future<void> _remove(BookmarkItem b) async {
    await DBService.instance.removeBookmark(b.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Закладки')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _bookmarks.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Закладок пока нет.\n'
                        'Открой книгу и нажми значок закладки.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _bookmarks.length,
                itemBuilder: (_, i) {
                  final b = _bookmarks[i];
                  final book = _booksById[b.bookId];

                  return Card(
                    child: ListTile(
                      title: Text(book?.title ?? 'Неизвестная книга'),
                      subtitle: Text(
                        'Стр. ${b.page + 1}\n${b.snippet}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(b),
                      ),
                      onTap: book == null
                          ? null
                          : () => openBookReader(context, book),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
