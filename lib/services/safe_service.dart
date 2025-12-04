import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class SafeService {
  /// Add a new safe item
  static Future<String> addSafeItem(Map<String, dynamic> safeData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'safe_items',
      safeData,
    );
    return docRef.id;
  }

  /// Get all safe items for a user
  static Stream<QuerySnapshot> getUserSafeItems(String userId) {
    return FirebaseService.queryDocuments(
      'safe_items',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get safe summary for a user
  static Future<Map<String, dynamic>> getSafeSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'safe_items',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalValue = 0.0;
    int totalItems = 0;
    Map<String, double> categoryBreakdown = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        // Check if this is a transaction or an item
        String type = data['type'] ?? '';
        if (type.isNotEmpty) {
          // This is a transaction
          double amount = data['amount'] ?? 0.0;
          if (type == 'deposit') {
            totalValue += amount;
          } else if (type == 'withdrawal') {
            totalValue -= amount;
          }
        } else {
          // This is an item
          double value = data['value'] ?? 0.0;
          String category = data['category'] ?? 'other';

          totalValue += value;
          totalItems++;

          categoryBreakdown[category] =
              (categoryBreakdown[category] ?? 0.0) + value;
        }
      }
    }

    return {
      'total_value': totalValue,
      'total_items': totalItems,
      'category_breakdown': categoryBreakdown,
    };
  }

  /// Update safe item
  static Future<void> updateSafeItem(
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    await FirebaseService.updateDocument('safe_items', itemId, itemData);
  }

  /// Delete safe item
  static Future<void> deleteSafeItem(String itemId) async {
    await FirebaseService.deleteDocument('safe_items', itemId);
  }

  /// Delete safe item with confirmation
  static Future<bool> deleteSafeItemWithConfirmation(String itemId) async {
    try {
      await FirebaseService.deleteDocument('safe_items', itemId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get safe items by category
  static Stream<QuerySnapshot> getSafeItemsByCategory(
    String userId,
    String category,
  ) {
    return FirebaseService.queryDocuments(
      'safe_items',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get safe items by location
  static Stream<QuerySnapshot> getSafeItemsByLocation(
    String userId,
    String location,
  ) {
    return FirebaseService.queryDocuments(
      'safe_items',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get safe items added in date range
  static Future<List<Map<String, dynamic>>> getSafeItemsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'safe_items',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> items = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        DateTime? dateAdded = data['date_added']?.toDate();
        if (dateAdded != null &&
            dateAdded.isAfter(startDate) &&
            dateAdded.isBefore(endDate)) {
          items.add(data);
        }
      }
    }

    return items;
  }

  /// Get category names
  static List<String> getCategoryNames() {
    return [
      'Jewelry',
      'Documents',
      'Cash',
      'Electronics',
      'Collectibles',
      'Other',
    ];
  }

  /// Get category icons
  static Map<String, String> getCategoryIcons() {
    return {
      'jewelry': '💍',
      'documents': '📄',
      'cash': '💰',
      'electronics': '📱',
      'collectibles': '🎨',
      'other': '📦',
    };
  }

  /// Get safe items by value range
  static Future<List<Map<String, dynamic>>> getSafeItemsByValueRange(
    String userId,
    double minValue,
    double maxValue,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'safe_items',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> items = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double value = data['value'] ?? 0.0;
        if (value >= minValue && value <= maxValue) {
          items.add(data);
        }
      }
    }

    return items;
  }

  /// Get total value by location
  static Future<Map<String, double>> getTotalValueByLocation(
    String userId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'safe_items',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> locationTotals = {};
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        String location = data['location'] ?? 'Unknown';
        double value = data['value'] ?? 0.0;
        locationTotals[location] = (locationTotals[location] ?? 0.0) + value;
      }
    }

    return locationTotals;
  }

  /// Add safe transaction (deposit or withdrawal)
  static Future<String> addSafeTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'safe_items',
      transactionData,
    );
    return docRef.id;
  }

  /// Transfer money from safe to bank account
  static Future<void> transferFromSafeToBank(
    String userId,
    double amount,
    String description,
    String notes,
  ) async {
    // Add withdrawal to safe
    Map<String, dynamic> safeWithdrawal = {
      'user_id': userId,
      'type': 'withdrawal',
      'description': description,
      'amount': amount,
      'date': DateTime.now(),
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };

    // Add deposit to bank account
    Map<String, dynamic> bankDeposit = {
      'user_id': userId,
      'type': 'transfer_in',
      'description': 'Transfer from Safe: $description',
      'amount': amount,
      'date': DateTime.now(),
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };

    // Add both transactions
    await FirebaseService.addDocument('safe_items', safeWithdrawal);
    await FirebaseService.addDocument('bank_transactions', bankDeposit);
  }

  /// Transfer money from bank account to safe
  static Future<void> transferFromBankToSafe(
    String userId,
    double amount,
    String description,
    String notes,
  ) async {
    // Add withdrawal from bank account
    Map<String, dynamic> bankWithdrawal = {
      'user_id': userId,
      'type': 'transfer_out',
      'description': 'Transfer to Safe: $description',
      'amount': amount,
      'date': DateTime.now(),
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };

    // Add deposit to safe
    Map<String, dynamic> safeDeposit = {
      'user_id': userId,
      'type': 'deposit',
      'description': description,
      'amount': amount,
      'date': DateTime.now(),
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };

    // Add both transactions
    await FirebaseService.addDocument('bank_transactions', bankWithdrawal);
    await FirebaseService.addDocument('safe_items', safeDeposit);
  }
}
