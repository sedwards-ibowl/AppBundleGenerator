# Changelog

All notable changes to AppBundleGenerator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow for automated builds and releases
- Dependency staging system (`--stage-dependencies`) for bundling GTK/GLib libraries
  - Copies lib/, share/, etc/, locale/ directories into app bundle
  - Automatic RPATH rewriting for relocatable bundles
  - GLib schema compilation support
  - Environment variable setup in wrapper script (XDG_DATA_DIRS, GTK_PATH, etc.)
- Documentation for building GTK applications with jhbuild (examples/JHBUILD-gFTP.md)

## [2.0.0] - 2025-01-12

### Added
- Full icon generation pipeline supporting PNG, SVG, and ICNS formats
- Automatic conversion of PNG/SVG to multi-resolution .icns files (10 sizes)
- Comprehensive code signing integration with hardened runtime support
- Entitlements generation for code signing exceptions
- Modern Info.plist generation with all macOS 12+ required keys
- Command-line options for:
  - Icon specification (`--icon`)
  - Code signing identity (`--sign`)
  - Hardened runtime (`--hardened-runtime`)
  - Custom entitlements (`--entitlements`)
  - Bundle identifier (`--identifier`)
  - App category (`--category`)
  - Minimum OS version (`--min-os`)
  - Bundle version (`--version`)
- Signature verification after signing
- Support for entitlement exceptions:
  - JIT compilation (`--allow-jit`)
  - Unsigned executable memory (`--allow-unsigned`)
  - DYLD environment variables (`--allow-dyld-vars`)

### Changed
- Modernized for macOS 12+ (Monterey and later)
- Replaced all deprecated CoreFoundation APIs:
  - `CFPropertyListCreateXMLData` → `CFPropertyListCreateData`
  - `CFURLWriteDataAndPropertiesToResource` → `CFWriteStreamCreateWithFile`
  - `CFStringGetSystemEncoding` → `kCFStringEncodingUTF8`
- Binary plist format for faster parsing
- Enhanced error handling with `CFErrorRef`
- Updated build system with modern clang flags
- Added security flags: `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`
- Compiler enforces no deprecated APIs with `-Werror=deprecated-declarations`

### Fixed
- Compiler warnings with modern Xcode versions
- Compatibility issues with macOS 12+
- Bundle validation issues with modern Gatekeeper

## [1.0.0] - Historical

### Added
- Initial version for Wine integration on macOS
- Basic application bundle creation
- Simple Info.plist generation
- PkgInfo file generation
- Shell script launcher

[Unreleased]: https://github.com/yourusername/AppBundleGenerator/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/yourusername/AppBundleGenerator/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/yourusername/AppBundleGenerator/releases/tag/v1.0.0
