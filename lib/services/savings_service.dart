import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class SavingsService {
  /// Add a new savings goal
  static Future<String> addSavingsGoal(Map<String, dynamic> goalData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'savings_goals',
      goalData,
    );
    return docRef.id;
  }

  /// Get all savings goals for a user
  static Stream<QuerySnapshot> getUserSavingsGoals(String userId) {
    return FirebaseService.queryDocuments(
      'savings_goals',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Add a savings transaction (deposit/withdrawal)
  static Future<void> addSavingsTransaction(
    String userId,
    String goalId,
    double amount,
    String type,
    String description,
  ) async {
    await FirebaseService.addDocument('savings_transactions', {
      'user_id': userId,
      'goal_id': goalId,
      'amount': amount,
      'type': type, // deposit, withdrawal, interest
      'date': DateTime.now(),
      'description': description,
      'is_automatic': type == 'deposit' && amount > 0,
    });
  }

  /// Process automatic monthly contributions for all active goals
  static Future<void> processAutomaticSavings(String userId) async {
    try {
      // Get all active savings goals for the user
      QuerySnapshot goalsSnapshot =
          await FirebaseService.queryDocuments(
            'savings_goals',
            field: 'user_id',
            isEqualTo: userId,
          ).first;

      for (var doc in goalsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['is_active'] == true) {
          double monthlyContribution = data['monthly_contribution'] ?? 0.0;
          String goalId = doc.id;
          String goalName = data['name'] ?? 'Unknown Goal';

          if (monthlyContribution > 0) {
            // Add monthly transaction
            await addSavingsTransaction(
              userId,
              goalId,
              monthlyContribution,
              'deposit',
              'Monthly contribution to $goalName',
            );

            // Update the goal's current amount
            double currentAmount = data['current_amount'] ?? 0.0;
            double newAmount = currentAmount + monthlyContribution;

            await FirebaseService.updateDocument('savings_goals', goalId, {
              'current_amount': newAmount,
              'last_monthly_contribution': DateTime.now(),
            });
          }
        }
      }
    } catch (e) {
      print('Error processing automatic savings: $e');
    }
  }

  /// Get savings summary for a user
  static Future<Map<String, dynamic>> getSavingsSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'savings_goals',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalSaved = 0.0;
    double totalTarget = 0.0;
    int activeGoals = 0;
    double totalMonthlyContributions = 0.0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['is_active'] == true) {
        totalSaved += data['current_amount'] ?? 0.0;
        totalTarget += data['target_amount'] ?? 0.0;
        totalMonthlyContributions += data['monthly_contribution'] ?? 0.0;
        activeGoals++;
      }
    }

    double totalProgress =
        totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0;

    return {
      'total_saved': totalSaved,
      'total_target': totalTarget,
      'total_progress': totalProgress,
      'active_goals': activeGoals,
      'total_monthly_contributions': totalMonthlyContributions,
    };
  }

  /// Update goal progress
  static Future<void> updateGoalProgress(
    String goalId,
    double newAmount,
  ) async {
    await FirebaseService.updateDocument('savings_goals', goalId, {
      'current_amount': newAmount,
      'last_updated': DateTime.now(),
    });
  }

  /// Get goal transactions
  static Stream<QuerySnapshot> getGoalTransactions(
    String userId,
    String goalId,
  ) {
    return FirebaseService.queryDocuments(
      'savings_transactions',
      field: 'goal_id',
      isEqualTo: goalId,
    );
  }

  /// Calculate goal progress percentage
  static double calculateProgressPercentage(double current, double target) {
    if (target <= 0) return 0.0;
    return (current / target) * 100;
  }

  /// Get goal status (on track, behind, ahead)
  static String getGoalStatus(
    double current,
    double target,
    DateTime? deadline,
  ) {
    if (deadline == null) return 'on_track';

    double progress = calculateProgressPercentage(current, target);
    DateTime now = DateTime.now();
    double timeProgress =
        ((deadline.difference(now).inDays) /
            (deadline.difference(now.add(Duration(days: 365))).inDays)) *
        100;

    if (progress >= timeProgress) return 'ahead';
    if (progress < timeProgress - 10) return 'behind';
    return 'on_track';
  }

  /// Manual trigger for monthly contributions (for testing)
  static Future<void> triggerMonthlyContributions(String userId) async {
    await processAutomaticSavings(userId);
  }

  /// Check if it's time for monthly contributions
  static bool shouldProcessMonthlyContributions(DateTime? lastContribution) {
    if (lastContribution == null) return true;

    DateTime now = DateTime.now();
    DateTime nextContribution = DateTime(
      lastContribution.year,
      lastContribution.month + 1,
      lastContribution.day,
    );

    return now.isAfter(nextContribution);
  }
}
