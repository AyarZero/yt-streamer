# yt-streamer

Минимальный набор скриптов и конфигов для 24/7 трансляции локального плейлиста на YouTube через nginx-rtmp и ffmpeg.

## Требования
- Ubuntu Server 24.04 LTS.
- Root-доступ к серверу.
- Установленный `git`.

## Клонирование репозитория
```bash
git clone <URL_вашего_репозитория> yt-streamer
cd yt-streamer
```

## Установка
Запустите установочный скрипт от пользователя root:
```bash
sudo ./scripts/install.sh
```

## Настройка YouTube ключа
1. Откройте `/etc/nginx/nginx.conf`.
2. В блоке `application live` раскомментируйте строку `push rtmp://...` и подставьте реальный `YOUR_STREAM_KEY`.
3. Проверяйте конфиг и перезапускайте nginx:
   ```bash
   nginx -t
   systemctl restart nginx
   ```

## Добавление видео и плейлиста
- Скопируйте свои файлы `video1.mp4`, `video2.mp4`, ... в `/opt/yt-playlist`.
- Отредактируйте `/opt/yt-playlist/playlist.txt`, чтобы имена совпадали с реальными файлами.

## Управление сервисом
```bash
systemctl status yt-stream.service
journalctl -u yt-stream.service -f
```

## Если нет потока на YouTube
- Проверьте правильность ключа/URL в `/etc/nginx/nginx.conf` и ещё раз перезапустите nginx.
- Убедитесь, что `nginx -t` проходит без ошибок.
- Посмотрите статус и логи сервиса: `systemctl status yt-stream.service` и `journalctl -u yt-stream.service -f`.
