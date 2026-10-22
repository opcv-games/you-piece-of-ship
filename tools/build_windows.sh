#!/bin/zsh
# Builds the Windows game and the zip for Dad, then refreshes the copy in iCloud Drive.
#   tools/build_windows.sh
# The iCloud file is overwritten in place (never deleted), so a link Olivier shared keeps
# pointing at the newest version.
set -e
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
mkdir -p builds/windows
"$GODOT" --headless --export-release "Windows Desktop" builds/windows/YouPieceOfShip.exe > /dev/null
cp docs/HOW_TO_PLAY_WITH_DAD.txt builds/windows/ 2>/dev/null || true
rm -rf builds/staging
mkdir -p builds/staging/YouPieceOfShip
cp builds/windows/YouPieceOfShip.exe builds/windows/HOW_TO_PLAY_WITH_DAD.txt builds/staging/YouPieceOfShip/
rm -f builds/YouPieceOfShip-Windows.zip
(cd builds/staging && zip -qr ../YouPieceOfShip-Windows.zip YouPieceOfShip)
rm -rf builds/staging
echo "Built builds/YouPieceOfShip-Windows.zip"
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/You Piece of Ship"
if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
	mkdir -p "$ICLOUD"
	cp builds/YouPieceOfShip-Windows.zip "$ICLOUD/YouPieceOfShip-Windows.zip" # in place: the shared link stays valid
	echo "Copied to iCloud Drive: You Piece of Ship/YouPieceOfShip-Windows.zip"
fi
