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

    // 引导页
    if (_showOnboarding) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: _OnboardingWrapper(onDone: _onOnboardingDone),
      );
    }

    // 应用锁
    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: _LockWrapper(onUnlocked: _onUnlocked),
      );
    }

    // 正常主界面
    return MaterialApp.router(
      title: 'Ember',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: MainShell.router,
    );
  }
}

/// 引导页包装器，完成时回调
class _OnboardingWrapper extends StatefulWidget {
  final VoidCallback onDone;

  const _OnboardingWrapper({required this.onDone});

  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    // 监听引导页完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToOnboarding();
    });
  }

  Future<void> _navigateToOnboarding() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
    if (result == true) {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 锁屏包装器，解锁后回调
class _LockWrapper extends StatefulWidget {
  final VoidCallback onUnlocked;

  const _LockWrapper({required this.onUnlocked});

  @override
  State<_LockWrapper> createState() => _LockWrapperState();
}

class _LockWrapperState extends State<_LockWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToLock();
    });
  }

  Future<void> _navigateToLock() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LockScreen()),
    );
    if (result == true) {
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
