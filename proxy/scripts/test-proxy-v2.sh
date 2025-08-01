#!/bin/bash
# test-proxy-v2.sh - Улучшенная проверка работоспособности прокси

echo "=== DIVITA Proxy Test v2 ==="
echo "Time: $(date)"
echo ""

# Определяем базовый URL
BASE_URL="https://divita.ae"
LOCAL_URL="http://127.0.0.1"

echo "1. Testing via domain name:"
echo -n "   $BASE_URL: "
status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" --connect-timeout 5 -k 2>/dev/null)
if [[ -n "$status" ]] && [[ "$status" != "000" ]]; then
    echo "✓ OK (HTTP $status)"
    TEST_URL=$BASE_URL
else
    echo "✗ Not accessible"
    echo ""
    echo "2. Testing via local IP:"
    echo -n "   $LOCAL_URL: "
    status=$(curl -s -o /dev/null -w "%{http_code}" "$LOCAL_URL" --connect-timeout 5 2>/dev/null)
    if [[ -n "$status" ]] && [[ "$status" != "000" ]]; then
        echo "✓ OK (HTTP $status)"
        TEST_URL=$LOCAL_URL
    else
        echo "✗ Not accessible"
    fi
fi

echo ""
echo "3. System checks:"
echo -n "   Nginx status: "
if systemctl is-active --quiet nginx; then
    echo "✓ Running"
else
    echo "✗ Not running"
fi

echo -n "   Server IP: "
ip addr show | grep -E "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d'/' -f1

echo ""
echo "4. Recent activity (last 5 requests):"
tail -5 /var/www/html/proxy/logs/access.log 2>/dev/null | awk '{print "   "$1" "$4" "$7" "$9}' || echo "   No recent logs"

echo ""
echo "5. Recent errors (if any):"
tail -5 /var/www/html/proxy/logs/error.log 2>/dev/null | head -3 || echo "   No recent errors"

echo ""
echo "6. Resource availability:"
echo -n "   Local images: "
if [[ -d "/var/www/html/assets/images/framer" ]]; then
    count=$(find /var/www/html/assets/images/framer -name "*.png" -o -name "*.jpg" | wc -l)
    echo "✓ $count files"
else
    echo "✗ Directory not found"
fi

echo -n "   Cache size: "
du -sh /var/www/html/proxy/cache/ 2>/dev/null | cut -f1 || echo "0"

echo ""
echo "=== End of test ==="
