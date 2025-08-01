#!/bin/bash
# test-proxy.sh - Проверка работоспособности прокси

echo "=== Testing Proxy Endpoints ==="
echo ""

# Массив тестовых URL
declare -A test_urls=(
    ["Main Site"]="/"
    ["Framer Image"]="/assets/images/framer/kTpflOGZxcyWvbSzQyrMZu2LOo.png"
    ["Local Assets"]="/assets/css/main.css"
    ["Proxy Status"]="/proxy/status"
)

# Проверяем каждый endpoint
for name in "${!test_urls[@]}"; do
    url="http://localhost${test_urls[$name]}"
    echo -n "Testing $name: "
    
    # Делаем запрос и проверяем статус
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5)
    
    if [[ "$status" == "200" ]] || [[ "$status" == "304" ]]; then
        echo "✓ OK (HTTP $status)"
    else
        echo "✗ ERROR (HTTP $status)"
    fi
done

echo ""
echo "=== External URL Test (via proxy) ==="
# Тестируем внешние URL через прокси
external_test_urls=(
    "http://localhost/proxy/fonts/api/css?family=Inter"
    "http://localhost/proxy/framer/sites/test"
)

for url in "${external_test_urls[@]}"; do
    echo -n "Testing $url: "
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5)
    echo "HTTP $status"
done

echo ""
echo "=== Cache Status ==="
du -sh /var/www/html/proxy/cache/

echo ""
echo "=== Recent Access (last 10) ==="
tail -10 /var/www/html/proxy/logs/access.log | cut -d' ' -f1,4,7,9

