import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ember/core/theme/ember_theme_extension.dart';

/// 引导页
/// 首次打开时展示：欢迎 → 投放 → 转化 → 销毁
const _kOnboardingDone = 'onboarding_done';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onDone;

  const OnboardingScreen({super.key, this.onDone});

  /// 是否已完成引导
  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  /// 标记引导已完成
  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingPageData> get _pages {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    return [
      _OnboardingPageData(
        icon: Icons.local_fire_department,
        title: '欢迎来到余烬',
        subtitle: '一个安全的情绪释放空间',
        description: '在这里，你的情绪不会被评判。\n它们会燃烧、转化、然后消散。',
        color: ext.onboardingWelcome,
      ),
      _OnboardingPageData(
        icon: Icons.edit_note,
        title: '投放你的情绪',
        subtitle: '写下、说出你的不爽',
        description: '文字或语音，选一个情绪和烈度，\n然后把它扔进去。',
        color: ext.onboardingThrow,
      ),
      _OnboardingPageData(
        icon: Icons.auto_awesome,
        title: '情绪转化为艺术',
        subtitle: '不堪的文字变成美丽的作品',
        description: '莎翁风格、俳句、反向鸡汤或抽象画，\n让负能量变成有温度的创造。',
        color: ext.onboardingTransform,
      ),
      _OnboardingPageData(
        icon: Icons.whatshot,
        title: '仪式感地销毁',
        subtitle: '焚、沉、散、烬',
        description: '看着你的情绪化为灰烬、沉入深海、\n随风消散，释放就这样完成。',
        color: ext.onboardingDestroy,
      ),
    ];
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    OnboardingScreen.markDone();
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = _pages;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('跳过',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
            // 页面内容
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final p = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 图标
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.color.withValues(alpha: 0.15),
                          ),
                          child: Icon(p.icon,
                              size: 56, color: p.color),
                        ),
                        const SizedBox(height: 40),
                        // 标题
                        Text(p.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(p.subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: p.color,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Text(p.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 指示器 + 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 页面指示器
                  Row(
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  // 下一步/开始按钮
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentPage == pages.length - 1 ? '开始' : '下一步'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}
