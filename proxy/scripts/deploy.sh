#!/bin/bash
# deploy.sh - Скрипт деплоя конфигурации прокси

echo "=== Деплой конфигурации прокси DIVITA ==="

# Проверяем права
if [[ $EUID -ne 0 ]]; then
   echo "Скрипт должен быть запущен от root"
   exit 1
fi

# Создаем резервную копию текущей конфигурации
BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /etc/nginx/sites-available "$BACKUP_DIR/"
cp -r /etc/nginx/sites-enabled "$BACKUP_DIR/"

echo "Резервная копия создана: $BACKUP_DIR"

# Копируем новую конфигурацию
cp /var/www/html/proxy/config/nginx-proxy.conf /etc/nginx/sites-available/divita-proxy

# Отключаем старую конфигурацию если есть
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

if [ -L /etc/nginx/sites-enabled/divita ]; then
    rm /etc/nginx/sites-enabled/divita
fi

# Включаем новую конфигурацию
ln -sf /etc/nginx/sites-available/divita-proxy /etc/nginx/sites-enabled/

# Тестируем конфигурацию
echo "Тестируем конфигурацию Nginx..."
if nginx -t; then
    echo "✓ Конфигурация корректна"
    echo "Перезапускаем Nginx..."
    systemctl reload nginx
    echo "✓ Nginx перезапущен"
else
    echo "✗ Ошибка в конфигурации! Откатываемся..."
    rm /etc/nginx/sites-enabled/divita-proxy
    cp -r "$BACKUP_DIR/sites-enabled/"* /etc/nginx/sites-enabled/
    systemctl reload nginx
    exit 1
fi

# Создаем директории для логов и кэша
mkdir -p /var/www/html/proxy/{logs,cache}
chown -R www-data:www-data /var/www/html/proxy/
chmod 755 /var/www/html/proxy/cache

echo "✓ Деплой завершен успешно"
