#!/bin/bash

GAME_NAME="Roguetal"
EXECUTABLE="${GAME_NAME}.x86_64"
PCK_FILE="${GAME_NAME}.pck"

cd "$(dirname "$0")" || {
    echo "[ERROR] Could not access the game's directory."
    exit 1
}

if [ ! -f "$EXECUTABLE" ]; then
    echo "[ERROR] Executable '$EXECUTABLE' not found."
    echo "Make sure it is in the same folder as this script."
    exit 1
fi

if [ ! -f "$PCK_FILE" ]; then
    echo "[ERROR] Data file '$PCK_FILE' not found."
    echo "Make sure it is in the same folder as the executable."
    exit 1
fi

if [ ! -x "$EXECUTABLE" ]; then
    echo "[INFO] Granting execution permissions to '$EXECUTABLE'..."
    chmod +x "$EXECUTABLE" || {
        echo "[ERROR] Could not grant execution permissions."
        exit 1
    }
fi

echo "[INFO] Starting $GAME_NAME..."
"./$EXECUTABLE" "$@"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "[ERROR] The game exited with code $EXIT_CODE."
    exit $EXIT_CODE
else
    echo "[INFO] The game closed successfully."
fi

