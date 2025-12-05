class BookmarkItem {
  final int id;
  final String bookId;
  final int page;
  final String snippet;
  final int createdAt;

  const BookmarkItem({
    required this.id,
    required this.bookId,
    required this.page,
    required this.snippet,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'page': page,
    'snippet': snippet,
    'createdAt': createdAt,
  };

  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    return BookmarkItem(
      id: map['id'] as int,
      bookId: map['bookId'] as String,
      page: (map['page'] as int?) ?? 0,
      snippet: (map['snippet'] as String?) ?? '',
      createdAt: (map['createdAt'] as int?) ?? 0,
    );
  }
}
