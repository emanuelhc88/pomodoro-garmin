#!/bin/bash
# Build .iq package for Connect IQ Store submission

SDKPATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/" | head -1)"
KEYPATH="$HOME/.connect-iq/developer_key.der"
JUNGLE="monkey.jungle"
OUTDIR="bin"
OUTPUT="$OUTDIR/toma.iq"

mkdir -p "$OUTDIR"

echo "Building release package..."
if "$SDKPATH/bin/monkeyc" -e -f "$JUNGLE" -o "$OUTPUT" -y "$KEYPATH" -w; then
    echo "Success: $OUTPUT"
    ls -lh "$OUTPUT"
    exit 0
else
    echo "Build failed."
    exit 1
fi
