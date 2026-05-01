import 'package:flutter/material.dart';
import '../../../data/services/reminder_service.dart';

/// 提醒设置页面
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 22, minute: 0);
  bool _dndEnabled = false;
  int _dndStart = 23;
  int _dndEnd = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await ReminderService.instance.isReminderEnabled();
    final time = await ReminderService.instance.getReminderTime();
    final dnd = await ReminderService.instance.getDndPeriod();

    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = time;
      _dndStart = dnd.start;
      _dndEnd = dnd.end;
      _dndEnabled = dnd.start != 0 || dnd.end != 6;
      _loading = false;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => _reminderEnabled = value);
    if (value) {
      await ReminderService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await ReminderService.instance.cancelDailyReminder();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: '选择提醒时间',
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_reminderEnabled) {
        await ReminderService.instance.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  Future<void> _toggleDnd(bool value) async {
    setState(() => _dndEnabled = value);
    if (value) {
      await ReminderService.instance.setDndPeriod(_dndStart, _dndEnd);
    } else {
      await ReminderService.instance.clearDndPeriod();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('提醒设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 每日提醒
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('每日提醒'),
                    subtitle: const Text('每天定时提醒你释放情绪'),
                    value: _reminderEnabled,
                    onChanged: _toggleReminder,
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                  if (_reminderEnabled) ...[
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('提醒时间'),
                      trailing: Text(
                        _reminderTime.format(context),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _pickTime,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 免打扰
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('免打扰模式'),
                    subtitle: const Text('在指定时段不发送提醒'),
                    value: _dndEnabled,
                    onChanged: _toggleDnd,
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                  if (_dndEnabled) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _HourPicker(
                            label: '开始',
                            selectedHour: _dndStart,
                            onChanged: (v) {
                              setState(() => _dndStart = v);
                              ReminderService.instance
                                  .setDndPeriod(_dndStart, _dndEnd);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('至',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _HourPicker(
                            label: '结束',
                            selectedHour: _dndEnd,
                            onChanged: (v) {
                              setState(() => _dndEnd = v);
                              ReminderService.instance
                                  .setDndPeriod(_dndStart, _dndEnd);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 说明
          Text(
            '提醒通知需要系统权限支持。\n如果收不到通知，请在系统设置中为余烬开启通知权限。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 小时选择器
class _HourPicker extends StatelessWidget {
  final String label;
  final int selectedHour;
  final ValueChanged<int> onChanged;

  const _HourPicker({
    required this.label,
    required this.selectedHour,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: selectedHour,
          isDense: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: List.generate(
            24,
            (i) => DropdownMenuItem(
              value: i,
              child: Text('${i.toString().padLeft(2, '0')}:00'),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
