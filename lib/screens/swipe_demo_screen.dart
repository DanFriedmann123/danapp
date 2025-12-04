import 'package:flutter/material.dart';
import '../widgets/swipe_button.dart';
import '../config/finance_theme.dart';

class SwipeDemoScreen extends StatefulWidget {
  const SwipeDemoScreen({super.key});

  @override
  State<SwipeDemoScreen> createState() => _SwipeDemoScreenState();
}

class _SwipeDemoScreenState extends State<SwipeDemoScreen> {
  String _lastAction = 'No action performed';

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FinanceTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swipe Button Demo', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Action Display
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Action', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Text(
                    _lastAction,
                    style: FinanceTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingL),

            // Swipe Button Examples
            Text('Swipe Button Examples', style: FinanceTheme.headingMedium),
            SizedBox(height: FinanceTheme.spacingM),

            // Delete Swipe Button
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete Action', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  SwipeButton(
                    text: 'Swipe to Delete',
                    icon: Icons.delete,
                    backgroundColor: FinanceTheme.dangerColor,
                    onSwipe: () {
                      setState(() {
                        _lastAction = 'Delete action performed!';
                      });
                      _showSnackBar('Item deleted successfully!');
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingM),

            // Confirm Swipe Button
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm Action', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  SwipeButton(
                    text: 'Swipe to Confirm',
                    icon: Icons.check,
                    backgroundColor: FinanceTheme.successColor,
                    onSwipe: () {
                      setState(() {
                        _lastAction = 'Confirm action performed!';
                      });
                      _showSnackBar('Action confirmed!');
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingM),

            // Save Swipe Button
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Save Action', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  SwipeButton(
                    text: 'Swipe to Save',
                    icon: Icons.save,
                    backgroundColor: FinanceTheme.primaryColor,
                    onSwipe: () {
                      setState(() {
                        _lastAction = 'Save action performed!';
                      });
                      _showSnackBar('Data saved successfully!');
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingM),

            // Disabled Swipe Button
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disabled Action', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  SwipeButton(
                    text: 'Swipe to Activate',
                    icon: Icons.lock,
                    backgroundColor: Colors.grey,
                    enabled: false,
                    onSwipe: () {
                      // This won't be called when disabled
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingL),

            // Swipe Action Buttons
            Text('Swipe Action Buttons', style: FinanceTheme.headingMedium),
            SizedBox(height: FinanceTheme.spacingM),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: SwipeActionButton(
                    text: 'Edit',
                    icon: Icons.edit,
                    backgroundColor: FinanceTheme.primaryColor,
                    onPressed: () {
                      setState(() {
                        _lastAction = 'Edit button pressed!';
                      });
                      _showSnackBar('Edit mode activated!');
                    },
                  ),
                ),
                SizedBox(width: FinanceTheme.spacingM),
                Expanded(
                  child: SwipeActionButton(
                    text: 'Delete',
                    icon: Icons.delete,
                    backgroundColor: FinanceTheme.dangerColor,
                    onPressed: () {
                      setState(() {
                        _lastAction = 'Delete button pressed!';
                      });
                      _showSnackBar('Delete action triggered!');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: FinanceTheme.spacingM),

            // More Action Buttons
            Row(
              children: [
                Expanded(
                  child: SwipeActionButton(
                    text: 'Share',
                    icon: Icons.share,
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      setState(() {
                        _lastAction = 'Share button pressed!';
                      });
                      _showSnackBar('Sharing content...');
                    },
                  ),
                ),
                SizedBox(width: FinanceTheme.spacingM),
                Expanded(
                  child: SwipeActionButton(
                    text: 'Favorite',
                    icon: Icons.favorite,
                    backgroundColor: Colors.pink,
                    onPressed: () {
                      setState(() {
                        _lastAction = 'Favorite button pressed!';
                      });
                      _showSnackBar('Added to favorites!');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
