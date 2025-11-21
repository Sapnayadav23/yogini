// ==================== MainNavbar ====================
import 'package:flutter/material.dart';
import 'package:yoga/AnlayzAI/Al_Analyze_screen.dart';
import 'package:yoga/Home/Home_Screen.dart';
import 'package:yoga/Practice/practice_yoga_screen.dart';
import 'package:yoga/course/course_Screen.dart';
import 'package:yoga/utils/app_assests.dart';

class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CoursesScreen(),
    const PracticeScreen(),
    const AlAnalyzeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              selectedIcon: AppAssets.homeImagesSelected,
              unselectedIcon: AppAssets.homeImages,
              index: 0,
            ),
            _buildNavItem(
              selectedIcon: AppAssets.courseIconImages,
              unselectedIcon: AppAssets.courseIconImages,
              index: 1,
            ),
            _buildNavItem(
              selectedIcon: AppAssets.practiceImages,
              unselectedIcon: AppAssets.practiceImages,
              index: 2,
            ),
            _buildNavItem(
              selectedIcon: AppAssets.analyzeImagesSelected,
              unselectedIcon: AppAssets.analyzeImages,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String selectedIcon,
    required String unselectedIcon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isSelected ? 14 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // color: isSelected ? Colors.orange : Colors.transparent,
        ),
        child: Image.asset(
          isSelected ? selectedIcon : unselectedIcon, // Conditional image
          color: isSelected ? Colors.orange : Colors.black,

          fit: BoxFit.contain,
          height: 25,
        ),
      ),
    );
  }
}
