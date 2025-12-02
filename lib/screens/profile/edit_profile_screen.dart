import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // For image selection
import 'dart:io';
import 'package:mad_gram/services/auth_service.dart'; // To use the upload function
import 'package:mad_gram/core/utils/theme.dart'; 

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  File? _selectedImage; // To hold the newly picked image file

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData['username']);
    _bioController = TextEditingController(text: widget.userData['bio']);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // --- Profile Image Picker ---
  void selectImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- Update Profile Logic ---
  void updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String newPhotoUrl = widget.userData['photoUrl']; // Start with existing URL

      // 1. If a new image was selected, upload it first
      if (_selectedImage != null) {
        newPhotoUrl = await _authService.uploadImageToStorage(
          'profilePics', // Folder name
          _selectedImage!,
        );
      }
      
      // 2. Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _usernameController.text,
        'bio': _bioController.text,
        'photoUrl': newPhotoUrl, // Save the new (or old) URL
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: updateProfile,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20, height: 20, 
                      child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2.0,)
                    )
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: pinkAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Photo (Now functional)
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    // Use the newly selected local image or the network image
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider<Object>
                        : NetworkImage(widget.userData['photoUrl'].isNotEmpty
                            ? widget.userData['photoUrl']
                            : 'https://i.stack.imgur.com/l60Hf.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: selectImage, // Call the image picker function
                      icon: const Icon(Icons.add_a_photo, color: pinkAccent, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Username Input
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Bio Input
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}