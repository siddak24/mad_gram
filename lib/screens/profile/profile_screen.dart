import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Service and Screen Imports
import 'package:mad_gram/services/firestore_service.dart';
import 'edit_profile_screen.dart'; // For editing profile details
import 'follow_list_screen.dart'; // For viewing followers/following lists
import '../auth/login_screen.dart'; // For logout navigation

class ProfileScreen extends StatefulWidget {
  final String uid; // The UID of the user whose profile we are viewing
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = <String, dynamic>{};
  int postLen = 0;
  bool isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  bool isFollowing = false;

  // Pagination / posts state
  List<DocumentSnapshot> posts = [];
  bool isLoadingPosts = false;
  DocumentSnapshot? lastPostDocument;
  bool hasMorePosts = true;

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    getData();
  }

  // Fetch all required user data and their post count
  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Fetch User Details
      DocumentSnapshot userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final data = userSnap.data();
      userData = (data != null && data is Map<String, dynamic>)
          ? data
          : <String, dynamic>{};

      // Ensure followers/following keys exist and are Lists
      userData['followers'] = (userData['followers'] is List) ? userData['followers'] : <dynamic>[];
      userData['following'] = (userData['following'] is List) ? userData['following'] : <dynamic>[];

      // Check if the current user is following this profile
      if (currentUserId != null) {
        isFollowing = (userData['followers'] as List).contains(currentUserId);
      }

      // 2. Fetch Post Count
      QuerySnapshot postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();
      postLen = postSnap.docs.length;

      // Reset pagination state and load first batch of posts
      posts = [];
      lastPostDocument = null;
      hasMorePosts = true;
      await loadPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load posts with pagination
  Future<void> loadPosts() async {
    if (isLoadingPosts || !hasMorePosts) return;

    setState(() {
      isLoadingPosts = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .orderBy('timestamp', descending: true)
          .limit(9);

      if (lastPostDocument != null) {
        query = query.startAfterDocument(lastPostDocument!);
      }

      QuerySnapshot postSnap = await query.get();

      // Append results
      setState(() {
        if (lastPostDocument == null) {
          posts = List<DocumentSnapshot>.from(postSnap.docs);
        } else {
          posts.addAll(postSnap.docs);
        }

        lastPostDocument = postSnap.docs.isNotEmpty ? postSnap.docs.last : null;
        hasMorePosts = postSnap.docs.length == 9;
        isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingPosts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    }
  }

  // LOGOUT FUNCTION
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userData.isEmpty) {
      return const Center(
          child: Text("User data not found.", style: TextStyle(color: Colors.white)));
    }

    final bool isOwnProfile = currentUserId == widget.uid;

    final photoUrl = (userData['photoUrl'] ?? '').toString();
    final displayPhoto = photoUrl.isNotEmpty ? photoUrl : 'https://i.stack.imgur.com/l60Hf.png';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          userData['username'] ?? 'Profile',
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. HEADER (Profile Picture & Stats)
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: 40,
                      backgroundImage: CachedNetworkImageProvider(displayPhoto),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildStatColumn('posts', postLen),

                              // Followers count (Tappable)
                              GestureDetector(
                                onTap: () {
                                  final followers = (userData['followers'] is List)
                                      ? List<String>.from(userData['followers'])
                                      : <String>[];
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => FollowListScreen(
                                      title: 'Followers',
                                      uids: followers,
                                    ),
                                  ));
                                },
                                child: buildStatColumn(
                                    'followers',
                                    (userData['followers'] is List)
                                        ? (userData['followers'] as List).length
                                        : 0),
                              ),

                              // Following count (Tappable)
                              GestureDetector(
                                onTap: () {
                                  final following = (userData['following'] is List)
                                      ? List<String>.from(userData['following'])
                                      : <String>[];
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => FollowListScreen(
                                      title: 'Following',
                                      uids: following,
                                    ),
                                  ));
                                },
                                child: buildStatColumn(
                                    'following',
                                    (userData['following'] is List)
                                        ? (userData['following'] as List).length
                                        : 0),
                              ),
                            ],
                          ),

                          // Action Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // EDIT PROFILE BUTTON (Only for own profile)
                              if (isOwnProfile)
                                buildProfileButton(
                                  'Edit Profile',
                                  () async {
                                    await Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                          EditProfileScreen(userData: userData),
                                    ));
                                    // Refresh data when returning from edit screen
                                    await getData();
                                  },
                                  isPrimary: false,
                                ),

                              // LOGOUT BUTTON (Only for own profile)
                              if (isOwnProfile)
                                buildProfileButton('Sign Out', logOut, isPrimary: false),

                              // FOLLOW/UNFOLLOW BUTTON (Only for other users)
                              if (!isOwnProfile)
                                buildProfileButton(
                                  isFollowing ? 'Unfollow' : 'Follow',
                                  () async {
                                    if (currentUserId == null) return;
                                    await _firestoreService.followUser(currentUserId!, widget.uid);
                                    // Re-fetch data to update counts and button text
                                    await getData();
                                  },
                                  isPrimary: !isFollowing,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 2. NAME & BIO
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    userData['username'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    (userData['bio'] ?? '').toString(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // 3. USER POSTS GRID
          posts.isEmpty && !isLoadingPosts
              ? (isOwnProfile
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text("You haven't posted anything yet.",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text("No posts yet.", style: TextStyle(color: Colors.grey)),
                      ),
                    ))
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!isLoadingPosts &&
                        hasMorePosts &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      loadPosts();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Prevent inner scroll conflict
                    itemCount: posts.length + (hasMorePosts ? 1 : 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 1.5,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }
                      final DocumentSnapshot postSnap = posts[index];
                      final imageUrl = (postSnap['imageUrl'] ?? '').toString();
                      return Container(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                )
        ],
      ),
    );
  }

  // Helper Widget for the stat numbers
  Column buildStatColumn(String label, int num) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget for the action buttons
  Widget buildProfileButton(String text, VoidCallback function, {bool isPrimary = true}) {
    Color buttonColor = isPrimary ? Colors.blue : Colors.black;
    Color textColor = isPrimary ? Colors.white : Colors.white;

    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: TextButton(
        onPressed: function,
        child: Container(
          decoration: BoxDecoration(
            color: buttonColor,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          width: 120,
          height: 27,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
