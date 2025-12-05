import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_item.dart';
import '../services/db_service.dart';
import 'reader/reader_router.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  List<BookItem> _books = [];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = _search.text.trim();
    final books = await DBService.instance.getBooks(
      query: q.isEmpty ? null : q,
    );
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  Future<String> _ensureBooksDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(dir.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir.path;
  }

  String _detectType(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    if (ext == 'txt') return 'txt';
    if (ext == 'pdf') return 'pdf';
    if (ext == 'docx') return 'docx';
    return 'unknown';
  }

  String _titleFromPath(String path) {
    final base = p.basenameWithoutExtension(path);
    return base.trim().isEmpty ? 'Без названия' : base.trim();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'docx':
        return Icons.description_outlined;
      case 'txt':
      default:
        return Icons.text_snippet_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'pdf':
        return 'PDF';
      case 'docx':
        return 'DOCX';
      case 'txt':
      default:
        return 'TXT';
    }
  }

  Future<void> _importBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'pdf', 'docx'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final originalPath = result.files.single.path;
    if (originalPath == null) return;

    final type = _detectType(originalPath);
    if (type == 'unknown') return;

    final booksDir = await _ensureBooksDir();
    final fileName = p.basename(originalPath);

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName =
        '${p.basenameWithoutExtension(fileName)}_$stamp${p.extension(fileName)}';
    final newPath = p.join(booksDir, safeName);

    await File(originalPath).copy(newPath);

    final id = stamp.toString();
    final book = BookItem(
      id: id,
      title: _titleFromPath(originalPath),
      filePath: newPath,
      type: type,
      lastPage: 0,
      totalPages: 0,
      addedAt: stamp,
    );

    await DBService.instance.upsertBook(book);
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Импортировано: ${book.title}')));
  }

  Future<void> _deleteBook(BookItem book) async {
    await DBService.instance.deleteBook(book.id);
    try {
      final f = File(book.filePath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Каталог')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importBook,
        icon: const Icon(Icons.add),
        label: const Text('Импорт'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Быстрый поиск',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: const [
                    Icon(Icons.folder_open_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Библиотека локальных файлов.\n'
                        'Поддержка: TXT • PDF • DOCX',
                        style: TextStyle(color: Colors.white70, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 22),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_books.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.library_add_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Библиотека пуста.\n'
                          'Нажми “Импорт” и добавь свой файл.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._books.map((b) {
                final progress = (b.totalPages > 0)
                    ? '${b.lastPage + 1}/${b.totalPages}'
                    : (b.lastPage > 0 ? 'стр. ${b.lastPage + 1}' : 'не начато');

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(_typeIcon(b.type)),
                    ),
                    title: Text(b.title),
                    subtitle: Text('${_typeLabel(b.type)} • $progress'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteBook(b),
                    ),
                    onTap: () => openBookReader(context, b),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
