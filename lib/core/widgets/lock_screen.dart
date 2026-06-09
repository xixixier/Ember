import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';

/// 应用锁屏页面
/// 支持生物识别 + 6位数字密码两种解锁方式
class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onUnlocked;
  const LockScreen({super.key, this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final List<String> _pinDigits = [];
  bool _isVerifying = false;
  String? _errorMessage;
  bool _showBiometric = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final biometricEnabled = await PinService.instance.isBiometricEnabled();
    final canAuth = await AuthService.instance.canAuthenticate();
    if (biometricEnabled && canAuth && mounted) {
      setState(() => _showBiometric = true);
      // 自动触发生物识别
      _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    final success = await AuthService.instance.authenticate();
    if (success && mounted) {
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _verifyPin() async {
    if (_pinDigits.length != 6) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final pin = _pinDigits.join();
    final success = await PinService.instance.verifyPin(pin);

    if (!mounted) return;

    if (success) {
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _errorMessage = '密码错误，请重试';
        _pinDigits.clear();
        _isVerifying = false;
      });
    }
  }

  void _onDigitTap(String digit) {
    if (_isVerifying || _pinDigits.length >= 6) return;
    setState(() {
      _pinDigits.add(digit);
      _errorMessage = null;
    });
    if (_pinDigits.length == 6) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_pinDigits.isEmpty) return;
    setState(() => _pinDigits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              // 图标
              Icon(Icons.local_fire_department,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('余烬',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text(_showBiometric ? '请验证身份' : '请输入密码',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 40),
              // PIN 圆点指示器
              _PinIndicator(
                count: _pinDigits.length,
                total: 6,
                error: _errorMessage,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_errorMessage!,
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 13)),
                ),
              const Spacer(),
              // 生物识别按钮
              if (_showBiometric)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    onPressed: _authenticateBiometric,
                    icon: const Icon(Icons.fingerprint, size: 40),
                    color: theme.colorScheme.primary,
                  ),
                ),
              // 数字键盘
              _NumericPad(
                onDigit: _onDigitTap,
                onDelete: _onDelete,
                isVerifying: _isVerifying,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// PIN 码圆点指示器
class _PinIndicator extends StatelessWidget {
  final int count;
  final int total;
  final String? error;

  const _PinIndicator({required this.count, required this.total, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final filled = index < count;
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? theme.colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: error != null
                  ? theme.colorScheme.error
                  : filled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

/// 数字键盘
class _NumericPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool isVerifying;

  const _NumericPad({
    required this.onDigit,
    required this.onDelete,
    required this.isVerifying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digitStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((d) => _DigitButton(
                          digit: d,
                          style: digitStyle!,
                          onTap: isVerifying ? null : onDigit,
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 72, height: 72), // 空位
                _DigitButton(
                  digit: '0',
                  style: digitStyle!,
                  onTap: isVerifying ? null : onDigit,
                ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton(
                    onPressed: isVerifying ? null : onDelete,
                    icon: Icon(Icons.backspace_outlined,
                        color: theme.colorScheme.onSurfaceVariant, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个数字按钮
class _DigitButton extends StatelessWidget {
  final String digit;
  final TextStyle style;
  final ValueChanged<String>? onTap;

  const _DigitButton({
    required this.digit,
    required this.style,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap?.call(digit),
          borderRadius: BorderRadius.circular(36),
          child: Center(child: Text(digit, style: style)),
        ),
      ),
    );
  }
}
