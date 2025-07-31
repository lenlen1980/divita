#!/bin/bash
# Скрипт для поддержания SSH соединения активным
while true; do
    echo "=== SSH Keep-Alive $(date) ==="
    echo "Server time: $(date)"
    echo "Uptime: $(uptime)"
    echo "Active connections: $(who | wc -l)"
    sleep 60
done
