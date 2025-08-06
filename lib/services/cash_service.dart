import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class CashService {
  /// Add a new cash entry
  static Future<String> addCashEntry(Map<String, dynamic> cashData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'cash_entries',
      cashData,
    );
    return docRef.id;
  }

  /// Get all cash entries for a user
  static Stream<QuerySnapshot> getUserCashEntries(String userId) {
    return FirebaseService.queryDocuments(
      'cash_entries',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get cash summary for a user
  static Future<Map<String, dynamic>> getCashSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'cash_entries',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalCash = 0.0;
    int totalEntries = 0;
    Map<String, double> typeBreakdown = {};
    Map<String, double> locationBreakdown = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double amount = data['amount'] ?? 0.0;
        String type = data['type'] ?? 'cash';
        String location = data['location'] ?? 'Unknown';

        totalCash += amount;
        totalEntries++;

        typeBreakdown[type] = (typeBreakdown[type] ?? 0.0) + amount;
        locationBreakdown[location] =
            (locationBreakdown[location] ?? 0.0) + amount;
      }
    }

    return {
      'total_cash': totalCash,
      'total_entries': totalEntries,
      'type_breakdown': typeBreakdown,
      'location_breakdown': locationBreakdown,
    };
  }

  /// Update cash entry
  static Future<void> updateCashEntry(
    String entryId,
    Map<String, dynamic> entryData,
  ) async {
    await FirebaseService.updateDocument('cash_entries', entryId, entryData);
  }

  /// Delete cash entry
  static Future<void> deleteCashEntry(String entryId) async {
    await FirebaseService.deleteDocument('cash_entries', entryId);
  }

  /// Delete cash entry with confirmation
  static Future<bool> deleteCashEntryWithConfirmation(String entryId) async {
    try {
      await FirebaseService.deleteDocument('cash_entries', entryId);
      return true;
    } catch (e) {
      print('Error deleting cash entry: $e');
      return false;
    }
  }

  /// Get cash entries by type
  static Stream<QuerySnapshot> getCashEntriesByType(
    String userId,
    String type,
  ) {
    return FirebaseService.queryDocuments(
      'cash_entries',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get cash entries by location
  static Stream<QuerySnapshot> getCashEntriesByLocation(
    String userId,
    String location,
  ) {
    return FirebaseService.queryDocuments(
      'cash_entries',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get cash entries in date range
  static Future<List<Map<String, dynamic>>> getCashEntriesInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'cash_entries',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> entries = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        DateTime? date = data['date']?.toDate();
        if (date != null && date.isAfter(startDate) && date.isBefore(endDate)) {
          entries.add(data);
        }
      }
    }

    return entries;
  }

  /// Get type names
  static List<String> getTypeNames() {
    return [
      'Cash',
      'Foreign Currency',
      'Coins',
      'Gift Cards',
      'Vouchers',
      'Other',
    ];
  }

  /// Get type icons
  static Map<String, String> getTypeIcons() {
    return {
      'cash': '💵',
      'foreign_currency': '💱',
      'coins': '🪙',
      'gift_cards': '🎁',
      'vouchers': '🎫',
      'other': '💰',
    };
  }

  /// Get cash entries by amount range
  static Future<List<Map<String, dynamic>>> getCashEntriesByAmountRange(
    String userId,
    double minAmount,
    double maxAmount,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'cash_entries',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> entries = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double amount = data['amount'] ?? 0.0;
        if (amount >= minAmount && amount <= maxAmount) {
          entries.add(data);
        }
      }
    }

    return entries;
  }

  /// Get total cash by location
  static Future<Map<String, double>> getTotalCashByLocation(
    String userId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'cash_entries',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> locationTotals = {};
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        String location = data['location'] ?? 'Unknown';
        double amount = data['amount'] ?? 0.0;
        locationTotals[location] = (locationTotals[location] ?? 0.0) + amount;
      }
    }

    return locationTotals;
  }

  /// Get total cash by type
  static Future<Map<String, double>> getTotalCashByType(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'cash_entries',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> typeTotals = {};
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        String type = data['type'] ?? 'cash';
        double amount = data['amount'] ?? 0.0;
        typeTotals[type] = (typeTotals[type] ?? 0.0) + amount;
      }
    }

    return typeTotals;
  }
}
