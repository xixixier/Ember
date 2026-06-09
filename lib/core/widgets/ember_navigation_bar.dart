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
    _NavDestination(icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department_outlined, label: '投放'),
    _NavDestination(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_outlined, label: '收藏'),
    _NavDestination(icon: Icons.whatshot_outlined, activeIcon: Icons.whatshot_outlined, label: '待毁'),
    _NavDestination(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_outlined, label: '回望'),
    _NavDestination(icon: Icons.person_outline, activeIcon: Icons.person_outline, label: '我的'),
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

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding > 0 ? bottomPadding : 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999), // Pill-shaped floating bar
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.8),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: SizedBox(
              height: 64,
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
    // 无论是选中还是未选中，图标颜色保持一致，通过底部的小圆点指示状态
    final iconColor = inactiveColor;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            destination.icon,
            size: 24,
            color: iconColor,
          ),
          const SizedBox(height: 4),
          // 底部小指示点 (tiny glowing ember dot)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
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
