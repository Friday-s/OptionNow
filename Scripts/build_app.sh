#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
output_dir="${project_dir:h}"
app_dir="$output_dir/OptionNow.app"
homebrew_swift="/opt/homebrew/opt/swift/Swift-6.3.xctoolchain/usr/bin/swift"
swift_bin="$(command -v swift)"

if [[ -x "$homebrew_swift" ]]; then
    swift_bin="$homebrew_swift"
fi

export CLANG_MODULE_CACHE_PATH="$project_dir/.build-local/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE_PATH"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

cd "$project_dir"
"$swift_bin" build -c release --disable-sandbox

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp ".build/release/OptionNowApp" "$app_dir/Contents/MacOS/OptionNowApp"
cp "Resources/Info.plist" "$app_dir/Contents/Info.plist"
chmod +x "$app_dir/Contents/MacOS/OptionNowApp"

codesign --force --deep --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"

echo "$app_dir"
