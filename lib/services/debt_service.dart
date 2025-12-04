import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class DebtService {
  /// Add a new debt entry
  static Future<String> addDebt(Map<String, dynamic> debtData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'debts',
      debtData,
    );
    return docRef.id;
  }

  /// Get all debts for a user (both owed and owed to you)
  static Stream<QuerySnapshot> getUserDebts(String userId) {
    return FirebaseService.queryDocuments(
      'debts',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get debts you owe to others
  static Stream<QuerySnapshot> getDebtsYouOwe(String userId) {
    return FirebaseService.queryDocuments(
      'debts',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get debts others owe to you
  static Stream<QuerySnapshot> getDebtsOwedToYou(String userId) {
    return FirebaseService.queryDocuments(
      'debts',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Add a debt payment transaction
  static Future<void> addDebtPayment(
    String userId,
    String debtId,
    double amount,
    String description,
  ) async {
    await FirebaseService.addDocument('debt_transactions', {
      'user_id': userId,
      'debt_id': debtId,
      'amount': amount,
      'date': DateTime.now(),
      'description': description,
      'type': 'payment',
    });
  }

  /// Get debt summary for a user
  static Future<Map<String, dynamic>> getDebtSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'debts',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalOwed = 0.0;
    double totalOwedToYou = 0.0;
    int activeDebtsOwed = 0;
    int activeDebtsOwedToYou = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        double amount = data['amount'] ?? 0.0;
        String type = data['type'] ?? 'owed';

        if (type == 'owed') {
          totalOwed += amount;
          activeDebtsOwed++;
        } else if (type == 'owed_to_you') {
          totalOwedToYou += amount;
          activeDebtsOwedToYou++;
        }
      }
    }

    double netDebt = totalOwed - totalOwedToYou;

    return {
      'total_owed': totalOwed,
      'total_owed_to_you': totalOwedToYou,
      'net_debt': netDebt,
      'active_debts_owed': activeDebtsOwed,
      'active_debts_owed_to_you': activeDebtsOwedToYou,
      'total_active_debts': activeDebtsOwed + activeDebtsOwedToYou,
    };
  }

  /// Update debt amount
  static Future<void> updateDebtAmount(String debtId, double newAmount) async {
    await FirebaseService.updateDocument('debts', debtId, {
      'amount': newAmount,
      'last_updated': DateTime.now(),
    });
  }

  /// Mark debt as paid
  static Future<void> markDebtAsPaid(String debtId) async {
    await FirebaseService.updateDocument('debts', debtId, {
      'is_active': false,
      'paid_date': DateTime.now(),
    });
  }

  /// Get debt transactions
  static Stream<QuerySnapshot> getDebtTransactions(
    String userId,
    String debtId,
  ) {
    return FirebaseService.queryDocuments(
      'debt_transactions',
      field: 'debt_id',
      isEqualTo: debtId,
    );
  }

  /// Calculate debt progress percentage
  static double calculateDebtProgressPercentage(double paid, double total) {
    if (total <= 0) return 0.0;
    return (paid / total) * 100;
  }

  /// Get debt status (active, paid, overdue)
  static String getDebtStatus(double amount, DateTime? dueDate) {
    if (amount <= 0) return 'paid';

    if (dueDate != null && DateTime.now().isAfter(dueDate)) {
      return 'overdue';
    }

    return 'active';
  }

  /// Manual trigger for debt processing (for testing)
  static Future<void> processDebtPayments(String userId) async {
    // This could be used for automatic debt reminders or processing
  }

  /// Check if debt is overdue
  static bool isDebtOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Get overdue debts count
  static Future<int> getOverdueDebtsCount(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'debts',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    int overdueCount = 0;
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        DateTime? dueDate = data['due_date']?.toDate();
        if (isDebtOverdue(dueDate)) {
          overdueCount++;
        }
      }
    }

    return overdueCount;
  }

  /// Delete debt
  static Future<void> deleteDebt(String debtId) async {
    await FirebaseService.deleteDocument('debts', debtId);
  }

  /// Delete debt with confirmation
  static Future<bool> deleteDebtWithConfirmation(String debtId) async {
    try {
      await FirebaseService.deleteDocument('debts', debtId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update debt
  static Future<void> updateDebt(
    String debtId,
    Map<String, dynamic> debtData,
  ) async {
    await FirebaseService.updateDocument('debts', debtId, debtData);
  }

  /// Process automatic monthly payments for all debts
  static Future<void> processAutomaticMonthlyPayments(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'debts',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        double monthlyPayment = data['monthly_payment'] ?? 0.0;
        double currentAmount = data['amount'] ?? 0.0;
        DateTime? lastPaymentDate = data['last_payment_date']?.toDate();

        // Check if we should process this month's payment
        bool shouldProcess = false;
        if (lastPaymentDate == null) {
          // First time processing
          shouldProcess = true;
        } else {
          // Check if we haven't processed this month yet
          DateTime lastPaymentMonth = DateTime(
            lastPaymentDate.year,
            lastPaymentDate.month,
            1,
          );
          if (firstDayOfMonth.isAfter(lastPaymentMonth)) {
            shouldProcess = true;
          }
        }

        if (shouldProcess && monthlyPayment > 0 && currentAmount > 0) {
          // Calculate payment amount (don't overpay)
          double paymentAmount =
              monthlyPayment > currentAmount ? currentAmount : monthlyPayment;

          // Update debt amount
          double newAmount = currentAmount - paymentAmount;
          bool isFullyPaid = newAmount <= 0;

          await FirebaseService.updateDocument('debts', doc.id, {
            'amount': newAmount,
            'last_payment_date': now,
            'is_active': !isFullyPaid,
            'paid_date': isFullyPaid ? now : null,
            'last_updated': now,
          });

          // Add payment transaction
          await FirebaseService.addDocument('debt_transactions', {
            'user_id': userId,
            'debt_id': doc.id,
            'amount': paymentAmount,
            'date': now,
            'description': 'Automatic monthly payment',
            'type': 'automatic_payment',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  /// Get debts with automatic payments
  static Future<List<Map<String, dynamic>>> getDebtsWithAutomaticPayments(
    String userId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'debts',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> debtsWithAutoPay = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null &&
          data['monthly_payment'] != null &&
          data['monthly_payment'] > 0) {
        debtsWithAutoPay.add({'id': doc.id, ...data});
      }
    }

    return debtsWithAutoPay;
  }

  /// Get total monthly payments
  static Future<double> getTotalMonthlyPayments(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'debts',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalMonthlyPayments = 0.0;
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        double monthlyPayment = data['monthly_payment'] ?? 0.0;
        totalMonthlyPayments += monthlyPayment;
      }
    }

    return totalMonthlyPayments;
  }

  /// Get next payment date for a debt
  static DateTime? getNextPaymentDate(DateTime? lastPaymentDate) {
    if (lastPaymentDate == null) {
      // If no previous payment, next payment is next month
      DateTime now = DateTime.now();
      return DateTime(now.year, now.month + 1, 1);
    } else {
      // Next payment is the first day of the next month after last payment
      return DateTime(lastPaymentDate.year, lastPaymentDate.month + 1, 1);
    }
  }
}
