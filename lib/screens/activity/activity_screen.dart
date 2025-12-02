import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Activity'),
      ),
      body: ListView(
        children: [
          _buildActivityItem(
            context,
            'mad_dev',
            'started following you.',
            'https://i.stack.imgur.com/l60Hf.png',
          ),
          _buildActivityItem(
            context,
            'flutter_fan',
            'liked your photo.',
            'https://i.stack.imgur.com/l60Hf.png',
          ),
          _buildActivityItem(
            context,
            'new_user',
            'commented: "Cool post!"',
            'https://i.stack.imgur.com/l60Hf.png',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String username, String action, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(imageUrl),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
                children: [
                  TextSpan(
                    text: username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $action'),
                ],
              ),
            ),
          ),
          // Optionally add a follow button or post preview here
        ],
      ),
    );
  }
}