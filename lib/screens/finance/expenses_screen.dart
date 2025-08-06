import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../config/finance_theme.dart';
import '../../services/expenses_service.dart';
import '../../services/automatic_expenses_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'other';
  DateTime _selectedDate = DateTime.now();
  List<File> _selectedFiles = [];
  bool _isUploading = false;

  // Automatic expenses controllers
  final TextEditingController _autoDescriptionController =
      TextEditingController();
  final TextEditingController _autoAmountController = TextEditingController();
  final TextEditingController _autoNotesController = TextEditingController();
  String _selectedAutoCategory = 'other';
  String _selectedFrequency = 'monthly';
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedEndDate;
  bool _isAutoActive = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
        });
      }
    } catch (e) {
      // Fallback if file picker is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File picker not available. You can still add expenses without attachments.',
          ),
        ),
      );
    }
  }

  Future<void> _addExpense() async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String userId = 'user123'; // Replace with actual user ID

      Map<String, dynamic> expenseData = {
        'user_id': userId,
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'merchant': _merchantController.text,
        'category': _selectedCategory,
        'date': _selectedDate,
        'notes': _notesController.text,
        'has_attachments': _selectedFiles.isNotEmpty,
        'created_at': DateTime.now(),
      };

      String expenseId;
      if (_selectedFiles.isNotEmpty) {
        expenseId = await ExpensesService.addExpenseWithFile(
          expenseData,
          _selectedFiles,
        );
      } else {
        expenseId = await ExpensesService.addExpense(expenseData);
      }

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      _merchantController.clear();
      _notesController.clear();
      _selectedCategory = 'other';
      _selectedDate = DateTime.now();
      _selectedFiles.clear();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Expense', style: FinanceTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Description',
                      hintText: 'e.g., Grocery shopping, Gas',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _merchantController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Merchant/Store',
                      hintText: 'e.g., Walmart, Shell',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Amount (₪)',
                      hintText: '25.50',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Category',
                    ),
                    items:
                        ExpensesService.getExpenseCategories().map((category) {
                          String icon =
                              ExpensesService.getCategoryIcons()[category] ??
                              '📄';
                          String name =
                              ExpensesService.getCategoryNames()[category] ??
                              category;
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Text(icon),
                                const SizedBox(width: 8),
                                Text(name),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'other';
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  ListTile(
                    title: Text(
                      'Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: FinanceTheme.bodyMedium,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Add Receipt/Invoice'),
                          style: FinanceTheme.secondaryButtonStyle,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedFiles.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FinanceTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Files (${_selectedFiles.length}):',
                            style: FinanceTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          ...(_selectedFiles.map(
                            (file) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.file_present,
                                    size: 16,
                                    color: FinanceTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.path.split('/').last,
                                      style: FinanceTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFiles.remove(file);
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
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
                onPressed: _isUploading ? null : _addExpense,
                style: FinanceTheme.primaryButtonStyle,
                child:
                    _isUploading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Add Expense'),
              ),
            ],
          ),
    );
  }

  Widget _buildExpensesSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ExpensesService.getExpensesSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalExpenses = data['total_expenses'] ?? 0.0;
          int totalCount = data['total_count'] ?? 0;
          Map<String, double> categoryTotals = Map<String, double>.from(
            data['category_totals'] ?? {},
          );

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                children: [
                  Text('Expenses Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Expenses',
                            style: FinanceTheme.bodyMedium,
                          ),
                          Text(
                            FinanceTheme.formatCurrency(totalExpenses),
                            style: FinanceTheme.valueLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Transactions',
                            style: FinanceTheme.bodyMedium,
                          ),
                          Text('$totalCount', style: FinanceTheme.valueMedium),
                        ],
                      ),
                    ],
                  ),
                  if (categoryTotals.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Divider(color: FinanceTheme.borderColor),
                    SizedBox(height: FinanceTheme.spacingM),
                    Column(
                      children:
                          categoryTotals.entries.take(3).map((entry) {
                            String category = entry.key;
                            double amount = entry.value;
                            String icon =
                                ExpensesService.getCategoryIcons()[category] ??
                                '📄';
                            String name =
                                ExpensesService.getCategoryNames()[category] ??
                                category;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(icon),
                                      const SizedBox(width: 8),
                                      Text(
                                        name,
                                        style: FinanceTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    FinanceTheme.formatCurrency(amount),
                                    style: FinanceTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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

  Widget _buildExpensesList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: ExpensesService.getUserExpenses(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: FinanceTheme.textTertiary,
                  ),
                  SizedBox(height: FinanceTheme.spacingL),
                  Text('No expenses yet', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    'Add your first expense to get started',
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

              double amount = data['amount'] ?? 0.0;
              String description = data['description'] ?? '';
              String merchant = data['merchant'] ?? '';
              String category = data['category'] ?? 'other';
              DateTime date = (data['date'] as Timestamp).toDate();
              bool hasAttachments = data['has_attachments'] ?? false;

              String icon =
                  ExpensesService.getCategoryIcons()[category] ?? '📄';
              String categoryName =
                  ExpensesService.getCategoryNames()[category] ?? category;

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
                                if (merchant.isNotEmpty)
                                  Text(
                                    merchant,
                                    style: FinanceTheme.bodyMedium,
                                  ),
                                Row(
                                  children: [
                                    Text(icon),
                                    const SizedBox(width: 4),
                                    Text(
                                      categoryName,
                                      style: FinanceTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FinanceTheme.formatCurrency(amount),
                                style: FinanceTheme.valueSmall,
                              ),
                              Text(
                                '${date.month}/${date.day}/${date.year}',
                                style: FinanceTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (hasAttachments)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 16,
                                color: FinanceTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Has receipt/invoice',
                                style: FinanceTheme.bodySmall.copyWith(
                                  color: FinanceTheme.primaryColor,
                                ),
                              ),
                            ],
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Expenses', style: FinanceTheme.headingSmall),
          backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Regular Expenses'),
              Tab(text: 'Automatic Expenses'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildRegularExpensesTab(userId),
              _buildAutomaticExpensesTab(userId),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOptionsDialog(context),
          backgroundColor: FinanceTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRegularExpensesTab(String userId) {
    return Padding(
      padding: FinanceTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpensesSummary(userId),
          SizedBox(height: FinanceTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Expenses', style: FinanceTheme.headingMedium),
              IconButton(
                onPressed: _showAddExpenseDialog,
                icon: Icon(
                  Icons.add_circle,
                  color: FinanceTheme.primaryColor,
                  size: 28,
                ),
              ),
            ],
          ),
          SizedBox(height: FinanceTheme.spacingM),
          Expanded(child: _buildExpensesList(userId)),
        ],
      ),
    );
  }

  Widget _buildAutomaticExpensesTab(String userId) {
    return Padding(
      padding: FinanceTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAutomaticExpensesSummary(userId),
          SizedBox(height: FinanceTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Automatic Expenses', style: FinanceTheme.headingMedium),
              IconButton(
                onPressed: () => _showAddAutomaticExpenseDialog(context),
                icon: Icon(
                  Icons.add_circle,
                  color: FinanceTheme.primaryColor,
                  size: 28,
                ),
              ),
            ],
          ),
          SizedBox(height: FinanceTheme.spacingM),
          Expanded(child: _buildAutomaticExpensesList(userId)),
        ],
      ),
    );
  }

  void _showAddOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Expense', style: FinanceTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Regular Expense'),
                  subtitle: const Text('One-time expense'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddExpenseDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: const Text('Automatic Expense'),
                  subtitle: const Text('Recurring expense'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddAutomaticExpenseDialog(context);
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

  Widget _buildAutomaticExpensesSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AutomaticExpensesService.getAutomaticExpensesSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double monthlyEquivalent = data['monthly_equivalent'] ?? 0.0;
          int totalCount = data['total_count'] ?? 0;
          Map<String, double> categoryTotals = Map<String, double>.from(
            data['category_totals'] ?? {},
          );

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                children: [
                  Text(
                    'Automatic Expenses Summary',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Equivalent',
                            style: FinanceTheme.bodyMedium,
                          ),
                          Text(
                            FinanceTheme.formatCurrency(monthlyEquivalent),
                            style: FinanceTheme.valueLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Recurring',
                            style: FinanceTheme.bodyMedium,
                          ),
                          Text('$totalCount', style: FinanceTheme.valueMedium),
                        ],
                      ),
                    ],
                  ),
                  if (categoryTotals.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Divider(color: FinanceTheme.borderColor),
                    SizedBox(height: FinanceTheme.spacingM),
                    Column(
                      children:
                          categoryTotals.entries.take(3).map((entry) {
                            String category = entry.key;
                            double amount = entry.value;
                            String icon =
                                ExpensesService.getCategoryIcons()[category] ??
                                '📄';
                            String name =
                                ExpensesService.getCategoryNames()[category] ??
                                category;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(icon),
                                      const SizedBox(width: 8),
                                      Text(
                                        name,
                                        style: FinanceTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    FinanceTheme.formatCurrency(amount),
                                    style: FinanceTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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

  void _showAddAutomaticExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Add Automatic Expense',
              style: FinanceTheme.headingSmall,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _autoDescriptionController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Description',
                      hintText: 'e.g., Netflix subscription, Rent',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _autoAmountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Amount (₪)',
                      hintText: '25.50',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _selectedAutoCategory,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Category',
                    ),
                    items:
                        ExpensesService.getExpenseCategories().map((category) {
                          String icon =
                              ExpensesService.getCategoryIcons()[category] ??
                              '📄';
                          String name =
                              ExpensesService.getCategoryNames()[category] ??
                              category;
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Text(icon),
                                const SizedBox(width: 8),
                                Text(name),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAutoCategory = value ?? 'other';
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Frequency',
                    ),
                    items:
                        AutomaticExpensesService.getFrequencyOptions().map((
                          option,
                        ) {
                          return DropdownMenuItem<String>(
                            value: option['key'] as String,
                            child: Text(option['name'] as String),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value ?? 'monthly';
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  ListTile(
                    title: Text(
                      'Start Date: ${_selectedStartDate.year}-${_selectedStartDate.month.toString().padLeft(2, '0')}-${_selectedStartDate.day.toString().padLeft(2, '0')}',
                      style: FinanceTheme.bodyMedium,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedStartDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedStartDate = date;
                        });
                      }
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isAutoActive,
                    onChanged: (value) {
                      setState(() {
                        _isAutoActive = value;
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _autoNotesController,
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
                onPressed: _addAutomaticExpense,
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _addAutomaticExpense() async {
    if (_autoDescriptionController.text.isEmpty ||
        _autoAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      String userId = 'user123'; // Replace with actual user ID

      AutomaticExpense expense = AutomaticExpense(
        id: '',
        userId: userId,
        description: _autoDescriptionController.text,
        amount: double.parse(_autoAmountController.text),
        category: _selectedAutoCategory,
        frequency: _selectedFrequency,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        isActive: _isAutoActive,
        notes: _autoNotesController.text,
      );

      await AutomaticExpensesService.addAutomaticExpense(expense);

      // Clear form
      _autoDescriptionController.clear();
      _autoAmountController.clear();
      _autoNotesController.clear();
      _selectedAutoCategory = 'other';
      _selectedFrequency = 'monthly';
      _selectedStartDate = DateTime.now();
      _selectedEndDate = null;
      _isAutoActive = true;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Automatic expense added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildAutomaticExpensesList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: AutomaticExpensesService.getUserAutomaticExpenses(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 80,
                    color: FinanceTheme.textTertiary,
                  ),
                  SizedBox(height: FinanceTheme.spacingL),
                  Text(
                    'No automatic expenses yet',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    'Add your first automatic expense to get started',
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

              double amount = data['amount'] ?? 0.0;
              String description = data['description'] ?? '';
              String category = data['category'] ?? 'other';
              String frequency = data['frequency'] ?? 'monthly';
              DateTime startDate = (data['start_date'] as Timestamp).toDate();
              bool isActive = data['is_active'] ?? true;
              String? notes = data['notes'];

              String icon =
                  ExpensesService.getCategoryIcons()[category] ?? '📄';
              String categoryName =
                  ExpensesService.getCategoryNames()[category] ?? category;
              String frequencyName =
                  AutomaticExpensesService.getFrequencyDisplayNames()[frequency] ??
                  frequency;

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
                                Row(
                                  children: [
                                    Text(icon),
                                    const SizedBox(width: 4),
                                    Text(
                                      categoryName,
                                      style: FinanceTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.repeat,
                                      size: 16,
                                      color: FinanceTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      frequencyName,
                                      style: FinanceTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (notes?.isNotEmpty == true)
                                  Text(
                                    notes!,
                                    style: FinanceTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FinanceTheme.formatCurrency(amount),
                                style: FinanceTheme.valueSmall,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: FinanceTheme.bodySmall.copyWith(
                                      color:
                                          isActive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
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
}
