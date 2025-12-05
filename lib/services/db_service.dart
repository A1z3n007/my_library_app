import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/book_item.dart';
import '../models/bookmark_item.dart';
import '../models/note_item.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final base = await getDatabasesPath();
    final path = p.join(base, 'novelshelf_v1_2.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (d, _) async {
        await d.execute('''
          CREATE TABLE books(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            filePath TEXT NOT NULL,
            type TEXT NOT NULL,
            lastPage INTEGER NOT NULL DEFAULT 0,
            totalPages INTEGER NOT NULL DEFAULT 0,
            addedAt INTEGER NOT NULL
          );
        ''');

        await d.execute('''
          CREATE TABLE bookmarks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookId TEXT NOT NULL,
            page INTEGER NOT NULL,
            snippet TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          );
        ''');

        await d.execute('''
          CREATE INDEX idx_bookmarks_bookId ON bookmarks(bookId);
        ''');

        await d.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookId TEXT NOT NULL,
            page INTEGER NOT NULL,
            text TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          );
        ''');

        await d.execute('''
          CREATE INDEX idx_notes_bookId ON notes(bookId);
        ''');

        await d.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookId TEXT NOT NULL,
            openedAt INTEGER NOT NULL
          );
        ''');

        await d.execute('''
          CREATE INDEX idx_history_bookId ON history(bookId);
        ''');
      },
    );
  }

  // ---------------- BOOKS ----------------

  Future<void> upsertBook(BookItem book) async {
    final d = await db;
    await d.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BookItem>> getBooks({String? query}) async {
    final d = await db;

    if (query == null || query.trim().isEmpty) {
      final rows = await d.query('books', orderBy: 'addedAt DESC');
      return rows.map(BookItem.fromMap).toList();
    }

    final q = '%${query.trim()}%';
    final rows = await d.query(
      'books',
      where: 'title LIKE ?',
      whereArgs: [q],
      orderBy: 'addedAt DESC',
    );
    return rows.map(BookItem.fromMap).toList();
  }

  Future<void> updateProgress({
    required String bookId,
    required int lastPage,
    required int totalPages,
  }) async {
    final d = await db;
    await d.update(
      'books',
      {'lastPage': lastPage, 'totalPages': totalPages},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> deleteBook(String bookId) async {
    final d = await db;
    await d.delete('books', where: 'id = ?', whereArgs: [bookId]);
    await d.delete('bookmarks', where: 'bookId = ?', whereArgs: [bookId]);
    await d.delete('notes', where: 'bookId = ?', whereArgs: [bookId]);
    await d.delete('history', where: 'bookId = ?', whereArgs: [bookId]);
  }

  // -------------- BOOKMARKS --------------

  Future<int> addBookmark({
    required String bookId,
    required int page,
    required String snippet,
  }) async {
    final d = await db;
    return d.insert('bookmarks', {
      'bookId': bookId,
      'page': page,
      'snippet': snippet,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeBookmark(int id) async {
    final d = await db;
    await d.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasBookmark({required String bookId, required int page}) async {
    final d = await db;
    final rows = await d.query(
      'bookmarks',
      where: 'bookId = ? AND page = ?',
      whereArgs: [bookId, page],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<BookmarkItem>> getAllBookmarks() async {
    final d = await db;
    final rows = await d.query('bookmarks', orderBy: 'createdAt DESC');
    return rows.map(BookmarkItem.fromMap).toList();
  }

  Future<List<BookmarkItem>> getBookmarksForBook(String bookId) async {
    final d = await db;
    final rows = await d.query(
      'bookmarks',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(BookmarkItem.fromMap).toList();
  }

  // ---------------- NOTES ----------------

  Future<int> addNote({
    required String bookId,
    required int page,
    required String text,
  }) async {
    final d = await db;
    return d.insert('notes', {
      'bookId': bookId,
      'page': page,
      'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeNote(int id) async {
    final d = await db;
    await d.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NoteItem>> getAllNotes() async {
    final d = await db;
    final rows = await d.query('notes', orderBy: 'createdAt DESC');
    return rows.map(NoteItem.fromMap).toList();
  }

  Future<List<NoteItem>> getNotesForBook(String bookId) async {
    final d = await db;
    final rows = await d.query(
      'notes',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(NoteItem.fromMap).toList();
  }

  // ---------------- HISTORY ----------------

  Future<void> addHistoryOpen(String bookId) async {
    final d = await db;
    await d.insert('history', {
      'bookId': bookId,
      'openedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Возвращает книги, отсортированные по последнему открытию
  Future<List<BookItem>> getRecentBooks({int limit = 12}) async {
    final d = await db;

    final rows = await d.rawQuery(
      '''
      SELECT b.*, h.lastOpened
      FROM books b
      JOIN (
        SELECT bookId, MAX(openedAt) AS lastOpened
        FROM history
        GROUP BY bookId
      ) h ON b.id = h.bookId
      ORDER BY h.lastOpened DESC
      LIMIT ?
    ''',
      [limit],
    );

    return rows.map(BookItem.fromMap).toList();
  }
}
