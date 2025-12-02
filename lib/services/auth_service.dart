import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ----------------------------------------------------
  // 1. SIGN UP USER (Creates user in Auth AND saves profile in Firestore)
  // ----------------------------------------------------
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
  }) async {
    String res = "An internal error has occurred"; // Default error message
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        
        // 1. Create user in Firebase Authentication
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. Save additional user data to Firestore
        // NOTE: This is the section causing the internal error if rules are wrong
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'username': username,
          'email': email,
          'bio': bio,
          'followers': [],
          'following': [],
          'photoUrl': '', 
        });

        res = "success";
      } else {
        res = "Please enter all the required fields.";
      }
    } on FirebaseAuthException catch (err) {
      // Handles email-already-in-use, weak-password, etc.
      res = err.message ?? "Authentication failed";
    } catch (err) {
      // Handles general errors, including Firestore write failure if permissions are wrong
      res = err.toString();
    }
    return res; 
  }

  // ----------------------------------------------------
  // 2. LOG IN USER
  // ----------------------------------------------------
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "An internal error has occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter email and password.";
      }
    } on FirebaseAuthException catch (err) {
      // Handles invalid-credential, user-not-found, etc.
      res = err.message ?? "Login failed";
    } catch (err) {
      res = err.toString();
    }
    return res; 
  }
  Future<String> uploadImageToStorage(String childName, file) async {
    // 1. Create a reference to the storage location
    Reference ref = _storage.ref().child(childName).child(_auth.currentUser!.uid);

    // 2. Upload the file (using putData is often cleaner for picked files)
    // NOTE: This assumes 'file' is the byte data (Uint8List) or a File object. 
    // We will use File in the EditProfileScreen.
    UploadTask uploadTask = ref.putFile(file);
    
    // 3. Wait for upload to complete
    TaskSnapshot snap = await uploadTask;
    
    // 4. Get the download URL
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }
}