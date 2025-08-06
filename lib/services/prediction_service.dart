import 'investment_service.dart';
import 'savings_service.dart';
import 'debt_service.dart';
import 'income_service.dart';
import 'expenses_service.dart';
import 'automatic_expenses_service.dart';
import 'bank_account_service.dart';
import 'safe_service.dart';
import 'assets_service.dart';

class PredictionService {
  /// Get future financial prediction for a specific month and year
  static Future<Map<String, dynamic>> getFuturePrediction(
    String userId,
    int targetMonth,
    int targetYear,
  ) async {
    DateTime now = DateTime.now();
    DateTime targetDate = DateTime(targetYear, targetMonth, 1);
    int monthsDifference =
        ((targetYear - now.year) * 12 + targetMonth - now.month);

    if (monthsDifference < 0) {
      return {
        'error': 'Target date is in the past',
        'current_balance': 0.0,
        'predicted_balance': 0.0,
        'predicted_net_worth': 0.0,
        'predicted_debt': 0.0,
        'predicted_savings': 0.0,
        'predicted_investments': 0.0,
        'monthly_income': 0.0,
        'monthly_expenses': 0.0,
        'monthly_debt_payments': 0.0,
        'monthly_savings': 0.0,
        'months_to_target': 0,
      };
    }

    // Get current financial data
    double currentBalance = await _getCurrentBankBalance(userId);
    double currentNetWorth = await _getCurrentNetWorth(userId);
    double currentDebt = await _getCurrentTotalDebt(userId);
    double currentSavings = await _getCurrentSavings(userId);
    double currentInvestments = await _getCurrentInvestments(userId);

    // Get monthly averages
    double monthlyIncome = await _getAverageMonthlyIncome(userId);
    double monthlyExpenses = await _getAverageMonthlyExpenses(userId);
    double monthlyAutomaticExpenses = await _getMonthlyAutomaticExpenses(
      userId,
    );
    double monthlyDebtPayments = await _getTotalMonthlyDebtPayments(userId);
    double monthlySavings = await _getAverageMonthlySavings(userId);

    // Calculate predictions
    double totalMonthlyExpenses = monthlyExpenses + monthlyAutomaticExpenses;
    double predictedBalance =
        currentBalance +
        (monthlyIncome - totalMonthlyExpenses) * monthsDifference;
    double predictedNetWorth =
        currentNetWorth +
        (monthlyIncome - totalMonthlyExpenses) * monthsDifference;
    double predictedDebt =
        currentDebt - (monthlyDebtPayments * monthsDifference);
    if (predictedDebt < 0) predictedDebt = 0;

    double predictedSavings =
        currentSavings + (monthlySavings * monthsDifference);
    double predictedInvestments =
        currentInvestments; // Assuming no new investments

    return {
      'current_balance': currentBalance,
      'predicted_balance': predictedBalance,
      'predicted_net_worth': predictedNetWorth,
      'predicted_debt': predictedDebt,
      'predicted_savings': predictedSavings,
      'predicted_investments': predictedInvestments,
      'monthly_income': monthlyIncome,
      'monthly_expenses': monthlyExpenses,
      'monthly_automatic_expenses': monthlyAutomaticExpenses,
      'monthly_debt_payments': monthlyDebtPayments,
      'monthly_savings': monthlySavings,
      'months_to_target': monthsDifference,
      'target_date': targetDate,
    };
  }

  /// Get minimum income recommendations based on occupation
  static Map<String, Map<String, dynamic>> getMinimumIncomeByOccupation() {
    return {
      'software_engineer': {
        'name': 'Software Engineer',
        'min_salary': 15000.0,
        'mid_salary': 25000.0,
        'senior_salary': 35000.0,
        'description': 'Development and programming roles',
        'icon': '💻',
      },
      'teacher': {
        'name': 'Teacher',
        'min_salary': 8000.0,
        'mid_salary': 12000.0,
        'senior_salary': 18000.0,
        'description': 'Education and teaching roles',
        'icon': '📚',
      },
      'nurse': {
        'name': 'Nurse',
        'min_salary': 10000.0,
        'mid_salary': 15000.0,
        'senior_salary': 22000.0,
        'description': 'Healthcare and nursing roles',
        'icon': '🏥',
      },
      'accountant': {
        'name': 'Accountant',
        'min_salary': 12000.0,
        'mid_salary': 18000.0,
        'senior_salary': 28000.0,
        'description': 'Financial and accounting roles',
        'icon': '📊',
      },
      'marketing': {
        'name': 'Marketing Specialist',
        'min_salary': 10000.0,
        'mid_salary': 16000.0,
        'senior_salary': 25000.0,
        'description': 'Marketing and advertising roles',
        'icon': '📢',
      },
      'sales': {
        'name': 'Sales Representative',
        'min_salary': 8000.0,
        'mid_salary': 15000.0,
        'senior_salary': 25000.0,
        'description': 'Sales and business development',
        'icon': '💼',
      },
      'designer': {
        'name': 'Designer',
        'min_salary': 10000.0,
        'mid_salary': 18000.0,
        'senior_salary': 28000.0,
        'description': 'Graphic and UI/UX design',
        'icon': '🎨',
      },
      'manager': {
        'name': 'Manager',
        'min_salary': 15000.0,
        'mid_salary': 25000.0,
        'senior_salary': 40000.0,
        'description': 'Management and leadership roles',
        'icon': '👔',
      },
      'consultant': {
        'name': 'Consultant',
        'min_salary': 12000.0,
        'mid_salary': 20000.0,
        'senior_salary': 35000.0,
        'description': 'Consulting and advisory roles',
        'icon': '💡',
      },
      'entrepreneur': {
        'name': 'Entrepreneur',
        'min_salary': 5000.0,
        'mid_salary': 15000.0,
        'senior_salary': 50000.0,
        'description': 'Business ownership and startups',
        'icon': '🚀',
      },
      'freelancer': {
        'name': 'Freelancer',
        'min_salary': 8000.0,
        'mid_salary': 15000.0,
        'senior_salary': 30000.0,
        'description': 'Independent contractor work',
        'icon': '🆓',
      },
      'student': {
        'name': 'Student',
        'min_salary': 3000.0,
        'mid_salary': 6000.0,
        'senior_salary': 10000.0,
        'description': 'Part-time and student work',
        'icon': '🎓',
      },
      'retail': {
        'name': 'Retail Worker',
        'min_salary': 6000.0,
        'mid_salary': 10000.0,
        'senior_salary': 15000.0,
        'description': 'Retail and customer service',
        'icon': '🛍️',
      },
      'other': {
        'name': 'Other',
        'min_salary': 8000.0,
        'mid_salary': 15000.0,
        'senior_salary': 25000.0,
        'description': 'Other occupations',
        'icon': '💼',
      },
    };
  }

  /// Get occupation names list
  static List<String> getOccupationNames() {
    var occupations = getMinimumIncomeByOccupation();
    return occupations.keys.toList();
  }

  /// Get occupation display names
  static Map<String, String> getOccupationDisplayNames() {
    var occupations = getMinimumIncomeByOccupation();
    Map<String, String> displayNames = {};
    occupations.forEach((key, value) {
      displayNames[key] = value['name'] as String;
    });
    return displayNames;
  }

  /// Get salary recommendations for an occupation
  static Map<String, dynamic>? getSalaryRecommendations(String occupation) {
    var occupations = getMinimumIncomeByOccupation();
    return occupations[occupation];
  }

  /// Calculate recommended salary based on experience level
  static double getRecommendedSalary(
    String occupation,
    String experienceLevel,
  ) {
    var recommendations = getSalaryRecommendations(occupation);
    if (recommendations == null) return 8000.0;

    switch (experienceLevel) {
      case 'entry':
        return recommendations['min_salary'] ?? 8000.0;
      case 'mid':
        return recommendations['mid_salary'] ?? 15000.0;
      case 'senior':
        return recommendations['senior_salary'] ?? 25000.0;
      default:
        return recommendations['mid_salary'] ?? 15000.0;
    }
  }

  /// Get experience level options
  static List<Map<String, dynamic>> getExperienceLevels() {
    return [
      {
        'key': 'entry',
        'name': 'Entry Level (0-2 years)',
        'description': 'Recent graduate or new to field',
      },
      {
        'key': 'mid',
        'name': 'Mid Level (3-7 years)',
        'description': 'Some experience in the field',
      },
      {
        'key': 'senior',
        'name': 'Senior Level (8+ years)',
        'description': 'Experienced professional',
      },
    ];
  }

  // Helper methods for current financial data
  static Future<double> _getCurrentBankBalance(String userId) async {
    var summary = await BankAccountService.getBankSummary(userId);
    return summary['total_balance'] ?? 0.0;
  }

  static Future<double> _getCurrentNetWorth(String userId) async {
    // Calculate net worth from all assets and liabilities
    double bankBalance = await _getCurrentBankBalance(userId);
    double safeValue = await _getCurrentSafeValue(userId);
    double cashValue = await _getCurrentCashValue(userId);
    double investmentsValue = await _getCurrentInvestments(userId);
    double assetsValue = await _getCurrentAssetsValue(userId);
    double debtAmount = await _getCurrentTotalDebt(userId);

    return bankBalance +
        safeValue +
        cashValue +
        investmentsValue +
        assetsValue -
        debtAmount;
  }

  static Future<double> _getCurrentTotalDebt(String userId) async {
    var summary = await DebtService.getDebtSummary(userId);
    return summary['total_owed'] ?? 0.0;
  }

  static Future<double> _getCurrentSavings(String userId) async {
    var summary = await SavingsService.getSavingsSummary(userId);
    return summary['total_current_amount'] ?? 0.0;
  }

  static Future<double> _getCurrentInvestments(String userId) async {
    var summary = await InvestmentService.getPortfolioSummary(userId);
    return summary['total_value'] ?? 0.0;
  }

  static Future<double> _getCurrentSafeValue(String userId) async {
    var summary = await SafeService.getSafeSummary(userId);
    return summary['total_value'] ?? 0.0;
  }

  static Future<double> _getCurrentCashValue(String userId) async {
    // For now, return 0 as CashService might not be implemented yet
    return 0.0;
  }

  static Future<double> _getCurrentAssetsValue(String userId) async {
    var summary = await AssetsService.getAssetsSummary(userId);
    return summary['total_current_value'] ?? 0.0;
  }

  static Future<double> _getAverageMonthlyIncome(String userId) async {
    // Get income summary and calculate average
    var summary = await IncomeService.getIncomeSummary(userId);
    double totalIncome = summary['total_income'] ?? 0.0;

    // Assume average over 6 months if we have data
    return totalIncome / 6; // Average over 6 months
  }

  static Future<double> _getAverageMonthlyExpenses(String userId) async {
    // Get expenses summary and calculate average
    var summary = await ExpensesService.getExpensesSummary(userId);
    double totalExpenses = summary['total_expenses'] ?? 0.0;

    // Assume average over 6 months if we have data
    return totalExpenses / 6; // Average over 6 months
  }

  static Future<double> _getTotalMonthlyDebtPayments(String userId) async {
    return await DebtService.getTotalMonthlyPayments(userId);
  }

  static Future<double> _getAverageMonthlySavings(String userId) async {
    // Calculate average monthly savings contribution
    var summary = await SavingsService.getSavingsSummary(userId);
    double totalSaved = summary['total_current_amount'] ?? 0.0;

    // Assume average savings over 12 months if no specific data
    return totalSaved / 12;
  }

  static Future<double> _getMonthlyAutomaticExpenses(String userId) async {
    // Get automatic expenses summary
    var summary = await AutomaticExpensesService.getAutomaticExpensesSummary(
      userId,
    );
    return summary['monthly_equivalent'] ?? 0.0;
  }
}
