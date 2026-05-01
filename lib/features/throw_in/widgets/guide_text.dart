import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ember/core/theme/typography.dart';

/// 每日引导语组件
/// 每天随机一句，同一天内保持不变（SharedPreferences 缓存）
class GuideText extends StatefulWidget {
  const GuideText({super.key});

  @override
  State<GuideText> createState() => _GuideTextState();
}

class _GuideTextState extends State<GuideText> {
  String _text = '';
  bool _loading = true;

  static const _allTexts = [
    '说吧，今天谁惹你了',
    '空着也挺好',
    '我也经常想骂人',
    '倒进来，让它烧',
    '不用忍着',
    '丢进来，然后看着它消失',
    '今天有什么想扔掉的？',
    '吐槽吧，没人看见',
    '说出来就好受了',
    '让余烬替你消化',
    '别憋着，扔进来',
    '崩溃也没关系的',
    '今天怎么了？',
    '谁又惹你了？',
    '骂两句，没事的',
    '火气挺大？来，放这',
    '写下来，然后烧掉',
    '这个世界欠你一个道歉',
    '发完火记得消散它',
    '你的愤怒值得被听见',
    '别跟自己过不去',
    '说出来，就轻了',
    '今天的日子不好过吧',
    '扔掉，然后继续走',
  ];

  @override
  void initState() {
    super.initState();
    _loadGuideText();
  }

  Future<void> _loadGuideText() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final cached = prefs.getString('guide_text_$today');

    if (cached != null) {
      setState(() {
        _text = cached;
        _loading = false;
      });
    } else {
      // 基于日期确定性选择
      final index = DateTime.now().millisecondsSinceEpoch ~/ (86400000) % _allTexts.length;
      final selected = _allTexts[index];
      await prefs.setString('guide_text_$today', selected);
      setState(() {
        _text = selected;
        _loading = false;
      });
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        _text,
        style: AppTypography.guideText.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
