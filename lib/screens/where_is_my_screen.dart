import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/where_is_my_service.dart';
import '../config/brain_theme.dart';

class WhereIsMyScreen extends StatefulWidget {
  const WhereIsMyScreen({super.key});

  @override
  State<WhereIsMyScreen> createState() => _WhereIsMyScreenState();
}

class _WhereIsMyScreenState extends State<WhereIsMyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _personController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _personController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      // Close dialog immediately
      Navigator.pop(context);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to add items')),
            );
          }
          return;
        }
        String userId = user.uid;

        LentItem item = LentItem(
          id: '',
          userId: userId,
          item: _itemController.text,
          person: _personController.text,
          date: _dateController.text,
          notes: _notesController.text,
          isReturned: false,
          createdAt: DateTime.now(),
        );

        await WhereIsMyService.addLentItem(item);

        // Clear form
        _itemController.clear();
        _personController.clear();
        _dateController.clear();
        _notesController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item added successfully!'),
              backgroundColor: BrainTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: BrainTheme.dangerColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleReturned(String itemId, bool currentStatus) async {
    try {
      await WhereIsMyService.toggleReturnedStatus(itemId, !currentStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: BrainTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await WhereIsMyService.deleteLentItem(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item deleted successfully!'),
            backgroundColor: BrainTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: BrainTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view items')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Where Is My', style: BrainTheme.headingSmall),
        backgroundColor: BrainTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: BrainTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track items you\'ve lent', style: BrainTheme.headingMedium),
            SizedBox(height: BrainTheme.spacingS),
            Text(
              'Keep track of what you\'ve given to others',
              style: BrainTheme.bodyLarge,
            ),
            SizedBox(height: BrainTheme.spacingL),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: WhereIsMyService.getUserLentItems(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: BrainTheme.textTertiary,
                            ),
                            SizedBox(height: BrainTheme.spacingM),
                            Text(
                              'No items tracked yet',
                              style: BrainTheme.headingSmall,
                            ),
                            SizedBox(height: BrainTheme.spacingS),
                            Text(
                              'Tap the + button to add your first item',
                              style: BrainTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        String itemName = data['item'] ?? '';
                        String person = data['person'] ?? '';
                        String date = data['date'] ?? '';
                        String notes = data['notes'] ?? '';
                        bool isReturned = data['is_returned'] ?? false;
                        String itemId = doc.id;

                        return Container(
                          margin: EdgeInsets.only(bottom: BrainTheme.spacingS),
                          decoration: BrainTheme.cardDecoration,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isReturned
                                      ? BrainTheme.successColor.withValues(
                                        alpha: 0.1,
                                      )
                                      : BrainTheme.warningColor.withValues(
                                        alpha: 0.1,
                                      ),
                              child: Icon(
                                isReturned ? Icons.check_circle : Icons.pending,
                                color:
                                    isReturned
                                        ? BrainTheme.successColor
                                        : BrainTheme.warningColor,
                              ),
                            ),
                            title: Text(
                              itemName,
                              style: BrainTheme.bodyMedium.copyWith(
                                decoration:
                                    isReturned
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To: $person',
                                  style: BrainTheme.bodySmall,
                                ),
                                Text(
                                  'Date: $date',
                                  style: BrainTheme.bodySmall,
                                ),
                                if (notes.isNotEmpty)
                                  Text(
                                    'Notes: $notes',
                                    style: BrainTheme.bodySmall,
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isReturned ? Icons.undo : Icons.check,
                                    color:
                                        isReturned
                                            ? BrainTheme.warningColor
                                            : BrainTheme.successColor,
                                  ),
                                  onPressed:
                                      () => _toggleReturned(itemId, isReturned),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: BrainTheme.dangerColor,
                                  ),
                                  onPressed: () => _deleteItem(itemId),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      color: BrainTheme.primaryColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: BrainTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Lent Item', style: BrainTheme.headingSmall),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _itemController,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Item Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: BrainTheme.spacingM),
                    TextFormField(
                      controller: _personController,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Lent To',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter who you lent it to';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: BrainTheme.spacingM),
                    TextFormField(
                      controller: _dateController,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Date Lent',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the date';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: BrainTheme.spacingM),
                    TextFormField(
                      controller: _notesController,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Notes (Optional)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: BrainTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addItem,
                style: BrainTheme.primaryButtonStyle,
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
