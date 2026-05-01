enum DestroyStyle {
  burn('焚', '🔥'),
  sink('沉', '🌊'),
  scatter('散', '🌬️'),
  ash('烬', '✨');

  final String label;
  final String emoji;
  const DestroyStyle(this.label, this.emoji);

  /// 从 name 字符串反查枚举
  static DestroyStyle fromName(String name) {
    return DestroyStyle.values.firstWhere(
      (e) => e.name == name,
      orElse: () => DestroyStyle.burn,
    );
  }
}
