import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/finance_theme.dart';
import '../../services/bank_account_service.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedType = 'deposit';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addBankTransaction() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a description')));
      return;
    }
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter an amount')));
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    // Show verification dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Bank Transaction',
              style: FinanceTheme.headingSmall,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please verify the transaction details:',
                  style: FinanceTheme.bodyMedium,
                ),
                SizedBox(height: FinanceTheme.spacingM),
                _buildVerificationRow('Type', _getTypeName(_selectedType)),
                _buildVerificationRow(
                  'Description',
                  _descriptionController.text,
                ),
                _buildVerificationRow(
                  'Amount',
                  FinanceTheme.formatCurrency(amount),
                ),
                if (_selectedDate != null)
                  _buildVerificationRow(
                    'Date',
                    '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                  ),
                if (_notesController.text.isNotEmpty)
                  _buildVerificationRow('Notes', _notesController.text),
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

    if (confirm == true) {
      Map<String, dynamic> transactionData = {
        'user_id': 'user123', // Replace with actual user ID
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'amount': amount,
        'date': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await BankAccountService.addBankTransaction(transactionData);

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      _selectedType = 'deposit';
      _selectedDate = null;
      _notesController.clear();

      // Close dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bank transaction added successfully!')),
      );
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'transfer_in':
        return 'Transfer In';
      case 'transfer_out':
        return 'Transfer Out';
      case 'fee':
        return 'Fee';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  Widget _buildVerificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: FinanceTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: FinanceTheme.bodyMedium)),
        ],
      ),
    );
  }

  void _showAddBankTransactionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Add Bank Transaction',
              style: FinanceTheme.headingSmall,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Transaction Type',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'deposit',
                        child: Text('Deposit'),
                      ),
                      DropdownMenuItem(
                        value: 'withdrawal',
                        child: Text('Withdrawal'),
                      ),
                      DropdownMenuItem(
                        value: 'transfer_in',
                        child: Text('Transfer In'),
                      ),
                      DropdownMenuItem(
                        value: 'transfer_out',
                        child: Text('Transfer Out'),
                      ),
                      DropdownMenuItem(value: 'fee', child: Text('Fee')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Description',
                      hintText: 'e.g., Salary deposit, ATM withdrawal',
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

                  // Date
                  InkWell(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365 * 10),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
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
                            _selectedDate != null
                                ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                : 'Select Date (Optional)',
                            style: FinanceTheme.bodyMedium.copyWith(
                              color:
                                  _selectedDate != null
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
                onPressed: () => Navigator.pop(context),
                style: FinanceTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addBankTransaction,
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Add Transaction'),
              ),
            ],
          ),
    );
  }

  Widget _buildBankSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: BankAccountService.getBankSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalBalance = data['total_balance'] ?? 0.0;
          double totalDeposits = data['total_deposits'] ?? 0.0;
          double totalWithdrawals = data['total_withdrawals'] ?? 0.0;
          int totalTransactions = data['total_transactions'] ?? 0;
          Map<String, double> typeBreakdown = Map<String, double>.from(
            data['type_breakdown'] ?? {},
          );

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Account Summary',
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
                              'Current Balance',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalBalance),
                              style: FinanceTheme.valueLarge.copyWith(
                                color:
                                    totalBalance >= 0
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
                              'Total Transactions',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              '$totalTransactions',
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
                            Text(
                              'Total Deposits',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalDeposits),
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
                              'Total Withdrawals',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalWithdrawals),
                              style: FinanceTheme.bodyMedium.copyWith(
                                color: FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (typeBreakdown.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Text('By Type:', style: FinanceTheme.bodyMedium),
                    SizedBox(height: FinanceTheme.spacingS),
                    ...typeBreakdown.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getTypeName(entry.key),
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(entry.value),
                              style: FinanceTheme.bodySmall,
                            ),
                          ],
                        ),
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

  Widget _buildBankTransactionsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: BankAccountService.getUserBankTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Container(
              decoration: FinanceTheme.cardDecorationElevated,
              child: Padding(
                padding: FinanceTheme.cardPadding,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 48,
                        color: FinanceTheme.textTertiary,
                      ),
                      SizedBox(height: FinanceTheme.spacingM),
                      Text(
                        'No bank transactions yet',
                        style: FinanceTheme.bodyLarge,
                      ),
                      SizedBox(height: FinanceTheme.spacingS),
                      Text(
                        'Add your first bank transaction',
                        style: FinanceTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox.shrink();

              String description = data['description'] ?? '';
              double amount = data['amount'] ?? 0.0;
              String type = data['type'] ?? 'other';
              DateTime? date = data['date']?.toDate();
              String notes = data['notes'] ?? '';

              bool isPositive = type == 'deposit' || type == 'transfer_in';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: FinanceTheme.cardDecoration,
                child: Padding(
                  padding: FinanceTheme.listItemPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  style: FinanceTheme.valueSmall,
                                ),
                                Text(
                                  _getTypeName(type),
                                  style: FinanceTheme.bodySmall.copyWith(
                                    color: FinanceTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                (isPositive ? '+' : '-') +
                                    FinanceTheme.formatCurrency(amount),
                                style: FinanceTheme.valueSmall.copyWith(
                                  color:
                                      isPositive
                                          ? FinanceTheme.successColor
                                          : FinanceTheme.dangerColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (date != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                            style: FinanceTheme.bodySmall.copyWith(
                              color: FinanceTheme.textSecondary,
                            ),
                          ),
                        ),
                      if (notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(notes, style: FinanceTheme.bodySmall),
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
        title: Text('Bank Account', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBankSummary(userId),
            SizedBox(height: FinanceTheme.spacingM),
            Expanded(child: _buildBankTransactionsList(userId)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBankTransactionDialog,
        backgroundColor: FinanceTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
