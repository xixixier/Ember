import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_provider.dart';

/// 主题选择页面
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  static const _themes = [
    _ThemeOption(
      name: '暗焰',
      key: 'dark',
      surface: ColorTokens.darkSurface,
      surfaceVariant: ColorTokens.darkSurfaceVariant,
      primary: ColorTokens.darkPrimary,
      accent: ColorTokens.darkAccent,
      description: '经典暗色，橙色余烬',
    ),
    _ThemeOption(
      name: '暖灰',
      key: 'warmGray',
      surface: ColorTokens.warmGraySurface,
      surfaceVariant: ColorTokens.warmGraySurfaceVariant,
      primary: ColorTokens.warmGrayPrimary,
      accent: ColorTokens.warmGrayAccent,
      description: '温暖灰调，柔和舒适',
    ),
    _ThemeOption(
      name: '深蓝',
      key: 'deepBlue',
      surface: ColorTokens.deepBlueSurface,
      surfaceVariant: ColorTokens.deepBlueSurfaceVariant,
      primary: ColorTokens.deepBluePrimary,
      accent: ColorTokens.deepBlueAccent,
      description: '深海蓝色，沉稳宁静',
    ),
    _ThemeOption(
      name: '纯黑',
      key: 'pureBlack',
      surface: ColorTokens.pureBlackSurface,
      surfaceVariant: ColorTokens.pureBlackSurfaceVariant,
      primary: ColorTokens.pureBlackPrimary,
      accent: ColorTokens.pureBlackAccent,
      description: 'OLED 纯黑，省电极致',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('主题')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _themes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = _themes[index];
          final isSelected = currentTheme == t.key;

          return _ThemeCard(
            theme: t,
            isSelected: isSelected,
            onTap: () => setThemeByName(ref, t.key),
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final _ThemeOption theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primary : theme.surfaceVariant,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            // 主题预览色块
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.surface,
                border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
              ),
              child: Stack(
                children: [
                  // 顶部 accent 条
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        color: theme.primary,
                      ),
                    ),
                  ),
                  // 中间按钮
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 文字信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(theme.description,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.primary.withValues(alpha: 0.7))),
                ],
              ),
            ),
            // 选中标记
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  final String name;
  final String key;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color accent;
  final String description;

  const _ThemeOption({
    required this.name,
    required this.key,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.accent,
    required this.description,
  });
}
