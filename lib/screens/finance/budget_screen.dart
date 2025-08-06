import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/finance_theme.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: FinanceTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Budget', style: FinanceTheme.headingLarge),
              SizedBox(height: FinanceTheme.spacingS),
              Text(
                'Set and track your monthly spending limits',
                style: FinanceTheme.bodyLarge,
              ),
              SizedBox(height: FinanceTheme.spacingXL),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: FinanceTheme.textTertiary,
                      ),
                      SizedBox(height: FinanceTheme.spacingL),
                      Text(
                        'Budget features coming soon!',
                        style: FinanceTheme.headingSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: FinanceTheme.spacingS),
                      Text(
                        'Create budgets and track spending',
                        style: FinanceTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
