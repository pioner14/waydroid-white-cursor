#!/bin/bash
# Ставит проверку белого курсора в systemd: перед каждым стартом waydroid-container.
# Installs the white-cursor check as ExecStartPre of waydroid-container.service.
#   sudo bash install_guard.sh
set -e
cd "$(dirname "$0")"
LIB=/usr/local/lib/waydroid-whitecursor
install -d "$LIB"
APK=build/WhiteCursor.apk; [ -f "$APK" ] || APK=prebuilt/WhiteCursor.apk
install -m 644 "$APK" "$LIB/WhiteCursor.apk"
install -m 755 ensure_white_cursor.sh "$LIB/ensure_white_cursor.sh"
install -d /etc/systemd/system/waydroid-container.service.d
cat > /etc/systemd/system/waydroid-container.service.d/white-cursor.conf <<EOF
[Service]
ExecStartPre=-$LIB/ensure_white_cursor.sh
EOF
systemctl daemon-reload
"$LIB/ensure_white_cursor.sh"
