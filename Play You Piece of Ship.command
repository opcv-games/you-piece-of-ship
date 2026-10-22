#!/bin/zsh
# Double-click to play You Piece of Ship on this Mac (opens the game with Godot).
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --path . > /dev/null 2>&1
