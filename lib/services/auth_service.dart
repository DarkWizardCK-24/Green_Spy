import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:green_spy/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Generate custom user ID (USERID000001 format)
  Future<String> _generateUserId() async {
    final counterDoc = _firestore.collection('metadata').doc('userCounter');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterDoc);

      int currentCount = 1;
      if (snapshot.exists) {
        currentCount = (snapshot.data()?['count'] ?? 0) + 1;
      }

      transaction.set(counterDoc, {'count': currentCount});

      // Format: USERID000001
      String customUserId = 'USERID${currentCount.toString().padLeft(6, '0')}';
      return customUserId;
    });
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      // Create Firebase Auth user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw Exception('User creation failed');

      // Generate custom user ID
      final String customUserId = await _generateUserId();

      // Create user profile in Firestore
      final UserModel userModel = UserModel(
        userId: customUserId,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      // Store custom user ID in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customUserId', customUserId);
      await prefs.setString('firebaseUid', user.uid);

      // Update display name
      await user.updateDisplayName(name);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw Exception('Sign in failed');

      // Get user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final UserModel userModel = UserModel.fromFirestore(userDoc);

      // Update last login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      // Store custom user ID in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customUserId', userModel.userId);
      await prefs.setString('firebaseUid', user.uid);

      return userModel.copyWith(lastLoginAt: DateTime.now());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      final User? user = currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile() {
    final User? user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    });
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? job,
    String? photoUrl,
  }) async {
    try {
      final User? user = currentUser;
      if (user == null) throw Exception('No user logged in');

      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (gender != null) updates['gender'] = gender;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }
      if (job != null) updates['job'] = job;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      // Update Firebase Auth display name
      if (name != null) {
        await user.updateDisplayName(name);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get custom user ID from SharedPreferences
  Future<String?> getCustomUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('customUserId');
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('customUserId');
      await prefs.remove('firebaseUid');
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'The email address is invalid';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return currentUser != null;
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final User? user = currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}
