import 'package:flutter/material.dart';

/// 紧急伪装：假计算器
/// 摇一摇触发后，全屏切换为一个看起来正常的计算器界面
/// 按住"="键 3 秒可退出伪装
class FakeCalculator extends StatefulWidget {
  const FakeCalculator({super.key});

  @override
  State<FakeCalculator> createState() => _FakeCalculatorState();
}

class _FakeCalculatorState extends State<FakeCalculator> {
  String _display = '0';
  String _operand = '';
  double? _firstValue;
  String _operator = '';
  bool _shouldResetDisplay = false;

  // 退出伪装的长按计时
  bool _isHoldingEquals = false;

  void _onDigit(String digit) {
    setState(() {
      if (_shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display = _display == '0' ? digit : _display + digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_firstValue != null && _operator.isNotEmpty && !_shouldResetDisplay) {
        _calculate();
      }
      _firstValue = double.tryParse(_display) ?? 0;
      _operator = op;
      _operand = _display;
      _shouldResetDisplay = true;
    });
  }

  void _calculate() {
    if (_firstValue == null || _operator.isEmpty) return;
    final second = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+':
        result = _firstValue! + second;
        break;
      case '-':
        result = _firstValue! - second;
        break;
      case '×':
        result = _firstValue! * second;
        break;
      case '÷':
        result = second == 0 ? 0 : _firstValue! / second;
        break;
      default:
        return;
    }
    setState(() {
      _display = _formatResult(result);
      _firstValue = null;
      _operator = '';
      _operand = '';
      _shouldResetDisplay = true;
    });
  }

  String _formatResult(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _firstValue = null;
      _operator = '';
      _operand = '';
      _shouldResetDisplay = false;
    });
  }

  void _onToggleSign() {
    if (_display == '0') return;
    setState(() {
      _display = _display.startsWith('-')
          ? _display.substring(1)
          : '-$_display';
    });
  }

  void _onPercent() {
    final v = double.tryParse(_display) ?? 0;
    setState(() {
      _display = _formatResult(v / 100);
      _shouldResetDisplay = true;
    });
  }

  void _onDecimal() {
    if (_display.contains('.')) return;
    setState(() {
      _display += '.';
    });
  }

  void _onEqualsLongPressStart() {
    _isHoldingEquals = true;
    // 按住 = 3秒退出伪装
    Future.delayed(const Duration(seconds: 3), () {
      if (_isHoldingEquals && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onEqualsLongPressEnd() {
    _isHoldingEquals = false;
  }

  @override
  Widget build(BuildContext context) {
    // 使用标准计算器配色，完全不像情绪App
    const bgColor = Color(0xFF1C1C1E);
    const displayColor = Color(0xFF000000);
    const numBtnColor = Color(0xFF333333);
    const opBtnColor = Color(0xFFFF9F0A);
    const funcBtnColor = Color(0xFFA5A5A5);
    const textColor = Colors.white;

    return PopScope(
      canPop: false, // 禁止返回键退出
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // 显示屏
              Expanded(
                child: Container(
                  color: displayColor,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.fromLTRB(16, 0, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_operand.isNotEmpty || _operator.isNotEmpty)
                        Text(
                          '$_operand $_operator',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 20),
                        ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          _display,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 按键区
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildRow([
                      _CalcBtn('AC', funcBtnColor, textColor, _onClear),
                      _CalcBtn('±', funcBtnColor, textColor, _onToggleSign),
                      _CalcBtn('%', funcBtnColor, textColor, _onPercent),
                      _CalcBtn('÷', opBtnColor, textColor, () => _onOperator('÷')),
                    ]),
                    _buildRow([
                      _CalcBtn('7', numBtnColor, textColor, () => _onDigit('7')),
                      _CalcBtn('8', numBtnColor, textColor, () => _onDigit('8')),
                      _CalcBtn('9', numBtnColor, textColor, () => _onDigit('9')),
                      _CalcBtn('×', opBtnColor, textColor, () => _onOperator('×')),
                    ]),
                    _buildRow([
                      _CalcBtn('4', numBtnColor, textColor, () => _onDigit('4')),
                      _CalcBtn('5', numBtnColor, textColor, () => _onDigit('5')),
                      _CalcBtn('6', numBtnColor, textColor, () => _onDigit('6')),
                      _CalcBtn('-', opBtnColor, textColor, () => _onOperator('-')),
                    ]),
                    _buildRow([
                      _CalcBtn('1', numBtnColor, textColor, () => _onDigit('1')),
                      _CalcBtn('2', numBtnColor, textColor, () => _onDigit('2')),
                      _CalcBtn('3', numBtnColor, textColor, () => _onDigit('3')),
                      _CalcBtn('+', opBtnColor, textColor, () => _onOperator('+')),
                    ]),
                    _buildRow([
                      _CalcBtn('0', numBtnColor, textColor, () => _onDigit('0'),
                          wide: true),
                      _CalcBtn('.', numBtnColor, textColor, _onDecimal),
                      _LongPressCalcBtn(
                        '=', opBtnColor, textColor,
                        onTap: _calculate,
                        onLongPressStart: _onEqualsLongPressStart,
                        onLongPressEnd: _onEqualsLongPressEnd,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons,
      ),
    );
  }
}

/// 计算器按钮
class _CalcBtn extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool wide;

  const _CalcBtn(this.label, this.bgColor, this.textColor, this.onTap,
      {this.wide = false});

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.of(context).size.width - 56) / 4;
    return SizedBox(
      width: wide ? size * 2 + 8 : size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(size / 2),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: wide ? 28 : 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 支持长按的 = 按钮（长按3秒退出伪装）
class _LongPressCalcBtn extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _LongPressCalcBtn(
    this.label,
    this.bgColor,
    this.textColor, {
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.of(context).size.width - 56) / 4;
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(size / 2),
          child: GestureDetector(
            onTap: onTap,
            onLongPressStart: (_) => onLongPressStart(),
            onLongPressEnd: (_) => onLongPressEnd(),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
