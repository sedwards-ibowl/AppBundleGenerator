#!/bin/bash

#
# This script creates a DMG installer for AppBundleGenerator
# It includes the built application, source code, and documentation
#

APP_NAME="AppBundleGenerator"
APP_PATH="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
VOL_NAME="$APP_NAME Installer"
SRC_FOLDER="$HOME/source/AppBundleGenerator"
TEMP_DIR="$APP_NAME-temp"  # Temporary directory for DMG contents

echo "Building DMG for: $APP_NAME"
echo "Application: $APP_PATH"
echo "DMG file: $DMG_NAME"
echo "Volume name: $VOL_NAME"
echo "Source folder: $SRC_FOLDER"
echo "Temp directory: $TEMP_DIR"
echo ""

# Change to Desktop directory
cd "$HOME/Desktop"

# Remove any existing temporary directory
rm -rf "$TEMP_DIR"

# Create new directory structure for DMG contents
mkdir -p "$TEMP_DIR/Source"
mkdir -p "$TEMP_DIR/Documentation"

# Copy Application bundle
if [ -d "$APP_PATH" ]; then
    echo "Copying application bundle..."
    rsync -av --links "$APP_PATH" "$TEMP_DIR/"
else
    echo "Warning: $APP_PATH not found on Desktop"
fi

# Copy source code files
echo "Copying source code..."
cp "$SRC_FOLDER"/*.c "$TEMP_DIR/Source/" 2>/dev/null
cp "$SRC_FOLDER"/*.h "$TEMP_DIR/Source/" 2>/dev/null
cp "$SRC_FOLDER/Makefile" "$TEMP_DIR/Source/" 2>/dev/null
cp "$SRC_FOLDER/.gitignore" "$TEMP_DIR/Source/" 2>/dev/null

# Copy icon resources as examples
if [ -d "$SRC_FOLDER/icons" ]; then
    echo "Copying icon examples..."
    cp -r "$SRC_FOLDER/icons" "$TEMP_DIR/Source/"
fi

# Copy documentation files
echo "Copying documentation..."
cp "$SRC_FOLDER/README.md" "$TEMP_DIR/Documentation/" 2>/dev/null
cp "$SRC_FOLDER/CLAUDE.md" "$TEMP_DIR/Documentation/" 2>/dev/null
cp "$SRC_FOLDER/QUICKSTART.md" "$TEMP_DIR/Documentation/" 2>/dev/null

# Copy this build script for reference
cp "$SRC_FOLDER/create_dmg_for_app.sh" "$TEMP_DIR/Source/" 2>/dev/null

# Create the DMG file
echo ""
echo "Creating DMG image..."
hdiutil create -volname "$VOL_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "Success! DMG created: $HOME/Desktop/$DMG_NAME"
    echo ""
    echo "DMG Contents:"
    echo "  - $APP_NAME.app (Application bundle)"
    echo "  - Source/ (C source files, Makefile, icons)"
    echo "  - Documentation/ (README, CLAUDE.md, QUICKSTART)"
else
    echo ""
    echo "Error: Failed to create DMG"
fi

# Clean up the temporary directory
rm -rf "$TEMP_DIR"

