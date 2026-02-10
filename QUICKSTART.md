# Quick Start Guide

Get started with AppBundleGenerator in 5 minutes.

## Build

```bash
make
```

That's it! The `AppBundleGenerator` binary is ready to use.

## Basic Usage

### Create a simple bundle

```bash
./AppBundleGenerator 'My App' /tmp '/usr/local/bin/myapp'
```

This creates `/tmp/My App.app` that launches `/usr/local/bin/myapp` when opened.

### Launch it

```bash
open "/tmp/My App.app"
```

## Add an Icon

### From SVG (auto-converts to .icns)

```bash
./AppBundleGenerator --icon myicon.svg 'My App' /tmp '/usr/local/bin/myapp'
```

### From PNG

```bash
./AppBundleGenerator --icon myicon.png 'My App' /tmp '/usr/local/bin/myapp'
```

### From existing ICNS

```bash
./AppBundleGenerator --icon myicon.icns 'My App' /tmp '/usr/local/bin/myapp'
```

## Code Signing

### Ad-hoc signing (for development)

```bash
./AppBundleGenerator --sign - --hardened-runtime 'My App' /tmp '/usr/local/bin/myapp'
```

### Developer ID signing (for distribution)

```bash
./AppBundleGenerator \
  --sign 'Developer ID Application: Your Name' \
  --hardened-runtime \
  'My App' /Applications '/usr/local/bin/myapp'
```

**Note:** Find your signing identity with:
```bash
security find-identity -p codesigning -v
```

## Dependency Bundling

You can bundle dependencies like libraries and resources with your application.

### Staging Dependencies

The `--stage-dependencies` option is useful for bundling libraries from a prefix (like Homebrew or a jhbuild checkout). It copies `lib/`, `share/`, and `etc/` directories.

```bash
./AppBundleGenerator \
  --stage-dependencies /opt/homebrew \
  'My App' /Applications '/usr/local/bin/myapp'
```

### Copying Custom Resources

The `--copy-resources` option provides a more flexible way to copy an entire directory into your application's `Resources` folder. This is useful for including assets, themes, or other resources.

```bash
./AppBundleGenerator \
  --copy-resources /path/to/my-resources \
  'My App' /Applications '/usr/local/bin/myapp'
```

## First-Run Resource Initialization

On first launch, you can automatically copy resources (like default configurations) from your app bundle to a user's local directory (`~/Library`).

```bash
./AppBundleGenerator \
  --init-resources gconf:gftp \
  --stage-dependencies /path/to/my-gftp-resources \
  'gFTP' /Applications '/usr/local/bin/gftp'
```
This command will copy the contents of `/path/to/my-gftp-resources/gconf` into `~/Library/gftp` the first time the user runs `gFTP.app`.

## Common Scenarios

### Wrap a CLI tool as a Mac app

```bash
./AppBundleGenerator \
  --icon terminal.svg \
  --sign - \
  'My CLI Tool' /Applications '/usr/local/bin/mytool'
```

### Create a terminal launcher

```bash
./AppBundleGenerator \
  'Midnight Commander' /Applications \
  'open -b com.apple.terminal /usr/local/bin/mc'
```

### Production build with all options

```bash
./AppBundleGenerator \
  --icon app.svg \
  --sign 'Developer ID Application: Your Name' \
  --hardened-runtime \
  --identifier com.example.myapp \
  --category public.app-category.developer-tools \
  --min-os 12.0 \
  --version 2.0.0 \
  'My Application' /Applications '/usr/local/bin/myapp'
```

## Verify Your Bundle

### Check Info.plist

```bash
plutil -p "/tmp/My App.app/Contents/Info.plist"
```

### Verify code signature

```bash
codesign -dvvv "/tmp/My App.app"
```

### Check bundle structure

```bash
ls -R "/tmp/My App.app"
```

## Quick Reference

### Most Useful Options

| Option | Purpose | Example |
|--------|---------|---------|
| `--icon PATH` | Add icon (PNG/SVG/ICNS) | `--icon app.svg` |
| `--sign ID` | Code sign | `--sign -` (ad-hoc) |
| `--hardened-runtime` | Enable hardened runtime | Always use with --sign |
| `--identifier ID` | Custom bundle ID | `--identifier com.example.app` |
| `--version VER` | Set version | `--version 2.0.0` |
| `--min-os VER` | Minimum macOS version | `--min-os 12.0` |
| `--stage-dependencies DIR` | Bundle dependencies from prefix | `--stage-dependencies /opt/homebrew` |
| `--copy-resources DIR` | Copy directory to Resources | `--copy-resources ./assets` |
| `--init-resources SRC:DEST` | Initialize resources on first run | `--init-resources gconf:gftp` |

### Get Help

```bash
./AppBundleGenerator --help
```

## Troubleshooting

### "App is damaged and can't be opened"

Your app needs to be code signed on macOS 10.15+:

```bash
./AppBundleGenerator --sign - --hardened-runtime 'My App' /tmp '/usr/local/bin/myapp'
```

### Icon doesn't appear

Make sure you're using one of these formats:
- `.svg` - Vector graphics (recommended)
- `.png` - At least 512x512 pixels
- `.icns` - Mac icon format

### Build fails

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

## Next Steps

- Read [README.md](README.md) for complete documentation
- Check [CLAUDE.md](CLAUDE.md) for development details
- See full options with `./AppBundleGenerator --help`

## Examples Included

Try with the included Putty icon:

```bash
./AppBundleGenerator \
  --icon icons/Putty.svg \
  --sign - \
  'Test App' /tmp '/bin/echo "Hello from Mac App!"'

open "/tmp/Test App.app"
```

## One-Liners

```bash
# Install globally
sudo make install

# Build and test in one command
make && ./AppBundleGenerator 'Test' /tmp '/bin/echo Hi' && open /tmp/Test.app

# Create bundle with icon and signing
./AppBundleGenerator --icon app.svg --sign - --hardened-runtime 'MyApp' /tmp '/path/to/exe'
```

---

**Need more?** Check out the comprehensive [README.md](README.md) for all features and options.
