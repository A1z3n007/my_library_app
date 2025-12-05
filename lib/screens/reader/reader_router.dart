import 'package:flutter/material.dart';
import '../../models/book_item.dart';
import 'pdf_reader_screen.dart';
import 'text_reader_screen.dart';

void openBookReader(BuildContext context, BookItem book) {
  if (book.type == 'pdf') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
    );
    return;
  }

  if (book.type == 'txt' || book.type == 'docx') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TextReaderScreen(book: book)),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Формат пока не поддерживается.')),
  );
}
