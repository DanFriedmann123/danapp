import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/finance_theme.dart';
import '../../services/debt_service.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _monthlyPaymentController =
      TextEditingController();
  String _selectedType = 'owed';
  DateTime? _selectedDueDate;
  bool _hasDueDate = false;
  bool _hasAutomaticPayment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _personController.dispose();
    _notesController.dispose();
    _monthlyPaymentController.dispose();
    super.dispose();
  }

  Future<void> _addDebt() async {
    if (_descriptionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a description')),
        );
      }
      return;
    }
    if (_personController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a person/entity')),
        );
      }
      return;
    }
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
      }
      return;
    }

    // Show verification dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Debt Details', style: FinanceTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerificationRow('Type', _selectedType == 'owed' ? 'You Owe' : 'Owed to You'),
            _buildVerificationRow('Description', _descriptionController.text.trim()),
            _buildVerificationRow('Person/Entity', _personController.text.trim()),
            _buildVerificationRow('Amount', '\$${amount.toStringAsFixed(2)}'),
            if (_selectedDueDate != null)
              _buildVerificationRow('Due Date', '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}'),
            if (_hasAutomaticPayment && _monthlyPaymentController.text.isNotEmpty)
              _buildVerificationRow('Monthly Payment', '\$${double.tryParse(_monthlyPaymentController.text)?.toStringAsFixed(2) ?? '0.00'}'),
            if (_notesController.text.trim().isNotEmpty)
              _buildVerificationRow('Notes', _notesController.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: FinanceTheme.textButtonStyle,
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: FinanceTheme.primaryButtonStyle,
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return; // User chose to edit, keep dialog open
    }

    // Close the add debt dialog
    Navigator.pop(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add debts')),
          );
        }
        return;
      }
      String userId = user.uid;

      await DebtService.addDebt({
        'user_id': userId,
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'person': _personController.text,
        'type': _selectedType, // 'owed' or 'owed_to_you'
        'due_date': _selectedDueDate,
        'monthly_payment':
            _hasAutomaticPayment
                ? double.tryParse(_monthlyPaymentController.text) ?? 0.0
                : 0.0,
        'is_active': true,
        'notes': _notesController.text,
        'created_at': DateTime.now(),
      });

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      _personController.clear();
      _notesController.clear();
      _monthlyPaymentController.clear();
      _selectedType = 'owed';
      _selectedDueDate = null;
      _hasDueDate = false;
      _hasAutomaticPayment = false;

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt added successfully!')),
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

  Widget _buildVerificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: FinanceTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: FinanceTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: FinanceTheme.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _editDebt(String debtId, Map<String, dynamic> debtData) async {
    // Initialize controllers with current debt data
    _descriptionController.text = debtData['description'] ?? '';
    _personController.text = debtData['person'] ?? '';
    _amountController.text = (debtData['amount'] ?? 0.0).toString();
    _selectedType = debtData['type'] ?? 'owed';
    _selectedDueDate =
        debtData['due_date'] != null
            ? (debtData['due_date'] as Timestamp).toDate()
            : null;
    _notesController.text = debtData['notes'] ?? '';

    if (mounted) {
      await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Edit Debt', style: FinanceTheme.headingSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Debt Type
                    Text('Debt Type', style: FinanceTheme.bodyMedium),
                    SizedBox(height: FinanceTheme.spacingS),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'I Owe',
                              style: FinanceTheme.bodyMedium,
                            ),
                            value: 'owed',
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                            activeColor: FinanceTheme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Owed to Me',
                              style: FinanceTheme.bodyMedium,
                            ),
                            value: 'owed_to_you',
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                            activeColor: FinanceTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Description',
                        hintText: 'e.g., Car loan, Business debt',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Person/Entity
                    TextField(
                      controller: _personController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Person/Entity',
                        hintText: 'e.g., Bank of America, John Smith',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Amount
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Amount (₪)',
                        hintText: '1000.00',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Due Date
                    InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 10),
                          ),
                        );
                        if (pickedDate != null && mounted) {
                          setState(() {
                            _selectedDueDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: FinanceTheme.borderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: FinanceTheme.backgroundColor,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: FinanceTheme.textSecondary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _selectedDueDate != null
                                  ? '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}'
                                  : 'Select Due Date (Optional)',
                              style: FinanceTheme.bodyMedium.copyWith(
                                color:
                                    _selectedDueDate != null
                                        ? FinanceTheme.textPrimary
                                        : FinanceTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Notes
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Notes (Optional)',
                        hintText: 'Additional details...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: FinanceTheme.textButtonStyle,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate form
                    if (_descriptionController.text.trim().isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a description')),
                        );
                      }
                      return;
                    }
                    if (_personController.text.trim().isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a person/entity'),
                          ),
                        );
                      }
                      return;
                    }
                    double? amount = double.tryParse(_amountController.text);
                    if (amount == null || amount <= 0) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
                        );
                      }
                      return;
                    }

                    // Show verification dialog
                    bool? confirm;
                    final currentContext = context;
                    if (mounted) {
                      confirm = await showDialog<bool>(
                        context: currentContext,
                        builder:
                            (context) => AlertDialog(
                              title: Text(
                                'Confirm Debt Update',
                                style: FinanceTheme.headingSmall,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Please verify the debt details:',
                                    style: FinanceTheme.bodyMedium,
                                  ),
                                  SizedBox(height: FinanceTheme.spacingM),
                                  _buildVerificationRow(
                                    'Type',
                                    _selectedType == 'owed'
                                        ? 'I Owe'
                                        : 'Owed to Me',
                                  ),
                                  _buildVerificationRow(
                                    'Description',
                                    _descriptionController.text,
                                  ),
                                  _buildVerificationRow(
                                    'Person/Entity',
                                    _personController.text,
                                  ),
                                  _buildVerificationRow(
                                    'Amount',
                                    FinanceTheme.formatCurrency(amount),
                                  ),
                                  if (_selectedDueDate != null)
                                    _buildVerificationRow(
                                      'Due Date',
                                      '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}',
                                    ),
                                  if (_notesController.text.isNotEmpty)
                                    _buildVerificationRow(
                                      'Notes',
                                      _notesController.text,
                                    ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  style: FinanceTheme.textButtonStyle,
                                  child: const Text('Edit'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FinanceTheme.primaryButtonStyle,
                                  child: const Text('Confirm & Update'),
                                ),
                              ],
                            ),
                      );
                    }

                    if (confirm == true) {
                      // Update debt
                      Map<String, dynamic> debtData = {
                        'type': _selectedType,
                        'description': _descriptionController.text.trim(),
                        'person': _personController.text.trim(),
                        'amount': amount,
                        'due_date':
                            _selectedDueDate != null
                                ? Timestamp.fromDate(_selectedDueDate!)
                                : null,
                        'notes': _notesController.text.trim(),
                        'updated_at': FieldValue.serverTimestamp(),
                      };

                      await DebtService.updateDebt(debtId, debtData);

                      // Clear form
                      _descriptionController.clear();
                      _personController.clear();
                      _amountController.clear();
                      _selectedType = 'owed';
                      _selectedDueDate = null;
                      _notesController.clear();

                      // Close dialog and show success message
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Debt updated successfully!')),
                        );
                      }
                    }
                  },
                  style: FinanceTheme.primaryButtonStyle,
                  child: const Text('Update'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _deleteDebt(String debtId, String description) async {
    bool? confirm;
    final currentContext = context;
    if (mounted) {
      confirm = await showDialog<bool>(
        context: currentContext,
        builder:
            (context) => AlertDialog(
              title: Text('Delete Debt', style: FinanceTheme.headingSmall),
              content: Text(
                'Are you sure you want to delete "$description"?\n\nThis action cannot be undone.',
                style: FinanceTheme.bodyMedium,
              ),
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
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );
    }

    if (confirm == true) {
      try {
        bool success = await DebtService.deleteDebtWithConfirmation(debtId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debt deleted successfully!')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete debt. Please try again.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting debt: $e')));
        }
      }
    }
  }

  void _showAddDebtDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Add Debt', style: FinanceTheme.headingSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'I Owe',
                              style: FinanceTheme.bodyMedium,
                            ),
                            value: 'owed',
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value ?? 'owed';
                              });
                            },
                            activeColor: FinanceTheme.dangerColor,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Owed to Me',
                              style: FinanceTheme.bodyMedium,
                            ),
                            value: 'owed_to_you',
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value ?? 'owed_to_you';
                              });
                            },
                            activeColor: FinanceTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FinanceTheme.spacingM),
                    TextField(
                      controller: _descriptionController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Description',
                        hintText: 'e.g., Car loan, Dinner bill',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),
                    TextField(
                      controller: _personController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Person/Entity',
                        hintText: 'e.g., John, Bank of America',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Amount (₪)',
                        hintText: '1000.00',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasAutomaticPayment,
                          onChanged: (value) {
                            setState(() {
                              _hasAutomaticPayment = value ?? false;
                              if (!_hasAutomaticPayment) {
                                _monthlyPaymentController.clear();
                              }
                            });
                          },
                          activeColor: FinanceTheme.primaryColor,
                        ),
                        Text(
                          'Set automatic monthly payment',
                          style: FinanceTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (_hasAutomaticPayment) ...[
                      SizedBox(height: FinanceTheme.spacingM),
                      TextField(
                        controller: _monthlyPaymentController,
                        keyboardType: TextInputType.number,
                        decoration: FinanceTheme.inputDecoration.copyWith(
                          labelText: 'Monthly Payment Amount (₪)',
                          hintText: '100.00',
                        ),
                      ),
                    ],
                    SizedBox(height: FinanceTheme.spacingM),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasDueDate,
                          onChanged: (value) {
                            setState(() {
                              _hasDueDate = value ?? false;
                              if (!_hasDueDate) _selectedDueDate = null;
                            });
                          },
                          activeColor: FinanceTheme.primaryColor,
                        ),
                        Text('Set due date', style: FinanceTheme.bodyMedium),
                      ],
                    ),
                    if (_hasDueDate) ...[
                      SizedBox(height: FinanceTheme.spacingM),
                      ListTile(
                        title: Text(
                          _selectedDueDate != null
                              ? 'Due Date: ${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}'
                              : 'Select Due Date',
                          style: FinanceTheme.bodyMedium,
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (date != null && mounted) {
                            setState(() {
                              _selectedDueDate = date;
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
                        hintText: 'Add any additional notes',
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
                  onPressed: _addDebt,
                  style: FinanceTheme.primaryButtonStyle,
                  child: const Text('Add Debt'),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildDebtSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DebtService.getDebtSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalOwed = data['total_owed'] ?? 0.0;
          double totalOwedToYou = data['total_owed_to_you'] ?? 0.0;
          double netDebt = data['net_debt'] ?? 0.0;
          int activeDebtsOwed = data['active_debts_owed'] ?? 0;
          int activeDebtsOwedToYou = data['active_debts_owed_to_you'] ?? 0;

          // Get total monthly payments
          return FutureBuilder<double>(
            future: DebtService.getTotalMonthlyPayments(userId),
            builder: (context, monthlySnapshot) {
              double totalMonthlyPayments = monthlySnapshot.data ?? 0.0;

              return Container(
                decoration: FinanceTheme.cardDecorationElevated,
                child: Padding(
                  padding: FinanceTheme.cardPadding,
                  child: Column(
                    children: [
                      Text('Debt Summary', style: FinanceTheme.headingSmall),
                      SizedBox(height: FinanceTheme.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You Owe', style: FinanceTheme.bodyMedium),
                              Text(
                                FinanceTheme.formatCurrency(totalOwed),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: FinanceTheme.dangerColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Owed to You',
                                style: FinanceTheme.bodyMedium,
                              ),
                              Text(
                                FinanceTheme.formatCurrency(totalOwedToYou),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: FinanceTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: FinanceTheme.spacingM),
                      Divider(color: FinanceTheme.borderColor),
                      SizedBox(height: FinanceTheme.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Net Debt', style: FinanceTheme.bodyMedium),
                              Text(
                                FinanceTheme.formatCurrency(netDebt),
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      netDebt >= 0
                                          ? FinanceTheme.dangerColor
                                          : FinanceTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Active Debts',
                                style: FinanceTheme.bodyMedium,
                              ),
                              Text(
                                '${activeDebtsOwed + activeDebtsOwedToYou}',
                                style: FinanceTheme.valueMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (totalMonthlyPayments > 0) ...[
                        SizedBox(height: FinanceTheme.spacingM),
                        Divider(color: FinanceTheme.borderColor),
                        SizedBox(height: FinanceTheme.spacingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Payments',
                                  style: FinanceTheme.bodyMedium,
                                ),
                                Text(
                                  FinanceTheme.formatCurrency(
                                    totalMonthlyPayments,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: FinanceTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.payment,
                              color: FinanceTheme.primaryColor,
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
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

  Widget _buildDebtList(String userId, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: DebtService.getUserDebts(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Filter debts by type
          var filteredDocs =
              snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>?;
                return data != null &&
                    data['type'] == type &&
                    data['is_active'] == true;
              }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'owed'
                        ? Icons.credit_card
                        : Icons.account_balance_wallet,
                    size: 80,
                    color: FinanceTheme.textTertiary,
                  ),
                  SizedBox(height: FinanceTheme.spacingL),
                  Text(
                    type == 'owed'
                        ? 'No debts you owe'
                        : 'No debts owed to you',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    type == 'owed'
                        ? 'You\'re all caught up!'
                        : 'No one owes you money',
                    style: FinanceTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var doc = filteredDocs[index];
              var data = doc.data() as Map<String, dynamic>;

              double amount = data['amount'] ?? 0.0;
              double monthlyPayment = data['monthly_payment'] ?? 0.0;
              String person = data['person'] ?? '';
              String description = data['description'] ?? '';
              DateTime? dueDate = data['due_date']?.toDate();
              DateTime? lastPaymentDate = data['last_payment_date']?.toDate();
              DebtService.getDebtStatus(amount, dueDate);
              bool isOverdue = DebtService.isDebtOverdue(dueDate);

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
                                  description,
                                  style: FinanceTheme.valueSmall,
                                ),
                                Text(person, style: FinanceTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    FinanceTheme.formatCurrency(amount),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          type == 'owed'
                                              ? FinanceTheme.dangerColor
                                              : FinanceTheme.successColor,
                                    ),
                                  ),
                                  if (isOverdue)
                                    Text(
                                      'OVERDUE',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: FinanceTheme.dangerColor,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _editDebt(doc.id, data),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: FinanceTheme.primaryColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(width: 4),
                              IconButton(
                                onPressed:
                                    () => _deleteDebt(doc.id, description),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: FinanceTheme.dangerColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (monthlyPayment > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payment,
                                size: 16,
                                color: FinanceTheme.primaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Monthly: ${FinanceTheme.formatCurrency(monthlyPayment)}',
                                style: FinanceTheme.bodySmall.copyWith(
                                  color: FinanceTheme.primaryColor,
                                ),
                              ),
                              if (lastPaymentDate != null) ...[
                                SizedBox(width: 8),
                                Text(
                                  'Last: ${lastPaymentDate.year}-${lastPaymentDate.month.toString().padLeft(2, '0')}-${lastPaymentDate.day.toString().padLeft(2, '0')}',
                                  style: FinanceTheme.bodySmall.copyWith(
                                    color: FinanceTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Due: ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                            style: FinanceTheme.bodySmall.copyWith(
                              color:
                                  isOverdue
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view debts')),
      );
    }
    String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Debt', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: FinanceTheme.textPrimary,
          unselectedLabelColor: FinanceTheme.textSecondary,
          indicatorColor: FinanceTheme.primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 16),
                  SizedBox(width: 8),
                  Text('I Owe'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 16),
                  SizedBox(width: 8),
                  Text('Owed to Me'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: FinanceTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebtSummary(userId),
              SizedBox(height: FinanceTheme.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please sign in to process payments',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      String userId = user.uid;
                      await DebtService.processAutomaticMonthlyPayments(userId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Automatic payments processed successfully!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.payment, size: 16),
                    label: Text('Process Monthly Payments'),
                    style: FinanceTheme.primaryButtonStyle,
                  ),
                  IconButton(
                    onPressed: _showAddDebtDialog,
                    icon: Icon(
                      Icons.add_circle,
                      color: FinanceTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
              SizedBox(height: FinanceTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Debts', style: FinanceTheme.headingMedium),
                  SizedBox(width: 40), // Spacer to balance the layout
                ],
              ),
              SizedBox(height: FinanceTheme.spacingM),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDebtList(userId, 'owed'),
                    _buildDebtList(userId, 'owed_to_you'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDebtDialog,
        backgroundColor: FinanceTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
