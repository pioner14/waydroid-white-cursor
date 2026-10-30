#!/bin/bash
# Проверка перед стартом waydroid-container: белый курсор на месте?
# Check before waydroid-container starts: is the white cursor still there?
#
# - WhiteCursor.apk в system.img (/system/product/overlay/WhiteCursor/) — если образ
#   заменили (waydroid upgrade и т.п.), кладёт его обратно.
#
# Ставится install_guard.sh; запускается от root как ExecStartPre=- (ошибка не мешает старту).
# Installed by install_guard.sh; runs as root via ExecStartPre=- (failure never blocks start).
LIB=/usr/local/lib/waydroid-whitecursor
IMG=/var/lib/waydroid/images/system.img
DST=/system/product/overlay/WhiteCursor/WhiteCursor.apk
log() { echo "white-cursor: $*"; }

[ -f "$IMG" ] || { log "нет $IMG"; exit 0; }

if debugfs -R "stat $DST" "$IMG" 2>/dev/null | grep -q '^Inode:'; then
    log "оверлей на месте"
elif mountpoint -q /var/lib/waydroid/rootfs; then
    log "образ смонтирован, пропускаю"
else
    log "оверлея нет — добавляю"
    M=$(mktemp -d)
    if mount -o loop,rw "$IMG" "$M"; then
        mkdir -p "$M$(dirname $DST)"
        install -m 644 "$LIB/WhiteCursor.apk" "$M$DST"
        chmod 755 "$M$(dirname $DST)"
        umount "$M"
        log "добавлен"
    fi
    rmdir "$M"
fi
exit 0
