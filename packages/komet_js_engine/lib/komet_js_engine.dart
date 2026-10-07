// Тонкая обёртка над fjs: приложение не импортирует fjs напрямую, чтобы
// App Store сборка могла подменить этот пакет на komet_js_engine_stub и
// выкинуть JS движок (и его нативный pod) целиком.
import 'package:fjs/fjs.dart';

typedef KometJsBridge = Future<Object?> Function(Object? request);

class KometJsSandbox {
  KometJsSandbox._(this._engine);

  final JsEngine _engine;

  static const bool isAvailable = true;

  static Future<void>? _initialization;

  static Future<void> initialize() => _initialization ??= LibFjs.init();

  static Future<KometJsSandbox> create({
    required String info,
    required int memoryLimit,
    required int gcThreshold,
    required int maxStackSize,
    required KometJsBridge bridge,
  }) async {
    await initialize();
    final engine = await JsEngine.create(
      builtins: JsBuiltinOptions.none(),
      runtimeOptions: JsEngineRuntimeOptions(
        memoryLimit: BigInt.from(memoryLimit),
        gcThreshold: BigInt.from(gcThreshold),
        maxStackSize: BigInt.from(maxStackSize),
        info: info,
      ),
    );
    final sandbox = KometJsSandbox._(engine);
    await engine.init(
      bridge: (value) async =>
          JsResult.ok(JsValue.from(await bridge(value.value))),
    );
    return sandbox;
  }

  Future<void> declareModules(Map<String, String> modules) =>
      _engine.declareNewModules(
        modules: modules.entries
            .map((e) => JsModule.code(module: e.key, code: e.value))
            .toList(),
      );

  Future<void> call(String module, String method, Object? param) => _engine
      .call(module: module, method: method, params: [JsValue.from(param)]);

  Future<void> close() => _engine.close();
}
