#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it with:"
    echo "brew install imagemagick"
    exit 1
fi

# Check if source image is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path-to-source-icon.png>"
    exit 1
fi

SOURCE_ICON=$1

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Go up one level to project root
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
ASSET_PATH="$PROJECT_ROOT/Filmz/Assets.xcassets/AppIcon.appiconset"

echo "Creating icons in: $ASSET_PATH"

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: Source icon not found at $SOURCE_ICON"
    exit 1
fi

# Create the AppIcon directory if it doesn't exist
mkdir -p "${ASSET_PATH}"

# Remove any existing icons
rm -f "$ASSET_PATH"/*.png

# Generate icons using a simpler format with white background
echo "Generating 1024x1024 icon as icon-1024.png"
convert "$SOURCE_ICON" -resize 1024x1024 -background white -alpha remove -alpha off "$ASSET_PATH/icon-1024.png"

echo "Generating 180x180 icon as icon-60@3x.png"
convert "$SOURCE_ICON" -resize 180x180 -background white -alpha remove -alpha off "$ASSET_PATH/icon-60@3x.png"

echo "Generating 120x120 icon as icon-60@2x.png"
convert "$SOURCE_ICON" -resize 120x120 -background white -alpha remove -alpha off "$ASSET_PATH/icon-60@2x.png"

echo "Generating 167x167 icon as icon-83.5@2x.png"
convert "$SOURCE_ICON" -resize 167x167 -background white -alpha remove -alpha off "$ASSET_PATH/icon-83.5@2x.png"

echo "Generating 152x152 icon as icon-76@2x.png"
convert "$SOURCE_ICON" -resize 152x152 -background white -alpha remove -alpha off "$ASSET_PATH/icon-76@2x.png"

echo "Generating 87x87 icon as icon-29@3x.png"
convert "$SOURCE_ICON" -resize 87x87 -background white -alpha remove -alpha off "$ASSET_PATH/icon-29@3x.png"

echo "Generating 80x80 icon as icon-40@2x.png"
convert "$SOURCE_ICON" -resize 80x80 -background white -alpha remove -alpha off "$ASSET_PATH/icon-40@2x.png"

echo "Generating 120x120 icon as icon-40@3x.png"
convert "$SOURCE_ICON" -resize 120x120 -background white -alpha remove -alpha off "$ASSET_PATH/icon-40@3x.png"

# Create Contents.json
cat > "${ASSET_PATH}/Contents.json" << 'EOL'
{
  "images" : [
    {
      "filename" : "icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOL

echo "App icons generated successfully!" 