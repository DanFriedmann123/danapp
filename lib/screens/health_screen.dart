import 'package:flutter/material.dart';
import '../config/health_theme.dart';
import 'health/weight_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: HealthTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health & Wellness', style: HealthTheme.headingLarge),
            SizedBox(height: HealthTheme.spacingS),
            Text(
              'Track your health metrics and wellness goals',
              style: HealthTheme.bodyLarge,
            ),
            SizedBox(height: HealthTheme.spacingXL),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildHealthCard(
                    context,
                    'Weight',
                    Icons.monitor_weight,
                    'Track your weight and BMI',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeightScreen(),
                        ),
                      );
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Sport',
                    Icons.fitness_center,
                    'Track your workouts and activities',
                    () {
                      // TODO: Navigate to sport screen
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Nutrition',
                    Icons.restaurant,
                    'Track your meals and nutrition',
                    () {
                      // TODO: Navigate to nutrition screen
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Sleep',
                    Icons.bedtime,
                    'Monitor your sleep patterns',
                    () {
                      // TODO: Navigate to sleep screen
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Meditation',
                    Icons.self_improvement,
                    'Track your mindfulness sessions',
                    () {
                      // TODO: Navigate to meditation screen
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Water',
                    Icons.water_drop,
                    'Track your daily water intake',
                    () {
                      // TODO: Navigate to water screen
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Steps',
                    Icons.directions_walk,
                    'Track your daily step count',
                    () {
                      // TODO: Navigate to steps screen
                    },
                  ),
                  _buildHealthCard(
                    context,
                    'Mood',
                    Icons.sentiment_satisfied,
                    'Track your daily mood and emotions',
                    () {
                      // TODO: Navigate to mood screen
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

  Widget _buildHealthCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: HealthTheme.cardDecoration,
        child: Padding(
          padding: HealthTheme.listItemPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HealthTheme.valueSmall),
              SizedBox(height: HealthTheme.spacingXS),
              Divider(color: HealthTheme.borderColor, thickness: 1),
              SizedBox(height: HealthTheme.spacingS),
              Icon(icon, size: 28, color: HealthTheme.primaryColor),
              SizedBox(height: HealthTheme.spacingXS),
              Expanded(
                child: Text(
                  description,
                  style: HealthTheme.bodySmall.copyWith(height: 1.2),
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
