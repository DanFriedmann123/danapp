import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class IncomeService {
  /// Add a new income entry
  static Future<String> addIncome(Map<String, dynamic> incomeData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'incomes',
      incomeData,
    );
    return docRef.id;
  }

  /// Get all incomes for a user
  static Stream<QuerySnapshot> getUserIncomes(String userId) {
    return FirebaseService.queryDocuments(
      'incomes',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get income summary for a user
  static Future<Map<String, dynamic>> getIncomeSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'incomes',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalIncome = 0.0;
    int totalIncomeCount = 0;
    Map<String, double> sourceTotals = {};
    Map<String, int> sourceCounts = {};
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCounts = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double amount = data['amount'] ?? 0.0;
        String source = data['source'] ?? 'other';
        String category = data['category'] ?? 'other';

        totalIncome += amount;
        totalIncomeCount++;

        sourceTotals[source] = (sourceTotals[source] ?? 0.0) + amount;
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;

        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    return {
      'total_income': totalIncome,
      'total_count': totalIncomeCount,
      'source_totals': sourceTotals,
      'source_counts': sourceCounts,
      'category_totals': categoryTotals,
      'category_counts': categoryCounts,
    };
  }

  /// Get incomes by source
  static Stream<QuerySnapshot> getIncomesBySource(
    String userId,
    String source,
  ) {
    return FirebaseService.queryDocuments(
      'incomes',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get incomes by category
  static Stream<QuerySnapshot> getIncomesByCategory(
    String userId,
    String category,
  ) {
    return FirebaseService.queryDocuments(
      'incomes',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Update income
  static Future<void> updateIncome(
    String incomeId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseService.updateDocument('incomes', incomeId, data);
  }

  /// Delete income
  static Future<void> deleteIncome(String incomeId) async {
    await FirebaseService.deleteDocument('incomes', incomeId);
  }

  /// Get income sources
  static List<String> getIncomeSources() {
    return [
      'salary',
      'freelance',
      'business',
      'investment',
      'rental',
      'bonus',
      'commission',
      'other',
    ];
  }

  /// Get source display names
  static Map<String, String> getSourceNames() {
    return {
      'salary': 'Salary',
      'freelance': 'Freelance',
      'business': 'Business',
      'investment': 'Investment',
      'rental': 'Rental',
      'bonus': 'Bonus',
      'commission': 'Commission',
      'other': 'Other',
    };
  }

  /// Get source icons
  static Map<String, String> getSourceIcons() {
    return {
      'salary': '💼',
      'freelance': '💻',
      'business': '🏢',
      'investment': '📈',
      'rental': '🏠',
      'bonus': '🎁',
      'commission': '💰',
      'other': '📄',
    };
  }

  /// Get income categories
  static List<String> getIncomeCategories() {
    return [
      'regular',
      'one_time',
      'seasonal',
      'performance',
      'passive',
      'other',
    ];
  }

  /// Get category display names
  static Map<String, String> getCategoryNames() {
    return {
      'regular': 'Regular Income',
      'one_time': 'One-time',
      'seasonal': 'Seasonal',
      'performance': 'Performance-based',
      'passive': 'Passive Income',
      'other': 'Other',
    };
  }

  /// Get category icons
  static Map<String, String> getCategoryIcons() {
    return {
      'regular': '📅',
      'one_time': '🎯',
      'seasonal': '🌱',
      'performance': '⭐',
      'passive': '🔄',
      'other': '📄',
    };
  }

  /// Calculate monthly income
  static Future<Map<String, double>> getMonthlyIncome(
    String userId,
    int year,
    int month,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'incomes',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> monthlyTotals = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        DateTime incomeDate = (data['date'] as Timestamp).toDate();

        if (incomeDate.year == year && incomeDate.month == month) {
          String source = data['source'] ?? 'other';
          double amount = data['amount'] ?? 0.0;

          monthlyTotals[source] = (monthlyTotals[source] ?? 0.0) + amount;
        }
      }
    }

    return monthlyTotals;
  }

  /// Get incomes for date range
  static Stream<QuerySnapshot> getIncomesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return FirebaseService.queryDocuments(
      'incomes',
      field: 'user_id',
      isEqualTo: userId,
    );
  }
}
