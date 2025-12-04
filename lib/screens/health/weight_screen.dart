import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/health_theme.dart';
import '../../services/weight_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _editWeightController = TextEditingController();
  final WeightService _weightService = WeightService();
  List<WeightEntry> _weightEntries = [];
  bool _isLoading = true;
  DateTime? _selectedEditDate;

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _editWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightEntries({bool showLoading = true}) async {
    print('DEBUG: _loadWeightEntries called, showLoading: $showLoading');
    if (showLoading) {
      print('DEBUG: Setting _isLoading = true');
      setState(() => _isLoading = true);
    }
    try {
      print('DEBUG: Fetching weight entries from service...');
      final entries = await _weightService.getWeightEntries();
      print('DEBUG: Received ${entries.length} entries from service');
      for (var entry in entries) {
        print('DEBUG: Entry - id: ${entry.id}, weight: ${entry.weight}, date: ${entry.date}');
      }
      print('DEBUG: Current _weightEntries length before setState: ${_weightEntries.length}');
      if (mounted) {
        setState(() {
          _weightEntries = entries;
          _isLoading = false;
          print('DEBUG: setState called, _weightEntries length: ${_weightEntries.length}');
        });
        print('DEBUG: After setState, _weightEntries length: ${_weightEntries.length}');
        // Force a rebuild by calling setState again with the same data
        // This ensures the UI updates even if Flutter thinks nothing changed
        Future.microtask(() {
          if (mounted) {
            setState(() {
              print('DEBUG: Force rebuild triggered');
            });
          }
        });
      }
    } catch (e) {
      print('DEBUG: Error loading weight entries: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading weight entries: $e')),
        );
      }
    }
  }

  Future<void> _addWeightEntry() async {
    print('DEBUG: _addWeightEntry called');
    final weightText = _weightController.text.trim();
    print('DEBUG: weightText: "$weightText"');
    if (weightText.isEmpty) {
      print('DEBUG: Weight text is empty, returning');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a weight')));
      }
      return;
    }

    final weight = double.tryParse(weightText);
    print('DEBUG: Parsed weight: $weight');
    if (weight == null || weight <= 0) {
      print('DEBUG: Invalid weight, returning');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight')),
        );
      }
      return;
    }

    // Add optimistically to UI immediately
    final now = DateTime.now();
    final newEntry = WeightEntry(
      id: 'temp_${now.millisecondsSinceEpoch}',
      weight: weight,
      date: now,
    );
    
    setState(() {
      _weightEntries.insert(0, newEntry); // Add at the beginning
      print('DEBUG: Added entry optimistically, _weightEntries.length: ${_weightEntries.length}');
    });
    
    _weightController.clear();
    
    // Save to Firestore in background
    try {
      print('DEBUG: Calling _weightService.addWeightEntry($weight)');
      await _weightService.addWeightEntry(weight);
      print('DEBUG: Weight entry added successfully to Firestore');
      
      // Reload from server to get the real ID and ensure consistency
      await _loadWeightEntries(showLoading: false);
      print('DEBUG: Reloaded from server, _weightEntries.length: ${_weightEntries.length}');
      
      if (mounted) {
        // Show details dialog
        _showWeightDetailsDialog(weight);
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _addWeightEntry: $e');
      print('DEBUG: Stack trace: $stackTrace');
      
      // Remove the optimistic entry on error
      setState(() {
        _weightEntries.removeWhere((e) => e.id == newEntry.id);
        print('DEBUG: Removed optimistic entry due to error');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding weight entry: $e')),
        );
      }
    }
  }

  void _showWeightDetailsDialog(double currentWeight) {
    // Calculate statistics
    final previousWeight = _weightEntries.length > 1 
        ? _weightEntries[1].weight 
        : null;
    final weightChange = previousWeight != null 
        ? currentWeight - previousWeight 
        : null;
    
    // Calculate average
    final totalWeight = _weightEntries.fold<double>(
      0.0, 
      (sum, entry) => sum + entry.weight,
    );
    final averageWeight = _weightEntries.isNotEmpty 
        ? totalWeight / _weightEntries.length 
        : currentWeight;
    
    // Calculate difference from average
    final diffFromAverage = currentWeight - averageWeight;
    
    // Get date range
    final oldestDate = _weightEntries.isNotEmpty
        ? _weightEntries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b)
        : DateTime.now();
    final daysTracked = DateTime.now().difference(oldestDate).inDays + 1;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: HealthTheme.successColor, size: 28),
            const SizedBox(width: 8),
            Text('Weight Saved', style: HealthTheme.headingSmall),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Weight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HealthTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${currentWeight.toStringAsFixed(1)} kg',
                      style: HealthTheme.headingLarge.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Weight Change
              if (weightChange != null) ...[
                Row(
                  children: [
                    Icon(
                      weightChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: weightChange > 0 
                          ? HealthTheme.dangerColor 
                          : HealthTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Change from last entry: ',
                      style: HealthTheme.bodyMedium,
                    ),
                    Text(
                      '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                      style: HealthTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: weightChange > 0 
                            ? HealthTheme.dangerColor 
                            : HealthTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Average Comparison
              Row(
                children: [
                  Icon(
                    diffFromAverage > 0 ? Icons.trending_up : Icons.trending_down,
                    color: diffFromAverage.abs() < 0.5 
                        ? Colors.grey 
                        : (diffFromAverage > 0 ? HealthTheme.dangerColor : HealthTheme.successColor),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Average weight: ',
                    style: HealthTheme.bodyMedium,
                  ),
                  Text(
                    '${averageWeight.toStringAsFixed(1)} kg',
                    style: HealthTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 28), // Align with icon above
                  Text(
                    'Difference: ',
                    style: HealthTheme.bodySmall,
                  ),
                  Text(
                    '${diffFromAverage > 0 ? '+' : ''}${diffFromAverage.toStringAsFixed(1)} kg',
                    style: HealthTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: diffFromAverage.abs() < 0.5 
                          ? Colors.grey 
                          : (diffFromAverage > 0 ? HealthTheme.dangerColor : HealthTheme.successColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Statistics
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 12),
              _buildStatRow('Total entries', '${_weightEntries.length}'),
              const SizedBox(height: 8),
              _buildStatRow('Days tracked', '$daysTracked'),
              const SizedBox(height: 8),
              _buildStatRow('Date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: HealthTheme.textButtonStyle,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: HealthTheme.bodyMedium),
        Text(
          value,
          style: HealthTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showEditWeightDialog(WeightEntry entry) {
    _editWeightController.text = entry.weight.toString();
    _selectedEditDate = entry.date;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Weight Entry', style: HealthTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editWeightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: HealthTheme.inputDecoration.copyWith(
                    labelText: 'Weight',
                    hintText: 'Enter weight (kg)',
                    suffixText: 'kg',
                  ),
                ),
                SizedBox(height: HealthTheme.spacingM),
                ListTile(
                  title: Text(
                    'Date: ${_selectedEditDate!.day}/${_selectedEditDate!.month}/${_selectedEditDate!.year}',
                    style: HealthTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedEditDate!,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null && mounted) {
                      setState(() {
                        _selectedEditDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: HealthTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _updateWeightEntry(entry),
                style: HealthTheme.primaryButtonStyle,
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateWeightEntry(WeightEntry entry) async {
    final weightText = _editWeightController.text.trim();
    if (weightText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a weight')));
      }
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight')),
        );
      }
      return;
    }

    // Close dialog immediately
    Navigator.pop(context);

    try {
      await _weightService.updateWeightEntry(
        entry.id,
        weight,
        _selectedEditDate!,
      );

      // Clear edit form
      _editWeightController.clear();
      _selectedEditDate = null;

      // Reload entries to refresh the page and graph without showing loading indicator
      await _loadWeightEntries(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight entry updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating weight entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: build() called, _weightEntries.length: ${_weightEntries.length}, _isLoading: $_isLoading');
    return Scaffold(
      backgroundColor: HealthTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        backgroundColor: HealthTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: HealthTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Weight Section
            Container(
              decoration: HealthTheme.cardDecoration,
              padding: HealthTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add New Weight', style: HealthTheme.headingSmall),
                  SizedBox(height: HealthTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: HealthTheme.inputDecoration.copyWith(
                            hintText: 'Enter weight (kg)',
                            suffixText: 'kg',
                          ),
                        ),
                      ),
                      SizedBox(width: HealthTheme.spacingM),
                      ElevatedButton(
                        onPressed: _addWeightEntry,
                        style: HealthTheme.primaryButtonStyle,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: HealthTheme.spacingL),

            // Graph Section
            if (_weightEntries.isNotEmpty) ...[
              Container(
                decoration: HealthTheme.cardDecoration,
                padding: HealthTheme.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight Progress', style: HealthTheme.headingSmall),
                    SizedBox(height: HealthTheme.spacingM),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        key: ValueKey('weight_chart_${_weightEntries.length}_${_weightEntries.isNotEmpty ? _weightEntries.first.id : ''}'),
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: HealthTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < _weightEntries.length) {
                                    final entry = _weightEntries[value.toInt()];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '${entry.date.day}/${entry.date.month}',
                                        style: HealthTheme.bodySmall,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots:
                                  _weightEntries.asMap().entries.map((entry) {
                                    return FlSpot(
                                      entry.key.toDouble(),
                                      entry.value.weight,
                                    );
                                  }).toList(),
                              isCurved: true,
                              color: HealthTheme.primaryColor,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: HealthTheme.spacingL),
            ],

            // Weight Entries List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _weightEntries.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 64,
                              color: HealthTheme.textTertiary,
                            ),
                            SizedBox(height: HealthTheme.spacingM),
                            Text(
                              'No weight entries yet',
                              style: HealthTheme.bodyLarge,
                            ),
                            SizedBox(height: HealthTheme.spacingS),
                            Text(
                              'Add your first weight entry to start tracking',
                              style: HealthTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        key: ValueKey('weight_list_${_weightEntries.length}'),
                        itemCount: _weightEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _weightEntries[index];
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: HealthTheme.spacingS,
                            ),
                            decoration: HealthTheme.cardDecoration,
                            padding: HealthTheme.listItemPadding,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monitor_weight,
                                  color: HealthTheme.primaryColor,
                                ),
                                SizedBox(width: HealthTheme.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.weight.toStringAsFixed(1)} kg',
                                        style: HealthTheme.valueMedium,
                                      ),
                                      Text(
                                        '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                        style: HealthTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showEditWeightDialog(entry),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: HealthTheme.primaryColor,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    // Remove from list immediately for better UX
                                    final deletedEntry = entry;
                                    setState(() {
                                      _weightEntries.removeAt(index);
                                    });

                                    try {
                                      await _weightService.deleteWeightEntry(
                                        deletedEntry.id,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Entry deleted'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // If deletion failed, reload the list to restore the entry
                                      await _loadWeightEntries();
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error deleting entry: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: HealthTheme.dangerColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
