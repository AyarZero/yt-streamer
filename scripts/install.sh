#!/usr/bin/env bash
set -euo pipefail

log() {
    echo "[INFO] $*"
}

abort() {
    echo "[ERROR] $*" >&2
    exit 1
}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    abort "Запускайте этот скрипт от root."
fi

REPO_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYLIST_DIR="/opt/yt-playlist"
NGINX_CONF_SRC="$REPO_DIR/configs/nginx.conf"
SERVICE_SRC="$REPO_DIR/configs/yt-stream.service"

export DEBIAN_FRONTEND=noninteractive

log "Обновление списка пакетов..."
apt-get update

log "Установка nginx, rtmp-модуля и ffmpeg..."
apt-get install -y nginx libnginx-mod-rtmp ffmpeg

if ! id -u streamer >/dev/null 2>&1; then
    log "Создание пользователя streamer без sudo-прав..."
    adduser --disabled-password --gecos "" streamer
else
    log "Пользователь streamer уже существует, пропускаем создание."
fi

log "Подготовка каталога плейлиста в $PLAYLIST_DIR ..."
mkdir -p "$PLAYLIST_DIR"
chown streamer:streamer "$PLAYLIST_DIR"

if [[ ! -f "$PLAYLIST_DIR/playlist.txt" ]]; then
    log "Копирование шаблона плейлиста в $PLAYLIST_DIR/playlist.txt ..."
    cp "$REPO_DIR/playlist/playlist.txt" "$PLAYLIST_DIR/playlist.txt"
    chown streamer:streamer "$PLAYLIST_DIR/playlist.txt"
else
    log "Файл плейлиста уже есть, не перезаписываем."
fi

if [[ -f /etc/nginx/nginx.conf ]]; then
    BACKUP_PATH="/etc/nginx/nginx.conf.backup-$(date +%Y%m%d-%H%M%S)"
    log "Резервная копия текущего nginx.conf в $BACKUP_PATH ..."
    cp /etc/nginx/nginx.conf "$BACKUP_PATH"
fi

log "Установка нового nginx.conf ..."
cp "$NGINX_CONF_SRC" /etc/nginx/nginx.conf

log "Проверка nginx конфигурации ..."
nginx -t

log "Перезапуск nginx ..."
systemctl restart nginx

log "Установка systemd unit yt-stream.service ..."
cp "$SERVICE_SRC" /etc/systemd/system/yt-stream.service
systemctl daemon-reload
systemctl enable yt-stream.service
systemctl restart yt-stream.service

cat <<'EOF'
-----
Установка завершена.
Установлено: nginx + libnginx-mod-rtmp + ffmpeg
Плейлист: /opt/yt-playlist (файл playlist.txt)
Ключ YouTube: впишите push rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY в /etc/nginx/nginx.conf и перезапустите nginx.
EOF
