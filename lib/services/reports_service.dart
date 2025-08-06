import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'investment_service.dart';
import 'savings_service.dart';
import 'debt_service.dart';
import 'expenses_service.dart';
import 'income_service.dart';

class ReportsService {
  /// Get comprehensive financial summary
  static Future<Map<String, dynamic>> getFinancialSummary(String userId) async {
    try {
      // Get data from all services
      Map<String, dynamic> investmentSummary =
          await InvestmentService.getPortfolioSummary(userId);
      Map<String, dynamic> savingsSummary =
          await SavingsService.getSavingsSummary(userId);
      Map<String, dynamic> debtSummary = await DebtService.getDebtSummary(
        userId,
      );
      Map<String, dynamic> expensesSummary =
          await ExpensesService.getExpensesSummary(userId);
      Map<String, dynamic> incomeSummary = await IncomeService.getIncomeSummary(
        userId,
      );

      // Calculate totals
      double totalInvestments = investmentSummary['total_value'] ?? 0.0;
      double totalSavings = savingsSummary['total_saved'] ?? 0.0;
      double totalDebtOwed = debtSummary['total_owed'] ?? 0.0;
      double totalDebtOwedToYou = debtSummary['total_owed_to_you'] ?? 0.0;
      double netDebt = debtSummary['net_debt'] ?? 0.0;
      double totalExpenses = expensesSummary['total_expenses'] ?? 0.0;
      double totalIncome = incomeSummary['total_income'] ?? 0.0;

      // Calculate net worth
      double netWorth =
          totalInvestments + totalSavings + totalDebtOwedToYou - totalDebtOwed;

      // Calculate cash flow
      double cashFlow = totalIncome - totalExpenses;

      return {
        'net_worth': netWorth,
        'total_assets': totalInvestments + totalSavings + totalDebtOwedToYou,
        'total_liabilities': totalDebtOwed,
        'cash_flow': cashFlow,
        'income': totalIncome,
        'expenses': totalExpenses,
        'investments': totalInvestments,
        'savings': totalSavings,
        'debt_owed': totalDebtOwed,
        'debt_owed_to_you': totalDebtOwedToYou,
        'net_debt': netDebt,
        'savings_rate':
            totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0.0,
        'expense_ratio':
            totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting financial summary: $e');
      return {};
    }
  }

  /// Get monthly trends for the last 6 months
  static Future<Map<String, dynamic>> getMonthlyTrends(String userId) async {
    Map<String, List<double>> trends = {
      'income': [],
      'expenses': [],
      'savings': [],
      'investments': [],
    };

    DateTime now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(now.year, now.month - i, 1);

      // Get monthly data
      Map<String, double> monthlyIncome = await IncomeService.getMonthlyIncome(
        userId,
        month.year,
        month.month,
      );
      Map<String, double> monthlyExpenses =
          await ExpensesService.getMonthlyExpenses(
            userId,
            month.year,
            month.month,
          );

      // Calculate totals
      double totalIncome = monthlyIncome.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
      double totalExpenses = monthlyExpenses.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
      double monthlySavings = totalIncome - totalExpenses;

      trends['income']!.add(totalIncome);
      trends['expenses']!.add(totalExpenses);
      trends['savings']!.add(monthlySavings);
      trends['investments']!.add(0.0); // Placeholder for investment growth
    }

    return {
      'trends': trends,
      'months': [
        '6 months ago',
        '5 months ago',
        '4 months ago',
        '3 months ago',
        '2 months ago',
        'Last month',
      ],
    };
  }

  /// Get category breakdowns
  static Future<Map<String, dynamic>> getCategoryBreakdowns(
    String userId,
  ) async {
    try {
      Map<String, dynamic> expensesSummary =
          await ExpensesService.getExpensesSummary(userId);
      Map<String, dynamic> incomeSummary = await IncomeService.getIncomeSummary(
        userId,
      );

      Map<String, double> expenseCategories = Map<String, double>.from(
        expensesSummary['category_totals'] ?? {},
      );
      Map<String, double> incomeSources = Map<String, double>.from(
        incomeSummary['source_totals'] ?? {},
      );

      return {
        'expense_categories': expenseCategories,
        'income_sources': incomeSources,
      };
    } catch (e) {
      print('Error getting category breakdowns: $e');
      return {};
    }
  }

  /// Get financial health indicators
  static Future<Map<String, dynamic>> getFinancialHealth(String userId) async {
    try {
      Map<String, dynamic> summary = await getFinancialSummary(userId);

      double netWorth = summary['net_worth'] ?? 0.0;
      double cashFlow = summary['cash_flow'] ?? 0.0;
      double savingsRate = summary['savings_rate'] ?? 0.0;
      double expenseRatio = summary['expense_ratio'] ?? 0.0;
      double netDebt = summary['net_debt'] ?? 0.0;

      // Calculate health scores (0-100)
      double netWorthScore =
          netWorth > 0 ? 100 : (netWorth / -10000 * 100).clamp(0, 100);
      double cashFlowScore =
          cashFlow > 0 ? 100 : (cashFlow / -5000 * 100).clamp(0, 100);
      double savingsRateScore = savingsRate.clamp(0, 100);
      double debtScore =
          netDebt <= 0 ? 100 : (100 - (netDebt / 10000 * 100)).clamp(0, 100);

      // Overall health score (average of all scores)
      double overallHealth =
          (netWorthScore + cashFlowScore + savingsRateScore + debtScore) / 4;

      return {
        'overall_health': overallHealth,
        'net_worth_score': netWorthScore,
        'cash_flow_score': cashFlowScore,
        'savings_rate_score': savingsRateScore,
        'debt_score': debtScore,
        'net_worth': netWorth,
        'cash_flow': cashFlow,
        'savings_rate': savingsRate,
        'expense_ratio': expenseRatio,
        'net_debt': netDebt,
      };
    } catch (e) {
      print('Error getting financial health: $e');
      return {};
    }
  }

  /// Get spending insights
  static Future<Map<String, dynamic>> getSpendingInsights(String userId) async {
    try {
      Map<String, dynamic> expensesSummary =
          await ExpensesService.getExpensesSummary(userId);
      Map<String, dynamic> incomeSummary = await IncomeService.getIncomeSummary(
        userId,
      );

      double totalExpenses = expensesSummary['total_expenses'] ?? 0.0;
      double totalIncome = incomeSummary['total_income'] ?? 0.0;
      Map<String, double> categoryTotals = Map<String, double>.from(
        expensesSummary['category_totals'] ?? {},
      );

      // Find top spending categories
      var sortedCategories =
          categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, dynamic>> topCategories =
          sortedCategories.take(3).map((entry) {
            return {
              'category': entry.key,
              'amount': entry.value,
              'percentage':
                  totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0.0,
            };
          }).toList();

      return {
        'total_expenses': totalExpenses,
        'total_income': totalIncome,
        'expense_ratio':
            totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0.0,
        'top_categories': topCategories,
        'category_breakdown': categoryTotals,
      };
    } catch (e) {
      print('Error getting spending insights: $e');
      return {};
    }
  }

  /// Get savings progress
  static Future<Map<String, dynamic>> getSavingsProgress(String userId) async {
    try {
      Map<String, dynamic> savingsSummary =
          await SavingsService.getSavingsSummary(userId);

      double totalSaved = savingsSummary['total_saved'] ?? 0.0;
      double totalTarget = savingsSummary['total_target'] ?? 0.0;
      double progress = savingsSummary['total_progress'] ?? 0.0;
      int activeGoals = savingsSummary['active_goals'] ?? 0;

      return {
        'total_saved': totalSaved,
        'total_target': totalTarget,
        'progress': progress,
        'active_goals': activeGoals,
        'completion_rate':
            totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting savings progress: $e');
      return {};
    }
  }

  /// Get investment performance
  static Future<Map<String, dynamic>> getInvestmentPerformance(
    String userId,
  ) async {
    try {
      Map<String, dynamic> investmentSummary =
          await InvestmentService.getPortfolioSummary(userId);

      double totalValue = investmentSummary['total_value'] ?? 0.0;
      double totalInvested = investmentSummary['total_invested'] ?? 0.0;
      double totalGainLoss = investmentSummary['total_gain_loss'] ?? 0.0;
      double gainLossPercentage =
          investmentSummary['gain_loss_percentage'] ?? 0.0;
      int investmentCount = investmentSummary['investment_count'] ?? 0;

      return {
        'total_value': totalValue,
        'total_invested': totalInvested,
        'total_gain_loss': totalGainLoss,
        'gain_loss_percentage': gainLossPercentage,
        'investment_count': investmentCount,
        'return_on_investment':
            totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting investment performance: $e');
      return {};
    }
  }

  /// Get debt analysis
  static Future<Map<String, dynamic>> getDebtAnalysis(String userId) async {
    try {
      Map<String, dynamic> debtSummary = await DebtService.getDebtSummary(
        userId,
      );

      double totalOwed = debtSummary['total_owed'] ?? 0.0;
      double totalOwedToYou = debtSummary['total_owed_to_you'] ?? 0.0;
      double netDebt = debtSummary['net_debt'] ?? 0.0;
      int activeDebtsOwed = debtSummary['active_debts_owed'] ?? 0;
      int activeDebtsOwedToYou = debtSummary['active_debts_owed_to_you'] ?? 0;

      return {
        'total_owed': totalOwed,
        'total_owed_to_you': totalOwedToYou,
        'net_debt': netDebt,
        'active_debts_owed': activeDebtsOwed,
        'active_debts_owed_to_you': activeDebtsOwedToYou,
        'total_debts': activeDebtsOwed + activeDebtsOwedToYou,
        'debt_ratio':
            totalOwed > 0
                ? (totalOwed / (totalOwed + totalOwedToYou)) * 100
                : 0.0,
      };
    } catch (e) {
      print('Error getting debt analysis: $e');
      return {};
    }
  }

  /// Get income analysis
  static Future<Map<String, dynamic>> getIncomeAnalysis(String userId) async {
    try {
      Map<String, dynamic> incomeSummary = await IncomeService.getIncomeSummary(
        userId,
      );

      double totalIncome = incomeSummary['total_income'] ?? 0.0;
      int totalEntries = incomeSummary['total_count'] ?? 0;
      Map<String, double> sourceTotals = Map<String, double>.from(
        incomeSummary['source_totals'] ?? {},
      );

      // Find top income sources
      var sortedSources =
          sourceTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, dynamic>> topSources =
          sortedSources.take(3).map((entry) {
            return {
              'source': entry.key,
              'amount': entry.value,
              'percentage':
                  totalIncome > 0 ? (entry.value / totalIncome) * 100 : 0.0,
            };
          }).toList();

      return {
        'total_income': totalIncome,
        'total_entries': totalEntries,
        'top_sources': topSources,
        'source_breakdown': sourceTotals,
        'average_income': totalEntries > 0 ? totalIncome / totalEntries : 0.0,
      };
    } catch (e) {
      print('Error getting income analysis: $e');
      return {};
    }
  }
}
