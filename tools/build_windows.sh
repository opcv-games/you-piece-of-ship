#!/bin/zsh
# Builds the Windows game and the zip for Dad, then drops a copy in ~/Downloads.
#   tools/build_windows.sh
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
cp "builds/YouPieceOfShip-Windows.zip" "$HOME/Downloads/" # Olivier picks it up from Downloads
echo "Copied to ~/Downloads/$(basename "builds/YouPieceOfShip-Windows.zip")"
