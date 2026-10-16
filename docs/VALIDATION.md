# Validation record

2026-10-16 UTC, Linux cloud workspace.

## Executed successfully

- Official Swift 6.0.3 release toolchain downloaded from download.swift.org into temporary workspace (no system install)
- Pure package debug build and **12 XCTest tests passed, 0 failures**, 0.434 seconds test time
- Includes 200 deterministic initial boards and complete plays over 100 seeds
- Swift frontend syntax parsing of both App source files passed; **this is not Apple SDK type-checking or an iOS build**
- Shared Xcode scheme XML parsed successfully
- Shell syntax check of CI script passed
- Independent source review; VoiceOver animation-lock issue and gravity test fixture repaired, regression coverage expanded

Exact core command (temporary tooling/cache paths are environment-specific):

```sh
CLANG_MODULE_CACHE_PATH=/tmp/starfall-swift/clang-cache \
 /tmp/starfall-swift/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin/swift test \
 --cache-path /tmp/starfall-swift/cache \
 --config-path /tmp/starfall-swift/config \
 --security-path /tmp/starfall-swift/security
```

The initial unconfigured invocation failed before compilation because its default home-directory compiler cache was read-only. The successful command explicitly used writable temporary build/cache locations and did not change permissions or write the home cache.

## Not run / blocked

- iOS app build and link: Xcode and Apple SDKs are unavailable in this Linux environment
- Simulator/device launch, screenshots, animation inspection and accessibility testing
- GitHub workflow execution: manual workflow is prepared, not dispatched
- App Store/device distribution signing

No visual or device quality claim follows from these core test results. See `ACCEPTANCE.md` for remaining runtime checks. The manual cloud workflow describes a future Apple-tooling validation route, not evidence of a completed run.
