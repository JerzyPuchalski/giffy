#!/bin/bash

# How to install:
#   sudo apt-get install libav-tools imagemagick
#   chmod a+x giffy.sh
#   connect your device with ADB (cable or wifi)

# Help message
function usage() {
	cat << EOF
Captures screen from Android device via ADB and converts it to a animated GIF.
Usage: ./giffy.sh output.gif 

EOF
}

# Output file
if [[ ! "$1" ]]; then
	usage
	exit 1
fi

TMP_MP4="/tmp/android-screen-tmp.mp4"
TMP_FRAMES_DIR="/tmp/android-screen-tmp-frames"
TMP_GIF="/tmp/android-screen-tmp.gif"

# Cleanup
rm -f "$TMP_MP4"
rm -rf "$TMP_FRAMES_DIR"
rm -f "$TMP_GIF"

# Record and pull video

CURRENTLY_SHOWING_TOUCHES=`adb shell settings get system show_touches`
echo "Turning on Show Touches on device, currently this setting is: $CURRENTLY_SHOWING_TOUCHES"
adb shell settings put system show_touches 1
echo "Starting recording, press CTRL+C when you're done..."
trap "echo 'Recording stopped, downloading output...'" INT
adb shell screenrecord --verbose --bit-rate 1000000 "/sdcard/tmp-android-screen.mp4"
trap - INT
sleep 5
adb pull "/sdcard/tmp-android-screen.mp4" "$TMP_MP4"
sleep 1
adb shell rm "/sdcard/tmp-android-screen.mp4"
if [[ $CURRENTLY_SHOWING_TOUCHES < 1 ]]; then
    echo "Restoring Show Touches value on device"
    adb shell settings put system show_touches 0
fi
# Create frames
echo "Extracting frames..."
mkdir -p "$TMP_FRAMES_DIR"
avconv -i "$TMP_MP4" -pix_fmt rgb24 -s 360x640 -r 10 "$TMP_FRAMES_DIR/%03d.png"

# Convert to GIF
echo "Converting to GIF..."
convert -loop 0 "$TMP_FRAMES_DIR/*.png" "$TMP_GIF"
convert -layers Optimize "$TMP_GIF" "$1"

exit 0
