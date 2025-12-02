import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mad_gram/models/post.dart';
import 'package:mad_gram/screens/widgets/post_card.dart';
import 'package:mad_gram/screens/activity/messages_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _posts = querySnapshot.docs;
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
        _hasMore = querySnapshot.docs.length == 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      setState(() {
        _posts.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
        _hasMore = querySnapshot.docs.length == 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more posts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        title: const Text(
          'MadGram',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
        ),
        actions: [
          // 🌟 MESSAGE / DM BUTTON 🌟
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () {
              // Placeholder for future navigation to the Direct Messages screen
              if (context.mounted) {
                // 🌟 Navigation to the target screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _posts.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _posts.isEmpty
              ? const Center(child: Text('No posts yet! Be the first to share.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _posts.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    // Convert the Firestore Document to your Post model
                    Post post = Post.fromSnap(_posts[index]);
                    return PostCard(post: post);
                  },
                ),
    );
  }
}
