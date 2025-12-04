import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/finance_theme.dart';
import '../../services/assets_service.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _estimatedValueController =
      TextEditingController();
  final TextEditingController _depreciationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _purchaseDate;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _estimatedValueController.dispose();
    _depreciationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addAsset() async {
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter asset name')),
        );
      }
      return;
    }

    double? estimatedValue = double.tryParse(_estimatedValueController.text);
    if (estimatedValue == null || estimatedValue <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid estimated value')),
        );
      }
      return;
    }

    double? monthlyDepreciation = double.tryParse(_depreciationController.text);
    if (monthlyDepreciation == null || monthlyDepreciation < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid monthly depreciation')),
        );
      }
      return;
    }

    // Show verification dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Asset Details', style: FinanceTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerificationRow('Name', _nameController.text.trim()),
            _buildVerificationRow('Location', _locationController.text.trim()),
            _buildVerificationRow('Estimated Value', '\$${estimatedValue.toStringAsFixed(2)}'),
            _buildVerificationRow('Monthly Depreciation', '\$${monthlyDepreciation.toStringAsFixed(2)}'),
            _buildVerificationRow('Purchase Date', _purchaseDate != null 
                ? '${_purchaseDate!.year}-${_purchaseDate!.month.toString().padLeft(2, '0')}-${_purchaseDate!.day.toString().padLeft(2, '0')}'
                : 'Not specified'),
            _buildVerificationRow('Date Added', _selectedDate != null 
                ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                : 'Today'),
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
            const SnackBar(content: Text('Please sign in to add assets')),
          );
        }
        return;
      }

      Map<String, dynamic> assetData = {
        'user_id': user.uid,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'estimated_value': estimatedValue,
        'monthly_depreciation': monthlyDepreciation,
        'purchase_date': _purchaseDate ?? DateTime.now(),
        'date_added': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await AssetsService.addAsset(assetData);

      // Clear form
      _nameController.clear();
      _estimatedValueController.clear();
      _depreciationController.clear();
      _locationController.clear();
      _purchaseDate = null;
      _selectedDate = null;
      _notesController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Asset added successfully!')));
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
            width: 120,
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

  void _showAddAssetDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Add Asset', style: FinanceTheme.headingSmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextField(
                      controller: _nameController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Asset Name',
                        hintText: 'e.g., iPhone 13, MacBook Pro',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Location',
                        hintText: 'e.g., Home office, Living room',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Estimated Value
                    TextField(
                      controller: _estimatedValueController,
                      keyboardType: TextInputType.number,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Estimated Value (₪)',
                        hintText: '5000.00',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Monthly Depreciation
                    TextField(
                      controller: _depreciationController,
                      keyboardType: TextInputType.number,
                      decoration: FinanceTheme.inputDecoration.copyWith(
                        labelText: 'Monthly Depreciation (₪)',
                        hintText: '100.00',
                      ),
                    ),
                    SizedBox(height: FinanceTheme.spacingM),

                    // Purchase Date
                    InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _purchaseDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365 * 10),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null && mounted) {
                          setState(() {
                            _purchaseDate = pickedDate;
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
                              _purchaseDate != null
                                  ? '${_purchaseDate!.year}-${_purchaseDate!.month.toString().padLeft(2, '0')}-${_purchaseDate!.day.toString().padLeft(2, '0')}'
                                  : 'Select Purchase Date (Optional)',
                              style: FinanceTheme.bodyMedium.copyWith(
                                color:
                                    _purchaseDate != null
                                        ? FinanceTheme.textPrimary
                                        : FinanceTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
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
                  onPressed: _addAsset,
                  style: FinanceTheme.primaryButtonStyle,
                  child: const Text('Add Asset'),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildAssetsSummary(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AssetsService.getAssetsSummary(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          double totalEstimatedValue = data['total_estimated_value'] ?? 0.0;
          double totalCurrentValue = data['total_current_value'] ?? 0.0;
          double totalDepreciation = data['total_depreciation'] ?? 0.0;
          int totalAssets = data['total_assets'] ?? 0;
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
                  Text('Assets Summary', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Value',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalCurrentValue),
                              style: FinanceTheme.valueLarge.copyWith(
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
                              'Total Assets',
                              style: FinanceTheme.bodyMedium,
                            ),
                            Text(
                              '$totalAssets',
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
                              'Original Value',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalEstimatedValue),
                              style: FinanceTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Depreciation',
                              style: FinanceTheme.bodySmall,
                            ),
                            Text(
                              FinanceTheme.formatCurrency(totalDepreciation),
                              style: FinanceTheme.bodyMedium.copyWith(
                                color: FinanceTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildAssetsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: AssetsService.getUserAssets(userId),
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
                        Icons.devices,
                        size: 48,
                        color: FinanceTheme.textTertiary,
                      ),
                      SizedBox(height: FinanceTheme.spacingM),
                      Text('No assets yet', style: FinanceTheme.bodyLarge),
                      SizedBox(height: FinanceTheme.spacingS),
                      Text(
                        'Add your first sellable asset',
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

              String name = data['name'] ?? '';
              String location = data['location'] ?? '';
              double estimatedValue = data['estimated_value'] ?? 0.0;
              double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;
              DateTime? purchaseDate = data['purchase_date']?.toDate();
              DateTime? dateAdded = data['date_added']?.toDate();
              String notes = data['notes'] ?? '';

              // Calculate current value and depreciation
              DateTime now = DateTime.now();
              int monthsSincePurchase = 0;
              if (purchaseDate != null) {
                monthsSincePurchase =
                    ((now.year - purchaseDate.year) * 12 +
                            now.month -
                            purchaseDate.month)
                        .abs();
              }
              double totalDepreciation =
                  monthlyDepreciation * monthsSincePurchase;
              double currentValue = estimatedValue - totalDepreciation;
              if (currentValue < 0) currentValue = 0;

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
                                Text(name, style: FinanceTheme.valueSmall),
                                Text(location, style: FinanceTheme.bodyMedium),
                                Text(
                                  'Monthly Depreciation: ${FinanceTheme.formatCurrency(monthlyDepreciation)}',
                                  style: FinanceTheme.bodySmall.copyWith(
                                    color: FinanceTheme.dangerColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FinanceTheme.formatCurrency(currentValue),
                                style: FinanceTheme.valueSmall.copyWith(
                                  color: FinanceTheme.successColor,
                                ),
                              ),
                              Text(
                                'Original: ${FinanceTheme.formatCurrency(estimatedValue)}',
                                style: FinanceTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (purchaseDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Purchase: ${purchaseDate.year}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}',
                            style: FinanceTheme.bodySmall.copyWith(
                              color: FinanceTheme.textSecondary,
                            ),
                          ),
                        ),
                      if (dateAdded != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
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
                            onPressed: () => _showEditAssetDialog(doc.id, data),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: FinanceTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteAsset(doc.id),
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

  void _showEditAssetDialog(String assetId, Map<String, dynamic> data) {
    // Pre-fill the form with existing data
    _nameController.text = data['name'] ?? '';
    _locationController.text = data['location'] ?? '';
    _estimatedValueController.text = (data['estimated_value'] ?? 0.0).toString();
    _depreciationController.text = (data['monthly_depreciation'] ?? 0.0).toString();
    _purchaseDate = data['purchase_date']?.toDate();
    _selectedDate = data['date_added']?.toDate();
    _notesController.text = data['notes'] ?? '';

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit Asset', style: FinanceTheme.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: _nameController,
                  decoration: FinanceTheme.inputDecoration.copyWith(
                    labelText: 'Asset Name',
                    hintText: 'e.g., iPhone 13, MacBook Pro',
                  ),
                ),
                SizedBox(height: FinanceTheme.spacingM),

                // Location
                TextField(
                  controller: _locationController,
                  decoration: FinanceTheme.inputDecoration.copyWith(
                    labelText: 'Location',
                    hintText: 'e.g., Home office, Living room',
                  ),
                ),
                SizedBox(height: FinanceTheme.spacingM),

                // Estimated Value
                TextField(
                  controller: _estimatedValueController,
                  keyboardType: TextInputType.number,
                  decoration: FinanceTheme.inputDecoration.copyWith(
                    labelText: 'Estimated Value (₪)',
                    hintText: '5000.00',
                  ),
                ),
                SizedBox(height: FinanceTheme.spacingM),

                // Monthly Depreciation
                TextField(
                  controller: _depreciationController,
                  keyboardType: TextInputType.number,
                  decoration: FinanceTheme.inputDecoration.copyWith(
                    labelText: 'Monthly Depreciation (₪)',
                    hintText: '100.00',
                  ),
                ),
                SizedBox(height: FinanceTheme.spacingM),

                // Purchase Date
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365 * 10),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && mounted) {
                      setState(() {
                        _purchaseDate = pickedDate;
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
                          _purchaseDate != null
                              ? '${_purchaseDate!.year}-${_purchaseDate!.month.toString().padLeft(2, '0')}-${_purchaseDate!.day.toString().padLeft(2, '0')}'
                              : 'Select Purchase Date (Optional)',
                          style: FinanceTheme.bodyMedium.copyWith(
                            color: _purchaseDate != null
                                ? FinanceTheme.textPrimary
                                : FinanceTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
              onPressed: () => _updateAsset(assetId),
              style: FinanceTheme.primaryButtonStyle,
              child: const Text('Update'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateAsset(String assetId) async {
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an asset name')),
        );
      }
      return;
    }

    double? estimatedValue = double.tryParse(_estimatedValueController.text);
    if (estimatedValue == null || estimatedValue < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid estimated value')),
        );
      }
      return;
    }

    double? depreciation = double.tryParse(_depreciationController.text);
    if (depreciation == null || depreciation < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid depreciation amount')),
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
            const SnackBar(content: Text('Please sign in to update assets')),
          );
        }
        return;
      }

      Map<String, dynamic> assetData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'estimated_value': estimatedValue,
        'monthly_depreciation': depreciation,
        'purchase_date': _purchaseDate,
        'date_added': _selectedDate ?? DateTime.now(),
        'notes': _notesController.text.trim(),
      };

      await AssetsService.updateAsset(assetId, assetData);

      // Clear form
      _nameController.clear();
      _locationController.clear();
      _estimatedValueController.clear();
      _depreciationController.clear();
      _purchaseDate = null;
      _selectedDate = null;
      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset updated successfully!')),
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

  Future<void> _deleteAsset(String assetId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Asset', style: FinanceTheme.headingSmall),
        content: const Text('Are you sure you want to delete this asset?'),
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
        await AssetsService.deleteAsset(assetId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset deleted successfully!')),
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
        body: Center(child: Text('Please sign in to view assets')),
      );
    }
    String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assets', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssetsSummary(userId),
            SizedBox(height: FinanceTheme.spacingM),
            Expanded(child: _buildAssetsList(userId)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        backgroundColor: FinanceTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
