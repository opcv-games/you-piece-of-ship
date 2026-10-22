#!/bin/zsh
# Records the 45-second Steam trailer (tools/record_trailer.gd) with Godot's Movie Maker and
# encodes it as Steam likes: 1920x1080 H.264 + AAC. Output: builds/ and ~/Downloads.
#   tools/record_trailer.sh
set -e
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
RAW=builds/trailer_raw.avi
OUT=builds/YouPieceOfShip-Steam-Trailer.mp4
mkdir -p builds
rm -f "$RAW"
"$GODOT" --path . --resolution 1920x1080 --fixed-fps 30 --write-movie "$RAW" -s tools/record_trailer.gd > /dev/null 2>&1 || true
ffmpeg -y -loglevel error -i "$RAW" -t 44 -vf "scale=1920:1080:flags=lanczos,fade=t=out:st=43.2:d=0.8" \
	-af "afade=t=out:st=42.5:d=1.5" -c:v libx264 -preset slow -crf 19 -profile:v high -pix_fmt yuv420p \
	-c:a aac -b:a 192k -movflags +faststart "$OUT"
rm -f "$RAW"
cp "$OUT" "$HOME/Downloads/"
echo "Made $OUT and copied it to ~/Downloads"
