import 'package:flutter/material.dart';
import 'package:dailynest/dashboard.dart';
import 'package:dailynest/weather.dart';
import 'package:dailynest/journal.dart';
import 'package:dailynest/savings.dart';
import 'package:dailynest/user_profile.dart';

const List<NavItem> appNavItems = [
  NavItem(label: 'Home', assetPath: 'images/homenavbar.png'),
  NavItem(label: 'Weather', assetPath: 'images/Weathernavbar.png'),
  NavItem(label: 'Journal', assetPath: 'images/Journalnavbar.png'),
  NavItem(label: 'Savings', assetPath: 'images/Savingsnavbar.png'),
  NavItem(label: 'Profile', assetPath: 'images/profilenavbar.png'),
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
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFF08902),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onItemSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.6,
                      child: Image.asset(
                        item.assetPath,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white.withOpacity(isSelected ? 1.0 : 0.75),
                      ),
                    ),
                  ],
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
  final String assetPath;

  const NavItem({required this.label, required this.assetPath});
}
