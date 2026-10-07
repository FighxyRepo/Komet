import 'package:flutter/services.dart' show appFlavor;

// #***! что включено в сборке, всё считается на компиляции из flavor и
// --dart-define=is_appstore_build=true (iOS App Store, см. CLAUDE.md)
abstract final class BuildProfile {
  static const String storeFlavor = 'store';

  // #***! store сборка (Google Play) урезана, без самообновления дев
  // инструментов и спуфа
  static const bool isStore = appFlavor == storeFlavor;

  /// App Store build, set with `--dart-define=is_appstore_build=true`.
  ///
  /// Plugins run downloaded JavaScript, which App Review does not allow for
  /// code that changes app behavior, and apps from the App Store are updated
  /// by the App Store. Such builds leave out plugins, the update check and
  /// the device spoofing screen. Sideloaded iOS builds are made without the
  /// flag and keep all of them, like Android.
  ///
  /// The gates below are const, so the compiler drops the disabled code
  /// from App Store builds.
  static const bool isAppStoreBuild = bool.fromEnvironment('is_appstore_build');

  /// Any store build (Google Play `store` flavor or App Store). Dev tooling,
  /// insecure transport, traffic capture, pranks, hidden content viewers and
  /// IP lookups are left out of both.
  static const bool isTrimmed = isStore || isAppStoreBuild;

  /// Plugins and their settings; built-in slash commands stay either way.
  static const bool plugins = !isAppStoreBuild;

  /// Update check, settings button and update dialog.
  static const bool selfUpdate = !isStore && !isAppStoreBuild;
  static const bool firebasePush = appFlavor == 'oneme' && !isAppStoreBuild;

  /// Device spoofing screen. Only the settings and login entry points are
  /// hidden; the connect handshake still sends the stored device profile.
  static const bool spoofUi = !isStore && !isAppStoreBuild;
  static const bool tokenLogin = false;
  static const bool qrLogin = false;
  static const bool devTools = !isTrimmed;
  static const bool insecureTransport = !isTrimmed;
  static const bool trafficCapture = !isTrimmed;
  static const bool pranks = !isTrimmed;
  static const bool hiddenContentViewers = !isTrimmed;
  static const bool digitalId = !isTrimmed;
  static const bool ipGeoLookup = !isTrimmed;
  static const bool sessionCityLookup = !isTrimmed;

  /// MAX server choice (host/port, Mincifry CA) and proxy. Must keep working
  /// in the App Store build, so it does not depend on [devTools].
  static const bool serverSelection = !isStore || isAppStoreBuild;

  // Pure versions of the gates above. dart-define values are fixed at
  // compile time, so tests check every combination through these.
  static bool pluginsFor({required bool appStoreBuild}) => !appStoreBuild;

  static bool selfUpdateFor({
    required bool store,
    required bool appStoreBuild,
  }) => !store && !appStoreBuild;

  static bool spoofUiFor({required bool store, required bool appStoreBuild}) =>
      !store && !appStoreBuild;
}
