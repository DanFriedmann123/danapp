import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get current authenticated user ID
  static String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Get current authenticated user ID or throw exception
  static String getCurrentUserIdOrThrow() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  /// Test Firebase connection and authentication
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
          'user_id': null,
        };
      }

      // Test Firestore connection
      await _firestore.collection('test').doc('connection_test').get();

      return {
        'success': true,
        'user_id': user.uid,
        'user_email': user.email,
        'message': 'Firebase connection successful',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'user_id': null};
    }
  }

  // Database Operations (Firestore)

  /// Add a document to a collection
  static Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collection).add(data);
  }

  /// Get a document by ID
  static Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  /// Update a document
  static Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  /// Delete a document
  static Future<void> deleteDocument(
    String collection,
    String documentId,
  ) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  /// Get all documents from a collection
  static Stream<QuerySnapshot> getDocumentsStream(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  /// Query documents with filters
  static Stream<QuerySnapshot> queryDocuments(
    String collection, {
    String? field,
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isLessThan,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }
    if (field != null && isGreaterThan != null) {
      query = query.where(field, isGreaterThan: isGreaterThan);
    }
    if (field != null && isLessThan != null) {
      query = query.where(field, isLessThan: isLessThan);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Storage Operations (Firebase Storage)

  /// Upload a file to Firebase Storage
  static Future<String> uploadFile(String path, File file) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload bytes to Firebase Storage
  static Future<String> uploadBytes(String path, Uint8List bytes) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putData(bytes);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Get download URL for a file
  static Future<String> getDownloadURL(String path) async {
    Reference ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }

  /// Delete a file from Firebase Storage
  static Future<void> deleteFile(String path) async {
    Reference ref = _storage.ref().child(path);
    await ref.delete();
  }

  /// List files in a directory
  static Future<ListResult> listFiles(String path) async {
    Reference ref = _storage.ref().child(path);
    return await ref.listAll();
  }

  // Example usage methods for common scenarios

  /// Save user profile data
  static Future<void> saveUserProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set(profileData, SetOptions(merge: true));
  }

  /// Upload user profile image
  static Future<String> uploadProfileImage(
    String userId,
    File imageFile,
  ) async {
    String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String path = 'users/$userId/profile_images/$fileName';
    return await uploadFile(path, imageFile);
  }

  /// Save a note or document
  static Future<String> saveNote(
    String userId,
    Map<String, dynamic> noteData,
  ) async {
    DocumentReference docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(noteData);
    return docRef.id;
  }

  /// Get user's notes
  static Stream<QuerySnapshot> getUserNotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
