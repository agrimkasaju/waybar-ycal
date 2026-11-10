#!/bin/bash
PID_FILE="$HOME/.cache/waybar-ycal/popup.pid"

# 1. Check PID_FILE
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill -SIGUSR1 "$PID"
        exit 0
    fi
fi

# 2. Check systemd MainPID if running
PID=$(systemctl --user show --property MainPID --value waybar-ycal.service 2>/dev/null)
if [ -n "$PID" ] && [ "$PID" -gt 0 ] && kill -0 "$PID" 2>/dev/null; then
    mkdir -p "$(dirname "$PID_FILE")"
    echo "$PID" > "$PID_FILE"
    kill -SIGUSR1 "$PID"
    exit 0
fi

# 3. Check pgrep fallback
PID=$(pgrep -f "waybar-ycal.*popup.py" | head -n 1)
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    mkdir -p "$(dirname "$PID_FILE")"
    echo "$PID" > "$PID_FILE"
    kill -SIGUSR1 "$PID"
    exit 0
fi

# 4. Daemon is stopped — restart via systemd if enabled, else launch directly
if systemctl --user is-enabled waybar-ycal.service &>/dev/null; then
    systemctl --user restart waybar-ycal.service
else
    "$HOME/.config/waybar-ycal/venv/bin/python3" "$HOME/.config/waybar-ycal/popup.py" &
fi

# Wait briefly for daemon activation and signal to open
for i in {1..20}; do
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            kill -SIGUSR1 "$PID"
            exit 0
        fi
    fi
    sleep 0.1
done

