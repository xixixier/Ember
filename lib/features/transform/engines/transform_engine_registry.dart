import 'package:ember/core/constants/emotions.dart';
import 'transform_engine.dart';
import 'shakespeare_engine.dart';
import 'haiku_engine.dart';
import 'dark_soup_engine.dart';
import 'abstract_art_engine.dart';

/// 转化引擎注册表
class TransformEngineRegistry {
  static final Map<TransformType, TransformEngine> _engines = {
    TransformType.shakespeare: ShakespeareEngine(),
    TransformType.haiku: HaikuEngine(),
    TransformType.darkSoup: DarkSoupEngine(),
    TransformType.art: AbstractArtEngine(),
  };

  /// 获取指定类型的引擎
  static TransformEngine get(TransformType type) {
    return _engines[type]!;
  }

  /// 获取所有引擎
  static List<TransformEngine> get all => _engines.values.toList();

  /// 执行指定类型的转化
  static Future<TransformResult> transform(
    TransformType type,
    String text,
    Emotion emotion,
    int intensity,
  ) {
    return get(type).transform(text, emotion, intensity);
  }
}
