import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailynest/dashboard.dart';
import 'package:dailynest/Weather/weather.dart';
import 'package:dailynest/Journal/journal.dart';
import 'package:dailynest/Savings/savings.dart';
import 'package:dailynest/AuthPage/user_profile.dart';

const List<NavItem> appNavItems = [
  NavItem(label: 'Home', icon: Icons.home),
  NavItem(label: 'Weather', icon: Icons.wb_sunny),
  NavItem(label: 'Journal', icon: Icons.book),
  NavItem(label: 'Savings', icon: Icons.savings),
  NavItem(label: 'Profile', icon: Icons.person),
];

class AppShell extends StatefulWidget {
  static const String id = "AppShell";
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = const [
    Dashboard(),
    Weather(),
    Journal(),
    Savings(),
    UserProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void setIndex(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScope(
      setIndex: setIndex,
      child: WillPopScope(
        onWillPop: () async {
          final now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Press back again to exit the app'),
              duration: Duration(seconds: 2),
            ));
            return false;
          }

          // If back pressed twice within 2 seconds, exit the app.
          await SystemNavigator.pop();
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomPhotoNav(
            currentIndex: _currentIndex,
            onItemSelected: setIndex,
            items: appNavItems,
          ),
        ),
      ),
    );
  }
}

class AppShellScope extends InheritedWidget {
  final void Function(int) setIndex;

  const AppShellScope({
    required this.setIndex,
    required super.child,
    super.key,
  });

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  static void setPage(BuildContext context, int index) {
    maybeOf(context)?.setIndex(index);
  }

  @override
  bool updateShouldNotify(covariant AppShellScope oldWidget) {
    return false;
  }
}

class BottomPhotoNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavItem> items;

  const BottomPhotoNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFFF08902),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onItemSelected(index),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 26,
                          color: isSelected 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class NavItem {
  final String label;
  final IconData icon;

  const NavItem({required this.label, required this.icon});
}
