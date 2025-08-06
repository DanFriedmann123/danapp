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
  final WeightService _weightService = WeightService();
  List<WeightEntry> _weightEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _weightService.getWeightEntries();
      setState(() {
        _weightEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading weight entries: $e')),
        );
      }
    }
  }

  Future<void> _addWeightEntry() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a weight')));
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    try {
      await _weightService.addWeightEntry(weight);
      _weightController.clear();
      await _loadWeightEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight entry added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding weight entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          keyboardType: TextInputType.number,
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
                                  onPressed: () async {
                                    try {
                                      await _weightService.deleteWeightEntry(
                                        entry.id,
                                      );
                                      await _loadWeightEntries();
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
