import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ember/core/providers/database_provider.dart';
import 'package:ember/core/theme/ember_theme_extension.dart';
import 'package:ember/core/widgets/ember_card.dart';
import 'package:ember/features/transform/engines/transform_engine.dart';
import 'package:ember/features/transform/engines/abstract_art_painter.dart';
import 'package:ember/features/transform/widgets/type_filter_bar.dart';
import 'package:ember/features/transform/widgets/empty_collection.dart';
import 'package:ember/features/transform/widgets/collection_card_entrance.dart';
import 'package:ember/features/destroy/widgets/swipe_to_burn.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  TransformType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final collectionDao = ref.watch(collectionDaoProvider);

    final collectionsStream = _selectedType == null
        ? collectionDao.watchAll()
        : collectionDao.watchByType(_selectedType!.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '转化馆',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // 类型筛选栏
          TypeFilterBar(
            selectedType: _selectedType,
            onSelected: (type) {
              setState(() => _selectedType = type);
            },
          ),
          const SizedBox(height: 8),

          // 收藏列表 — 瀑布流
          Expanded(
            child: StreamBuilder(
              stream: collectionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const EmptyCollection();
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return CollectionCardEntrance(
                              index: index,
                              child: SwipeToBurn(
                                onBurn: () async {
                                  await collectionDao.deleteCollection(item.id);
                                },
                                confirmText: '确认销毁这条收藏？',
                                child: _TypedCollectionCard(
                                  type: item.type,
                                  content: item.content,
                                  emotionTag: item.emotionTag,
                                  intensity: item.intensity,
                                ),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 分类型收藏卡片
/// 4 种类型各有不同的视觉风格
class _TypedCollectionCard extends StatelessWidget {
  final String type;
  final String content;
  final String? emotionTag;
  final int? intensity;

  const _TypedCollectionCard({
    required this.type,
    required this.content,
    this.emotionTag,
    this.intensity,
  });

  TransformType get transformType => TransformType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => TransformType.darkSoup,
      );

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;

    return Stack(
      children: [
        // 卡片内容
        switch (transformType) {
          TransformType.shakespeare =>
            _ShakespeareCard(content: content),
          TransformType.haiku =>
            _HaikuCard(content: content),
          TransformType.darkSoup =>
            _DarkSoupCard(content: content),
          TransformType.art =>
            _ArtCard(content: content),
        },

        // 暗金细线顶部装饰
        Positioned(
          top: 0,
          left: 12,
          right: 12,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ext.emberGold.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ),

        // 烧焦纸边效果（底边 gradient overlay）
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    ext.emberGold.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 莎翁卡片 — 仿旧书页风格
class _ShakespeareCard extends StatelessWidget {
  final String content;
  const _ShakespeareCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    return EmberCard(
      backgroundColor: ext.shakespeareBg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎭', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '莎翁剧场',
                style: TextStyle(
                  color: ext.shakespeareTitle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: ext.shakespeareText,
              fontSize: 13,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// 俳句卡片 — 竖排诗意
class _HaikuCard extends StatelessWidget {
  final String content;
  const _HaikuCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    final lines = content.split('\n');

    return EmberCard(
      backgroundColor: ext.haikuBg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎋', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '俳句',
                style: TextStyle(
                  color: ext.haikuTitle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                color: ext.haikuText,
                fontSize: 14,
                height: 1.6,
                letterSpacing: 1.5,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// 反向鸡汤卡片 — 温暖暗色
class _DarkSoupCard extends StatelessWidget {
  final String content;
  const _DarkSoupCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    return EmberCard(
      backgroundColor: ext.darkSoupBg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍲', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '反向鸡汤',
                style: TextStyle(
                  color: ext.darkSoupTitle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: ext.darkSoupText,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// 抽象画卡片 — 画布缩略图
class _ArtCard extends StatelessWidget {
  final String content;
  const _ArtCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    return EmberCard(
      backgroundColor: ext.artBg,
      borderRadius: 12,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '抽象画',
                  style: TextStyle(
                    color: ext.artTitle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
              child: _buildArtThumbnail(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtThumbnail(BuildContext context) {
    final ext = Theme.of(context).extension<EmberThemeExtension>()!;
    try {
      final data = json.decode(content) as Map<String, dynamic>;
      final paletteRaw = (data['palette'] as List).cast<int>();
      final elementsRaw =
          (data['elements'] as List).cast<Map<String, dynamic>>();
      final strokeWidth = (data['strokeWidth'] as num).toDouble();
      final bgAlpha = (data['bgAlpha'] as num).toDouble();

      return CustomPaint(
        painter: AbstractArtPainter(
          palette: paletteRaw.map((v) => Color(v)).toList(),
          elements: elementsRaw,
          strokeWidth: strokeWidth,
          bgAlpha: bgAlpha,
        ),
        size: Size.infinite,
      );
    } catch (_) {
      return Container(
        color: ext.artBg,
        child: const Center(
          child: Text('🎨', style: TextStyle(fontSize: 24)),
        ),
      );
    }
  }
}
