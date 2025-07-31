#!/bin/bash
# test-proxy.sh - Проверка работоспособности прокси

echo "=== Testing Proxy Endpoints ==="
echo ""

# Массив тестовых URL
declare -A test_urls=(
    ["Framer CDN"]="/proxy/framer/images/kTpflOGZxcyWvbSzQyrMZu2LOo.png"
    ["Google Fonts API"]="/proxy/fonts/api/css?family=Inter"
    ["jsDelivr"]="/proxy/jsdelivr/npm/jquery@3.6.4/dist/jquery.min.js"
    ["unpkg"]="/proxy/unpkg/react@18/umd/react.production.min.js"
    ["Proxy Status"]="/proxy/status"
)

# Проверяем каждый endpoint
for name in "${!test_urls[@]}"; do
    url="https://divita.ae${test_urls[$name]}"
    echo -n "Testing $name: "
    
    # Делаем запрос и проверяем статус
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status" = "200" ]; then
        echo "✓ OK (HTTP $status)"
    else
        echo "✗ ERROR (HTTP $status)"
    fi
done

echo ""
echo "=== Cache Status ==="
du -sh /var/www/html/proxy/cache/ 2>/dev/null || echo "Cache directory empty"

echo ""
echo "=== Recent Proxy Logs ==="
tail -5 /var/www/html/proxy/logs/access.log 2>/dev/null || echo "No access logs yet"
