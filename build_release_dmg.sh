#!/bin/bash

#
# Build a release DMG for AppBundleGenerator
# This creates a distributable disk image with the binary, documentation, and source code
#

set -e  # Exit on error

APP_NAME="AppBundleGenerator"
VERSION="2.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOL_NAME="${APP_NAME} ${VERSION}"
TEMP_DIR="${APP_NAME}-${VERSION}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo "Building Release DMG for ${APP_NAME}"
echo "Version: ${VERSION}"
echo "========================================="
echo ""

# Change to script directory
cd "$SCRIPT_DIR"

# Check if binary exists
if [ ! -f "AppBundleGenerator" ]; then
    echo "Error: AppBundleGenerator binary not found. Run 'make' first."
    exit 1
fi

# Remove any existing DMG and temp directory
rm -rf "$TEMP_DIR" "$DMG_NAME"

# Create directory structure
echo "Creating release structure..."
mkdir -p "$TEMP_DIR"
mkdir -p "$TEMP_DIR/Documentation"
mkdir -p "$TEMP_DIR/Source"
mkdir -p "$TEMP_DIR/Examples"

# Copy the binary
echo "Copying binary..."
cp AppBundleGenerator "$TEMP_DIR/"
chmod 755 "$TEMP_DIR/AppBundleGenerator"

# Copy documentation
echo "Copying documentation..."
cp README.md "$TEMP_DIR/"
cp QUICKSTART.md "$TEMP_DIR/Documentation/"
cp CLAUDE.md "$TEMP_DIR/Documentation/"
cp CHANGELOG.md "$TEMP_DIR/Documentation/" 2>/dev/null || true

# Copy source code
echo "Copying source code..."
cp *.c "$TEMP_DIR/Source/"
cp *.h "$TEMP_DIR/Source/"
cp Makefile "$TEMP_DIR/Source/"
cp .gitignore "$TEMP_DIR/Source/" 2>/dev/null || true

# Copy examples
echo "Copying examples..."
cp examples/*.txt "$TEMP_DIR/Examples/" 2>/dev/null || true
cp examples/*.md "$TEMP_DIR/Examples/" 2>/dev/null || true

# Copy icon resources
echo "Copying icon resources..."
cp -r icons "$TEMP_DIR/Source/"

# Copy build scripts
echo "Copying build scripts..."
cp create_dmg_for_app.sh "$TEMP_DIR/Source/" 2>/dev/null || true
cp build_release_dmg.sh "$TEMP_DIR/Source/" 2>/dev/null || true

# Create an install script
echo "Creating install script..."
cat > "$TEMP_DIR/install.sh" << 'EOF'
#!/bin/bash
#
# Install AppBundleGenerator to /usr/local/bin
#

INSTALL_DIR="/usr/local/bin"
BINARY="AppBundleGenerator"

echo "Installing AppBundleGenerator to $INSTALL_DIR..."

if [ ! -w "$INSTALL_DIR" ]; then
    echo "Requires sudo access to write to $INSTALL_DIR"
    sudo install -m 755 "$BINARY" "$INSTALL_DIR/"
else
    install -m 755 "$BINARY" "$INSTALL_DIR/"
fi

if [ $? -eq 0 ]; then
    echo "Successfully installed to $INSTALL_DIR/$BINARY"
    echo ""
    echo "Run 'AppBundleGenerator --help' to get started"
else
    echo "Installation failed"
    exit 1
fi
EOF
chmod 755 "$TEMP_DIR/install.sh"

# Create README for the DMG
echo "Creating DMG README..."
cat > "$TEMP_DIR/READ_ME_FIRST.txt" << EOF
========================================
AppBundleGenerator ${VERSION}
========================================

Modern macOS Application Bundle Creator

A command-line utility for creating macOS Application Bundles (.app)
from executables or command strings, with full icon generation,
code signing, and modern Info.plist support.

QUICK START
-----------

1. Run the install script:
   ./install.sh

2. Or manually copy to your preferred location:
   cp AppBundleGenerator /usr/local/bin/

3. Try it out:
   AppBundleGenerator --help
   AppBundleGenerator 'Test' /tmp '/bin/echo Hello'

CONTENTS
--------

AppBundleGenerator   - The main executable
install.sh           - Installation script (copies to /usr/local/bin)
README.md            - Full documentation
Documentation/       - Additional documentation files
Source/              - Complete source code and Makefile
Examples/            - Example usage scenarios

REQUIREMENTS
------------

- macOS 12.0 (Monterey) or later
- Xcode Command Line Tools (for building from source)

DOCUMENTATION
-------------

See README.md for full documentation, examples, and troubleshooting.

For developer documentation, see Documentation/CLAUDE.md

AUTHOR
------

Steven Edwards (winehacker@gmail.com)

LICENSE
-------

See source code headers for licensing terms.
EOF

# Create the DMG
echo ""
echo "Creating DMG image..."
hdiutil create -volname "$VOL_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "SUCCESS!"
    echo "========================================="
    echo ""
    echo "DMG created: $DMG_NAME"
    echo "Size: $(du -h "$DMG_NAME" | cut -f1)"
    echo ""
    echo "Contents:"
    echo "  - AppBundleGenerator binary"
    echo "  - install.sh (installation script)"
    echo "  - README.md and documentation"
    echo "  - Complete source code"
    echo "  - Examples"
    echo ""
    echo "To test the DMG:"
    echo "  open $DMG_NAME"
    echo ""
else
    echo ""
    echo "Error: Failed to create DMG"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up temporary directory
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Done!"
