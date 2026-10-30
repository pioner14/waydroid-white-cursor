#!/bin/bash
# Собрать WhiteCursor.apk из res/ / Build WhiteCursor.apk from res/
#   ANDROID_SDK=~/Android/Sdk bash build.sh
# Нужны build-tools (aapt2, zipalign, apksigner) и platforms/android-33+.
# Ключ — открытый тестовый ключ AOSP, им подписаны образы Waydroid (скачивается в keys/).
set -e
cd "$(dirname "$0")"
SDK=${ANDROID_SDK:-$HOME/Android/Sdk}
BT=$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)
JAR=$(ls "$SDK"/platforms/android-*/android.jar | sort -V | tail -1)

if [ ! -f keys/platform.pk8 ]; then
    mkdir -p keys
    U=https://android.googlesource.com/platform/build/+/refs/heads/main/target/product/security
    curl -sfL "$U/platform.pk8?format=TEXT" | base64 -d > keys/platform.pk8
    curl -sfL "$U/platform.x509.pem?format=TEXT" | base64 -d > keys/platform.x509.pem
fi

rm -rf build && mkdir build
"$BT/aapt2" compile --dir res -o build/res.zip
"$BT/aapt2" link -o build/unsigned.apk --manifest AndroidManifest.xml -I "$JAR" \
    --min-sdk-version 33 --target-sdk-version 33 build/res.zip
"$BT/zipalign" -f 4 build/unsigned.apk build/aligned.apk
"$BT/apksigner" sign --key keys/platform.pk8 --cert keys/platform.x509.pem \
    --out build/WhiteCursor.apk build/aligned.apk
echo "build/WhiteCursor.apk"
