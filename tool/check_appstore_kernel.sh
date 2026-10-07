#!/usr/bin/env bash
# Linux-friendly proof that the App Store build really drops the excluded
# modules: compiles lib/main.dart to a tree-shaken AOT kernel (same TFA pass
# that `flutter build ipa` runs) with the stub engine and the define, then
# greps it for markers. Run from any OS; no Xcode needed.
set -euo pipefail
cd "$(dirname "$0")/.."
FLUTTER_ROOT=${FLUTTER_ROOT:-$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")}
DART_BIN=$FLUTTER_ROOT/bin/cache/dart-sdk/bin
SDK=$FLUTTER_ROOT/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/
OUT=$(mktemp -d)/appstore.dill

[[ -e pubspec_overrides.yaml ]] && { echo "pubspec_overrides.yaml exists" >&2; exit 1; }
cp pubspec.lock pubspec.lock.appstore-bak
trap 'rm -f pubspec_overrides.yaml; mv -f pubspec.lock.appstore-bak pubspec.lock; flutter pub get >/dev/null || true' EXIT
printf 'dependency_overrides:\n  komet_js_engine:\n    path: packages/komet_js_engine_stub\n' > pubspec_overrides.yaml
flutter pub get >/dev/null

"$DART_BIN/dartaotruntime" "$DART_BIN/snapshots/frontend_server_aot.dart.snapshot" \
  --sdk-root "$SDK" --target=flutter --aot --tfa --minimal-kernel \
  --no-embed-source-text --no-print-incremental-dependencies \
  -Ddart.vm.product=true -Dis_appstore_build=true \
  --packages .dart_tool/package_config.json --output-dill "$OUT" \
  package:komet/main.dart >/dev/null

fail=0
for s in package:fjs JsEngine PluginRuntime PluginStore PluginsScreen PluginUpdater \
         UpdateChecker UpdateInstaller showUpdateDialog update_config \
         SpoofScreen DebugMenuScreen; do
  if grep -qaF "$s" "$OUT"; then echo "LEAK: $s"; fail=1; fi
done
for s in ServerConfig ServerSettingsSheet ProxyConfig ProxySettingsSheet; do
  grep -qaF "$s" "$OUT" || { echo "MISSING: $s (server selection)"; fail=1; }
done
[[ $fail == 0 ]] && echo "OK: excluded modules absent, server selection present"
exit $fail
