import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _imageFile;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _captionController.dispose();
  }

  // --- 1. IMAGE SELECTION LOGIC ---
  Future<Future> _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Take a photo'),
                onPressed: () => _pickImage(ImageSource.camera, context)),
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Choose from Gallery'),
                onPressed: () => _pickImage(ImageSource.gallery, context)),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  void _pickImage(ImageSource source, BuildContext context) async {
    Navigator.pop(context); // Close the dialog
    XFile? file = await ImagePicker().pickImage(source: source);
    if (file != null) {
      setState(() {
        _imageFile = File(file.path);
      });
    }
  }
  // ------------------------------------

  // --- 2. UPLOAD & POST LOGIC (Share button) ---
  void postImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_imageFile == null) return;
      
      // A. Upload Image to Firebase Storage
      String fileName = 'posts/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // B. Get User Info (You'd ideally use a UserProvider here)
      // For now, fetch username from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      
      String username = userDoc.get('username') ?? 'Anonymous';
      String profileImage = userDoc.get('photoUrl') ?? '';

      // C. Save Post Data to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'username': username,
        'profileImage': profileImage, 
        'caption': _captionController.text,
        'imageUrl': downloadUrl,           // <--- CHECK THIS KEY NAME
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(), // <--- CHECK THIS KEY NAME
      });

      // D. Success & Cleanup
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post Shared Successfully!')),
        );
        // Reset state after posting
        setState(() {
          _isLoading = false;
          _imageFile = null;
          _captionController.clear();
        });
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error Sharing: ${e.toString()}')),
        );
      }
    }
  }
  // ------------------------------------


  // --- 3. UI BUILD METHODS ---
  Widget buildSelectImageView(BuildContext context) {
    return Center(
      child: IconButton(
        icon: const Icon(
          Icons.add_a_photo_outlined,
          size: 50,
          color: Colors.white,
        ),
        onPressed: () => _selectImage(context),
      ),
    );
  }

  Widget buildPostFormView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _imageFile = null;
              _captionController.clear();
            });
          },
        ),
        title: const Text('New Post'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: postImage,
            child: _isLoading 
                ? const Center(child: SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,)
                  ))
                : const Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    // TODO: Replace with current user's actual profile image
                    backgroundImage: NetworkImage('https://i.stack.imgur.com/l60Hf.png'), 
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      decoration: const InputDecoration(
                        hintText: "Write a caption...",
                        border: InputBorder.none,
                      ),
                      maxLines: 8,
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Add more options like tag people, add location here...
          ],
        ),
      ),
    );
  }

  // --- 4. MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    if (_imageFile != null) {
      return buildPostFormView();
    }
    
    // Default screen is the prompt to select an image
    return Scaffold(
      body: buildSelectImageView(context),
    );
  }
}