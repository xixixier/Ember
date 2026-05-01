import 'package:uuid/uuid.dart';

/// UUID 生成器
class IdGenerator {
  static const _uuid = Uuid();

  static String generate() => _uuid.v4();
}
