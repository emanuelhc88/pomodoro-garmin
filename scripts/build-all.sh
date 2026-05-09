#!/bin/bash
# Build Toma for all supported devices and report results.

SDKPATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/" | head -1)"
KEYPATH="$HOME/.connect-iq/developer_key.der"
JUNGLE="monkey.jungle"
OUTDIR="bin"

DEVICES=(
    fr255
    fr255s
    fr255m
    fr265
    fr265s
    fr955
    fr965
    fenix7
    fenix7pro
    fenix843mm
    fenix847mm
    epix2
    venu3
    venu3s
    vivoactive5
)

mkdir -p "$OUTDIR"

PASS=0
FAIL=0
FAILED_DEVICES=()

for device in "${DEVICES[@]}"; do
    echo -n "Building $device... "
    if "$SDKPATH/bin/monkeyc" -d "$device" -f "$JUNGLE" -o "$OUTDIR/toma_${device}.prg" -y "$KEYPATH" -w 2>/dev/null; then
        echo "OK"
        ((PASS++))
    else
        echo "FAILED"
        ((FAIL++))
        FAILED_DEVICES+=("$device")
    fi
done

echo ""
echo "=== Results ==="
echo "Pass: $PASS / ${#DEVICES[@]}"
echo "Fail: $FAIL / ${#DEVICES[@]}"

if [ $FAIL -gt 0 ]; then
    echo "Failed devices: ${FAILED_DEVICES[*]}"
    exit 1
fi

exit 0
