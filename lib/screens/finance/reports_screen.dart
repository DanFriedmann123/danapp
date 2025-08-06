import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/finance_theme.dart';
import '../../services/reports_service.dart';
import '../../services/expenses_service.dart';
import '../../services/income_service.dart';
import '../../services/prediction_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int? _selectedPredictionMonth;
  int? _selectedPredictionYear;

  @override
  Widget build(BuildContext context) {
    String userId = 'user123'; // Replace with actual user ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Reports', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: FinanceTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Financial Overview', style: FinanceTheme.headingLarge),
              SizedBox(height: FinanceTheme.spacingS),
              Text(
                'Comprehensive analysis of your financial health',
                style: FinanceTheme.bodyLarge,
              ),
              SizedBox(height: FinanceTheme.spacingXL),

              // Financial Summary
              _buildFinancialSummary(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Financial Health Score
              _buildFinancialHealth(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Cash Flow Analysis
              _buildCashFlowAnalysis(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Spending Insights
              _buildSpendingInsights(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Savings Progress
              _buildSavingsProgress(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Investment Performance
              _buildInvestmentPerformance(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Debt Analysis
              _buildDebtAnalysis(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Income Analysis
              _buildIncomeAnalysis(userId),
              SizedBox(height: FinanceTheme.spacingL),

              // Future Predictions
              _buildFuturePredictions(userId),
              SizedBox(height: FinanceTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getFinancialSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double netWorth = data['net_worth'] ?? 0.0;
          double totalAssets = data['total_assets'] ?? 0.0;
          double totalLiabilities = data['total_liabilities'] ?? 0.0;
          double cashFlow = data['cash_flow'] ?? 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Worth', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(netWorth),
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color:
                                    netWorth >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Cash Flow', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(cashFlow),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color:
                                    cashFlow >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Assets', style: FinanceTheme.bodySmall),
                            Text(
                              FinanceTheme.formatCurrency(totalAssets),
                              style: FinanceTheme.valueMedium,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Liabilities',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalLiabilities),
                              style: FinanceTheme.valueMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildFinancialHealth(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getFinancialHealth(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double overallHealth = data['overall_health'] ?? 0.0;
          double netWorthScore = data['net_worth_score'] ?? 0.0;
          double cashFlowScore = data['cash_flow_score'] ?? 0.0;
          double savingsRateScore = data['savings_rate_score'] ?? 0.0;
          double debtScore = data['debt_score'] ?? 0.0;

          String healthStatus =
              overallHealth >= 80
                  ? 'Excellent'
                  : overallHealth >= 60
                  ? 'Good'
                  : overallHealth >= 40
                  ? 'Fair'
                  : 'Poor';

          Color healthColor =
              overallHealth >= 80
                  ? FinanceTheme.successColor
                  : overallHealth >= 60
                  ? Colors.orange
                  : overallHealth >= 40
                  ? Colors.yellow[700]!
                  : FinanceTheme.dangerColor;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Health Score',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(healthStatus, style: FinanceTheme.bodyMedium),
                            Text(
                              '${overallHealth.toStringAsFixed(0)}/100',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: healthColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: healthColor.withOpacity(0.1),
                                border: Border.all(
                                  color: healthColor,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${overallHealth.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: healthColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  _buildHealthIndicator('Net Worth', netWorthScore),
                  _buildHealthIndicator('Cash Flow', cashFlowScore),
                  _buildHealthIndicator('Savings Rate', savingsRateScore),
                  _buildHealthIndicator('Debt Management', debtScore),
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildHealthIndicator(String label, double score) {
    Color color =
        score >= 80
            ? FinanceTheme.successColor
            : score >= 60
            ? Colors.orange
            : score >= 40
            ? Colors.yellow[700]!
            : FinanceTheme.dangerColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: FinanceTheme.bodySmall)),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: FinanceTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${score.toStringAsFixed(0)}',
            style: FinanceTheme.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowAnalysis(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getFinancialSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double income = data['income'] ?? 0.0;
          double expenses = data['expenses'] ?? 0.0;
          double cashFlow = data['cash_flow'] ?? 0.0;
          double savingsRate = data['savings_rate'] ?? 0.0;
          double expenseRatio = data['expense_ratio'] ?? 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash Flow Analysis', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Income', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(income),
                              style: FinanceTheme.valueLarge.copyWith(
                                color: FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Expenses', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(expenses),
                              style: FinanceTheme.valueLarge.copyWith(
                                color: FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Cash Flow',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(cashFlow),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color:
                                    cashFlow >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Savings Rate',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              '${savingsRate.toStringAsFixed(1)}%',
                              style: FinanceTheme.valueMedium.copyWith(
                                color: FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  LinearProgressIndicator(
                    value: expenseRatio / 100,
                    backgroundColor: FinanceTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FinanceTheme.dangerColor,
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    'Expense Ratio: ${expenseRatio.toStringAsFixed(1)}%',
                    style: FinanceTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildSpendingInsights(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getSpendingInsights(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalExpenses = data['total_expenses'] ?? 0.0;
          double totalIncome = data['total_income'] ?? 0.0;
          double expenseRatio = data['expense_ratio'] ?? 0.0;
          List<Map<String, dynamic>> topCategories =
              List<Map<String, dynamic>>.from(data['top_categories'] ?? []);

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spending Insights', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Expenses',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalExpenses),
                              style: FinanceTheme.valueLarge,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Expense Ratio',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              '${expenseRatio.toStringAsFixed(1)}%',
                              style: FinanceTheme.valueLarge.copyWith(
                                color:
                                    expenseRatio > 80
                                        ? FinanceTheme.dangerColor
                                        : FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (topCategories.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Text(
                      'Top Spending Categories:',
                      style: FinanceTheme.bodyMedium,
                    ),
                    SizedBox(height: FinanceTheme.spacingS),
                    ...topCategories.map((category) {
                      String categoryName =
                          ExpensesService.getCategoryNames()[category['category']] ??
                          category['category'];
                      String icon =
                          ExpensesService.getCategoryIcons()[category['category']] ??
                          '📄';
                      double amount = category['amount'] ?? 0.0;
                      double percentage = category['percentage'] ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(icon),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categoryName,
                                style: FinanceTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '₪${amount.toStringAsFixed(2)}',
                              style: FinanceTheme.bodyMedium,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${percentage.toStringAsFixed(1)}%)',
                              style: FinanceTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildSavingsProgress(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getSavingsProgress(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalSaved = data['total_saved'] ?? 0.0;
          double totalTarget = data['total_target'] ?? 0.0;
          double progress = data['progress'] ?? 0.0;
          int activeGoals = data['active_goals'] ?? 0;
          double completionRate = data['completion_rate'] ?? 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Savings Progress', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Saved', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(totalSaved),
                              style: FinanceTheme.valueLarge.copyWith(
                                color: FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Active Goals',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              '$activeGoals',
                              style: FinanceTheme.valueLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  LinearProgressIndicator(
                    value: completionRate / 100,
                    backgroundColor: FinanceTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FinanceTheme.successColor,
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    'Progress: ${completionRate.toStringAsFixed(1)}% (${FinanceTheme.formatCurrency(totalSaved)} / ${FinanceTheme.formatCurrency(totalTarget)})',
                    style: FinanceTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildInvestmentPerformance(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getInvestmentPerformance(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalValue = data['total_value'] ?? 0.0;
          double totalInvested = data['total_invested'] ?? 0.0;
          double totalGainLoss = data['total_gain_loss'] ?? 0.0;
          double gainLossPercentage = data['gain_loss_percentage'] ?? 0.0;
          int investmentCount = data['investment_count'] ?? 0;
          double roi = data['return_on_investment'] ?? 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment Performance',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portfolio Value',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalValue),
                              style: FinanceTheme.valueLarge,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Invested',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalInvested),
                              style: FinanceTheme.valueLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gain/Loss', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(totalGainLoss),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color:
                                    totalGainLoss >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('ROI', style: FinanceTheme.bodyMedium),
                            Text(
                              '${roi.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color:
                                    roi >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    '$investmentCount Investments • ${gainLossPercentage.toStringAsFixed(1)}% Change',
                    style: FinanceTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildDebtAnalysis(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getDebtAnalysis(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalOwed = data['total_owed'] ?? 0.0;
          double totalOwedToYou = data['total_owed_to_you'] ?? 0.0;
          double netDebt = data['net_debt'] ?? 0.0;
          int totalDebts = data['total_debts'] ?? 0;
          double debtRatio = data['debt_ratio'] ?? 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debt Analysis', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You Owe', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(totalOwed),
                              style: FinanceTheme.valueLarge.copyWith(
                                color: FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Owed to You', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(totalOwedToYou),
                              style: FinanceTheme.valueLarge.copyWith(
                                color: FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Debt', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(netDebt),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color:
                                    netDebt <= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Total Debts', style: FinanceTheme.bodyMedium),
                            Text('$totalDebts', style: FinanceTheme.valueLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (totalOwed > 0 || totalOwedToYou > 0) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    LinearProgressIndicator(
                      value: debtRatio / 100,
                      backgroundColor: FinanceTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FinanceTheme.dangerColor,
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingS),
                    Text(
                      'Debt Ratio: ${debtRatio.toStringAsFixed(1)}%',
                      style: FinanceTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildIncomeAnalysis(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReportsService.getIncomeAnalysis(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalIncome = data['total_income'] ?? 0.0;
          int totalEntries = data['total_entries'] ?? 0;
          double averageIncome = data['average_income'] ?? 0.0;
          List<Map<String, dynamic>> topSources =
              List<Map<String, dynamic>>.from(data['top_sources'] ?? []);

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income Analysis', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Income',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalIncome),
                              style: FinanceTheme.valueLarge.copyWith(
                                color: FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Average per Entry',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(averageIncome),
                              style: FinanceTheme.valueLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    '$totalEntries Income Entries',
                    style: FinanceTheme.bodySmall,
                  ),
                  if (topSources.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Text('Top Income Sources:', style: FinanceTheme.bodyMedium),
                    SizedBox(height: FinanceTheme.spacingS),
                    ...topSources.map((source) {
                      String sourceName =
                          IncomeService.getSourceNames()[source['source']] ??
                          source['source'];
                      String icon =
                          IncomeService.getSourceIcons()[source['source']] ??
                          '📄';
                      double amount = source['amount'] ?? 0.0;
                      double percentage = source['percentage'] ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(icon),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sourceName,
                                style: FinanceTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '₪${amount.toStringAsFixed(2)}',
                              style: FinanceTheme.bodyMedium,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${percentage.toStringAsFixed(1)}%)',
                              style: FinanceTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildFuturePredictions(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PredictionService.getFuturePrediction(
        userId,
        _selectedPredictionMonth ?? DateTime.now().month + 1,
        _selectedPredictionYear ?? DateTime.now().year,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;

          if (data['error'] != null) {
            return Container(
              decoration: FinanceTheme.cardDecorationElevated,
              child: Padding(
                padding: FinanceTheme.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Future Predictions',
                      style: FinanceTheme.headingSmall,
                    ),
                    SizedBox(height: FinanceTheme.spacingM),
                    Text(
                      'Select a future date to see predictions',
                      style: FinanceTheme.bodyMedium,
                    ),
                    SizedBox(height: FinanceTheme.spacingM),
                    ElevatedButton(
                      onPressed: () => _showPredictionDialog(userId),
                      style: FinanceTheme.primaryButtonStyle,
                      child: Text('Set Prediction Date'),
                    ),
                  ],
                ),
              ),
            );
          }

          double currentBalance = data['current_balance'] ?? 0.0;
          double predictedBalance = data['predicted_balance'] ?? 0.0;
          double predictedNetWorth = data['predicted_net_worth'] ?? 0.0;
          double predictedDebt = data['predicted_debt'] ?? 0.0;
          double predictedSavings = data['predicted_savings'] ?? 0.0;
          double monthlyIncome = data['monthly_income'] ?? 0.0;
          double monthlyExpenses = data['monthly_expenses'] ?? 0.0;
          int monthsToTarget = data['months_to_target'] ?? 0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Future Predictions',
                        style: FinanceTheme.headingSmall,
                      ),
                      IconButton(
                        onPressed: () => _showPredictionDialog(userId),
                        icon: Icon(
                          Icons.calendar_today,
                          color: FinanceTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Text(
                    '${monthsToTarget} months from now',
                    style: FinanceTheme.bodySmall.copyWith(
                      color: FinanceTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Predicted Balance',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(predictedBalance),
                              style: FinanceTheme.valueLarge.copyWith(
                                color:
                                    predictedBalance >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Predicted Net Worth',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(predictedNetWorth),
                              style: FinanceTheme.valueLarge.copyWith(
                                color:
                                    predictedNetWorth >= 0
                                        ? FinanceTheme.successColor
                                        : FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Income',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(monthlyIncome),
                              style: FinanceTheme.bodyMedium.copyWith(
                                color: FinanceTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Monthly Expenses',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(monthlyExpenses),
                              style: FinanceTheme.bodyMedium.copyWith(
                                color: FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (predictedDebt > 0) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Text(
                      'Predicted Debt: ${FinanceTheme.formatCurrency(predictedDebt)}',
                      style: FinanceTheme.bodyMedium.copyWith(
                        color: FinanceTheme.dangerColor,
                      ),
                    ),
                  ],
                  if (predictedSavings > 0) ...[
                    Text(
                      'Predicted Savings: ${FinanceTheme.formatCurrency(predictedSavings)}',
                      style: FinanceTheme.bodyMedium.copyWith(
                        color: FinanceTheme.successColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: FinanceTheme.cardDecorationElevated,
          child: Padding(
            padding: FinanceTheme.cardPadding,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  void _showPredictionDialog(String userId) {
    int selectedMonth = _selectedPredictionMonth ?? DateTime.now().month;
    int selectedYear = _selectedPredictionYear ?? DateTime.now().year;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    'Set Prediction Date',
                    style: FinanceTheme.headingSmall,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select month and year for prediction:',
                        style: FinanceTheme.bodyMedium,
                      ),
                      SizedBox(height: FinanceTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              decoration: FinanceTheme.inputDecoration.copyWith(
                                labelText: 'Month',
                              ),
                              items: List.generate(12, (index) {
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(_getMonthName(index + 1)),
                                );
                              }),
                              onChanged: (value) {
                                setState(() {
                                  selectedMonth = value!;
                                });
                                this.setState(() {
                                  _selectedPredictionMonth = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: FinanceTheme.spacingM),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: FinanceTheme.inputDecoration.copyWith(
                                labelText: 'Year',
                              ),
                              items: List.generate(5, (index) {
                                int year = DateTime.now().year + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (value) {
                                setState(() {
                                  selectedYear = value!;
                                });
                                this.setState(() {
                                  _selectedPredictionYear = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: FinanceTheme.textButtonStyle,
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        this.setState(() {
                          // This will trigger a rebuild with the new prediction
                        });
                      },
                      style: FinanceTheme.primaryButtonStyle,
                      child: const Text('Generate Prediction'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
