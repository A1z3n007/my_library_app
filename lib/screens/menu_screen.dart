import 'package:flutter/material.dart';
import 'notes_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Меню')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.folder_open_outlined),
              title: Text('Локальная библиотека'),
              subtitle: Text('Импорт TXT / PDF / DOCX'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.note_outlined),
              title: const Text('Заметки'),
              subtitle: const Text('Все заметки из книг'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesScreen()),
                );
              },
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.bookmark_outline),
              title: Text('Закладки'),
              subtitle: Text('Открывай вкладку “Закладки” снизу'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.public_outlined),
              title: Text('Онлайн-источники'),
              subtitle: Text('Скоро подключим парсинг'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('О приложении'),
              subtitle: Text('NovelShelf • локальная читалка'),
            ),
          ),
        ],
      ),
    );
  }
}
