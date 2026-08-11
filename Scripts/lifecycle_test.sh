#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
homebrew_swiftc="/opt/homebrew/opt/swift/Swift-6.3.xctoolchain/usr/bin/swiftc"
swiftc_bin="$(command -v swiftc)"
if [[ -x "$homebrew_swiftc" ]]; then swiftc_bin="$homebrew_swiftc"; fi

export CLANG_MODULE_CACHE_PATH="$project_dir/.build-local/module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
target_arch="$(uname -m)"

"$swiftc_bin" \
    -parse-as-library \
    -sdk "$sdk_path" \
    -target "${target_arch}-apple-macosx26.0" \
    "$project_dir/Validation/LifecycleValidation.swift" \
    -o "$project_dir/.build-local/lifecycle-validation"

"$project_dir/.build-local/lifecycle-validation"
