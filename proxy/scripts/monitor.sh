#!/bin/bash
# monitor.sh - Проверка работоспособности прокси

echo "=== Мониторинг прокси-сервера DIVITA ==="
echo "Время: $(date)"
echo "========================================"

PROXY_DOMAINS=(
    "divita.ae/proxy/status"
    "divita.ae/proxy/fonts/css?family=Inter:wght@400"
)

SUCCESS_COUNT=0
TOTAL_COUNT=${#PROXY_DOMAINS[@]}

for domain in "${PROXY_DOMAINS[@]}"; do
    echo -n "Проверяем $domain ... "
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain" --connect-timeout 10)
    
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo "✓ OK (HTTP $HTTP_CODE)"
        ((SUCCESS_COUNT++))
    else
        echo "✗ ERROR (HTTP $HTTP_CODE)"
    fi
done

echo "========================================"
echo "Результат: $SUCCESS_COUNT/$TOTAL_COUNT сервисов работают"

if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
    echo "✓ Все прокси-сервисы работают нормально"
    exit 0
else
    echo "⚠ Обнаружены проблемы с прокси-сервисами"
    exit 1
fi
