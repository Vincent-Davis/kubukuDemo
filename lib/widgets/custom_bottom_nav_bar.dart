import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(color: const Color(0x193abeff)),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          top: 12,
          right: 24,
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home,
              label: 'Home',
              isActive: currentIndex == 0,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.history,
              label: 'History',
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.directions_run,
              label: 'Run',
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.people,
              label: 'Community',
              isActive: currentIndex == 3,
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.settings,
              label: 'Settings',
              isActive: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? const Color(0xff3abeff)
                  : const Color(0xff888b94),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: 10,
                color: isActive
                    ? const Color(0xff3abeff)
                    : const Color(0xff888b94),
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
