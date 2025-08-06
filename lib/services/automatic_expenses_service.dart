import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AutomaticExpense {
  final String id;
  final String userId;
  final String description;
  final double amount;
  final String category;
  final String frequency; // 'monthly', 'weekly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? notes;

  AutomaticExpense({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'description': description,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      'notes': notes,
      'created_at': DateTime.now(),
    };
  }

  factory AutomaticExpense.fromMap(String id, Map<String, dynamic> data) {
    return AutomaticExpense(
      id: id,
      userId: data['user_id'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'other',
      frequency: data['frequency'] ?? 'monthly',
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate:
          data['end_date'] != null
              ? (data['end_date'] as Timestamp).toDate()
              : null,
      isActive: data['is_active'] ?? true,
      notes: data['notes'],
    );
  }
}

class AutomaticExpensesService {
  /// Add a new automatic expense
  static Future<String> addAutomaticExpense(AutomaticExpense expense) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'automatic_expenses',
      expense.toMap(),
    );
    return docRef.id;
  }

  /// Get all automatic expenses for a user
  static Stream<QuerySnapshot> getUserAutomaticExpenses(String userId) {
    return FirebaseService.queryDocuments(
      'automatic_expenses',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Update automatic expense
  static Future<void> updateAutomaticExpense(
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseService.updateDocument('automatic_expenses', expenseId, data);
  }

  /// Delete automatic expense
  static Future<void> deleteAutomaticExpense(String expenseId) async {
    await FirebaseService.deleteDocument('automatic_expenses', expenseId);
  }

  /// Get automatic expenses summary
  static Future<Map<String, dynamic>> getAutomaticExpensesSummary(
    String userId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'automatic_expenses',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalMonthlyAmount = 0.0;
    double totalWeeklyAmount = 0.0;
    double totalYearlyAmount = 0.0;
    int totalCount = 0;
    Map<String, double> categoryTotals = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        double amount = data['amount'] ?? 0.0;
        String frequency = data['frequency'] ?? 'monthly';
        String category = data['category'] ?? 'other';

        totalCount++;

        switch (frequency) {
          case 'monthly':
            totalMonthlyAmount += amount;
            break;
          case 'weekly':
            totalWeeklyAmount += amount;
            break;
          case 'yearly':
            totalYearlyAmount += amount;
            break;
        }

        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }
    }

    // Convert to monthly equivalent
    double monthlyEquivalent =
        totalMonthlyAmount +
        (totalWeeklyAmount * 4.33) + // Average weeks per month
        (totalYearlyAmount / 12);

    return {
      'total_monthly_amount': totalMonthlyAmount,
      'total_weekly_amount': totalWeeklyAmount,
      'total_yearly_amount': totalYearlyAmount,
      'monthly_equivalent': monthlyEquivalent,
      'total_count': totalCount,
      'category_totals': categoryTotals,
    };
  }

  /// Get frequency options
  static List<Map<String, dynamic>> getFrequencyOptions() {
    return [
      {
        'key': 'monthly',
        'name': 'Monthly',
        'description': 'Recurring every month',
      },
      {
        'key': 'weekly',
        'name': 'Weekly',
        'description': 'Recurring every week',
      },
      {
        'key': 'yearly',
        'name': 'Yearly',
        'description': 'Recurring every year',
      },
    ];
  }

  /// Get frequency display names
  static Map<String, String> getFrequencyDisplayNames() {
    return {'monthly': 'Monthly', 'weekly': 'Weekly', 'yearly': 'Yearly'};
  }

  /// Calculate next occurrence date
  static DateTime getNextOccurrence(DateTime startDate, String frequency) {
    DateTime now = DateTime.now();
    DateTime nextDate = startDate;

    while (nextDate.isBefore(now)) {
      switch (frequency) {
        case 'monthly':
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'yearly':
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
      }
    }

    return nextDate;
  }

  /// Check if automatic expense should be triggered
  static bool shouldTriggerExpense(
    AutomaticExpense expense,
    DateTime currentDate,
  ) {
    if (!expense.isActive) return false;
    if (expense.endDate != null && currentDate.isAfter(expense.endDate!)) {
      return false;
    }

    DateTime nextOccurrence = getNextOccurrence(
      expense.startDate,
      expense.frequency,
    );

    // Check if we're in the same month/week/year as the next occurrence
    switch (expense.frequency) {
      case 'monthly':
        return currentDate.year == nextOccurrence.year &&
            currentDate.month == nextOccurrence.month;
      case 'weekly':
        // Check if we're in the same week
        DateTime weekStart = currentDate.subtract(
          Duration(days: currentDate.weekday - 1),
        );
        DateTime nextWeekStart = nextOccurrence.subtract(
          Duration(days: nextOccurrence.weekday - 1),
        );
        return weekStart.isAtSameMomentAs(nextWeekStart);
      case 'yearly':
        return currentDate.year == nextOccurrence.year &&
            currentDate.month == nextOccurrence.month &&
            currentDate.day == nextOccurrence.day;
      default:
        return false;
    }
  }

  /// Get all active automatic expenses for a user
  static Future<List<AutomaticExpense>> getActiveAutomaticExpenses(
    String userId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'automatic_expenses',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<AutomaticExpense> expenses = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        expenses.add(AutomaticExpense.fromMap(doc.id, data));
      }
    }

    return expenses;
  }
}
