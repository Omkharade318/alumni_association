import 'package:alumni_connect/screens/settings_screen.dart';
import 'package:alumni_connect/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'alumni_directory_screen.dart';
import 'donation_screen.dart';
import 'feed_screen.dart';
import 'home_screen.dart';
import 'connections_screen.dart';
import 'jobs_screen.dart';
import 'messaging_screen.dart';
import 'search_alumni_screen.dart';
import 'events_calendar_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'admin/admin_gate_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// Helper to change tabs or push screens
  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateTo(Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
// Pass the scaffold key function so the Home menu button works
      HomeScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      const FeedScreen(),
      const SearchAlumniScreen(),
      const EventsCalendarScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey, // Essential for opening drawer from sub-widgets
      drawer: const AppDrawer(),
// We only show the "Standard" AppBar for non-home screens
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              backgroundColor: AppTheme.primaryRed,
              title: Text(_getTitle()),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar:
          AppBottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Feed';
      case 2:
        return 'Search';
      case 3:
        return 'Events';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}
