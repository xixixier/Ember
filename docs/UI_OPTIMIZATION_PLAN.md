# Ember UI 优化方案 v1.1

> 基于 DESIGN.md 设计规范 vs 当前代码实现的系统差距分析
> 创建日期: 2026-04-30
> 最后更新: 2026-05-01
> 状态: P0 ✅ 完成 | P1 ✅ 完成 | P2 ✅ 完成 | P3 ✅ 完成

---

## P0: Bug 修复 ✅ 全部完成

### 0.1 硬编码颜色绕过主题系统 ✅

**严重度**: P0-Critical
**影响范围**: 主题切换完全失效于 6 处文件/40+ 色值

| 文件 | 问题 | 硬编码色值数 |
|------|------|-------------|
| `lib/features/transform/collection_screen.dart` | `_ShakespeareCard` / `_HaikuCard` / `_DarkSoupCard` / `_ArtCard` 直接 `Color(0xFF...)` | 20+ |
| `lib/features/transform/widgets/transform_selector.dart` | `_TransformCard` 4 种类型色直接硬编码 | 4 |
| `lib/features/review/screens/calendar_screen.dart` | `HeatMapCalendarPainter` 使用 `Colors.white54/70/24` | 3 |
| `lib/core/widgets/onboarding.dart` | 4 页各使用独立 `Color(0xFFE8915A)` 等 | 4 |
| `lib/core/widgets/fake_calculator.dart` | 全部 5 色硬编码 | 5 (可保留) |
| `lib/features/throw_in/throw_in_screen.dart` | 直接引用 `ColorTokens` 静态常量 | 若干 |

**修复方案**:

1. 创建 `lib/core/theme/ember_theme_extension.dart`:
   ```dart
   class EmberThemeExtension extends ThemeExtension<EmberThemeExtension> {
     // 情绪色 (8 种低饱和)
     final Color angerColor;      // 暗红/余烬橙
     final Color anxietyColor;    // 灰紫/暗蓝紫
     final Color depressionColor; // 冷蓝/深灰蓝
     final Color grievanceColor;  // 灰粉/雾紫
     final Color irritabilityColor;// 铜橙/暗黄
     final Color breakdownColor;  // 黑紫/深红
     final Color numbColor;       // 石墨灰/冷灰
     final Color calmColor;       // 深绿灰/雾蓝

     // 转化类型色
     final Color shakespeareColor; // 暗金/铜
     final Color haikuColor;       // 青灰/深绿
     final Color darkSoupColor;    // 紫灰
     final Color artColor;         // 焦橙

     // 余烬系统色
     final Color emberGold;        // 暗金 #F2B56B
     final Color copperColor;      // 铜 #C9824A
     final Color fireOrange;       // 火光橙 #FF8A4C
     final Color darkRedOrange;    // 暗红橙 #A9472B

     // 文本层级
     final Color textWeak;         // 弱提示 #5F5A55
     final Color textDisabled;     // 禁用

     // 热力图专用
     final Color heatMapEmpty;     // 无记录日期
     final Color heatMapMuted;     // 低频
     final Color heatMapBright;    // 高频
   }
   ```

2. 为 4 套主题各定义一份 `EmberThemeExtension` 值:
   - `dark` 主题: 暖色调情绪色
   - `warmGray` 主题: 低饱和暖灰情绪色
   - `deepBlue` 主题: 冷蓝色调情绪色
   - `pureBlack` 主题: 高对比度情绪色

3. 在 `AppTheme._buildTheme()` 中通过 `extensions: [emberExt]` 注册

4. 各文件改用 `Theme.of(context).extension<EmberThemeExtension>()!.angerColor` 等

### 0.2 主题选择不持久化 ✅

**严重度**: P0-High
**影响**: 用户切换主题后重启 App 回到 dark 主题

**修复方案**:
1. `pubspec.yaml` 添加 `shared_preferences: ^2.3.4`
2. `theme_provider.dart` 改造:
   - `AsyncNotifierProvider` 替代 `StateProvider`
   - `initState` 从 `SharedPreferences.getString('theme_name')` 读取，默认 `'dark'`
   - `setTheme` 时同步 `SharedPreferences.setString('theme_name', name)`
3. `main.dart` 确保在 `ProviderScope` 初始化前加载完成

### 0.3 SubmitButton 双触发 ✅

**严重度**: P0-Medium
**文件**: `lib/features/throw_in/widgets/submit_button.dart`
**问题**: `GestureDetector.onTapUp` + `FilledButton.onPressed` 同时存在

**修复**: 移除 `GestureDetector`，保留 `FilledButton` 即可。按压缩放效果通过 `AnimatedScale` + `GestureDetector` 的事件回调改为 `onTapDown`/`onTapUp`/`onTapCancel` 控制 scale 动画，`onPressed` 只绑定一次。

### 0.4 ReminderScreen DropdownButtonFormField 参数错误 ✅

**严重度**: P0-Medium
**文件**: `lib/features/settings/screens/reminder_screen.dart`
**问题**: 第 222 行使用 `initialValue` 参数，但 `DropdownButtonFormField` 正确参数名是 `value`

**修复**: `initialValue: _selectedHour` → `value: _selectedHour`

### 0.5 CollectSnackbar Undo 空操作 ✅

**严重度**: P0-Low
**文件**: `lib/features/throw_in/throw_in_screen.dart` 第 237 行
**问题**: `onUndo: () async {}` 没有实现

**修复**:
1. 在 `_collectResult()` 成功后记录 `String _lastCollectedId`
2. `onUndo` 回调中调用 `collectionDao.deleteCollection(id)` 删除

### 0.6 导航不一致 ✅

**严重度**: P0-Medium
**问题**: `ThemeScreen`、`ReminderScreen`、`PrivacyPolicyScreen` 在 GoRouter 注册了路由但实际用 `Navigator.push(MaterialPageRoute(...))`

**修复**:
1. `SettingsScreen` 中将 `Navigator.push(MaterialPageRoute(builder: (_) => ThemeScreen()))` 改为 `context.go('/theme')`
2. 同理 `reminder` → `context.go('/reminder')`，`privacy` → `context.go('/privacy')`
3. 保留 GoRouter 中的全屏路由定义 (已有 parentNavigatorKey)

#### P0 完成总结

- **flutter analyze**: `No issues found!` — 零错误零警告
- **新增文件**: `ember_theme_extension.dart`、`UI_OPTIMIZATION_PLAN.md`
- **修改文件**: `app_theme.dart`、`theme_provider.dart`、`collection_screen.dart`、`transform_selector.dart`、`heat_map_calendar.dart`、`calendar_screen.dart`、`onboarding.dart`、`submit_button.dart`、`throw_in_screen.dart`、`settings_screen.dart`、`reminder_screen.dart`
- **删除文件**: `collection_card.dart`、`destroy_style_picker.dart`
- **完成日期**: 2026-04-30

---

## P1: 设计规范对齐 ✅ 全部完成

### 1.1 底部导航 → 玻璃拟态 ✅

**DESIGN.md §6.2 要求**: 深色半透明玻璃 + 轻微模糊 + 细线性图标 + 余烬橙高亮 + 切换动画

**当前**: Material `NavigationBar`，无模糊/发光/自定义图标

**方案**: 创建 `lib/core/widgets/ember_navigation_bar.dart`
- `ClipRRect` + `BackdropFilter(sigma: 20)` 毛玻璃
- `Colors.black.withOpacity(0.6)` 半透明背景
- 自定义 SVG 细线图标 (或 phosphor_flutter)
- 选中态: `primary` 色图标 + `AnimatedContainer` 上浮 2px + 光晕 `BoxShadow`
- 顶部 0.5px 高光线 `primary.withOpacity(0.1)`

### 1.2 输入区域 → 情绪容器 ✅

**DESIGN.md §7.1 要求**: 深色半透明 + 暗色纹理 + 极细高光 + 聚焦余烬橙微光

**当前**: 无边框 `TextField` 在简单 `Container` 中

**方案**: 重构 `TextInputArea` 为 `EmotionContainer`
- `AnimatedContainer` + 聚焦态动画
- 边框: `border: Border.all(color: focused ? primary.withOpacity(0.4) : border, width: 0.5)`
- 光晕: `boxShadow: focused ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 16)] : []`
- 光标: `cursorColor: colorScheme.primary`
- 可选: 内部噪点纹理 `CustomPaint`

### 1.3 色彩系统补齐 → (已合入 P0.1)

### 1.4 卡片系统 → 玻璃拟态 ✅

**DESIGN.md §8.3 要求**: 半透明 + 细线边框 + 柔和阴影 + 边缘微高光

**当前**: `CardTheme` 纯色 + 0.5px 边框

**方案**: 创建 `lib/core/widgets/ember_card.dart`
- `EmberCard({required Widget child, bool glass = false})`
- 非玻璃态: `surfaceVariant` 填充 + 边框 + 下方阴影
- 玻璃态: `surfaceVariant.withOpacity(0.5)` + `BackdropFilter` + 边框 + 阴影
- 顶部/左侧微弱高光: `LinearGradient` 叠加

### 1.5 页面转场 ✅

**DESIGN.md §9.3 要求**: 淡入淡出 + 轻微位移 + 光晕过渡

**当前**: 默认 Material 右滑

**方案**: GoRouter `pageBuilder` 自定义
- Tab 内: `FadeTransition` + `SlideTransition(offset: 0.02)` 300ms
- 全屏: `FadeTransition` 300ms
- BottomSheet: `Curves.easeOutCubic` 展开

#### P1 完成总结

- **flutter analyze**: `No issues found!` — 零错误零警告
- **新增文件**: `ember_navigation_bar.dart`、`ember_card.dart`
- **修改文件**: `main_shell.dart`（替换 NavigationBar + 自定义转场）、`text_input_area.dart`（→情绪容器）、`collection_screen.dart`（导入 EmberCard）
- **完成日期**: 2026-05-01

---

## P2: 动效与氛围增强 ✅ 全部完成

### 2.1 首页背景余烬呼吸光 ✅
- `EmberBreathBackground` 组件
- `RadialGradient` 中心色在 `primary.withOpacity(0.03~0.085)` 间脉动
- 6 秒周期, `Curves.easeInOut`，双层（大光晕 + 内核高光）

### 2.2 首页漂浮粒子 ✅
- `EmberParticleField` CustomPainter
- 12 粒子, 1~3px, 透明度 0.05-0.15
- 缓慢上浮 + 正弦摆动，`RepaintBoundary` 隔离
- 固定 seed 避免布局跳变，淡入淡出避免硬切

### 2.3 输入聚焦动效 ✅
- 容器 `AnimatedScale(scale: 1.008)` 微放大（已在 P1.2 完成）
- 边框色过渡（已在 P1.2）
- 余烬色光标（已在 P1.2）

### 2.4 按钮仪式动效 ✅
- 常驻低亮光晕 `primary.12`
- 按下: `scale: 0.96` + 光晕消失
- 释放: 600ms 光晕扩散动画（半径 0→40，透明度弹射后消散）

### 2.5 标签微交互 ✅
- IntensitySlider thumb 大小随烈度值动态变化：1档 r=8，5档 r=12
- overlay 波纹半径同步放大

### 2.6 空状态呼吸光 ✅
- `EmberEmptyState` 组件：中央余烬橙光点呼吸 + 图标微缩放 + 克制文案
- 已替换：`EmptyCollection`（收藏馆）、`CalendarScreen`（本月概览 + 词云）

#### P2 完成总结

- **flutter analyze**: `No issues found!` — 零错误零警告
- **新增文件**: `ember_breath_background.dart`、`ember_particle_field.dart`、`ember_empty_state.dart`
- **修改文件**: `throw_in_screen.dart`（嵌入呼吸光+粒子）、`submit_button.dart`（光晕扩散动效）、`intensity_slider.dart`（thumb 随值变化）、`empty_collection.dart`（替换为 EmberEmptyState）、`calendar_screen.dart`（两处空状态替换）
- **完成日期**: 2026-05-01

---

## P3: 高级打磨 ✅ 全部完成

### 3.1 销毁方式卡片动态预览 ✅
- 新建 `lib/features/throw_in/widgets/destroy_style_preview.dart`
- 4 种微型 Canvas 动画预览 (火光/水波/烟雾/星尘)
- `_BurnPreviewPainter`：火光粒子上飘 + 核心亮点闪烁
- `_SinkPreviewPainter`：3 圈涟漪错峰扩散
- `_ScatterPreviewPainter`：6 团烟雾上飘 + 模糊光晕
- `_AshPreviewPainter`：8 颗星尘闪烁 + 十字星芒
- 嵌入 `destroy_time_picker.dart` 替换 emoji 为动画预览

### 3.2 AI 转化灰烬聚合文字 ✅
- 新建 `lib/features/transform/widgets/ash_text_reveal.dart`
- `AshTextReveal` 组件：35 颗粒子 3 阶段动画
  - 聚合（0~40%）：随机位置→文字区域
  - 驻留（40~70%）：与渐现文字共存
  - 消融（70~100%）：散开淡出
- Text 区域 opacity 30%~60% 渐现
- 嵌入 `transform_result_card.dart`，组件改为 StatefulWidget

### 3.3 收藏馆卡片升级 ✅
- 新建 `lib/features/transform/widgets/collection_card_entrance.dart`
- `CollectionCardEntrance`：FadeTransition + ScaleTransition(0.95→1.0)
- 延迟错峰：index * 50ms，最长 400ms
- `_TypedCollectionCard` 添加暗金细线顶部装饰 + 烧焦纸边底部 gradient
- `emberGold.withValues(alpha: 0.25)` 顶部渐变线
- `emberGold.withValues(alpha: 0.06)` 底部烧焦渐变

### 3.4 日历增强 ✅
- 新建 `lib/features/review/widgets/animated_heat_map_calendar.dart`
- `AnimatedHeatMapCalendar`：双 AnimationController
  - `revealController`(1s)：月份切换时错峰浮现
  - `pulseController`(3s repeat)：高烈度(count≥4)日期闪烁
- `HeatMapCalendarPainter` 新增 `revealProgress`/`pulseValue` 参数
- 日期格子：错峰 stagger + scale 缩放 + alpha 渐现
- `calendar_screen.dart` 热力图包裹 AnimatedSwitcher(300ms) 月份切换淡入淡出

### 3.5 词云增强 ✅
- 新建 `lib/features/review/widgets/animated_word_cloud.dart`
- `AnimatedWordCloud`：4s repeat AnimationController 驱动
- `WordCloudPainter` 新增 `revealProgress`/`glowPulse` 参数
- 词语烟雾浮现：错峰 stagger + easeOutCubic 透明度
- 高频词(ratio>0.7)微光：sin 脉动 alpha + blur 光晕
- `calendar_screen.dart` 词云改用 AnimatedWordCloud

#### P3 完成总结

- **flutter analyze**: `No issues found!` — 零错误零警告
- **新增文件**: `destroy_style_preview.dart`、`ash_text_reveal.dart`、`collection_card_entrance.dart`、`animated_heat_map_calendar.dart`、`animated_word_cloud.dart`
- **修改文件**: `destroy_time_picker.dart`、`transform_result_card.dart`、`collection_screen.dart`、`heat_map_calendar.dart`、`calendar_screen.dart`、`word_cloud_painter.dart`
- **完成日期**: 2026-05-01

---

## 依赖关系

```
P0 (Bug修复)
 │
 ├── P0.1 (ThemeExtension) ──→ P1.1 + P1.2 + P1.4
 │
 ├── P0.2 (主题持久化) ──→ P1.1
 │
 └── P0.6 (导航统一) ──→ P1.5
                              │
                              └── P2 (动效) ──→ P3 (高级打磨)
```

## 工时预估

| 优先级 | 工作日 |
|--------|--------|
| P0 | 1 |
| P1 | 3 |
| P2 | 3 |
| P3 | 3 |
| **合计** | **~10** |
