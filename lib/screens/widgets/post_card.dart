import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mad_gram/models/post.dart';
import 'package:intl/intl.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad_gram/services/firestore_service.dart'; 
import 'package:share_plus/share_plus.dart'; // Remember to run 'flutter pub add share_plus'


class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
        return const SizedBox.shrink(); // Hide if user is unexpectedly null
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // HEADER SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.post.profImage.isNotEmpty ? widget.post.profImage : 'https://i.stack.imgur.com/l60Hf.png', 
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () { /* TODO: Show delete/report dialog */ },
                  icon: const Icon(Icons.more_vert),
                )
              ],
            ),
          ),

          // POST IMAGE SECTION
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: widget.post.postUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),

          // LIKE, COMMENT & SHARE BUTTONS SECTION
          Row(
            children: [
              // LIKE BUTTON
              IconButton(
                icon: widget.post.likes.contains(user.uid)
                    ? const Icon(Icons.favorite, color: Colors.red) 
                    : const Icon(Icons.favorite_border, color: Colors.white), 
                onPressed: () async { 
                  await _firestoreService.likePost(
                    widget.post.postId, 
                    user.uid, 
                    widget.post.likes,
                  );
                },
              ),
              // COMMENT BUTTON
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () { /* TODO: Navigate to comments screen */ },
              ),
              // SHARE BUTTON (functional)
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () async { 
                   await Share.share('Check out this post on MadGram: ${widget.post.postUrl}');
                },
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () { /* TODO: Implement save/bookmark */ },
                  ),
                ),
              )
            ],
          ),
          
          // CAPTION & LIKES COUNT SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800),
                  child: Text(
                    '${widget.post.likes.length} likes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: '${widget.post.username} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.post.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // POST DATE
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    DateFormat.yMMMd().format(widget.post.datePublished),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}