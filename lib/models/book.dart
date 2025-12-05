class Book {
  final String id;
  final String title;
  final String subtitle;
  final String country;
  final String coverUrl;

  /// Для учебного проекта — простой текст.
  /// Позже можно заменить на загрузку с файла/сети.
  final String content;

  const Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.country,
    required this.coverUrl,
    required this.content,
  });
}
