import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/finance_theme.dart';
import '../../services/safe_service.dart';

class SafeScreen extends StatefulWidget {
  const SafeScreen({super.key});

  @override
  State<SafeScreen> createState() => _SafeScreenState();
}

class _SafeScreenState extends State<SafeScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'jewelry';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addSafeItem() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a description')));
      return;
    }
    if (_valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a value')));
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a location')));
      return;
    }

    double? value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid value')));
      return;
    }

    // Show verification dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Safe Item', style: FinanceTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please verify the item details:',
                  style: FinanceTheme.bodyMedium,
                ),
                SizedBox(height: FinanceTheme.spacingM),
                _buildVerificationRow(
                  'Category',
                  _getCategoryName(_selectedCategory),
                ),
                _buildVerificationRow(
                  'Description',
                  _descriptionController.text,
                ),
                _buildVerificationRow('Location', _locationController.text),
                _buildVerificationRow(
                  'Value',
                  FinanceTheme.formatCurrency(value),
                ),
                if (_selectedDate != null)
                  _buildVerificationRow(
                    'Date Added',
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
      Map<String, dynamic> safeData = {
        'user_id': 'user123', // Replace with actual user ID
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'value': value,
        'date_added': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await SafeService.addSafeItem(safeData);

      // Clear form
      _descriptionController.clear();
      _valueController.clear();
      _locationController.clear();
      _selectedCategory = 'jewelry';
      _selectedDate = null;
      _notesController.clear();

      // Close dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Safe item added successfully!')));
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'jewelry':
        return 'Jewelry';
      case 'documents':
        return 'Documents';
      case 'cash':
        return 'Cash';
      case 'electronics':
        return 'Electronics';
      case 'collectibles':
        return 'Collectibles';
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
            width: 80,
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

  void _showAddSafeItemDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Safe Item', style: FinanceTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Category',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'jewelry',
                        child: Text('Jewelry'),
                      ),
                      DropdownMenuItem(
                        value: 'documents',
                        child: Text('Documents'),
                      ),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                        value: 'electronics',
                        child: Text('Electronics'),
                      ),
                      DropdownMenuItem(
                        value: 'collectibles',
                        child: Text('Collectibles'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Description',
                      hintText: 'e.g., Diamond ring, Passport',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Location
                  TextField(
                    controller: _locationController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Location',
                      hintText: 'e.g., Home safe, Bank vault',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Value
                  TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Value (₪)',
                      hintText: '5000.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Date Added
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
                                : 'Select Date Added (Optional)',
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
                onPressed: _addSafeItem,
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Add Item'),
              ),
            ],
          ),
    );
  }

  Widget _buildSafeSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SafeService.getSafeSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalValue = data['total_value'] ?? 0.0;
          int totalItems = data['total_items'] ?? 0;
          Map<String, double> categoryBreakdown = Map<String, double>.from(
            data['category_breakdown'] ?? {},
          );

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safe Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Value', style: FinanceTheme.bodyMedium),
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
                            Text('Total Items', style: FinanceTheme.bodyMedium),
                            Text('$totalItems', style: FinanceTheme.valueLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (categoryBreakdown.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Text('By Category:', style: FinanceTheme.bodyMedium),
                    SizedBox(height: FinanceTheme.spacingS),
                    ...categoryBreakdown.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getCategoryName(entry.key),
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

  Widget _buildSafeItemsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: SafeService.getUserSafeItems(userId),
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
                        Icons.security,
                        size: 48,
                        color: FinanceTheme.textTertiary,
                      ),
                      SizedBox(height: FinanceTheme.spacingM),
                      Text('No safe items yet', style: FinanceTheme.bodyLarge),
                      SizedBox(height: FinanceTheme.spacingS),
                      Text(
                        'Add your first secure item',
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
              String location = data['location'] ?? '';
              double value = data['value'] ?? 0.0;
              double amount = data['amount'] ?? 0.0;
              String category = data['category'] ?? 'other';
              String type = data['type'] ?? '';
              DateTime? dateAdded = data['date_added']?.toDate();
              DateTime? date = data['date']?.toDate();
              String notes = data['notes'] ?? '';

              // Check if this is a transaction (has type) or an item (has category)
              bool isTransaction = type.isNotEmpty;
              bool isPositive = type == 'deposit';

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
                                if (isTransaction)
                                  Text(
                                    type == 'deposit'
                                        ? 'Deposit'
                                        : 'Withdrawal',
                                    style: FinanceTheme.bodySmall.copyWith(
                                      color:
                                          isPositive
                                              ? FinanceTheme.successColor
                                              : FinanceTheme.dangerColor,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    location,
                                    style: FinanceTheme.bodyMedium,
                                  ),
                                  Text(
                                    _getCategoryName(category),
                                    style: FinanceTheme.bodySmall.copyWith(
                                      color: FinanceTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isTransaction
                                    ? (isPositive ? '+' : '-') +
                                        FinanceTheme.formatCurrency(amount)
                                    : FinanceTheme.formatCurrency(value),
                                style: FinanceTheme.valueSmall.copyWith(
                                  color:
                                      isTransaction
                                          ? (isPositive
                                              ? FinanceTheme.successColor
                                              : FinanceTheme.dangerColor)
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isTransaction && date != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                            style: FinanceTheme.bodySmall.copyWith(
                              color: FinanceTheme.textSecondary,
                            ),
                          ),
                        ),
                      if (!isTransaction && dateAdded != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Added: ${dateAdded.year}-${dateAdded.month.toString().padLeft(2, '0')}-${dateAdded.day.toString().padLeft(2, '0')}',
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

  Widget _buildTransferToBankDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    return AlertDialog(
      title: Text('Transfer to Bank Account', style: FinanceTheme.headingSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: FinanceTheme.inputDecoration.copyWith(
                labelText: 'Description',
                hintText: 'e.g., Transfer to bank for bills',
              ),
            ),
            SizedBox(height: FinanceTheme.spacingM),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: FinanceTheme.inputDecoration.copyWith(
                labelText: 'Amount (₪)',
                hintText: '1000.00',
              ),
            ),
            SizedBox(height: FinanceTheme.spacingM),
            TextField(
              controller: notesController,
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
          onPressed: () async {
            if (descriptionController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter a description')),
              );
              return;
            }
            if (amountController.text.trim().isEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Please enter an amount')));
              return;
            }

            double? amount = double.tryParse(amountController.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }

            String userId = 'user123'; // Replace with actual user ID
            await SafeService.transferFromSafeToBank(
              userId,
              amount,
              descriptionController.text.trim(),
              notesController.text.trim(),
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transfer to bank completed successfully!'),
              ),
            );
          },
          style: FinanceTheme.primaryButtonStyle,
          child: const Text('Transfer'),
        ),
      ],
    );
  }

  void _showActionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Safe Actions', style: FinanceTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.add, color: FinanceTheme.primaryColor),
                  title: Text('Add Safe Item'),
                  subtitle: Text('Add a valuable item to your safe'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddSafeItemDialog();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.account_balance,
                    color: FinanceTheme.successColor,
                  ),
                  title: Text('Transfer to Bank'),
                  subtitle: Text('Move money from safe to bank account'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => _buildTransferToBankDialog(),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: FinanceTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = 'user123'; // Replace with actual user ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Safe', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafeSummary(userId),
            SizedBox(height: FinanceTheme.spacingM),
            Expanded(child: _buildSafeItemsList(userId)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionDialog,
        backgroundColor: FinanceTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
