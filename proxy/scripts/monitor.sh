#!/bin/bash
# monitor.sh - Мониторинг работы прокси

echo "=== DIVITA Proxy Monitor ==="
echo "Time: $(date)"
echo ""

# Проверка статуса Nginx
echo "1. Nginx Status:"
if systemctl is-active --quiet nginx; then
    echo "   ✓ Nginx is running"
else
    echo "   ✗ Nginx is NOT running"
fi

# Проверка использования кэша
echo ""
echo "2. Cache Usage:"
cache_size=$(du -sh /var/www/html/proxy/cache/ 2>/dev/null | cut -f1)
echo "   Cache size: ${cache_size:-0}"
echo "   Cache files: $(find /var/www/html/proxy/cache/ -type f 2>/dev/null | wc -l)"

# Статистика запросов за последний час
echo ""
echo "3. Request Statistics (last hour):"
if [ -f /var/www/html/proxy/logs/access.log ]; then
    total_requests=$(grep "$(date -d '1 hour ago' '+%d/%b/%Y:%H')" /var/www/html/proxy/logs/access.log 2>/dev/null | wc -l)
    proxy_requests=$(grep "$(date -d '1 hour ago' '+%d/%b/%Y:%H')" /var/www/html/proxy/logs/access.log 2>/dev/null | grep "/proxy/" | wc -l)
    echo "   Total requests: $total_requests"
    echo "   Proxy requests: $proxy_requests"
else
    echo "   No access logs available"
fi

# Топ проксированных доменов
echo ""
echo "4. Top Proxied Domains:"
if [ -f /var/www/html/proxy/logs/access.log ]; then
    grep "/proxy/" /var/www/html/proxy/logs/access.log | \
        awk '{print $7}' | \
        sed -E 's|/proxy/([^/]+)/.*|\1|' | \
        sort | uniq -c | sort -rn | head -5 | \
        while read count domain; do
            echo "   $domain: $count requests"
        done
fi

# Ошибки за последний час
echo ""
echo "5. Recent Errors (last hour):"
if [ -f /var/www/html/proxy/logs/error.log ]; then
    error_count=$(grep "$(date -d '1 hour ago' '+%Y/%m/%d %H')" /var/www/html/proxy/logs/error.log 2>/dev/null | wc -l)
    echo "   Error count: $error_count"
    if [ "$error_count" -gt 0 ]; then
        echo "   Latest errors:"
        grep "$(date -d '1 hour ago' '+%Y/%m/%d %H')" /var/www/html/proxy/logs/error.log 2>/dev/null | tail -3 | sed 's/^/   /'
    fi
fi

echo ""
echo "=== End of Report ==="
