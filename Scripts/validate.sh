#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
homebrew_swiftc="/opt/homebrew/opt/swift/Swift-6.3.xctoolchain/usr/bin/swiftc"
swiftc_bin="$(command -v swiftc)"

if [[ -x "$homebrew_swiftc" ]]; then
    swiftc_bin="$homebrew_swiftc"
fi

cd "$project_dir"
export CLANG_MODULE_CACHE_PATH="$project_dir/.build-local/module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
"$swiftc_bin" -frontend -parse Sources/OptionNowApp/*.swift
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
target_arch="$(uname -m)"
"$swiftc_bin" \
    -sdk "$sdk_path" \
    -target "${target_arch}-apple-macosx26.0" \
    Sources/OptionNowApp/RadialGeometry.swift \
    Validation/RadialGeometryValidation.swift \
    -o .build-local/radial-geometry-validation
.build-local/radial-geometry-validation

[[ -L AGENTS.md ]]
[[ "$(readlink AGENTS.md)" == "CLAUDE.md" ]]
plutil -lint Resources/Info.plist >/dev/null
rg -q 'LSUIElement' Resources/Info.plist
rg -q 'kEventHotKeyReleased' Sources/OptionNowApp/HotKeyManager.swift
rg -q 'RadialLauncherView' Sources/OptionNowApp/LauncherView.swift
rg -Fq 'NSWorkspace.shared.open(home)' Sources/OptionNowApp/ActionExecutor.swift
rg -Fq 'com.ivor.sendlingo.show-panel' Sources/OptionNowApp/ApplicationIntegration.swift
rg -Fq 'com.ivor.sendlingo.hide-panel' Sources/OptionNowApp/ApplicationIntegration.swift
rg -Fq 'SMAppService.mainApp' Sources/OptionNowApp/LoginItemManager.swift
! rg -q '/Users/ivor/' Sources/OptionNowApp
! rg -q 'RoundedRectangle' Sources/OptionNowApp/LauncherView.swift
[[ ! -e Sources/OptionNowApp/FilesBrowser.swift ]]
[[ -f Validation/LifecycleValidation.swift ]]

echo "PASS: OptionNow source and project structure validation"
