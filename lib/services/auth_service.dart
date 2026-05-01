import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentFirebaseUid => _auth.currentUser?.uid;

  /// Lightweight sign-in — just establishes a Firebase Auth session (no Firestore fetch).
  Future<void> signInWithEmailDirect(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Lightweight account creation — just creates the Firebase Auth user.
  Future<void> createUserDirect(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      // Validate inputs first
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Email and password cannot be empty');
      }
      
      // Normalize email
      final normalizedEmail = email.trim().toLowerCase();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Sign in failed. Please try again.');
      }
      
      print('Firebase Auth successful for user: ${credential.user!.uid}');
      
      // Try to get user data from Firestore, but don't fail if it doesn't work
      try {
        final userModel = await _getUserWithRetry(credential.user!.uid);
        if (userModel != null) {
          print('User data retrieved from Firestore');
          return userModel;
        }
      } catch (e) {
        print('Failed to get user data from Firestore: $e');
        print('Creating basic user model from Firebase Auth data');
        
        // Create a basic user model from Firebase Auth data
        return UserModel(
          uid: credential.user!.uid,
          name: credential.user!.displayName ?? 'User',
          email: credential.user!.email ?? normalizedEmail,
          isAdmin: false, // Default to false for regular users
          phone: credential.user!.phoneNumber,
          profileImage: credential.user!.photoURL,
          createdAt: credential.user!.metadata.creationTime,
        );
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error in sign-in: ${e.code}');
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please check your email and password.';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Error in email sign-in: $e');
      // Handle PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails')) {
        final user = _auth.currentUser;
        if (user != null) {
          print('Sign-in succeeded natively despite Pigeon error. Proceeding...');
          return await _getUserWithRetry(user.uid) ?? UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? email.trim().toLowerCase(),
            isAdmin: false,
            phone: user.phoneNumber,
            profileImage: user.photoURL,
            createdAt: user.metadata.creationTime,
          );
        }
        throw Exception('Authentication failed. Please try again.');
      }
      rethrow;
    }
  }

  Future<UserModel?> _getUserWithRetry(String uid, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await _firestore.getUser(uid);
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        print('Retry ${i + 1} for getUser failed: $e');
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return null;
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String branch,
    required String batch,
    required String company,
    required String jobTitle,
    required String city,
    String? degree,
    String? profileImage,
  }) async {
    try {
      // Validate inputs first
      if (email.trim().isEmpty || password.trim().isEmpty || name.trim().isEmpty) {
        throw Exception('Email, password, and name are required');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }
      
      // Normalize email
      final normalizedEmail = email.trim().toLowerCase();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Account creation failed. Please try again.');
      }

      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name.trim(),
        email: normalizedEmail,
        isAdmin: false, // Default to false for regular users
        phone: phone.trim().isEmpty ? null : phone.trim(),
        branch: branch.trim().isEmpty ? null : branch.trim(),
        batch: batch.trim().isEmpty ? null : batch.trim(),
        company: company.trim().isEmpty ? null : company.trim(),
        jobTitle: jobTitle.trim().isEmpty ? null : jobTitle.trim(),
        city: city.trim().isEmpty ? null : city.trim(),
        degree: degree?.trim().isEmpty == true ? null : degree?.trim(),
        profileImage: profileImage?.trim().isEmpty == true ? null : profileImage?.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.createUser(userModel);
      print('User profile created successfully in Firestore');
      return userModel;
    } on FirebaseException catch (e) {
      print('Firestore error in sign-up: ${e.code}');
      String errorMessage;
      
      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'Permission denied. Please contact support.';
          break;
        case 'unavailable':
          errorMessage = 'Service temporarily unavailable. Please try again.';
          break;
        case 'not-found':
          errorMessage = 'User data not found. Please try again.';
          break;
        default:
          errorMessage = 'Profile creation failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error in sign-up: ${e.code}');
      String errorMessage;
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account with this email already exists.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password format.';
          break;
        default:
          errorMessage = 'Account creation failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Error in email sign-up: $e');
      // Handle PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails')) {
        final user = _auth.currentUser;
        if (user != null) {
          print('Sign-up succeeded natively despite Pigeon error. Creating Firestore profile...');
          final userModel = UserModel(
            uid: user.uid,
            name: name.trim(),
            email: email.trim().toLowerCase(),
            isAdmin: false,
            phone: phone.trim().isEmpty ? null : phone.trim(),
            branch: branch.trim().isEmpty ? null : branch.trim(),
            batch: batch.trim().isEmpty ? null : batch.trim(),
            company: company.trim().isEmpty ? null : company.trim(),
            jobTitle: jobTitle.trim().isEmpty ? null : jobTitle.trim(),
            city: city.trim().isEmpty ? null : city.trim(),
            degree: degree?.trim().isEmpty == true ? null : degree?.trim(),
            profileImage: profileImage?.trim().isEmpty == true ? null : profileImage?.trim(),
            createdAt: DateTime.now(),
          );
          try {
            await _firestore.createUser(userModel);
          } catch (firestoreError) {
            print('Firestore creation failed during Pigeon recovery: $firestoreError');
          }
          return userModel;
        }
        throw Exception('Account creation failed. Please try again.');
      }
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // First, ensure we're signed out from Google to avoid stale credentials
      await _googleSignIn.signOut();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      
      // Validate Google Auth tokens
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception('Failed to sign in with Google credentials');
      }

      print('Google Auth successful for user: ${userCredential.user!.uid}');

      // Try to get user data from Firestore, but don't fail if it doesn't work
      try {
        var userModel = await _getUserWithRetry(userCredential.user!.uid);
        if (userModel != null) {
          print('User data retrieved from Firestore');
          return userModel;
        }
      } catch (e) {
        print('Failed to get user data from Firestore: $e');
        print('Creating basic user model from Google Auth data');
      }

      // Create a basic user model from Google Auth data
      final displayName = userCredential.user!.displayName;
      final email = userCredential.user!.email;
      final photoURL = userCredential.user!.photoURL;
      
      if (email == null || email.isEmpty) {
        throw Exception('Could not get email from Google account');
      }
      
      return UserModel(
        uid: userCredential.user!.uid,
        name: (displayName is String && displayName.isNotEmpty) ? displayName : 'User',
        email: email,
        isAdmin: false, // Default to false for regular users
        profileImage: (photoURL is String && photoURL.isNotEmpty) ? photoURL : null,
        createdAt: userCredential.user!.metadata.creationTime,
      );
      
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error in Google sign-in: ${e.code}');
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = 'Google credentials are invalid or expired. Please try again.';
          break;
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with the same email address but different sign-in method.';
          break;
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          errorMessage = 'Google verification failed. Please try again.';
          break;
        default:
          errorMessage = 'Google sign-in failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Error in Google Sign-In: $e');
      if (e.toString().contains('PigeonUserDetails')) {
        final user = _auth.currentUser;
        if (user != null) {
          print('Google sign-in succeeded natively despite Pigeon error. Proceeding...');
          return await _getUserWithRetry(user.uid) ?? UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            isAdmin: false,
            profileImage: user.photoURL,
            createdAt: user.metadata.creationTime,
          );
        }
        throw Exception('Google authentication failed. Please try again.');
      }
      if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection and try again.');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      // Continue with sign out even if there's an error
    }
  }

  Future<void> refreshCredentials() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
    } catch (e) {
      print('Error refreshing credentials: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getUser(String uid) async {
    return await _getUserWithRetry(uid);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.updateUser(uid, data);
  }

  Future<void> updateProfileImage(String uid, String url) async {
    await _firestore.updateUser(uid, {'profileImage': url});
  }
}
