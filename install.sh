#!/bin/bash
# Встроить белый курсор в system.img Waydroid / Bake the white cursor into Waydroid's system.img
#   sudo bash install.sh            — с копией образа system.img.before-white-cursor
#   sudo bash install.sh remove     — вернуть копию
# Закройте игры: сессия Waydroid будет остановлена. / Waydroid session will be stopped.
set -e
cd "$(dirname "$0")"
IMG=/var/lib/waydroid/images/system.img
BAK=$IMG.before-white-cursor
APK=build/WhiteCursor.apk; [ -f "$APK" ] || APK=prebuilt/WhiteCursor.apk
DIR=/system/product/overlay/WhiteCursor

waydroid session stop 2>/dev/null || true
systemctl stop waydroid-container

if [ "$1" = remove ]; then
    [ -f "$BAK" ] || { echo "нет $BAK / no backup"; exit 1; }
    cp --reflink=auto "$BAK" "$IMG"
    systemctl start waydroid-container
    echo "Откат сделан / reverted"
    exit 0
fi

[ -f "$BAK" ] || cp --reflink=auto "$IMG" "$BAK"
M=$(mktemp -d)
mount -o loop,rw "$IMG" "$M"
mkdir -p "$M$DIR"
install -m 644 "$APK" "$M$DIR/WhiteCursor.apk"
chmod 755 "$M$DIR"
umount "$M"; rmdir "$M"
systemctl start waydroid-container
echo "Готово, запустите Waydroid / Done, start Waydroid. Копия / backup: $BAK"
