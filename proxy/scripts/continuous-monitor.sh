#!/bin/bash

# continuous-monitor.sh - Непрерывный мониторинг с алертами

ALERT_EMAIL="admin@divita.ae"
SLACK_WEBHOOK_URL=""  # Заполнить при необходимости
TELEGRAM_BOT_TOKEN=""  # Заполнить при необходимости
TELEGRAM_CHAT_ID=""    # Заполнить при необходимости

# Thresholds
ERROR_THRESHOLD=50
RESPONSE_TIME_THRESHOLD=2000  # ms
DISK_USAGE_THRESHOLD=80      # %
MEMORY_USAGE_THRESHOLD=90     # %

# Alert function
send_alert() {
    local severity="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$severity] $message" >> /var/www/html/proxy/logs/alerts.log
    
    # Console output
    case "$severity" in
        "CRITICAL")
            echo -e "\033[0;31m[CRITICAL]\033[0m $message"
            ;;
        "WARNING")
            echo -e "\033[1;33m[WARNING]\033[0m $message"
            ;;
        "INFO")
            echo -e "\033[0;34m[INFO]\033[0m $message"
            ;;
    esac
    
    # Email alert for critical issues
    if [ "$severity" = "CRITICAL" ] && [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "[DIVITA Alert] $severity: $message" "$ALERT_EMAIL" 2>/dev/null
    fi
    
    # Slack notification
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"[$severity] $message\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null
    fi
    
    # Telegram notification
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=$TELEGRAM_CHAT_ID" \
            -d "text=[$severity] $message" > /dev/null 2>&1
    fi
}

# Check functions
check_nginx() {
    if ! systemctl is-active --quiet nginx; then
        send_alert "CRITICAL" "Nginx is down!"
        return 1
    fi
    return 0
}

check_disk_usage() {
    local usage=$(df -h / | tail -1 | awk '{print $(NF-1)}' | sed 's/%//')
    if [ "$usage" -gt "$DISK_USAGE_THRESHOLD" ]; then
        send_alert "WARNING" "Disk usage is at ${usage}%"
        return 1
    fi
    return 0
}

check_memory_usage() {
    local usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    if [ "$usage" -gt "$MEMORY_USAGE_THRESHOLD" ]; then
        send_alert "WARNING" "Memory usage is at ${usage}%"
        return 1
    fi
    return 0
}

check_response_time() {
    local response_time=$(curl -s -o /dev/null -w '%{time_total}' --max-time 10 https://divita.ae | awk '{print int($1*1000)}')
    if [ "$response_time" -gt "$RESPONSE_TIME_THRESHOLD" ]; then
        send_alert "WARNING" "Slow response time: ${response_time}ms"
        return 1
    fi
    return 0
}

check_error_rate() {
    local errors=$(tail -1000 /var/www/html/proxy/logs/access.log 2>/dev/null | grep -c ' [45][0-9][0-9] ')
    if [ "$errors" -gt "$ERROR_THRESHOLD" ]; then
        send_alert "CRITICAL" "High error rate: $errors errors in last 1000 requests"
        return 1
    fi
    return 0
}

check_ssl_expiry() {
    local expiry_date=$(echo | openssl s_client -servername divita.ae -connect divita.ae:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
    local current_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    if [ "$days_left" -lt 7 ]; then
        send_alert "CRITICAL" "SSL certificate expires in $days_left days!"
        return 1
    elif [ "$days_left" -lt 30 ]; then
        send_alert "WARNING" "SSL certificate expires in $days_left days"
        return 1
    fi
    return 0
}

# Main monitoring loop
if [ "$1" = "--daemon" ]; then
    send_alert "INFO" "Starting continuous monitoring daemon"
    
    while true; do
        check_nginx
        check_disk_usage
        check_memory_usage
        check_response_time
        check_error_rate
        check_ssl_expiry
        
        sleep 300  # Check every 5 minutes
    done
else
    # Single run
    echo "=== DIVITA Monitoring Check ==="
    echo "Time: $(date)"
    echo ""
    
    check_nginx && echo "✓ Nginx: OK" || echo "✗ Nginx: FAIL"
    check_disk_usage && echo "✓ Disk Usage: OK" || echo "✗ Disk Usage: WARNING"
    check_memory_usage && echo "✓ Memory Usage: OK" || echo "✗ Memory Usage: WARNING"
    check_response_time && echo "✓ Response Time: OK" || echo "✗ Response Time: WARNING"
    check_error_rate && echo "✓ Error Rate: OK" || echo "✗ Error Rate: WARNING"
    check_ssl_expiry && echo "✓ SSL Certificate: OK" || echo "✗ SSL Certificate: WARNING"
    
    echo ""
    echo "To run as daemon: $0 --daemon &"
fi
