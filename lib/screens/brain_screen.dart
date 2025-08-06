import 'package:flutter/material.dart';
import '../config/brain_theme.dart';
import 'where_is_my_screen.dart';
import 'docs_saver_screen.dart';

class BrainScreen extends StatelessWidget {
  const BrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: BrainTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brain & Learning', style: BrainTheme.headingLarge),
            SizedBox(height: BrainTheme.spacingS),
            Text(
              'Enhance your cognitive skills and knowledge',
              style: BrainTheme.bodyLarge,
            ),
            SizedBox(height: BrainTheme.spacingXL),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(
                    context,
                    'Language',
                    Icons.language,
                    'Learn new languages with interactive exercises',
                    () {
                      // TODO: Navigate to specific feature
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Language coming soon!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    'Math',
                    Icons.calculate,
                    'Improve your mathematical skills',
                    () {
                      // TODO: Navigate to specific feature
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Math coming soon!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    'Knowledge',
                    Icons.quiz,
                    'Test and expand your knowledge',
                    () {
                      // TODO: Navigate to specific feature
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Knowledge coming soon!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    'Where Is My',
                    Icons.search,
                    'Track items you\'ve lent to others',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WhereIsMyScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    context,
                    'Docs Saver',
                    Icons.folder,
                    'Store and organize documents & manuals',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DocsSaverScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BrainTheme.cardDecoration,
        child: Padding(
          padding: BrainTheme.listItemPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BrainTheme.valueSmall),
              SizedBox(height: BrainTheme.spacingXS),
              Divider(color: BrainTheme.borderColor, thickness: 1),
              SizedBox(height: BrainTheme.spacingS),
              Icon(icon, size: 28, color: BrainTheme.primaryColor),
              SizedBox(height: BrainTheme.spacingXS),
              Expanded(
                child: Text(
                  description,
                  style: BrainTheme.bodySmall.copyWith(height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
