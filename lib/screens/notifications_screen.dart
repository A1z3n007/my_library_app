import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Позже сюда придут уведомления\n'
            'о новых главах из интернета.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
