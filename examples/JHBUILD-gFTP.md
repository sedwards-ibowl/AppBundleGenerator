# Building gFTP with JHBuild on macOS

This document outlines the complete process for setting up jhbuild to build gFTP (and other GTK+ applications) natively on macOS without Homebrew library dependencies.

## Prerequisites

### Required Tools

1. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **Homebrew** (for build tools only, not libraries)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Build Tools from Homebrew**
   ```bash
   brew install cmake ninja automake autoconf libtool pkg-config meson
   ```

### Verify Prerequisites

```bash
# Check Xcode Command Line Tools
xcode-select -p
# Should output: /Library/Developer/CommandLineTools or /Applications/Xcode.app/Contents/Developer

# Check macOS SDK
ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
# Should show MacOSX.sdk

# Check pkg-config
which pkg-config
# Should output: /opt/homebrew/bin/pkg-config
```

## Step 1: Create Directory Structure

```bash
mkdir -p ~/source/jhbuild
cd ~/source/jhbuild

# Create subdirectories
mkdir -p install          # Where built libraries install
mkdir -p checkout         # Where source code is checked out
mkdir -p build            # Build artifacts
mkdir -p pkgs             # Downloaded tarballs
mkdir -p modulesets       # Module definition files
mkdir -p patches          # Patches for modules
```

## Step 2: Install JHBuild

### Download JHBuild Source

```bash
cd ~/source/jhbuild
git clone https://gitlab.gnome.org/GNOME/jhbuild.git jhbuild-src
cd jhbuild-src
```

### Build and Install JHBuild

```bash
./autogen.sh --simple-install --prefix=$HOME/source/jhbuild/install
make
make install
```

### Verify Installation

```bash
export PATH=~/source/jhbuild/install/bin:$PATH
jhbuild --version
```

## Step 3: Configure JHBuild (jhbuildrc)

Create `~/source/jhbuild/jhbuildrc` with the following content:

```python
# JHBuild configuration for macOS native GTK3 build
# No Homebrew dependencies - macOS SDK and native tools only

import os

# Prefix where GTK3 and dependencies will be installed
prefix = os.path.expanduser('~/source/jhbuild/install')
checkoutroot = os.path.expanduser('~/source/jhbuild/checkout')
buildroot = os.path.expanduser('~/source/jhbuild/build')

# Use macOS native tools
os.environ['CC'] = '/usr/bin/clang'
os.environ['CXX'] = '/usr/bin/clang++'
os.environ['OBJC'] = '/usr/bin/clang'

# Compiler and linker flags for macOS
_macos_sdk = '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'
os.environ['CFLAGS'] = f'-isysroot {_macos_sdk} -I{prefix}/include'
os.environ['CXXFLAGS'] = f'-isysroot {_macos_sdk} -I{prefix}/include'
os.environ['LDFLAGS'] = f'-isysroot {_macos_sdk} -L{prefix}/lib'
os.environ['OBJCFLAGS'] = f'-isysroot {_macos_sdk} -I{prefix}/include'

# PKG_CONFIG settings - use LIBDIR to completely override default search paths
# This prevents pkg-config from finding Homebrew libraries
os.environ['PKG_CONFIG_LIBDIR'] = f'{prefix}/lib/pkgconfig:{prefix}/share/pkgconfig'
os.environ['PKG_CONFIG_PATH'] = f'{prefix}/lib/pkgconfig:{prefix}/share/pkgconfig'
os.environ['PKG_CONFIG'] = '/opt/homebrew/bin/pkg-config'

# Path settings - include Homebrew build tools but exclude Homebrew libraries
# Homebrew bin is at END of PATH (lowest priority) for build tools only
os.environ['PATH'] = f'{prefix}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Applications/Xcode.app/Contents/Developer/usr/bin:/opt/homebrew/bin'

# Exclude Homebrew library paths - we only use Homebrew build tools, not libraries
if 'HOMEBREW_PREFIX' in os.environ:
    del os.environ['HOMEBREW_PREFIX']

# Module sets for GTK3 and your application
modulesets_dir = os.path.expanduser('~/source/jhbuild/modulesets')
moduleset = [
    'gtk-osx-bootstrap.modules',
    'gtk-osx.modules',
    'gtk-osx-network.modules',    # For networking libraries
    'gftp.modules'                 # Your application moduleset
]
modules = ['meta-gtk-osx-bootstrap', 'meta-gtk-osx-gtk3', 'gftp']

# Build configuration
makeargs = '-j4'  # Parallel build with 4 jobs (adjust for your CPU)
nice_build = True

# Disable default autogenargs that break some projects
autogenargs = ''

# Module-specific autogenargs overrides
module_autogenargs = {
    'openssl': 'shared',  # Only pass 'shared' to openssl Configure
}

# Module-specific mesonargs for native macOS builds (no X11)
module_mesonargs = {
    'cairo': '-Dfontconfig=enabled -Dfreetype=enabled -Dxcb=disabled -Dxlib=disabled -Dxlib-xcb=disabled -Dquartz=enabled -Dzlib=enabled -Dtests=disabled',
}

# Skip modules that aren't needed or cause issues
skip = ['gtk-doc']

# Installation settings
use_local_modulesets = True
modulesets_dir = os.path.expanduser('~/source/jhbuild/modulesets')

# Interaction settings
interact = True
nonetwork = False

# Tarball location
tarballdir = os.path.expanduser('~/source/jhbuild/pkgs')
```

## Step 4: Download GTK-OSX Modulesets

```bash
cd ~/source/jhbuild/modulesets

# Download standard GTK-OSX modulesets
curl -O https://gitlab.gnome.org/GNOME/gtk-osx/-/raw/master/modulesets-stable/gtk-osx-bootstrap.modules
curl -O https://gitlab.gnome.org/GNOME/gtk-osx/-/raw/master/modulesets-stable/gtk-osx.modules
curl -O https://gitlab.gnome.org/GNOME/gtk-osx/-/raw/master/modulesets-stable/gtk-osx-network.modules
```

## Step 5: Create Application Moduleset

Create `~/source/jhbuild/modulesets/gftp.modules` (or `yourapp.modules`):

```xml
<?xml version="1.0"?>
<!DOCTYPE moduleset SYSTEM "moduleset.dtd">
<?xml-stylesheet type="text/xsl" href="moduleset.xsl"?>
<moduleset>

  <repository type="git" name="github" href="https://github.com/"/>

  <!-- Your application module -->
  <meson id="gftp" mesonargs="-Dman=false">
    <branch repo="github"
            module="your-username/gftp.git"
            checkoutdir="gftp">
      <!-- Optional: Apply macOS-specific patches -->
      <patch file="gftp-macos.patch" strip="1"/>
    </branch>
    <dependencies>
      <dep package="gtk+-3.0"/>
      <dep package="glib"/>
      <!-- Add other dependencies as needed -->
    </dependencies>
  </meson>

</moduleset>
```

### Module Type Examples

For different build systems, use these module types:

**Autotools:**
```xml
<autotools id="myapp" autogenargs="--disable-static">
  <branch repo="github" module="user/myapp.git"/>
  <dependencies>
    <dep package="gtk+-3.0"/>
  </dependencies>
</autotools>
```

**CMake:**
```xml
<cmake id="myapp" cmakeargs="-DENABLE_TESTS=OFF">
  <branch repo="github" module="user/myapp.git"/>
  <dependencies>
    <dep package="gtk+-3.0"/>
  </dependencies>
</cmake>
```

**Meson:**
```xml
<meson id="myapp" mesonargs="-Dtests=false">
  <branch repo="github" module="user/myapp.git"/>
  <dependencies>
    <dep package="gtk+-3.0"/>
  </dependencies>
</meson>
```

## Step 6: Build Bootstrap Dependencies

```bash
export PATH=~/source/jhbuild/install/bin:$PATH
cd ~/source/jhbuild

jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-bootstrap
```

This builds essential tools and libraries:
- libffi
- gettext
- pkg-config
- Other bootstrap tools

## Step 7: Build GTK3 and Core Libraries

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-gtk3
```

This builds the complete GTK3 stack:
- glib
- cairo
- pango
- gdk-pixbuf
- atk
- gtk+-3.0
- And all their dependencies

**Note:** This step can take 1-2 hours depending on your system.

## Step 8: Build Your Application

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc build gftp
```

Or for another application, use its module name from your moduleset.

## Step 9: Create macOS Application Bundle

After building, create a `.app` bundle:

```bash
# Create bundle structure
mkdir -p ~/Applications/gFTP.app/Contents/{MacOS,Resources,Frameworks,lib}

# Copy executable
cp ~/source/jhbuild/install/bin/gftp ~/Applications/gFTP.app/Contents/MacOS/

# Copy required libraries
cd ~/source/jhbuild/install/lib
cp -R *.dylib ~/Applications/gFTP.app/Contents/lib/

# Copy GTK resources
mkdir -p ~/Applications/gFTP.app/Contents/Resources/share
cp -R ~/source/jhbuild/install/share/gtk-3.0 ~/Applications/gFTP.app/Contents/Resources/share/
cp -R ~/source/jhbuild/install/share/icons ~/Applications/gFTP.app/Contents/Resources/share/
cp -R ~/source/jhbuild/install/share/glib-2.0 ~/Applications/gFTP.app/Contents/Resources/share/

# Create Info.plist
cat > ~/Applications/gFTP.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>gftp</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.gftp</string>
    <key>CFBundleName</key>
    <string>gFTP</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>
EOF

# Fix library paths with install_name_tool
# (See "Library Path Fixing" section below)
```

## Common JHBuild Commands

### Building
```bash
# Build a module and all dependencies
jhbuild build <module-name>

# Build only the module (skip dependencies)
jhbuild buildone <module-name>

# Update source code without building
jhbuild update <module-name>
```

### Information
```bash
# List modules that would be built
jhbuild list <module-name>

# Show module information
jhbuild info <module-name>

# Show what depends on a module
jhbuild rdepends <module-name>
```

### Maintenance
```bash
# Clean build directory for a module
jhbuild cleanone <module-name>

# Run a command in jhbuild environment
jhbuild run <command>

# Start shell in jhbuild environment
jhbuild shell
```

## Troubleshooting

### Build Fails with Missing Dependencies

1. Check system dependencies:
   ```bash
   jhbuild sysdeps --install <module-name>
   ```

2. Verify pkg-config can find libraries:
   ```bash
   jhbuild shell
   pkg-config --list-all
   pkg-config --cflags --libs <library-name>
   ```

### Build Fails with Compiler Errors

1. Check that SDK path is correct:
   ```bash
   ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
   ```

2. Verify environment variables:
   ```bash
   jhbuild shell
   echo $CC
   echo $CFLAGS
   echo $PKG_CONFIG_LIBDIR
   ```

### Module Not Found

1. Verify moduleset file exists and has correct name in `jhbuildrc`
2. Check module syntax:
   ```bash
   xmllint --noout ~/source/jhbuild/modulesets/yourapp.modules
   ```

### Linking Against Homebrew Libraries

If you accidentally link against Homebrew libraries:

1. Clean and rebuild:
   ```bash
   jhbuild cleanone <module-name>
   jhbuild buildone <module-name>
   ```

2. Check library linkage:
   ```bash
   otool -L ~/source/jhbuild/install/bin/<your-app>
   ```
   Should show libraries from `~/source/jhbuild/install/lib`, NOT `/opt/homebrew/lib`

## Adding a New Project

To add a new GTK+ application:

1. **Create a moduleset file** in `~/source/jhbuild/modulesets/yourapp.modules`

2. **Add the moduleset** to `jhbuildrc`:
   ```python
   moduleset = [
       'gtk-osx-bootstrap.modules',
       'gtk-osx.modules',
       'gtk-osx-network.modules',
       'yourapp.modules'  # Add this line
   ]
   ```

3. **Add your module** to the build list:
   ```python
   modules = ['meta-gtk-osx-bootstrap', 'meta-gtk-osx-gtk3', 'yourapp']
   ```

4. **Build it**:
   ```bash
   jhbuild build yourapp
   ```

## Library Path Fixing for .app Bundles

After creating the bundle, fix library paths to be self-contained:

```bash
#!/bin/bash
APP_DIR="$HOME/Applications/gFTP.app/Contents"
EXEC="$APP_DIR/MacOS/gftp"

# Fix executable
for lib in $(otool -L "$EXEC" | grep "$HOME/source/jhbuild/install" | awk '{print $1}'); do
    base=$(basename "$lib")
    install_name_tool -change "$lib" "@executable_path/../lib/$base" "$EXEC"
done

# Fix libraries
for dylib in "$APP_DIR"/lib/*.dylib; do
    # Fix library's own ID
    base=$(basename "$dylib")
    install_name_tool -id "@executable_path/../lib/$base" "$dylib"

    # Fix library dependencies
    for lib in $(otool -L "$dylib" | grep "$HOME/source/jhbuild/install" | awk '{print $1}'); do
        depbase=$(basename "$lib")
        install_name_tool -change "$lib" "@executable_path/../lib/$depbase" "$dylib"
    done
done
```

## Environment Variables for Running

If not using a `.app` bundle, set these before running:

```bash
export PATH="$HOME/source/jhbuild/install/bin:$PATH"
export DYLD_LIBRARY_PATH="$HOME/source/jhbuild/install/lib:$DYLD_LIBRARY_PATH"
export XDG_DATA_DIRS="$HOME/source/jhbuild/install/share:$XDG_DATA_DIRS"
export GTK_PATH="$HOME/source/jhbuild/install/lib/gtk-3.0"
export GDK_PIXBUF_MODULE_FILE="$HOME/source/jhbuild/install/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"

# Run your application
gftp
```

## Clean Rebuild from Scratch

If you need to completely rebuild everything:

```bash
# Remove all built files
rm -rf ~/source/jhbuild/install/*
rm -rf ~/source/jhbuild/checkout/*
rm -rf ~/source/jhbuild/build/*

# Rebuild jhbuild
cd ~/source/jhbuild/jhbuild-src
make install

# Rebuild everything
export PATH=~/source/jhbuild/install/bin:$PATH
jhbuild build meta-gtk-osx-bootstrap
jhbuild build meta-gtk-osx-gtk3
jhbuild build yourapp
```

## References

- JHBuild Manual: https://gitlab.gnome.org/GNOME/jhbuild/-/tree/master/doc
- GTK-OSX Project: https://gitlab.gnome.org/GNOME/gtk-osx
- GTK Documentation: https://docs.gtk.org/gtk3/
