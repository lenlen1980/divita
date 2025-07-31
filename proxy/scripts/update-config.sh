#!/bin/bash
# update-config.sh - Обновление конфигурации прокси

echo "=== Updating Proxy Configuration ==="

# Проверка прав
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Бэкап текущей конфигурации
echo "1. Creating backup..."
cp /etc/nginx/sites-available/divita-proxy /etc/nginx/sites-available/divita-proxy.backup.$(date +%Y%m%d_%H%M%S)

# Проверка синтаксиса
echo "2. Testing nginx configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "ERROR: Nginx configuration test failed!"
    exit 1
fi

# Перезагрузка Nginx
echo "3. Reloading nginx..."
systemctl reload nginx

# Очистка старого кэша (опционально)
echo "4. Cache management..."
cache_size=$(du -sh /var/www/html/proxy/cache/ | cut -f1)
echo "   Current cache size: $cache_size"

# Проверка работоспособности
echo "5. Testing proxy endpoints..."
/var/www/html/proxy/scripts/test-proxy.sh

echo ""
echo "Configuration update completed!"
