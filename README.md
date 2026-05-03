# Ember（余烬）—— 负面情绪释放工具

<p align="center">
  <img src="assets/icon/icon.png" width="128" alt="Ember App Icon" />
</p>

<p align="center">
  <a href="https://github.com/LiDonghao1120/Ember/releases">
    <img src="https://img.shields.io/github/v/release/LiDonghao1120/Ember?color=orange" alt="Release" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter" />
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/platform-Android-brightgreen" alt="Platform" />
</p>

<p align="center">
  <i>把情绪写下来，让它在火焰中消散。</i>
</p>

---

## 📱 是什么

Ember 是一款**本地优先**的负面情绪释放工具。你把不想留存的文字写进 App，Ember 会将其转化为诗意的表达，然后以你选择的仪式将其「销毁」——不保存原文，不留痕迹。

> 核心理念：**书写即释放，转化即疗愈，销毁即新生。**

---

## ✨ 功能特性

### 🗂 五大模块

| 模块 | 功能 |
|------|------|
| **投放（ThrowIn）** | 文字/语音输入情绪，选择情绪类型与烈度，AI 转化为诗意表达 |
| **收藏（Collection）** | 浏览转化收藏馆，4 种卡片风格，左滑销毁 |
| **待毁（Pending）** | 查看所有等待销毁的情绪条目，实时倒计时，支持暂缓/立即销毁 |
| **回望（Review）** | 情绪日历热力图 / 周报 / 词云 / 年度情绪年鉴 |
| **我的（Settings）** | 应用锁 / 紧急伪装（摇一摇→计算器）/ 4 套主题 / 定时提醒 |

### 🎨 设计亮点

- **本地优先**：所有数据存本地 SQLite，不上传云端
- **不存原文**：原始情绪文字不保存，只保留转化结果
- **主题系统**：4 套完整主题（暗色 / 暖灰 / 深蓝 / 纯黑），即时切换
- **动效系统**：余烬呼吸光背景、粒子场、灰烬聚合文字、卡片错峰入场、全屏倒计时粒子等精细动效
- **全屏倒计时**：销毁前的沉浸式倒计时体验，大号数字 + 火焰粒子动画
- **应用锁**：生物识别 + 6 位密码，保护你的私密空间
- **紧急伪装**：摇一摇手机，瞬间切换为计算器界面

---

## 📸 截图

> 待应用运行截图补充...

---

## 🛠 技术栈

| 类别 | 技术 |
|------|------|
| **框架** | Flutter 3.x |
| **语言** | Dart |
| **本地数据库** | SQLite（Drift / sqflite） |
| **状态管理** | Riverpod |
| **路由** | GoRouter |
| **动画** | Flutter 原生动画（CustomPainter / AnimationController） |
| **最低支持** | Android SDK 21+ |

---

## 🚀 安装方式

### 方式一：下载 Release APK

前往 [Releases](https://github.com/LiDonghao1120/Ember/releases) 页面，下载最新 `app-release.apk`，安装到 Android 手机。

### 方式二：自行构建

```bash
# 克隆仓库
git clone https://github.com/LiDonghao1120/Ember.git
cd Ember/ember

# 获取依赖
flutter pub get

# 构建 Release APK
flutter build apk --release

# APK 输出路径
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 项目结构

```
ember/
├── lib/
│   ├── core/           # 核心层（主题/常量/工具/Widget）
│   ├── data/           # 数据层（Database / DAO / Service）
│   ├── features/       # 功能模块（按功能拆分）
│   │   ├── throw_in/  # 投放页
│   │   ├── transform/  # 转化页
│   │   ├── destroy/    # 销毁动画
│   │   ├── review/     # 回望（日历/周报/词云/年鉴）
│   │   └── settings/   # 设置页
│   └── main.dart
├── android/            # Android 平台配置
├── assets/             # 资源文件（模板 JSON / 图标）
└── pubspec.yaml
```

---

## 🔒 隐私说明

Ember **不会**将任何个人数据上传到云端：

- 所有情绪记录仅存储在本地 SQLite 数据库
- 转化引擎使用本地模板，无需联网
- 无广告、无跟踪、无数据收集
- 详见应用内《隐私政策》页面

---

## 📝 开发计划

- [x] Phase 1：核心骨架 + 投放 + 销毁调度
- [x] Phase 2：4 转化引擎 + 4 销毁动画 + 语音 + 收藏
- [x] Phase 3：日历热力图 + 周报 + 词云 + 收藏馆 + 年度年鉴
- [x] Phase 4：应用锁 + 紧急伪装 + 主题切换 + 定时提醒 + 数据导出 + 引导页
- [x] Phase 5：UI 精修（P0/P1/P2/P3 全部完成）
- [x] Phase 6：待毁 Tab + 全屏倒计时 + 全面 UI 打磨
- [ ] iOS 平台适配（待赞助 Mac 设备 💸）

---

## 📄 开源协议

[MIT License](LICENSE)

---

## 💬 关于

由 [@LiDonghao1120](https://github.com/LiDonghao1120) 开发维护。
如有问题或建议，欢迎提交 [Issue](https://github.com/LiDonghao1120/Ember/issues)。
