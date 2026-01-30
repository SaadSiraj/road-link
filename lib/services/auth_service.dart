import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'shared_preferences_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    logRegistrationEvent(
      phone: phone,
      event: 'otp_request',
    );
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        logRegistrationEvent(
          phone: phone,
          event: 'otp_error',
          detail: e.message,
        );
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (verificationId, _) {
        logRegistrationEvent(
          phone: phone,
          event: 'otp_sent',
          detail: verificationId,
        );
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<String?> uploadProfilePhoto({
    required File file,
    required String uid,
  }) async {
    final ref = _storage.ref().child('users/$uid/profile_photo.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final snapshot = await ref.putFile(file, metadata);
    final url = await snapshot.ref.getDownloadURL();
    logRegistrationEvent(
      phone: uid,
      event: 'photo_uploaded',
      detail: url,
    );
    return url;
  }

  Future<void> saveUserProfile({
    required String uid,
    required String phone,
    required String fullName,
    String? photoUrl,
  }) async {
    final doc = _firestore.collection('users').doc(uid);
    final snapshot = await doc.get();

    final data = <String, dynamic>{
      'phone': phone,
      'name': fullName,
      'photoUrl': photoUrl ?? '',
    };

    // Only set createdAt the first time the doc is created.
    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      // By default, every new user is not an admin unless explicitly set later.
      data['isAdmin'] = false;
    } else {
      // If the document exists but doesn't have an isAdmin flag yet, default it to false
      final existingData = snapshot.data();
      final hasIsAdminKey = (existingData != null) && existingData.containsKey('isAdmin');
      if (!hasIsAdminKey) {
        data['isAdmin'] = false;
      }
    }

    await doc.set(data, SetOptions(merge: true));
    logRegistrationEvent(
      phone: phone,
      event: 'profile_saved',
    );

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await currentUser.updateDisplayName(fullName);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await currentUser.updatePhotoURL(photoUrl);
      }
    }
  }

  Future<bool> checkUserExists(String phone) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      logRegistrationEvent(
        phone: phone,
        event: 'check_user_exists_error',
        detail: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // Clear SharedPreferences login state
    await SharedPreferencesService.clearLoginState();
  }

  Future<void> deleteAccount(String uid) async {
    try {
      // Delete user's cars subcollection
      final carsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .get();
      
      // Delete all car documents
      for (var doc in carsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user's storage files (profile photo)
      try {
        final photoRef = _storage.ref().child('users/$uid/profile_photo.jpg');
        await photoRef.delete();
      } catch (e) {
        // Ignore storage errors (file might not exist)
        developer.log(
          'Storage deletion error (non-critical): $e',
          name: 'AuthService',
        );
      }

      // Delete user from Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        await currentUser.delete();
      }

      logRegistrationEvent(
        phone: uid,
        event: 'account_deleted',
      );
    } catch (e) {
      logRegistrationEvent(
        phone: uid,
        event: 'account_deletion_error',
        detail: e.toString(),
      );
      rethrow;
    }
  }

  void logRegistrationEvent({
    required String phone,
    required String event,
    String? detail,
  }) {
    developer.log(
      'Registration $event for $phone${detail != null ? ': $detail' : ''}',
      name: 'AuthService',
    );
  }
}
