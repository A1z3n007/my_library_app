import 'package:flutter/material.dart';

import '../models/book_item.dart';
import '../services/db_service.dart';
import 'reader/reader_router.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  bool _loading = true;
  List<BookItem> _continue = [];
  List<BookItem> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() => _loading = true);

    final books = await DBService.instance.getBooks();

    final cont = books.where((b) => b.lastPage > 0 || b.totalPages > 0).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    final recent = await DBService.instance.getRecentBooks(limit: 12);

    if (!mounted) return;
    setState(() {
      _continue = cont;
      _recent = recent;
      _loading = false;
    });
  }

  Widget _recentCard(BookItem b) {
    final progress = (b.totalPages > 0)
        ? '${b.lastPage + 1}/${b.totalPages}'
        : (b.lastPage > 0 ? 'стр. ${b.lastPage + 1}' : 'не начато');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openBookReader(context, b),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(_typeIcon(b.type)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Читать')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          Icon(Icons.chrome_reader_mode_outlined, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Твой центр чтения.\n'
                              'Продолжение, история и быстрый доступ.',
                              style: TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Недавно открытые',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  if (_recent.isEmpty)
                    const Text(
                      'История пока пуста.',
                      style: TextStyle(color: Colors.white54),
                    )
                  else
                    SizedBox(
                      height: 96,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recent.length,
                        itemBuilder: (_, i) => _recentCard(_recent[i]),
                      ),
                    ),

                  const SizedBox(height: 22),

                  const Text(
                    'Продолжить',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  if (_continue.isEmpty)
                    const Text(
                      'Пока нет активного чтения.',
                      style: TextStyle(color: Colors.white54),
                    )
                  else
                    ..._continue.map((b) {
                      final progress = (b.totalPages > 0)
                          ? '${b.lastPage + 1}/${b.totalPages}'
                          : 'стр. ${b.lastPage + 1}';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(_typeIcon(b.type)),
                          ),
                          title: Text(b.title),
                          subtitle: Text('${b.type.toUpperCase()} • $progress'),
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
