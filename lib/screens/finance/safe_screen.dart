import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/finance_theme.dart';
import '../../services/safe_service.dart';
import '../../services/currency_service.dart';
import '../../services/preferences_service.dart';
import '../../widgets/currency_converter.dart';

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
  String _selectedCurrency = 'ILS';
  String _mainCurrency = 'ILS';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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

  Future<void> _addSafeItem() async {
    if (_descriptionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a description')),
        );
      }
      return;
    }
    if (_valueController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a value')));
      }
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a location')),
        );
      }
      return;
    }

    double? value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid value')),
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
            const SnackBar(content: Text('Please sign in to add safe items')),
          );
        }
        return;
      }

      Map<String, dynamic> safeItemData = {
        'user_id': user.uid,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'value': value,
        'currency': _selectedCurrency,
        'date_added': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await SafeService.addSafeItem(safeItemData);

      // Clear form
      _descriptionController.clear();
      _valueController.clear();
      _locationController.clear();
      _selectedCategory = 'jewelry';
      _selectedDate = null;
      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safe item added successfully!')),
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

                  // Value
                  TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Value',
                      hintText: '5000.00',
                      suffixText:
                          CurrencyService.getCurrencySymbols()[_selectedCurrency] ??
                          _selectedCurrency,
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
              String currency = data['currency'] ?? 'ILS';
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
                                        CurrencyService.formatCurrency(
                                          amount,
                                          currency,
                                        )
                                    : CurrencyService.formatCurrency(
                                      value,
                                      currency,
                                    ),
                                style: FinanceTheme.valueSmall.copyWith(
                                  color:
                                      isTransaction
                                          ? (isPositive
                                              ? FinanceTheme.successColor
                                              : FinanceTheme.dangerColor)
                                          : null,
                                ),
                              ),
                              if (currency != _mainCurrency)
                                FutureBuilder<double>(
                                  future: CurrencyService.convertCurrency(
                                    isTransaction ? amount : value,
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
                      SizedBox(height: FinanceTheme.spacingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _showEditSafeItemDialog(doc.id, data),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: FinanceTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteSafeItem(doc.id),
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

            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to transfer funds'),
                  ),
                );
              }
              return;
            }
            String userId = user.uid;
            await SafeService.transferFromSafeToBank(
              userId,
              amount,
              descriptionController.text.trim(),
              notesController.text.trim(),
            );

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transfer to bank completed successfully!'),
                ),
              );
            }
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

  void _showEditSafeItemDialog(String itemId, Map<String, dynamic> data) {
    // Pre-fill the form with existing data
    _descriptionController.text = data['description'] ?? '';
    _valueController.text = (data['value'] ?? 0.0).toString();
    _locationController.text = data['location'] ?? '';
    _selectedCategory = data['category'] ?? 'jewelry';
    _selectedCurrency = data['currency'] ?? 'ILS';
    _selectedDate = data['date_added']?.toDate();
    _notesController.text = data['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Safe Item', style: FinanceTheme.headingSmall),
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
                  DropdownMenuItem(value: 'jewelry', child: Text('Jewelry')),
                  DropdownMenuItem(value: 'documents', child: Text('Documents')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                  DropdownMenuItem(value: 'collectibles', child: Text('Collectibles')),
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

              // Value
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: FinanceTheme.inputDecoration.copyWith(
                  labelText: 'Value',
                  hintText: '5000.00',
                  suffixText: CurrencyService.getCurrencySymbols()[_selectedCurrency] ?? _selectedCurrency,
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
                            : 'Select Date Added (Optional)',
                        style: FinanceTheme.bodyMedium.copyWith(
                          color: _selectedDate != null
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
            onPressed: () => _updateSafeItem(itemId),
            style: FinanceTheme.primaryButtonStyle,
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSafeItem(String itemId) async {
    if (_descriptionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a description')),
        );
      }
      return;
    }
    if (_valueController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a value')),
        );
      }
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a location')),
        );
      }
      return;
    }

    double? value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid value')),
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
            const SnackBar(content: Text('Please sign in to update safe items')),
          );
        }
        return;
      }

      Map<String, dynamic> safeItemData = {
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'value': value,
        'currency': _selectedCurrency,
        'date_added': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
      };

      await SafeService.updateSafeItem(itemId, safeItemData);

      // Clear form
      _descriptionController.clear();
      _valueController.clear();
      _locationController.clear();
      _selectedCategory = 'jewelry';
      _selectedDate = null;
      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safe item updated successfully!')),
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

  Future<void> _deleteSafeItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Safe Item', style: FinanceTheme.headingSmall),
        content: const Text('Are you sure you want to delete this safe item?'),
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
        await SafeService.deleteSafeItem(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Safe item deleted successfully!')),
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
        body: Center(child: Text('Please sign in to view safe')),
      );
    }
    String userId = user.uid;

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
