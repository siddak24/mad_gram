import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Screen Imports
import '../profile/profile_screen.dart'; 

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  // Search pagination variables
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoadingSearch = false;
  bool _hasMoreSearch = true;
  DocumentSnapshot? _lastSearchDocument;
  String _currentSearchTerm = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch({String searchTerm = ''}) async {
    if (_isLoadingSearch) return;

    setState(() {
      _isLoadingSearch = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .limit(20);

      if (searchTerm.isNotEmpty) {
        query = query
            .where('username', isGreaterThanOrEqualTo: searchTerm)
            .where('username', isLessThan: '$searchTerm\uf8ff');
      }

      if (_lastSearchDocument != null && searchTerm == _currentSearchTerm) {
        query = query.startAfterDocument(_lastSearchDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      setState(() {
        if (_lastSearchDocument == null || searchTerm != _currentSearchTerm) {
          _searchResults = snapshot.docs;
          _currentSearchTerm = searchTerm;
        } else {
          _searchResults.addAll(snapshot.docs);
        }
        _lastSearchDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreSearch = snapshot.docs.length == 20;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSearch = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search for a user...',
            labelStyle: TextStyle(color: Colors.white),
            filled: true,
            border: InputBorder.none,
          ),
          onFieldSubmitted: (_) {
            setState(() {
              // Trigger the search when the user hits Enter/Submit
              isSearching = true;
              _lastSearchDocument = null;
            });
            _performSearch(searchTerm: searchController.text);
          },
          onChanged: (value) {
            // If the search bar is cleared, revert to the explore view
            if (value.isEmpty) {
              setState(() {
                isSearching = false;
              });
            }
          },
        ),
      ),
      body: isSearching
          ? FutureBuilder(
              // Query the 'users' collection for prefix matching
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isGreaterThanOrEqualTo: searchController.text)
                  .where('username', isLessThan: '${searchController.text}z') // Prefix match
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // If there's an error, show it clearly (e.g., permission denied)
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                // Show list of users found
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var userSnap = snapshot.data!.docs[index];
                    
                    // 🌟 CRITICAL FIX: Safe access for profile fields 🌟
                    final String photoUrl = userSnap.data().containsKey('photoUrl') 
                                            ? userSnap['photoUrl'] ?? '' 
                                            : '';
                    final String bio = userSnap.data().containsKey('bio') 
                                       ? userSnap['bio'] ?? '' 
                                       : '';
                    final String username = userSnap['username'] ?? 'User Not Found';

                    return InkWell(
                      onTap: () {
                        // Navigate to the user's profile screen
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: userSnap['uid']),
                        ));
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            // Use photoUrl if available, otherwise use placeholder
                            photoUrl.isNotEmpty ? photoUrl : 'https://i.stack.imgur.com/l60Hf.png',
                          ),
                        ),
                        title: Text(username),
                        subtitle: Text(bio),
                      ),
                    );
                  },
                );
              },
            )
          : FutureBuilder(
              // Default/Explore View: Show a Grid of posts from all users when not actively searching
              future: FirebaseFirestore.instance.collection('posts').limit(24).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No explore posts found.', style: TextStyle(color: Colors.grey)));
                }

                // Show a grid of posts for the "Explore" feel
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot postSnap = snapshot.data!.docs[index];
                    return CachedNetworkImage(
                      imageUrl: postSnap['imageUrl'] ?? '', // Safely access imageUrl
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade900),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    );
                  },
                );
              },
            ),
    );
  }
}