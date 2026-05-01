import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/ember_theme_extension.dart';

/// 余烬玻璃拟态底部导航栏
///
/// 特性：
/// - BackdropFilter 毛玻璃模糊 (sigma=20)
/// - 半透明深色背景
/// - 顶部 0.5px 高光线
/// - 余烬橙高亮选中项 + 动画指示点
/// - AnimatedContainer 切换动画 (200ms)
class EmberNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    _NavDestination(icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department, label: '投放'),
    _NavDestination(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: '收藏'),
    _NavDestination(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: '回望'),
    _NavDestination(icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  const EmberNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<EmberThemeExtension>();
    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: primaryColor.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60 + bottomPadding,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  children: List.generate(
                    _destinations.length,
                    (index) => Expanded(
                      child: _NavItem(
                        destination: _destinations[index],
                        isSelected: selectedIndex == index,
                        primaryColor: primaryColor,
                        inactiveColor: colorScheme.onSurfaceVariant,
                        textWeak: ext?.textWeak ?? colorScheme.onSurfaceVariant,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个导航项
class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final Color primaryColor;
  final Color inactiveColor;
  final Color textWeak;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.primaryColor,
    required this.inactiveColor,
    required this.textWeak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标 + 选中光晕
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.14)
                  : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.18),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSelected ? destination.activeIcon : destination.icon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: isSelected ? primaryColor : inactiveColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          // 标签文字
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? primaryColor : textWeak,
              letterSpacing: 0.2,
            ),
            child: Text(destination.label),
          ),
          const SizedBox(height: 2),
          // 底部小指示点
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: isSelected ? 16 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isSelected ? 0.8 : 0),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
