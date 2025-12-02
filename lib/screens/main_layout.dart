import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Use package imports for screens (reliable and unambiguous)
import 'package:mad_gram/screens/home/feed_screen.dart';
import 'package:mad_gram/screens/add_post/add_post_screen.dart';
import 'package:mad_gram/screens/search/search_screen.dart';
import 'package:mad_gram/screens/profile/profile_screen.dart';
import 'package:mad_gram/screens/activity/activity_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _page = 0;

  late final List<Widget> _homeScreens;

  @override
  void initState() {
    super.initState();

    // Get current user once
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // If user is not signed in yet, show a placeholder for the Profile tab
    // (you can replace this with a redirect to your login screen if desired)
    final Widget profileWidget = (currentUser != null)
        ? ProfileScreen(uid: currentUser.uid)
        : const Center(child: CircularProgressIndicator());

    _homeScreens = [
      const FeedScreen(),         // Index 0: Home Feed
      const SearchScreen(),       // Index 1: Search
      const AddPostScreen(),      // Index 2: Add Post
      const ActivityScreen(),     // Index 3: Activity/Notifications
      profileWidget,             // Index 4: Profile (uses current user's UID)
    ];
  }

  void navigationTapped(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _page,
        children: _homeScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _page,
        onTap: navigationTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''), // Activity
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}
