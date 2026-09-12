---
type: rules
updated: 2026-06-22
зачем: как ДОЛЖЕН работать вечный YouTube-стрим «Сказки от Папы» — чтобы не падал и быстро чинился
---

# Правила вечного стрима (Сказки от Папы 24/7)

> Канал-фундамент. Простой = потеря охвата/дохода. Эти правила выведены из разбора простоя 19–21.06.2026.

## Архитектура (как есть)
- **VPS** `5.129.252.18` (Timeweb, 1 ядро / 961 МБ) → systemd `yt-stream` → `/opt/yt-streamer/scripts/stream.sh` → `ffmpeg` пушит плейлист `/opt/yt-playlist/*.mp4` на `rtmps://a.rtmp.youtube.com:443/live2/<ключ>`.
- **Ключ потока** `f78a-qhqc-xjb2-ea3q-2yqg` = liveStream id `LQHAQfMP_yX8-PTpcO-Feg1718884066779797` («Default stream key»).
- Доступ к VPS с рабочей машины — **только через прокси-тоннель** (прямой SSH/ping заблокирован). См. [[vps_access_and_guard]].

## ЖЁСТКИЕ ПРАВИЛА (нарушение = простой)

### Поток (ffmpeg / stream.sh)
1. **Непрерывный ОДИН ffmpeg** на весь плейлист: `-stream_loop -1 -f concat`. ❌ НЕЛЬЗЯ запускать ffmpeg по одному файлу в цикле — разрыв RTMP между файлами завершает YouTube-эфир (autoStop).
2. **`-c copy`, без переэнкода.** VPS = 1 ядро, libx264 в реалтайме не тянет. Исходники уже единообразны (h264 1080p30 / aac 44.1k стерео, keyframe каждые 2с) → copy безопасен и совместим с YouTube.
3. **Прямой egress (без прокси).** YouTube принимает поток с RU-IP (`health=good` проверено). proxychains НЕ нужен — Андрей хочет без прокси. (proxychains4 на VPS остаётся установленным как запасной вариант, но в `stream.sh` не используется.)
4. При падении ffmpeg — авто-реконнект (`while true; … sleep 3`).
5. Эталон скрипта = `act/stream/scripts/stream.sh` (в репо). Деплой/откат — `act/scripts/vps_stream_fix.py --apply` (бэкап делается автоматически).

### Эфир на YouTube (broadcast)
6. **`enableAutoStop = False`** — ОБЯЗАТЕЛЬНО. С autoStop=True любой разрыв завершает эфир навсегда (нельзя воскресить). Это была корневая причина простоя.
7. **Видеорекордер / DVR — ВЫКЛЮЧЕН** (`enableDvr = False`). Требование Андрея.
8. **`enableAutoStart = False`, `monitorStream.enableMonitorStream = False`** — чтобы эфиром управлять вручную/через API (иначе ручной `transition` даёт 403 «Invalid transition»).
9. Новый эфир создаём, КОПИРУЯ настройки эталона (title/описание/доступ public/`selfDeclaredMadeForKids`) — не менять политику самовольно.
10. Поднятие эфира = `act/scripts/yt_create_live.py` (создать → bind к активному потоку → transition→live).

### Что НЕ ронять
11. **Не трогать VPS/прокси без предупреждения о риске для стрима.** Любой рестарт сервиса = разрыв; при autoStop=False эфир переживёт, но предупреждать Андрея — обязательно.
12. Прокси-переменные в `/etc/environment` на VPS — оставить (для бота), на стрим не влияют.

## Проверка / источники истины
- Сервис на VPS: `python act/scripts/vps_guard.py` (yt-stream/nginx/ffmpeg).
- **Эфир (главный критерий):** `python act/scripts/yt_live_status.py` — есть ли active broadcast в `live` + health потока.
- Помни: `systemctl active` ≠ зритель видит эфир; `health=good` ≠ эфир в live. Полную правду даёт ТОЛЬКО YouTube API (lifeCycleStatus active-broadcast).

## «Всё ок» = одновременно
- liveStream `streamStatus=active`, `health ∈ {good, ok}`;
- есть **один** broadcast в `lifeCycle=live`, привязанный к этому потоку;
- ffmpeg на VPS жив (один процесс, `-stream_loop`).

## Инструменты
`vps_guard.py` · `vps_stream_fix.py` (deploy stream.sh) · `yt_live_status.py` · `yt_create_live.py` · `yt_set_dvr.py` · `stream_status.py` (монитор+дашборд+авто-recover). Все — `python …`, без пайпов/`&&`.
