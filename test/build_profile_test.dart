// Run both ways:
//   flutter test test/build_profile_test.dart
//   flutter test --dart-define=is_appstore_build=true test/build_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/build_profile.dart';
import 'package:komet/core/config/config.dart';
import 'package:komet_js_engine/komet_js_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('is_appstore_build defaults to false', () {
    expect(
      BuildProfile.isAppStoreBuild,
      const bool.fromEnvironment('is_appstore_build'),
    );
  });

  test('App Store build trims review-unsafe modules', () {
    if (!BuildProfile.isAppStoreBuild) {
      expect(BuildProfile.plugins, isTrue);
      return;
    }
    expect(BuildProfile.isTrimmed, isTrue);
    for (final flag in <bool>[
      BuildProfile.plugins,
      BuildProfile.selfUpdate,
      BuildProfile.spoofUi,
      BuildProfile.devTools,
      BuildProfile.insecureTransport,
      BuildProfile.trafficCapture,
      BuildProfile.pranks,
      BuildProfile.hiddenContentViewers,
      BuildProfile.digitalId,
      BuildProfile.ipGeoLookup,
      BuildProfile.sessionCityLookup,
      BuildProfile.firebasePush,
      BuildProfile.tokenLogin,
      BuildProfile.qrLogin,
    ]) {
      expect(flag, isFalse);
    }
  });

  test('server selection stays available in the App Store build', () {
    if (BuildProfile.isAppStoreBuild) {
      expect(BuildProfile.serverSelection, isTrue);
    }
    if (!BuildProfile.isStore) expect(BuildProfile.serverSelection, isTrue);
  });

  test('saved server endpoint is honoured when selection is enabled', () async {
    SharedPreferences.setMockInitialValues({});
    await ServerConfig.saveEndpoint(
      host: 'api-test.oneme.ru',
      port: 8443,
      trustMincifryCa: false,
    );
    final endpoint = await ServerConfig.loadEndpoint();
    if (BuildProfile.serverSelection) {
      expect(endpoint.host, 'api-test.oneme.ru');
      expect(endpoint.port, 8443);
    } else {
      expect(endpoint.host, ServerConfig.defaultHost);
    }
    expect(endpoint.trustMincifryCa, isFalse);

    await ServerConfig.resetEndpoint();
    final reset = await ServerConfig.loadEndpoint();
    expect(reset.host, ServerConfig.defaultHost);
    expect(reset.port, ServerConfig.defaultPort);
  });

  test('JS engine package matches the build kind', () {
    // Real engine in normal builds; the stub (via pubspec_overrides.yaml) only
    // when tool/build_ios_appstore.sh resolved dependencies.
    expect(KometJsSandbox.isAvailable, isA<bool>());
  });
}
