import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class LentItem {
  final String id;
  final String userId;
  final String item;
  final String person;
  final String date;
  final String notes;
  final bool isReturned;
  final DateTime createdAt;

  LentItem({
    required this.id,
    required this.userId,
    required this.item,
    required this.person,
    required this.date,
    required this.notes,
    required this.isReturned,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'item': item,
      'person': person,
      'date': date,
      'notes': notes,
      'is_returned': isReturned,
      'created_at': createdAt,
    };
  }

  factory LentItem.fromMap(String id, Map<String, dynamic> data) {
    return LentItem(
      id: id,
      userId: data['user_id'] ?? '',
      item: data['item'] ?? '',
      person: data['person'] ?? '',
      date: data['date'] ?? '',
      notes: data['notes'] ?? '',
      isReturned: data['is_returned'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}

class WhereIsMyService {
  /// Add a new lent item
  static Future<String> addLentItem(LentItem item) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'lent_items',
      item.toMap(),
    );
    return docRef.id;
  }

  /// Get all lent items for a user
  static Stream<QuerySnapshot> getUserLentItems(String userId) {
    return FirebaseService.queryDocuments(
      'lent_items',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Update lent item
  static Future<void> updateLentItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseService.updateDocument('lent_items', itemId, data);
  }

  /// Delete lent item
  static Future<void> deleteLentItem(String itemId) async {
    await FirebaseService.deleteDocument('lent_items', itemId);
  }

  /// Toggle returned status
  static Future<void> toggleReturnedStatus(
    String itemId,
    bool isReturned,
  ) async {
    await updateLentItem(itemId, {'is_returned': isReturned});
  }

  /// Get lent items summary
  static Future<Map<String, dynamic>> getLentItemsSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'lent_items',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    int totalItems = 0;
    int returnedItems = 0;
    int pendingItems = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalItems++;
        bool isReturned = data['is_returned'] ?? false;
        if (isReturned) {
          returnedItems++;
        } else {
          pendingItems++;
        }
      }
    }

    return {
      'total_items': totalItems,
      'returned_items': returnedItems,
      'pending_items': pendingItems,
    };
  }

  /// Get lent items by status
  static Stream<QuerySnapshot> getLentItemsByStatus(
    String userId,
    bool isReturned,
  ) {
    return FirebaseService.queryDocuments(
      'lent_items',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Search lent items
  static Stream<QuerySnapshot> searchLentItems(
    String userId,
    String searchTerm,
  ) {
    return FirebaseService.queryDocuments(
      'lent_items',
      field: 'user_id',
      isEqualTo: userId,
    );
  }
}
