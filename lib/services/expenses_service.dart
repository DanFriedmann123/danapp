import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'firebase_service.dart';

class ExpensesService {
  /// Add a new expense
  static Future<String> addExpense(Map<String, dynamic> expenseData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'expenses',
      expenseData,
    );
    return docRef.id;
  }

  /// Get all expenses for a user
  static Stream<QuerySnapshot> getUserExpenses(String userId) {
    return FirebaseService.queryDocuments(
      'expenses',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Upload expense receipt/invoice file
  static Future<String> uploadExpenseFile(
    String userId,
    String expenseId,
    File file,
  ) async {
    String fileName =
        'expense_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    String path = 'users/$userId/expenses/$expenseId/receipts/$fileName';

    Reference ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload expense receipt/invoice from bytes (for web)
  static Future<String> uploadExpenseBytes(
    String userId,
    String expenseId,
    Uint8List bytes,
    String fileName,
  ) async {
    String filePath =
        'expense_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    String path = 'users/$userId/expenses/$expenseId/receipts/$filePath';

    Reference ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putData(bytes);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Get expense files
  static Future<List<String>> getExpenseFiles(
    String userId,
    String expenseId,
  ) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(
        'users/$userId/expenses/$expenseId/receipts',
      );
      ListResult result = await ref.listAll();

      List<String> urls = [];
      for (var item in result.items) {
        String url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      print('Error getting expense files: $e');
      return [];
    }
  }

  /// Add expense with file upload
  static Future<String> addExpenseWithFile(
    Map<String, dynamic> expenseData,
    List<File> files,
  ) async {
    String userId = expenseData['user_id'];

    // Add expense to database
    String expenseId = await addExpense(expenseData);

    // Upload files
    List<String> fileUrls = [];
    for (File file in files) {
      String url = await uploadExpenseFile(userId, expenseId, file);
      fileUrls.add(url);
    }

    // Update expense with file URLs
    await FirebaseService.updateDocument('expenses', expenseId, {
      'file_urls': fileUrls,
      'has_attachments': fileUrls.isNotEmpty,
    });

    return expenseId;
  }

  /// Get expenses summary for a user
  static Future<Map<String, dynamic>> getExpensesSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'expenses',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalExpenses = 0.0;
    int totalExpensesCount = 0;
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCounts = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double amount = data['amount'] ?? 0.0;
        String category = data['category'] ?? 'other';

        totalExpenses += amount;
        totalExpensesCount++;

        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    return {
      'total_expenses': totalExpenses,
      'total_count': totalExpensesCount,
      'category_totals': categoryTotals,
      'category_counts': categoryCounts,
    };
  }

  /// Get expenses by category
  static Stream<QuerySnapshot> getExpensesByCategory(
    String userId,
    String category,
  ) {
    return FirebaseService.queryDocuments(
      'expenses',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Update expense
  static Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseService.updateDocument('expenses', expenseId, data);
  }

  /// Delete expense
  static Future<void> deleteExpense(String expenseId) async {
    await FirebaseService.deleteDocument('expenses', expenseId);
  }

  /// Get expense categories
  static List<String> getExpenseCategories() {
    return [
      'food',
      'transport',
      'entertainment',
      'shopping',
      'utilities',
      'health',
      'education',
      'travel',
      'business',
      'other',
    ];
  }

  /// Get category display names
  static Map<String, String> getCategoryNames() {
    return {
      'food': 'Food & Dining',
      'transport': 'Transportation',
      'entertainment': 'Entertainment',
      'shopping': 'Shopping',
      'utilities': 'Utilities',
      'health': 'Healthcare',
      'education': 'Education',
      'travel': 'Travel',
      'business': 'Business',
      'other': 'Other',
    };
  }

  /// Get category icons
  static Map<String, String> getCategoryIcons() {
    return {
      'food': '🍽️',
      'transport': '🚗',
      'entertainment': '🎬',
      'shopping': '🛍️',
      'utilities': '⚡',
      'health': '🏥',
      'education': '📚',
      'travel': '✈️',
      'business': '💼',
      'other': '📄',
    };
  }

  /// Calculate monthly expenses
  static Future<Map<String, double>> getMonthlyExpenses(
    String userId,
    int year,
    int month,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'expenses',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> monthlyTotals = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        DateTime expenseDate = (data['date'] as Timestamp).toDate();

        if (expenseDate.year == year && expenseDate.month == month) {
          String category = data['category'] ?? 'other';
          double amount = data['amount'] ?? 0.0;

          monthlyTotals[category] = (monthlyTotals[category] ?? 0.0) + amount;
        }
      }
    }

    return monthlyTotals;
  }

  /// Get expenses for date range
  static Stream<QuerySnapshot> getExpensesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return FirebaseService.queryDocuments(
      'expenses',
      field: 'user_id',
      isEqualTo: userId,
    );
  }
}
