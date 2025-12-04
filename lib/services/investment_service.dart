import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class InvestmentService {
  /// Add a new investment
  static Future<String> addInvestment(
    Map<String, dynamic> investmentData,
  ) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'investments',
      investmentData,
    );
    return docRef.id;
  }

  /// Get all investments for a user
  static Stream<QuerySnapshot> getUserInvestments(String userId) {
    return FirebaseService.queryDocuments(
      'investments',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Add a monthly transaction for an investment
  static Future<void> addMonthlyTransaction(
    String userId,
    String investmentId,
    double amount,
  ) async {
    await FirebaseService.addDocument('transactions', {
      'user_id': userId,
      'investment_id': investmentId,
      'amount': amount,
      'date': DateTime.now(),
      'type': 'monthly_payment',
    });
  }

  /// Process automatic monthly payments for all investments
  static Future<void> processAutomaticMonthlyPayments(String userId) async {
    try {
      // Get all automatic investments for the user
      QuerySnapshot investmentsSnapshot =
          await FirebaseService.queryDocuments(
            'investments',
            field: 'user_id',
            isEqualTo: userId,
          ).first;

      for (var doc in investmentsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['is_automatic'] == true) {
          double monthlyAmount = data['monthly_amount'] ?? 0.0;
          String investmentId = doc.id;

          // Add monthly transaction
          await addMonthlyTransaction(userId, investmentId, monthlyAmount);

          // Update the investment's total invested amount
          double currentTotalInvested = data['total_invested'] ?? 0.0;
          double newTotalInvested = currentTotalInvested + monthlyAmount;

          await FirebaseService.updateDocument('investments', investmentId, {
            'total_invested': newTotalInvested,
            'last_monthly_payment': DateTime.now(),
          });
        }
      }
    } catch (e) {
      null;
    }
  }

  /// Get portfolio summary for a user
  static Future<Map<String, dynamic>> getPortfolioSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'investments',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalValue = 0.0;
    double totalInvested = 0.0;
    int investmentCount = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalValue += data['current_value'] ?? 0.0;
        totalInvested += data['total_invested'] ?? 0.0;
        investmentCount++;
      }
    }

    double totalGainLoss = totalValue - totalInvested;
    double gainLossPercentage =
        totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;

    return {
      'total_value': totalValue,
      'total_invested': totalInvested,
      'total_gain_loss': totalGainLoss,
      'gain_loss_percentage': gainLossPercentage,
      'investment_count': investmentCount,
    };
  }

  /// Update investment current value
  static Future<void> updateInvestmentValue(
    String investmentId,
    double newValue,
  ) async {
    await FirebaseService.updateDocument('investments', investmentId, {
      'current_value': newValue,
      'last_updated': DateTime.now(),
    });
  }

  /// Get investment transactions
  static Stream<QuerySnapshot> getInvestmentTransactions(
    String userId,
    String investmentId,
  ) {
    return FirebaseService.queryDocuments(
      'transactions',
      field: 'investment_id',
      isEqualTo: investmentId,
    );
  }

  /// Manual trigger for monthly payments (for testing)
  static Future<void> triggerMonthlyPayments(String userId) async {
    await processAutomaticMonthlyPayments(userId);
  }

  /// Check if it's time for monthly payments (simple logic)
  static bool shouldProcessMonthlyPayments(DateTime? lastPayment) {
    if (lastPayment == null) return true;

    DateTime now = DateTime.now();
    DateTime nextPayment = DateTime(
      lastPayment.year,
      lastPayment.month + 1,
      lastPayment.day,
    );

    return now.isAfter(nextPayment);
  }

  /// Update investment
  static Future<void> updateInvestment(
    String investmentId,
    Map<String, dynamic> investmentData,
  ) async {
    await FirebaseService.updateDocument('investments', investmentId, investmentData);
  }

  /// Delete investment
  static Future<void> deleteInvestment(String investmentId) async {
    await FirebaseService.deleteDocument('investments', investmentId);
  }

  /// Delete investment with confirmation
  static Future<bool> deleteInvestmentWithConfirmation(String investmentId) async {
    try {
      await FirebaseService.deleteDocument('investments', investmentId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
