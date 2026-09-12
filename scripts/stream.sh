#!/bin/bash
set -euo pipefail

PLAYLIST_DIR="/opt/yt-playlist"
STREAM_KEY="f78a-qhqc-xjb2-ea3q-2yqg"
TMP_PLAYLIST="/tmp/yt_shuffled_playlist.txt"

while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Генерация нового перемешанного плейлиста..."

    find "$PLAYLIST_DIR" -maxdepth 1 -name "*.mp4" | shuf | while read -r f; do
        echo "file '$f'"
    done > "$TMP_PLAYLIST"

    COUNT=$(wc -l < "$TMP_PLAYLIST")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Файлов в плейлисте: $COUNT. Запуск ffmpeg..."

    ffmpeg -re -fflags +genpts -f concat -safe 0 -i "$TMP_PLAYLIST" \
        -c:v libx264 -preset veryfast -profile:v high \
        -b:v 2500k -maxrate 2500k -bufsize 5000k \
        -g 60 -keyint_min 60 -r 30 -pix_fmt yuv420p \
        -c:a aac -b:a 128k -ar 44100 -ac 2 \
        -f flv -flvflags no_duration_filesize \
        "rtmps://a.rtmp.youtube.com:443/live2/$STREAM_KEY" || true

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ffmpeg завершился, пауза 3с перед перезапуском..."
    sleep 3
done
