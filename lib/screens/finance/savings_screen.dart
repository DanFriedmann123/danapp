import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/finance_theme.dart';
import '../../services/savings_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _currentAmountController =
      TextEditingController();
  final TextEditingController _monthlyContributionController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'emergency';
  DateTime? _selectedDeadline;
  bool _hasDeadline = false;

  final List<String> _categories = [
    'emergency',
    'vacation',
    'house',
    'car',
    'wedding',
    'education',
    'custom',
  ];

  final Map<String, String> _categoryNames = {
    'emergency': 'Emergency Fund',
    'vacation': 'Vacation',
    'house': 'House Down Payment',
    'car': 'Car Purchase',
    'wedding': 'Wedding',
    'education': 'Education',
    'custom': 'Custom Goal',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _monthlyContributionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addSavingsGoal() async {
    if (_nameController.text.isEmpty ||
        _targetAmountController.text.isEmpty ||
        _currentAmountController.text.isEmpty ||
        _monthlyContributionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      String userId = 'user123'; // Replace with actual user ID

      await SavingsService.addSavingsGoal({
        'user_id': userId,
        'name': _nameController.text,
        'target_amount': double.parse(_targetAmountController.text),
        'current_amount': double.parse(_currentAmountController.text),
        'monthly_contribution': double.parse(
          _monthlyContributionController.text,
        ),
        'category': _selectedCategory,
        'deadline': _selectedDeadline,
        'is_active': true,
        'notes': _notesController.text,
        'created_at': DateTime.now(),
      });

      // Clear form
      _nameController.clear();
      _targetAmountController.clear();
      _currentAmountController.clear();
      _monthlyContributionController.clear();
      _notesController.clear();
      _selectedCategory = 'emergency';
      _selectedDeadline = null;
      _hasDeadline = false;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Savings Goal', style: FinanceTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Goal Name',
                      hintText: 'e.g., Emergency Fund',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Category',
                    ),
                    items:
                        _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_categoryNames[category] ?? category),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'emergency';
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _targetAmountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Target Amount (₪)',
                      hintText: '10000.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _currentAmountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Current Amount (₪)',
                      hintText: '2500.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _monthlyContributionController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Monthly Contribution (\$)',
                      hintText: '500.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasDeadline,
                        onChanged: (value) {
                          setState(() {
                            _hasDeadline = value ?? false;
                            if (!_hasDeadline) _selectedDeadline = null;
                          });
                        },
                        activeColor: FinanceTheme.primaryColor,
                      ),
                      Text('Set deadline', style: FinanceTheme.bodyMedium),
                    ],
                  ),
                  if (_hasDeadline) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    ListTile(
                      title: Text(
                        _selectedDeadline != null
                            ? 'Deadline: ${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
                            : 'Select Deadline',
                        style: FinanceTheme.bodyMedium,
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDeadline = date;
                          });
                        }
                      },
                    ),
                  ],
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Notes (optional)',
                      hintText: 'Add any notes about this goal',
                    ),
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
                onPressed: _addSavingsGoal,
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Add Goal'),
              ),
            ],
          ),
    );
  }

  Widget _buildSavingsSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SavingsService.getSavingsSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalSaved = data['total_saved'] ?? 0.0;
          double totalTarget = data['total_target'] ?? 0.0;
          double totalProgress = data['total_progress'] ?? 0.0;
          int activeGoals = data['active_goals'] ?? 0;
          double monthlyContributions =
              data['total_monthly_contributions'] ?? 0.0;

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                children: [
                  Text('Savings Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Saved', style: FinanceTheme.bodyMedium),
                          Text(
                            FinanceTheme.formatCurrency(totalSaved),
                            style: FinanceTheme.valueLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Progress', style: FinanceTheme.bodyMedium),
                          Text(
                            '${totalProgress.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: FinanceTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  LinearProgressIndicator(
                    value: totalProgress / 100,
                    backgroundColor: FinanceTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FinanceTheme.successColor,
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ${FinanceTheme.formatCurrency(totalTarget)}',
                        style: FinanceTheme.bodyMedium,
                      ),
                      Text(
                        '$activeGoals Active Goals',
                        style: FinanceTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (monthlyContributions > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Monthly: ${FinanceTheme.formatCurrency(monthlyContributions)}',
                        style: FinanceTheme.bodySmall.copyWith(
                          color: FinanceTheme.primaryColor,
                        ),
                      ),
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

  Widget _buildGoalsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: SavingsService.getUserSavingsGoals(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings,
                    size: 80,
                    color: FinanceTheme.textTertiary,
                  ),
                  SizedBox(height: FinanceTheme.spacingL),
                  Text(
                    'No savings goals yet',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    'Add your first savings goal to get started',
                    style: FinanceTheme.bodyMedium,
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

              double currentAmount = data['current_amount'] ?? 0.0;
              double targetAmount = data['target_amount'] ?? 0.0;
              double progress = SavingsService.calculateProgressPercentage(
                currentAmount,
                targetAmount,
              );
              String category = data['category'] ?? 'custom';
              String categoryName = _categoryNames[category] ?? category;
              DateTime? deadline = data['deadline']?.toDate();
              String status = SavingsService.getGoalStatus(
                currentAmount,
                targetAmount,
                deadline,
              );

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
                                  categoryName,
                                  style: FinanceTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FinanceTheme.formatCurrency(currentAmount),
                                style: FinanceTheme.valueSmall,
                              ),
                              Text(
                                '${progress.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: FinanceTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: FinanceTheme.spacingS),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: FinanceTheme.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FinanceTheme.successColor,
                        ),
                      ),
                      SizedBox(height: FinanceTheme.spacingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target: ${FinanceTheme.formatCurrency(targetAmount)}',
                            style: FinanceTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.autorenew,
                                size: 16,
                                color: FinanceTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${FinanceTheme.formatCurrency(data['monthly_contribution'] ?? 0.0)}/mo',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: FinanceTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (deadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Deadline: ${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
                            style: FinanceTheme.bodySmall.copyWith(
                              color:
                                  status == 'behind'
                                      ? FinanceTheme.dangerColor
                                      : FinanceTheme.textSecondary,
                            ),
                          ),
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
    String userId = 'user123'; // Replace with actual user ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Savings', style: FinanceTheme.headingSmall),
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
              _buildSavingsSummary(userId),
              SizedBox(height: FinanceTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Savings Goals', style: FinanceTheme.headingMedium),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await SavingsService.triggerMonthlyContributions(
                            userId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Monthly contributions processed!'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.autorenew,
                          color: FinanceTheme.successColor,
                          size: 24,
                        ),
                        tooltip: 'Process Monthly Contributions',
                      ),
                      IconButton(
                        onPressed: _showAddGoalDialog,
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
              Expanded(child: _buildGoalsList(userId)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: FinanceTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
