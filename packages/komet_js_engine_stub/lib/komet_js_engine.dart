// Заглушка для App Store сборки: тот же API, что у komet_js_engine, но без
// JS движка и без нативного кода. Подключается через pubspec_overrides.yaml
// из tool/build_ios_appstore.sh.
typedef KometJsBridge = Future<Object?> Function(Object? request);

class KometJsSandbox {
  KometJsSandbox._();

  static const bool isAvailable = false;

  static Future<void> initialize() async {}

  static Future<KometJsSandbox> create({
    required String info,
    required int memoryLimit,
    required int gcThreshold,
    required int maxStackSize,
    required KometJsBridge bridge,
  }) => throw UnsupportedError('JS plugins are not part of this build');

  Future<void> declareModules(Map<String, String> modules) async {}

  Future<void> call(String module, String method, Object? param) async {}

  Future<void> close() async {}
}
