// lib/screens/activity/messages_screen.dart

import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Direct Messages'),
      ),
      body: const Center(
        child: Text(
          "TODO: Messaging Feature Coming Soon!",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}