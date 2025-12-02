import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class FirestoreService {
  final Logger _logger = Logger('FirestoreService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------------------------------------------
  // 1. LIKE/UNLIKE POST (Atomic Update)
  // ----------------------------------------------------
  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      // Check if the user ID is already in the likes list
      if (likes.contains(uid)) {
        // If liked, UNLIKE (remove UID from the array)
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        // If not liked, LIKE (add UID to the array)
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      _logger.severe('Error in likePost: ${e.toString()}');
    }
  }

  // ----------------------------------------------------
  // 2. FOLLOW/UNFOLLOW USER (Atomic Update on two documents)
  // ----------------------------------------------------
  Future<void> followUser(String currentUid, String followUid) async {
    try {
      DocumentSnapshot userSnap = await _firestore.collection('users').doc(followUid).get();
      List followers = (userSnap.data() as Map<String, dynamic>)['followers'];

      if (followers.contains(currentUid)) {
        // UNFOLLOW
        await _firestore.collection('users').doc(followUid).update({
          'followers': FieldValue.arrayRemove([currentUid])
        });
        await _firestore.collection('users').doc(currentUid).update({
          'following': FieldValue.arrayRemove([followUid])
        });
      } else {
        // FOLLOW
        await _firestore.collection('users').doc(followUid).update({
          'followers': FieldValue.arrayUnion([currentUid])
        });
        await _firestore.collection('users').doc(currentUid).update({
          'following': FieldValue.arrayUnion([followUid])
        });
      }
    } catch (e) {
      _logger.severe('Error in followUser: ${e.toString()}');
    }
  }
}