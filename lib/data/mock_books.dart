import '../models/book.dart';

const _lorem = '''
Глава 1

В тот день город был особенно тихим.
Пыль медленно оседала на каменных улицах, а ветер нес чужие разговоры.

Глава 2

Он открыл дверь, не зная, что за ней начнётся новая жизнь.
Слова старика звучали как предупреждение и приглашение одновременно.

Глава 3

Путь героя никогда не бывает прямым.
Каждый выбор оставляет след, и иногда цена слишком высока.

Глава 4

Ночь была долгой.
Но именно в темноте люди находят самые честные ответы.

Глава 5

Сила — это не способность победить других.
Сила — это умение не проиграть себе.
''';

final mockBooks = <Book>[
  Book(
    id: 'omniscient',
    title: 'Всеведущая Точка Зрения',
    subtitle: 'от Первого Лица',
    country: 'Корея',
    coverUrl:
        'https://images.unsplash.com/photo-1529655683826-aba9b3e77383?q=80&w=800',
    content: _lorem * 12,
  ),
  Book(
    id: 'sword-king',
    title: 'Король Меча',
    subtitle: '(Новелла)',
    country: 'Корея',
    coverUrl:
        'https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=800',
    content: _lorem * 10,
  ),
  Book(
    id: 'heroes-hunted',
    title: 'Главные Герои',
    subtitle: 'Пытаются Убить Меня',
    country: 'Корея',
    coverUrl:
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=800',
    content: _lorem * 11,
  ),
  Book(
    id: 'sss-class',
    title: 'Пробуждение единственного',
    subtitle: 'класса с рангом SSS!',
    country: 'Корея',
    coverUrl:
        'https://images.unsplash.com/photo-1455885666463-5ef768f9d5a8?q=80&w=800',
    content: _lorem * 14,
  ),
];
