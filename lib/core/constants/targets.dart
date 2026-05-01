enum Target {
  work('工作'),
  love('感情'),
  self('自己'),
  social('社交'),
  stranger('陌生人'),
  world('这个世界'),
  none('不指定');

  final String label;
  const Target(this.label);

  /// 从 name 字符串反查枚举
  static Target fromName(String name) {
    return Target.values.firstWhere(
      (e) => e.name == name,
      orElse: () => Target.none,
    );
  }
}
