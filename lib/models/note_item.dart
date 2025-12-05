class NoteItem {
  final int id;
  final String bookId;
  final int page;
  final String text;
  final int createdAt;

  const NoteItem({
    required this.id,
    required this.bookId,
    required this.page,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'page': page,
    'text': text,
    'createdAt': createdAt,
  };

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map['id'] as int,
      bookId: map['bookId'] as String,
      page: (map['page'] as int?) ?? 0,
      text: (map['text'] as String?) ?? '',
      createdAt: (map['createdAt'] as int?) ?? 0,
    );
  }
}
