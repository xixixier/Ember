import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/main_shell.dart';
import 'core/widgets/lock_screen.dart';
import 'core/widgets/onboarding.dart';
import 'core/services/pin_service.dart';
import 'core/providers/database_provider.dart';
import 'data/services/destroy_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 捕获并显示所有 Flutter 框架错误
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  // 自定义错误界面，防止黑屏卡死
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red.shade900,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FATAL ERROR',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.yellow, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                details.stack.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 初始化销毁调度（WorkManager）
  await DestroyScheduler.init();
  // 启动时立即检查一次过期条目
  await DestroyScheduler.checkNow();

  runApp(const ProviderScope(child: EmberApp()));
}

class EmberApp extends ConsumerStatefulWidget {
  const EmberApp({super.key});

  @override
  ConsumerState<EmberApp> createState() => _EmberAppState();
}

class _EmberAppState extends ConsumerState<EmberApp> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isInitialized = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initApp() async {
    // 检查是否需要引导
    final onboardingDone = await OnboardingScreen.isDone();
    final lockEnabled = await PinService.instance.isLockEnabled();

    if (!mounted) return;

    setState(() {
      _showOnboarding = !onboardingDone;
      _isLocked = lockEnabled;
      _isInitialized = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从后台回到前台时，检查是否需要锁屏
    if (state == AppLifecycleState.resumed) {
      _checkLockOnResume();
    }
  }

  Future<void> _checkLockOnResume() async {
    final lockEnabled = await PinService.instance.isLockEnabled();
    if (lockEnabled && !_isLocked && mounted) {
      setState(() => _isLocked = true);
    }
  }

  void _onUnlocked() {
    setState(() => _isLocked = false);
  }

  void _onOnboardingDone() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    // 预热数据库
    ref.watch(databaseProvider);
    final theme = ref.watch(themeDataProvider);

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 始终使用 MaterialApp.router 作为根，保证路由和状态不丢失
    return MaterialApp.router(
      title: 'Ember',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: MainShell.router,
      builder: (context, child) {
        return Stack(
          children: [
            // ignore: use_null_aware_elements
            if (child != null) child,
            // 引导页 Overlay
            if (_showOnboarding)
              Positioned.fill(
                child: OnboardingScreen(onDone: _onOnboardingDone),
              ),
            // 应用锁 Overlay (若引导已完成且处于锁屏状态)
            if (!_showOnboarding && _isLocked)
              Positioned.fill(
                child: LockScreen(onUnlocked: _onUnlocked),
              ),
          ],
        );
      },
    );
  }
}

