import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/investment_service.dart';
import '../../config/finance_theme.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _totalInvestedController =
      TextEditingController();
  final TextEditingController _currentValueController = TextEditingController();
  final TextEditingController _monthlyAmountController =
      TextEditingController();
  bool _isAutomatic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _totalInvestedController.dispose();
    _currentValueController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
  }

  Future<void> _addInvestment() async {
    if (_nameController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _totalInvestedController.text.isEmpty ||
        _currentValueController.text.isEmpty ||
        _monthlyAmountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      // For now, using a hardcoded user ID - you'll need to get this from auth
      String userId = 'user123'; // Replace with actual user ID

      await InvestmentService.addInvestment({
        'user_id': userId,
        'name': _nameController.text,
        'company': _companyController.text,
        'total_invested': double.parse(_totalInvestedController.text),
        'current_value': double.parse(_currentValueController.text),
        'monthly_amount': double.parse(_monthlyAmountController.text),
        'is_automatic': _isAutomatic,
        'created_at': DateTime.now(),
      });

      // Clear form
      _nameController.clear();
      _companyController.clear();
      _totalInvestedController.clear();
      _currentValueController.clear();
      _monthlyAmountController.clear();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investment added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddInvestmentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Investment', style: FinanceTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Investment Name',
                      hintText: 'e.g., Vanguard S&P 500 ETF',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _companyController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Company',
                      hintText: 'e.g., Vanguard',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _totalInvestedController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Total Invested (\$)',
                      hintText: '5000.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _currentValueController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Current Value (₪)',
                      hintText: '5500.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _monthlyAmountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Monthly Amount (₪)',
                      hintText: '500.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAutomatic,
                        onChanged: (value) {
                          setState(() {
                            _isAutomatic = value ?? true;
                          });
                        },
                        activeColor: FinanceTheme.primaryColor,
                      ),
                      Text(
                        'Automatic monthly payments',
                        style: FinanceTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: FinanceTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addInvestment,
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Add Investment'),
              ),
            ],
          ),
    );
  }

  Widget _buildPortfolioSummary(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: InvestmentService.getUserInvestments(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          double totalValue = 0.0;
          double totalInvested = 0.0;
          int investmentCount = snapshot.data!.docs.length;

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              totalValue += data['current_value'] ?? 0.0;
              totalInvested += data['total_invested'] ?? 0.0;
            }
          }

          double totalGainLoss = totalValue - totalInvested;
          double gainLossPercentage =
              totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                children: [
                  Text('Portfolio Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Value', style: FinanceTheme.bodyMedium),
                          Text(
                            FinanceTheme.formatCurrency(totalValue),
                            style: FinanceTheme.valueLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
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
                          Text(
                            '${gainLossPercentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color:
                                  totalGainLoss >= 0
                                      ? FinanceTheme.successColor
                                      : FinanceTheme.dangerColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Invested: ${FinanceTheme.formatCurrency(totalInvested)}',
                        style: FinanceTheme.bodyMedium,
                      ),
                      Text(
                        '$investmentCount Investments',
                        style: FinanceTheme.bodyMedium,
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

  Widget _buildInvestmentsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: InvestmentService.getUserInvestments(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No investments yet',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first investment to get started',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              double totalInvested = data['total_invested'] ?? 0.0;
              double currentValue = data['current_value'] ?? 0.0;
              double gainLoss = currentValue - totalInvested;
              double gainLossPercentage =
                  totalInvested > 0 ? (gainLoss / totalInvested) * 100 : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: FinanceTheme.cardDecoration,
                child: Padding(
                  padding: FinanceTheme.listItemPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: FinanceTheme.valueSmall,
                                ),
                                Text(
                                  data['company'] ?? '',
                                  style: FinanceTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${currentValue.toStringAsFixed(2)}',
                                style: FinanceTheme.valueSmall,
                              ),
                              Text(
                                '${gainLossPercentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color:
                                      gainLoss >= 0
                                          ? FinanceTheme.successColor
                                          : FinanceTheme.dangerColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invested: \$${totalInvested.toStringAsFixed(2)}',
                            style: FinanceTheme.bodySmall,
                          ),
                          if (data['is_automatic'] == true)
                            Row(
                              children: [
                                Icon(
                                  Icons.autorenew,
                                  size: 16,
                                  color: FinanceTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${(data['monthly_amount'] ?? 0.0).toStringAsFixed(0)}/mo',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: FinanceTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // For now, using hardcoded user ID - replace with actual user ID from auth
    String userId = 'user123';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Investments',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
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
              _buildPortfolioSummary(userId),
              SizedBox(height: FinanceTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Investments', style: FinanceTheme.headingMedium),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          // For testing - trigger monthly payments
                          await InvestmentService.triggerMonthlyPayments(
                            userId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Monthly payments processed!'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.autorenew,
                          color: FinanceTheme.successColor,
                          size: 24,
                        ),
                        tooltip: 'Process Monthly Payments',
                      ),
                      IconButton(
                        onPressed: _showAddInvestmentDialog,
                        icon: Icon(
                          Icons.add_circle,
                          color: FinanceTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: FinanceTheme.spacingM),
              Expanded(child: _buildInvestmentsList(userId)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInvestmentDialog,
        backgroundColor: FinanceTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
