import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class BankAccountService {
  /// Add a new bank transaction
  static Future<String> addBankTransaction(Map<String, dynamic> transactionData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'bank_transactions',
      transactionData,
    );
    return docRef.id;
  }

  /// Get all bank transactions for a user
  static Stream<QuerySnapshot> getUserBankTransactions(String userId) {
    return FirebaseService.queryDocuments(
      'bank_transactions',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get bank summary for a user
  static Future<Map<String, dynamic>> getBankSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'bank_transactions',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalBalance = 0.0;
    double totalDeposits = 0.0;
    double totalWithdrawals = 0.0;
    int totalTransactions = 0;
    Map<String, double> typeBreakdown = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double amount = data['amount'] ?? 0.0;
        String type = data['type'] ?? 'other';

        totalTransactions++;

        if (type == 'deposit' || type == 'transfer_in') {
          totalBalance += amount;
          totalDeposits += amount;
        } else if (type == 'withdrawal' || type == 'transfer_out' || type == 'fee') {
          totalBalance -= amount;
          totalWithdrawals += amount;
        }

        typeBreakdown[type] = (typeBreakdown[type] ?? 0.0) + amount;
      }
    }

    return {
      'total_balance': totalBalance,
      'total_deposits': totalDeposits,
      'total_withdrawals': totalWithdrawals,
      'total_transactions': totalTransactions,
      'type_breakdown': typeBreakdown,
    };
  }

  /// Update bank transaction
  static Future<void> updateBankTransaction(String transactionId, Map<String, dynamic> transactionData) async {
    await FirebaseService.updateDocument('bank_transactions', transactionId, transactionData);
  }

  /// Delete bank transaction
  static Future<void> deleteBankTransaction(String transactionId) async {
    await FirebaseService.deleteDocument('bank_transactions', transactionId);
  }

  /// Delete bank transaction with confirmation
  static Future<bool> deleteBankTransactionWithConfirmation(String transactionId) async {
    try {
      await FirebaseService.deleteDocument('bank_transactions', transactionId);
      return true;
    } catch (e) {
      print('Error deleting bank transaction: $e');
      return false;
    }
  }

  /// Get bank transactions by type
  static Stream<QuerySnapshot> getBankTransactionsByType(String userId, String type) {
    return FirebaseService.queryDocuments(
      'bank_transactions',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get bank transactions in date range
  static Future<List<Map<String, dynamic>>> getBankTransactionsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'bank_transactions',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> transactions = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        DateTime? date = data['date']?.toDate();
        if (date != null &&
            date.isAfter(startDate) &&
            date.isBefore(endDate)) {
          transactions.add(data);
        }
      }
    }

    return transactions;
  }

  /// Get type names
  static List<String> getTypeNames() {
    return [
      'Deposit',
      'Withdrawal',
      'Transfer In',
      'Transfer Out',
      'Fee',
      'Other',
    ];
  }

  /// Get type icons
  static Map<String, String> getTypeIcons() {
    return {
      'deposit': '💰',
      'withdrawal': '💸',
      'transfer_in': '📥',
      'transfer_out': '📤',
      'fee': '💳',
      'other': '🏦',
    };
  }

  /// Get bank transactions by amount range
  static Future<List<Map<String, dynamic>>> getBankTransactionsByAmountRange(
    String userId,
    double minAmount,
    double maxAmount,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'bank_transactions',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> transactions = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double amount = data['amount'] ?? 0.0;
        if (amount >= minAmount && amount <= maxAmount) {
          transactions.add(data);
        }
      }
    }

    return transactions;
  }

  /// Get total balance by type
  static Future<Map<String, double>> getTotalBalanceByType(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'bank_transactions',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> typeTotals = {};
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        String type = data['type'] ?? 'other';
        double amount = data['amount'] ?? 0.0;
        typeTotals[type] = (typeTotals[type] ?? 0.0) + amount;
      }
    }

    return typeTotals;
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

  /// Get bank transactions with highest amounts
  static Future<List<Map<String, dynamic>>> getBankTransactionsWithHighestAmounts(
    String userId,
    int limit,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'bank_transactions',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> transactions = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        transactions.add(data);
      }
    }

    // Sort by amount (highest first) and limit results
    transactions.sort((a, b) => (b['amount'] ?? 0.0).compareTo(a['amount'] ?? 0.0));
    return transactions.take(limit).toList();
  }

  /// Get bank transactions with lowest amounts
  static Future<List<Map<String, dynamic>>> getBankTransactionsWithLowestAmounts(
    String userId,
    int limit,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'bank_transactions',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> transactions = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        transactions.add(data);
      }
    }

    // Sort by amount (lowest first) and limit results
    transactions.sort((a, b) => (a['amount'] ?? 0.0).compareTo(b['amount'] ?? 0.0));
    return transactions.take(limit).toList();
  }
} 