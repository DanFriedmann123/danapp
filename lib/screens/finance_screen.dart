import 'package:flutter/material.dart';
import '../config/finance_theme.dart';
import 'finance/investments_screen.dart';
import 'finance/income_screen.dart';
import 'finance/expenses_screen.dart';
import 'finance/savings_screen.dart';
import 'finance/debt_screen.dart';
import 'finance/reports_screen.dart';
import 'finance/safe_screen.dart';
import 'finance/cash_screen.dart';
import 'finance/assets_screen.dart';
import 'finance/bank_account_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finance & Budget', style: FinanceTheme.headingLarge),
            SizedBox(height: FinanceTheme.spacingS),
            Text(
              'Manage your finances and track your spending',
              style: FinanceTheme.bodyLarge,
            ),
            SizedBox(height: FinanceTheme.spacingXL),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildFinanceCard(
                    context,
                    'Investments',
                    Icons.trending_up,
                    'Track your portfolio and investments',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvestmentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Income',
                    Icons.attach_money,
                    'Track your income sources',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IncomeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Expenses',
                    Icons.receipt_long,
                    'Log and categorize your expenses',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpensesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Savings',
                    Icons.savings,
                    'Monitor your savings goals',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Debt',
                    Icons.credit_card,
                    'Track and manage your debt',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebtScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Reports',
                    Icons.analytics,
                    'View financial reports and insights',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Safe',
                    Icons.security,
                    'Secure storage and valuables',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SafeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Cash',
                    Icons.money,
                    'Track physical cash and currency',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CashScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Assets',
                    Icons.devices,
                    'Track sellable devices and items',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssetsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFinanceCard(
                    context,
                    'Bank Account',
                    Icons.account_balance,
                    'Track bank account and transfers',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BankAccountScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: FinanceTheme.cardDecoration,
        child: Padding(
          padding: FinanceTheme.listItemPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: FinanceTheme.valueSmall),
              SizedBox(height: FinanceTheme.spacingXS),
              Divider(color: FinanceTheme.borderColor, thickness: 1),
              SizedBox(height: FinanceTheme.spacingS),
              Icon(icon, size: 28, color: FinanceTheme.primaryColor),
              SizedBox(height: FinanceTheme.spacingXS),
              Expanded(
                child: Text(
                  description,
                  style: FinanceTheme.bodySmall.copyWith(height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
