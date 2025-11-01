import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';

ValueNotifier<Authservice> authService = ValueNotifier(Authservice());

class Authservice {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
    await userCredential.user!.updateDisplayName(username);
    await userCredential.user!.reload();
    return userCredential;
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<String?> uploadProfilePicture(Uint8List imageBytes) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }

      if (kDebugMode) {
        print('Starting profile picture upload for user: $userId');
        print('Image size: ${imageBytes.length} bytes');
      }

      // Always use base64 fallback for simplicity and reliability
      if (imageBytes.length > 1000000) {
        throw Exception('Image too large. Please use a smaller image (max 1MB)');
      }

      final base64Image = base64Encode(imageBytes);
      final downloadUrl = 'data:image/jpeg;base64,$base64Image';

      if (kDebugMode) {
        print('Using base64 storage in Firestore');
      }

      // Save base64 to Firestore
      await firestore.collection('users').doc(userId).set({
        'profilePictureUrl': downloadUrl,
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('Profile picture saved successfully to Firestore');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR in uploadProfilePicture: $e');
        print('Error type: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  Future<String?> getProfilePictureUrl() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return null;

      final doc = await firestore.collection('users').doc(userId).get();
      return doc.data()?['profilePictureUrl'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting profile picture URL: $e');
      }
      return null;
    }
  }

  Future<void> saveUserProfile({
    String? contactNumber,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return;

      await firestore.collection('users').doc(userId).set({
        'contactNumber': contactNumber ?? '',
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user profile: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return null;

      final doc = await firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
}