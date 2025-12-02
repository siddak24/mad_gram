import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import ProfileScreen for navigation
import 'profile_screen.dart'; 

class FollowListScreen extends StatelessWidget {
  final String title; // "Followers" or "Following"
  final List<dynamic> uids; // The list of user UIDs

  const FollowListScreen({
    super.key,
    required this.title,
    required this.uids,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: uids.length,
        itemBuilder: (context, index) {
          String userId = uids[index];
          
          // Use a FutureBuilder to fetch each user's profile based on their UID
          return FutureBuilder(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a brief placeholder while waiting for the user data
                return const ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.grey),
                  title: Text('Loading...', style: TextStyle(color: Colors.grey)),
                );
              }

              if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                return const SizedBox.shrink(); // Hide if user doesn't exist
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              
              return InkWell(
                onTap: () {
                  // Navigate to the user's profile screen
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: userId),
                  ));
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      userData['photoUrl'].isNotEmpty
                          ? userData['photoUrl']
                          : 'https://i.stack.imgur.com/l60Hf.png',
                    ),
                  ),
                  title: Text(userData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(userData['bio'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}