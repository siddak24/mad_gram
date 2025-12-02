import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String username;
  final String caption;
  final String postUrl;
  final String profImage;
  final DateTime datePublished;
  final List likes;

  const Post({
    required this.postId,
    required this.uid,
    required this.username,
    required this.caption,
    required this.postUrl,
    required this.profImage,
    required this.datePublished,
    required this.likes,
  });

  // Method to convert Firestore DocumentSnapshot into a Post object
  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      postId: snap.id, // Use the document ID as the Post ID
      uid: snapshot['uid'],
      username: snapshot['username'],
      caption: snapshot['caption'],
      postUrl: snapshot['imageUrl'], // Using 'imageUrl' as saved in AddPostScreen
      profImage: snapshot['profileImage'] as String,
      datePublished: (snapshot['timestamp'] as Timestamp).toDate(),
      likes: snapshot['likes'],
    );
  }
}
