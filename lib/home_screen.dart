import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/health_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/brain_screen.dart';
import 'screens/settings_screen.dart';
import 'config/health_theme.dart';
import 'config/finance_theme.dart';
import 'config/brain_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 1;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _foregroundColorAnimation;

  final List<Widget> _screens = [
    const HealthScreen(),
    const FinanceScreen(),
    const BrainScreen(),
  ];

  final List<Color> _tabColors = [
    HealthTheme.primaryColor.withValues(alpha: 0.1), // Health - Light Green
    FinanceTheme.primaryColor.withValues(alpha: 0.1), // Finance - Light Blue
    BrainTheme.primaryColor.withValues(alpha: 0.1), // Brain - Light Purple
  ];

  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _backgroundColorAnimation = ColorTween(
      begin: _tabColors[_currentIndex],
      end: _tabColors[_currentIndex],
    ).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _foregroundColorAnimation = ColorTween(
      begin: Colors.black87,
      end: Colors.black87,
    ).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Animate to new colors
    _backgroundColorAnimation = ColorTween(
      begin: _backgroundColorAnimation.value ?? _tabColors[_currentIndex],
      end: _tabColors[_currentIndex],
    ).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _colorAnimationController,
          builder: (context, child) {
            return AppBar(
              title: Text(
                _getTitle(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _foregroundColorAnimation.value,
                ),
              ),
              backgroundColor: _backgroundColorAnimation.value,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/app_icon_transparent.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: _foregroundColorAnimation.value,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabChanged,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _getSelectedTabColor(),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Finance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Brain',
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Health';
      case 1:
        return 'Finance';
      case 2:
        return 'Brain';
      default:
        return 'DanApp';
    }
  }

  Color _getSelectedTabColor() {
    switch (_currentIndex) {
      case 0:
        return HealthTheme.primaryColor;
      case 1:
        return FinanceTheme.primaryColor;
      case 2:
        return BrainTheme.primaryColor;
      default:
        return Colors.black;
    }
  }
}
