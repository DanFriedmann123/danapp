import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (_nameController.text.isEmpty || _companyController.text.isEmpty ||
        _totalInvestedController.text.isEmpty || _currentValueController.text.isEmpty ||
        _monthlyAmountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }

    // Close dialog immediately
    Navigator.pop(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add investments')),
          );
        }
        return;
      }
      String userId = user.uid;

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
      _isAutomatic = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
                      SizedBox(height: FinanceTheme.spacingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _showEditInvestmentDialog(doc.id, data),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: FinanceTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteInvestment(doc.id),
                            icon: Icon(
                              Icons.delete_outline,
                              color: FinanceTheme.dangerColor,
                              size: 20,
                            ),
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

  void _showEditInvestmentDialog(String investmentId, Map<String, dynamic> data) {
    // Pre-fill the form with existing data
    _nameController.text = data['name'] ?? '';
    _companyController.text = data['company'] ?? '';
    _totalInvestedController.text = (data['total_invested'] ?? 0.0).toString();
    _currentValueController.text = (data['current_value'] ?? 0.0).toString();
    _monthlyAmountController.text = (data['monthly_amount'] ?? 0.0).toString();
    _isAutomatic = data['is_automatic'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Investment', style: FinanceTheme.headingSmall),
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
                  labelText: 'Total Invested (₪)',
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
                  Text('Automatic Investment', style: FinanceTheme.bodyMedium),
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
            onPressed: () => _updateInvestment(investmentId),
            style: FinanceTheme.primaryButtonStyle,
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateInvestment(String investmentId) async {
    if (_nameController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _totalInvestedController.text.isEmpty ||
        _currentValueController.text.isEmpty ||
        _monthlyAmountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }

    // Close the edit dialog immediately
    Navigator.pop(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to update investments')),
          );
        }
        return;
      }

      Map<String, dynamic> investmentData = {
        'name': _nameController.text,
        'company': _companyController.text,
        'total_invested': double.parse(_totalInvestedController.text),
        'current_value': double.parse(_currentValueController.text),
        'monthly_amount': double.parse(_monthlyAmountController.text),
        'is_automatic': _isAutomatic,
      };

      await InvestmentService.updateInvestment(investmentId, investmentData);

      // Clear form
      _nameController.clear();
      _companyController.clear();
      _totalInvestedController.clear();
      _currentValueController.clear();
      _monthlyAmountController.clear();
      _isAutomatic = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvestment(String investmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Investment', style: FinanceTheme.headingSmall),
        content: const Text('Are you sure you want to delete this investment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: FinanceTheme.textButtonStyle,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FinanceTheme.dangerColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await InvestmentService.deleteInvestment(investmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Investment deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view investments')),
      );
    }
    String userId = user.uid;

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
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Monthly payments processed!'),
                              ),
                            );
                          }
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
