import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/finance_theme.dart';
import '../../services/income_service.dart';
import '../../services/prediction_service.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedSource = 'salary';
  String _selectedCategory = 'regular';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _employerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addIncome() async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      String userId = 'user123'; // Replace with actual user ID

      Map<String, dynamic> incomeData = {
        'user_id': userId,
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'employer': _employerController.text,
        'source': _selectedSource,
        'category': _selectedCategory,
        'date': _selectedDate,
        'notes': _notesController.text,
        'created_at': DateTime.now(),
      };

      await IncomeService.addIncome(incomeData);

      // Clear form
      _descriptionController.clear();
      _amountController.clear();
      _employerController.clear();
      _notesController.clear();
      _selectedSource = 'salary';
      _selectedCategory = 'regular';
      _selectedDate = DateTime.now();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddIncomeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Income', style: FinanceTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Description',
                      hintText: 'e.g., Monthly salary, Project payment',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _employerController,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Employer/Client',
                      hintText: 'e.g., Tech Corp, John Doe',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Amount (₪)',
                      hintText: '5000.00',
                    ),
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _selectedSource,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Income Source',
                    ),
                    items:
                        IncomeService.getIncomeSources().map((source) {
                          String icon =
                              IncomeService.getSourceIcons()[source] ?? '📄';
                          String name =
                              IncomeService.getSourceNames()[source] ?? source;
                          return DropdownMenuItem(
                            value: source,
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
                        _selectedSource = value ?? 'salary';
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Category',
                    ),
                    items:
                        IncomeService.getIncomeCategories().map((category) {
                          String icon =
                              IncomeService.getCategoryIcons()[category] ??
                              '📄';
                          String name =
                              IncomeService.getCategoryNames()[category] ??
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
                        _selectedCategory = value ?? 'regular';
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
                onPressed: _addIncome,
                style: FinanceTheme.primaryButtonStyle,
                child: const Text('Add Income'),
              ),
            ],
          ),
    );
  }

  Widget _buildIncomeSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: IncomeService.getIncomeSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalIncome = data['total_income'] ?? 0.0;
          int totalCount = data['total_count'] ?? 0;
          Map<String, double> sourceTotals = Map<String, double>.from(
            data['source_totals'] ?? {},
          );

          return Container(
            decoration: FinanceTheme.cardDecorationElevated,
            child: Padding(
              padding: FinanceTheme.cardPadding,
              child: Column(
                children: [
                  Text('Income Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Income', style: FinanceTheme.bodyMedium),
                          Text(
                            FinanceTheme.formatCurrency(totalIncome),
                            style: FinanceTheme.valueLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Entries', style: FinanceTheme.bodyMedium),
                          Text('$totalCount', style: FinanceTheme.valueMedium),
                        ],
                      ),
                    ],
                  ),
                  if (sourceTotals.isNotEmpty) ...[
                    SizedBox(height: FinanceTheme.spacingM),
                    Divider(color: FinanceTheme.borderColor),
                    SizedBox(height: FinanceTheme.spacingM),
                    Column(
                      children:
                          sourceTotals.entries.take(3).map((entry) {
                            String source = entry.key;
                            double amount = entry.value;
                            String icon =
                                IncomeService.getSourceIcons()[source] ?? '📄';
                            String name =
                                IncomeService.getSourceNames()[source] ??
                                source;

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

  Widget _buildIncomeList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: IncomeService.getUserIncomes(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 80,
                    color: FinanceTheme.textTertiary,
                  ),
                  SizedBox(height: FinanceTheme.spacingL),
                  Text(
                    'No income entries yet',
                    style: FinanceTheme.headingSmall,
                  ),
                  SizedBox(height: FinanceTheme.spacingS),
                  Text(
                    'Add your first income entry to get started',
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
              String employer = data['employer'] ?? '';
              String source = data['source'] ?? 'other';
              DateTime date = (data['date'] as Timestamp).toDate();

              String icon = IncomeService.getSourceIcons()[source] ?? '📄';
              String sourceName =
                  IncomeService.getSourceNames()[source] ?? source;

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
                                if (employer.isNotEmpty)
                                  Text(
                                    employer,
                                    style: FinanceTheme.bodyMedium,
                                  ),
                                Row(
                                  children: [
                                    Text(icon),
                                    const SizedBox(width: 4),
                                    Text(
                                      sourceName,
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

  void _showSalaryRecommendations() {
    String selectedOccupation = 'software_engineer';
    String selectedExperience = 'mid';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    'Salary Recommendations',
                    style: FinanceTheme.headingSmall,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select your occupation:',
                          style: FinanceTheme.bodyMedium,
                        ),
                        SizedBox(height: FinanceTheme.spacingM),
                        DropdownButtonFormField<String>(
                          value: selectedOccupation,
                          decoration: FinanceTheme.inputDecoration.copyWith(
                            labelText: 'Occupation',
                          ),
                          items: [
                            for (String occupation
                                in PredictionService.getOccupationNames())
                              DropdownMenuItem<String>(
                                value: occupation,
                                child: Row(
                                  children: [
                                    Text(
                                      PredictionService.getMinimumIncomeByOccupation()[occupation]?['icon'] ??
                                          '💼',
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      PredictionService.getOccupationDisplayNames()[occupation] ??
                                          occupation,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedOccupation = value!;
                            });
                          },
                        ),
                        SizedBox(height: FinanceTheme.spacingM),
                        Text(
                          'Select experience level:',
                          style: FinanceTheme.bodyMedium,
                        ),
                        SizedBox(height: FinanceTheme.spacingM),
                        DropdownButtonFormField<String>(
                          value: selectedExperience,
                          decoration: FinanceTheme.inputDecoration.copyWith(
                            labelText: 'Experience Level',
                          ),
                          items: [
                            for (var level
                                in PredictionService.getExperienceLevels())
                              DropdownMenuItem<String>(
                                value: level['key'] as String,
                                child: Text(level['name'] as String),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedExperience = value!;
                            });
                          },
                        ),
                        SizedBox(height: FinanceTheme.spacingL),
                        Container(
                          padding: FinanceTheme.cardPadding,
                          decoration: FinanceTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Salary Recommendations',
                                style: FinanceTheme.headingSmall,
                              ),
                              SizedBox(height: FinanceTheme.spacingM),
                              _buildSalaryRange(
                                selectedOccupation,
                                selectedExperience,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: FinanceTheme.textButtonStyle,
                      child: const Text('Close'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildSalaryRange(String occupation, String experience) {
    var recommendations = PredictionService.getSalaryRecommendations(
      occupation,
    );
    if (recommendations == null) return const SizedBox.shrink();

    double minSalary = recommendations['min_salary'] ?? 0.0;
    double midSalary = recommendations['mid_salary'] ?? 0.0;
    double seniorSalary = recommendations['senior_salary'] ?? 0.0;
    String description = recommendations['description'] ?? '';

    double recommendedSalary = PredictionService.getRecommendedSalary(
      occupation,
      experience,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description, style: FinanceTheme.bodySmall),
        SizedBox(height: FinanceTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entry Level', style: FinanceTheme.bodySmall),
                  Text(
                    FinanceTheme.formatCurrency(minSalary),
                    style: FinanceTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mid Level', style: FinanceTheme.bodySmall),
                  Text(
                    FinanceTheme.formatCurrency(midSalary),
                    style: FinanceTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Senior Level', style: FinanceTheme.bodySmall),
                  Text(
                    FinanceTheme.formatCurrency(seniorSalary),
                    style: FinanceTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: FinanceTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FinanceTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FinanceTheme.successColor),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: FinanceTheme.successColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended for your level:',
                      style: FinanceTheme.bodySmall,
                    ),
                    Text(
                      FinanceTheme.formatCurrency(recommendedSalary),
                      style: FinanceTheme.bodyMedium.copyWith(
                        color: FinanceTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = 'user123'; // Replace with actual user ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Income', style: FinanceTheme.headingSmall),
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
              _buildIncomeSummary(userId),
              SizedBox(height: FinanceTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Income', style: FinanceTheme.headingMedium),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showSalaryRecommendations,
                        icon: Icon(
                          Icons.work,
                          color: FinanceTheme.successColor,
                          size: 24,
                        ),
                        tooltip: 'Salary Recommendations',
                      ),
                      IconButton(
                        onPressed: _showAddIncomeDialog,
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
              Expanded(child: _buildIncomeList(userId)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIncomeDialog,
        backgroundColor: FinanceTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
