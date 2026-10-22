#!/bin/zsh
# Records the 45-second showreel (tools/record_demo.gd) with Godot's Movie Maker at 1920x1080,
# 30 fps, music included, then makes an MP4 (H.264 + AAC) in builds/ and copies it to iCloud Drive.
#   tools/record_demo.sh
set -e
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
VERSION=$(grep -E '^const VERSION' scripts/ui/main_menu.gd | sed -E 's/.*"v?([^"]+)".*/\1/')
RAW=builds/demo_raw.avi
OUT=builds/YouPieceOfShip-demo-$VERSION.mp4
mkdir -p builds
rm -f "$RAW"
"$GODOT" --path . --resolution 1920x1080 --fixed-fps 30 --write-movie "$RAW" -s tools/record_demo.gd > /dev/null 2>&1 || true # Godot reports harmless leaks at exit
ffmpeg -y -loglevel error -i "$RAW" -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart "$OUT"
rm -f "$RAW"
echo "Made $OUT"
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/You Piece of Ship"
if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
	mkdir -p "$ICLOUD"
	cp "$OUT" "$ICLOUD/"
	echo "Copied to iCloud Drive: You Piece of Ship/$(basename "$OUT")"
fi
