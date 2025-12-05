import 'package:flutter/material.dart';

import 'bookmarks_screen.dart';
import 'catalog_screen.dart';
import 'read_screen.dart';
import 'notifications_screen.dart';
import 'menu_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 1;

  final _pages = const [
    BookmarksScreen(),
    CatalogScreen(),
    ReadScreen(),
    NotificationsScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Закладки',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers_rounded),
            label: 'Каталог',
          ),
          NavigationDestination(
            icon: Icon(Icons.chrome_reader_mode_outlined),
            selectedIcon: Icon(Icons.chrome_reader_mode_rounded),
            label: 'Читать',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Уведомления',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_open_rounded),
            label: 'Меню',
          ),
        ],
      ),
    );
  }
}
