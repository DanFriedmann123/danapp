import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/finance_theme.dart';
import '../../services/cash_service.dart';
import '../../services/currency_service.dart';
import '../../services/preferences_service.dart';
import '../../widgets/currency_converter.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'cash';
  String _selectedCurrency = 'ILS';
  String _mainCurrency = 'ILS';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadMainCurrency();
  }

  Future<void> _loadMainCurrency() async {
    final mainCurrency = await PreferencesService.getMainCurrency();
    setState(() {
      _mainCurrency = mainCurrency;
      _selectedCurrency = mainCurrency;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addCashEntry() async {
    if (_descriptionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a description')),
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
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Cash Entry', style: FinanceTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerificationRow('Type', _getTypeName(_selectedType)),
                _buildVerificationRow(
                  'Description',
                  _descriptionController.text.trim(),
                ),
                _buildVerificationRow(
                  'Location',
                  _locationController.text.trim(),
                ),
                _buildVerificationRow(
                  'Amount',
                  '\$${amount.toStringAsFixed(2)}',
                ),
                _buildVerificationRow(
                  'Date',
                  _selectedDate != null
                      ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                      : 'Today',
                ),
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

    if (confirm == true) {
      // Close the add dialog immediately
      Navigator.pop(context);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to add cash transactions'),
            ),
          );
        }
        return;
      }

      Map<String, dynamic> cashData = {
        'user_id': user.uid,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'amount': amount,
        'currency': _selectedCurrency,
        'date': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await CashService.addCashEntry(cashData);

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      _locationController.clear();
      _selectedType = 'cash';
      _selectedDate = null;
      _notesController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash entry added successfully!')),
        );
      }
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'foreign_currency':
        return 'Foreign Currency';
      case 'coins':
        return 'Coins';
      case 'gift_cards':
        return 'Gift Cards';
      case 'vouchers':
        return 'Vouchers';
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

  void _showAddCashEntryDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Add Cash Entry', style: FinanceTheme.headingSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Type',
                      ),
                      items: [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'foreign_currency',
                          child: Text('Foreign Currency'),
                        ),
                        DropdownMenuItem(value: 'coins', child: Text('Coins')),
                        DropdownMenuItem(
                          value: 'gift_cards',
                          child: Text('Gift Cards'),
                        ),
                        DropdownMenuItem(
                          value: 'vouchers',
                          child: Text('Vouchers'),
                        ),
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
                        hintText: 'e.g., Emergency cash, USD dollars',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Location',
                        hintText: 'e.g., Wallet, Home safe, Car',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Currency
                    CurrencySelector(
                      selectedCurrency: _selectedCurrency,
                      onCurrencyChanged: (currency) {
                        setState(() {
                          _selectedCurrency = currency;
                        });
                      },
                      label: 'Currency',
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Amount
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Amount',
                        hintText: '500.00',
                        suffixText:
                            CurrencyService.getCurrencySymbols()[_selectedCurrency] ??
                            _selectedCurrency,
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
                        if (pickedDate != null && mounted) {
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
                  onPressed: _addCashEntry,
                  style: FinanceTheme.primaryButtonStyle,
                  child: const Text('Add Entry'),
                ),
              ],
            ),
      );
    }
  }

  void _showEditCashEntryDialog(String entryId, Map<String, dynamic> data) {
    // Pre-fill the form with existing data
    _descriptionController.text = data['description'] ?? '';
    _amountController.text = (data['amount'] ?? 0.0).toString();
    _locationController.text = data['location'] ?? '';
    _selectedType = data['type'] ?? 'cash';
    _selectedCurrency = data['currency'] ?? 'ILS';
    _selectedDate = data['date']?.toDate();
    _notesController.text = data['notes'] ?? '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Cash Entry', style: FinanceTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Type',
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                        value: 'foreign_currency',
                        child: Text('Foreign Currency'),
                      ),
                      DropdownMenuItem(value: 'coins', child: Text('Coins')),
                      DropdownMenuItem(
                        value: 'gift_cards',
                        child: Text('Gift Cards'),
                      ),
                      DropdownMenuItem(
                        value: 'vouchers',
                        child: Text('Vouchers'),
                      ),
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
                      hintText: 'e.g., Emergency cash, USD dollars',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Location
                  TextField(
                    controller: _locationController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Location',
                      hintText: 'e.g., Wallet, Home safe, Car',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Currency
                  CurrencySelector(
                    selectedCurrency: _selectedCurrency,
                    onCurrencyChanged: (currency) {
                      setState(() {
                        _selectedCurrency = currency;
                      });
                    },
                    label: 'Currency',
                  ),
                  SizedBox(height: FinanceTheme.spacingM),

                  // Amount
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Amount',
                      hintText: '500.00',
                      suffixText:
                          CurrencyService.getCurrencySymbols()[_selectedCurrency] ??
                          _selectedCurrency,
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
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pickedDate != null && mounted) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: FinanceTheme.cardPadding,
                      decoration: FinanceTheme.cardDecoration.copyWith(
                        border: Border.all(color: FinanceTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                : 'Select Date',
                            style: FinanceTheme.bodyMedium,
                          ),
                          const Icon(Icons.calendar_today),
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
                onPressed: () => _updateCashEntry(entryId),
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _updateCashEntry(String entryId) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
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
            const SnackBar(
              content: Text('Please sign in to update cash transactions'),
            ),
          );
        }
        return;
      }

      Map<String, dynamic> cashData = {
        'user_id': user.uid,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'amount': amount,
        'currency': _selectedCurrency,
        'date': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
      };

      await CashService.updateCashEntry(entryId, cashData);

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      _locationController.clear();
      _selectedType = 'cash';
      _selectedDate = null;
      _notesController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash entry updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cash entry: $e')),
        );
      }
    }
  }

  void _deleteCashEntry(String entryId) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Cash Entry', style: FinanceTheme.headingSmall),
            content: const Text(
              'Are you sure you want to delete this cash entry?',
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
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await CashService.deleteCashEntry(entryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cash entry deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting cash entry: $e')),
          );
        }
      }
    }
  }

  Widget _buildCashSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: CashService.getCashSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalCash = data['total_cash'] ?? 0.0;
          int totalEntries = data['total_entries'] ?? 0;
          Map<String, double> typeBreakdown = Map<String, double>.from(
            data['type_breakdown'] ?? {},
          );
          Map<String, double> locationBreakdown = Map<String, double>.from(
            data['location_breakdown'] ?? {},
          );

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Cash', style: FinanceTheme.bodyMedium),
                            Text(
                              FinanceTheme.formatCurrency(totalCash),
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
                              'Total Entries',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              '$totalEntries',
                              style: FinanceTheme.valueLarge,
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
                  if (locationBreakdown.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Text('By Location:', style: FinanceTheme.bodyMedium),
                    SizedBox(height: FinanceTheme.spacingS),
                    ...locationBreakdown.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: FinanceTheme.bodySmall),
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

  Widget _buildCashEntriesList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: CashService.getUserCashEntries(userId),
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
                        Icons.money,
                        size: 48,
                        color: FinanceTheme.textTertiary,
                      ),
                      SizedBox(height: FinanceTheme.spacingM),
                      Text(
                        'No cash entries yet',
                        style: FinanceTheme.bodyLarge,
                      ),
                      SizedBox(height: FinanceTheme.spacingS),
                      Text(
                        'Add your first cash entry',
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
              double amount = data['amount'] ?? 0.0;
              String currency = data['currency'] ?? 'ILS';
              String type = data['type'] ?? 'cash';
              DateTime? date = data['date']?.toDate();
              String notes = data['notes'] ?? '';

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
                                Text(location, style: FinanceTheme.bodyMedium),
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
                                CurrencyService.formatCurrency(
                                  amount,
                                  currency,
                                ),
                                style: FinanceTheme.valueSmall,
                              ),
                              if (currency != _mainCurrency)
                                FutureBuilder<double>(
                                  future: CurrencyService.convertCurrency(
                                    amount,
                                    currency,
                                    _mainCurrency,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Text(
                                        '≈ ${CurrencyService.formatCurrency(snapshot.data!, _mainCurrency)}',
                                        style: FinanceTheme.bodySmall.copyWith(
                                          color: FinanceTheme.textSecondary,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
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
                            onPressed:
                                () => _showEditCashEntryDialog(doc.id, data),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: FinanceTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteCashEntry(doc.id),
                            icon: Icon(
                              Icons.delete_outline,
                              color: FinanceTheme.dangerColor,
                              size: 20,
                            ),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view cash')),
      );
    }
    String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cash', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCashSummary(userId),
            SizedBox(height: FinanceTheme.spacingM),
            Expanded(child: _buildCashEntriesList(userId)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCashEntryDialog,
        backgroundColor: FinanceTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
