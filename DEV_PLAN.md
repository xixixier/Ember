# Ember（余烬）— 开发规划文档

> 项目代号「Ember（余烬）」：你把情绪丢进来，它燃烧、转化、然后消散。
> 目标平台：Android only
> 技术栈：Flutter + SQLite(Drift) + Riverpod + Lottie

---

## 一、数据库 Schema

### entries（情绪条目）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT PK | UUID |
| raw_text | TEXT | 原文，销毁后置空 |
| emotion_tag | TEXT | 愤怒/沮丧/焦虑/崩溃/烦躁/自定义 |
| target_tag | TEXT | 工作/感情/自己/社交/陌生人/这个世界/不指定 |
| intensity | INT | 1-5 |
| destroy_at | INT | unix timestamp，计划销毁时间 |
| destroy_style | TEXT | burn/sink/scatter/ash |
| voice_path | TEXT | 语音临时文件路径，销毁时删除 |
| is_destroyed | BOOL | 默认 false |
| created_at | INT | 创建时间 |
| destroyed_at | INT | 实际销毁时间 |

### collections（转化收藏）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT PK | UUID |
| source_entry_id | TEXT | 可空，原文已删 |
| type | TEXT | shakespeare/haiku/soup/art |
| content | TEXT | 转化后的文字 |
| image_path | TEXT | 抽象画本地路径 |
| emotion_tag | TEXT | 情绪标签 |
| intensity | INT | 烈度 |
| created_at | INT | 收藏时间 |

### keywords（词频统计）
| 字段 | 类型 | 说明 |
|------|------|------|
| word | TEXT PK | 关键词 |
| count | INT | 出现次数 |
| emotion_tag | TEXT | 关联情绪 |
| month | TEXT | "2026-04" 格式 |
| updated_at | INT | 更新时间 |

### daily_stats（日统计缓存）
| 字段 | 类型 | 说明 |
|------|------|------|
| date | TEXT PK | "2026-04-29" |
| total_count | INT | 当天吐槽次数 |
| intensity_sum | INT | 烈度总和 |
| top_emotion | TEXT | 主要情绪 |
| top_target | TEXT | 高杀伤对象 |

### 销毁策略
- entries.raw_text + voice_path 到期硬删除，仅保留 emotion_tag / intensity / target_tag
- keywords 在写入时提取、销毁时不删除（词频是脱敏统计）

---

## 二、项目目录结构

```
lib/
  main.dart
  core/
    theme/
      app_theme.dart          -- 4套主题定义
      color_tokens.dart       -- 色彩Token
      typography.dart         -- 字体系统
    constants/
      emotions.dart           -- 情绪枚举+映射
      targets.dart            -- 攻击对象枚举
      destroy_styles.dart     -- 销毁方式枚举
    utils/
      id_generator.dart       -- UUID生成
      timestamp.dart          -- 时间戳工具
    widgets/
      main_shell.dart         -- Tab导航壳
      lock_screen.dart        -- 应用锁屏
      fake_calculator.dart    -- 伪装计算器
      onboarding.dart         -- 引导页
    services/
      auth_service.dart       -- 生物识别
      pin_service.dart        -- 密码锁
      shake_detector.dart     -- 摇一摇检测
  data/
    database/
      app_database.dart       -- SQLite初始化+迁移
      daos/
        entry_dao.dart
        collection_dao.dart
        keyword_dao.dart
        daily_stats_dao.dart
    models/
      entry.dart
      collection.dart
      daily_stats.dart
    services/
      destroy_scheduler.dart  -- 销毁调度(WorkManager)
      speech_service.dart     -- 语音识别封装
      reminder_service.dart   -- 定时提醒
      export_service.dart     -- 数据导出
    transform_templates/
      shakespeare_templates.json
      haiku_templates.json
      dark_soup_templates.json
      art_mapping.json
  features/
    throw_in/                 -- Tab1: 投放
      throw_in_screen.dart
      throw_in_controller.dart
      widgets/
        guide_text.dart
        text_input_area.dart
        emotion_picker.dart
        target_picker.dart
        intensity_slider.dart
        destroy_time_picker.dart
        voice_input_button.dart
        submit_button.dart
    transform/                -- Tab2: 转化收藏
      collection_screen.dart
      engines/
        transform_engine.dart       -- 抽象接口
        shakespeare_engine.dart
        haiku_engine.dart
        dark_soup_engine.dart
        abstract_art_engine.dart
      widgets/
        transform_selector.dart
        transform_result_card.dart
        collection_card.dart
        type_filter_bar.dart
        empty_collection.dart
        collect_snackbar.dart
    destroy/                  -- 销毁动画
      animations/
        destroy_animation.dart      -- 抽象Widget
        burn_animation.dart
        sink_animation.dart
        scatter_animation.dart
        ash_animation.dart
      widgets/
        destroy_style_picker.dart
        destroy_countdown.dart
        swipe_to_burn.dart
    review/                   -- Tab3: 回望
      screens/
        calendar_screen.dart
        weekly_report_screen.dart
        annual_report_screen.dart
      providers/
        calendar_provider.dart
        wordcloud_provider.dart
      services/
        weekly_report_service.dart
        annual_report_service.dart
      widgets/
        heat_map_calendar.dart
        day_detail_sheet.dart
        week_vs_week_card.dart
        word_cloud_painter.dart
    settings/                 -- Tab4: 我的
      settings_screen.dart
      screens/
        theme_screen.dart
        reminder_screen.dart
```

---

## 三、Phase 详细拆解

### Phase 1：骨架与投放

#### 1.1 项目初始化
| # | 任务 | 具体操作 |
|---|------|----------|
| 1.1.1 | 创建 Flutter 项目 | `flutter create ember --org com.novcloud --platforms android` |
| 1.1.2 | 添加核心依赖 | drift, drift_flutter, path_provider, uuid, flutter_riverpod, go_router, google_fonts |
| 1.1.3 | 添加动画依赖 | lottie, flutter_animate |
| 1.1.4 | 添加平台依赖 | speech_to_text, workmanager, flutter_local_notifications, local_auth |
| 1.1.5 | 配置 Android | minSdk 24, targetSdk 34; 权限: RECORD_AUDIO, USE_BIOMETRIC |
| 1.1.6 | 创建目录结构 | 按 schema 创建 core/ data/ features/ |

#### 1.2 数据层设计
| # | 任务 | 关键实现 |
|---|------|----------|
| 1.2.1 | Entry 模型 | drift @DataClassName，字段见Schema |
| 1.2.2 | Collection 模型 | type 枚举：shakespeare/haiku/soup/art |
| 1.2.3 | DailyStats 模型 | 日期字符串作主键 |
| 1.2.4 | Keyword 模型 | 复合主键：(word, month) |
| 1.2.5 | EntryDao | CRUD + watchPendingEntries() + destroyRawText(id) |
| 1.2.6 | CollectionDao | CRUD + watchByType(type) |
| 1.2.7 | KeywordDao | upsertKeyword() + getTopByMonth() |
| 1.2.8 | DailyStatsDao | incrementDay() + getMonthStats() |
| 1.2.9 | AppDatabase | 汇总DAO，LazyDatabase初始化 |

#### 1.3 主题与导航
| # | 任务 | 关键实现 |
|---|------|----------|
| 1.3.1 | 色彩Token | 4套：暗色/暖灰/深蓝/纯黑 |
| 1.3.2 | 字体系统 | 引导语: Playfair Display, 正文: Inter/Noto Sans SC |
| 1.3.3 | AppTheme | ThemeData工厂，统一 borderRadius=12, elevation=0 |
| 1.3.4 | Emotion枚举 | anger/depression/anxiety/breakdown/irritation/custom + emoji |
| 1.3.5 | Target枚举 | work/love/self/social/stranger/world/none |
| 1.3.6 | DestroyStyle枚举 | burn/sink/scatter/ash |
| 1.3.7 | GoRouter | 4个ShellRoute Tab路由 |
| 1.3.8 | MainShell | NavigationBar + 4 Tab (🔥✨📊⚙) |
| 1.3.9 | ProviderScope | 注册Database/Theme Provider |

#### 1.4 投放页 UI
| # | 任务 | 关键实现 |
|---|------|----------|
| 1.4.1 | 投放主页面 | 引导语→输入区→元数据按钮行→「扔进去」 |
| 1.4.2 | 引导语 | 20+句每日随机，SharedPreferences缓存 |
| 1.4.3 | 文本输入 | TextField无边框、大字号、maxLines=null |
| 1.4.4 | 情绪选择器 | BottomSheet, 4×2 Grid, 6预设+自定义 |
| 1.4.5 | 对象选择器 | BottomSheet, FlowRow Chip, 7选项 |
| 1.4.6 | 烈度滑动条 | 5档离散Slider，暖黄→深红渐变 |
| 1.4.7 | 销毁时间 | BottomSheet, 5 Chip (立刻/6h/24h/3天/7天) |
| 1.4.8 | 语音输入 | 按住录音, SpeechToText流式识别 |
| 1.4.9 | 「扔进去」按钮 | 大圆角全宽，按下缩放动画 |
| 1.4.10 | 提交逻辑 | 校验→写DB→更新stats→提取关键词→启动倒计时 |

#### 1.5 销毁调度
| # | 任务 | 关键实现 |
|---|------|----------|
| 1.5.1 | WorkManager | 每15min检查，软删除到期条目 |
| 1.5.2 | 软删除 | raw_text='', voice_path删除, is_destroyed=1 |
| 1.5.3 | 立刻销毁 | 选"立刻"时直接调用destroyEntry |

---

### Phase 2：转化与消散

#### 2.1 转化引擎
| # | 任务 | 关键实现 |
|---|------|----------|
| 2.1.1 | TransformEngine接口 | 抽象类，transform(text, emotion, intensity) |
| 2.1.2 | 莎翁剧场 | 本地词典映射+50+句式模板 |
| 2.1.3 | 俳句生成 | 中文分词→3核心词→5-7-5模板 |
| 2.1.4 | 反向鸡汤 | (emotion, intensity)检索100+模板 |
| 2.1.5 | 抽象画 | emotion→色相, intensity→饱和度, CustomPainter |
| 2.1.6 | 模板数据 | JSON文件 |
| 2.1.7 | 转化选择面板 | BottomSheet, 4横向卡片 |
| 2.1.8 | 转化结果卡片 | 展示+收藏按钮 |

#### 2.2 销毁仪式动画
| # | 任务 | 关键实现 |
|---|------|----------|
| 2.2.1 | 动画框架 | 抽象Widget + onComplete回调 |
| 2.2.2 | 焚🔥 | Lottie，intensity控制速度 |
| 2.2.3 | 沉🌊 | AnimatedBuilder + Transform.translate |
| 2.2.4 | 散🌬️ | 粒子系统 |
| 2.2.5 | 烬✨ | Lottie + 自定义粒子 |
| 2.2.6 | 方式选择 | 4选项卡片+缩略预览 |
| 2.2.7 | 3秒确认 | 环形倒计时+撤销 |
| 2.2.8 | 滑动即焚 | Dismissible组件 |

#### 2.3 语音与收藏
| # | 任务 | 关键实现 |
|---|------|----------|
| 2.3.1 | 语音服务 | speech_to_text封装 |
| 2.3.2 | 录音交互 | 长按录音+波形动画 |
| 2.3.3 | 收藏逻辑 | 不存原文，只存转化结果 |
| 2.3.4 | 收藏Toast | SnackBar + 5秒撤销 |

---

### Phase 3：回望与统计

#### 3.1 情绪日历热力图
- Riverpod Provider查daily_stats
- TableCalendar + 自定义CalendarBuilders
- 点击某天BottomSheet（不展示原文）

#### 3.2 每周情绪报告
- 本地聚合计算5指标
- 一句话模板化生成
- fl_chart趋势折线
- 本周vs上周对比

#### 3.3 情绪词云
- CustomPainter螺旋布局
- 词频→字号，emotion→颜色
- 点击显示次数不展示原句

#### 3.4 转化收藏馆
- SliverMasonryGrid瀑布流
- 4种类型卡片不同样式
- 类型筛选Chip + 空状态

#### 3.5 年度情绪年鉴
- 全年聚合
- 长滚动：封面→情绪地图→月度曲线→关键词→总结

---

### Phase 4：打磨与上架

- Android小组件（日历+快捷入口）
- 应用锁（生物识别+6位密码）
- 紧急伪装（摇一摇→计算器）
- 4套主题切换
- 定时提醒+免打扰
- 数据导出（仅统计CSV）
- 引导页+空状态文案
- 隐私政策+上架

---

## 四、依赖版本

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  drift: ^2.15.0
  drift_flutter: ^0.2.0
  go_router: ^14.0.0
  uuid: ^4.3.0
  lottie: ^3.1.0
  flutter_animate: ^4.5.0
  speech_to_text: ^7.0.0
  workmanager: ^0.5.0
  flutter_local_notifications: ^18.0.0
  local_auth: ^2.2.0
  flutter_secure_storage: ^9.2.0
  sensors_plus: ^6.0.0
  fl_chart: ^0.69.0
  google_fonts: ^6.2.0
  path_provider: ^2.1.0
  share_plus: ^9.0.0
```

## 五、风险与注意

1. 莎翁/俳句质量：纯模板可能不够惊艳，准备大量高质量模板
2. 销毁定时器可靠性：WorkManager兜底，避免后台杀进程
3. 抽象画美感：用预设风格模板+算法微调，避免程序员审美
4. 语音离线能力：部分设备不支持，需fallback提示
5. 应用审核：App Store对情绪健康类有额外要求
