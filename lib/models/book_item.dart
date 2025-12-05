class BookItem {
  final String id;
  final String title;
  final String filePath;
  final String type; // txt | pdf | docx
  final int lastPage;
  final int totalPages;
  final int addedAt;

  const BookItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.type,
    required this.lastPage,
    required this.totalPages,
    required this.addedAt,
  });

  BookItem copyWith({
    String? id,
    String? title,
    String? filePath,
    String? type,
    int? lastPage,
    int? totalPages,
    int? addedAt,
  }) {
    return BookItem(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'filePath': filePath,
    'type': type,
    'lastPage': lastPage,
    'totalPages': totalPages,
    'addedAt': addedAt,
  };

  factory BookItem.fromMap(Map<String, dynamic> map) {
    return BookItem(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      type: map['type'] as String,
      lastPage: (map['lastPage'] as int?) ?? 0,
      totalPages: (map['totalPages'] as int?) ?? 0,
      addedAt: (map['addedAt'] as int?) ?? 0,
    );
  }
}
