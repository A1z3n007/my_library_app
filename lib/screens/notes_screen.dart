import 'package:flutter/material.dart';

import '../models/book_item.dart';
import '../models/note_item.dart';
import '../services/db_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _loading = true;
  List<NoteItem> _notes = [];
  Map<String, BookItem> _booksById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final books = await DBService.instance.getBooks();
    final notes = await DBService.instance.getAllNotes();

    _booksById = {for (final b in books) b.id: b};

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _remove(NoteItem n) async {
    await DBService.instance.removeNote(n.id);
    await _load();
  }

  String _bookTitle(String bookId) {
    return _booksById[bookId]?.title ?? 'Неизвестная книга';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заметки')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Заметок пока нет.\n'
                        'Открой книгу и добавь заметку с иконкой сверху.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _notes.length,
                itemBuilder: (_, i) {
                  final n = _notes[i];

                  return Card(
                    child: ListTile(
                      title: Text(_bookTitle(n.bookId)),
                      subtitle: Text(
                        'Стр. ${n.page + 1}\n${n.text}',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(n),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
