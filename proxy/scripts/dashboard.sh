#!/bin/bash

# dashboard.sh - Real-time monitoring dashboard

clear

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    DIVITA MONITORING DASHBOARD                  ║"
    echo "║                    $(date '+%Y-%m-%d %H:%M:%S')                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # System Resources
    echo "📊 SYSTEM RESOURCES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    printf "CPU Usage:     [%-20s] %.1f%%\n" $(printf '#%.0s' $(seq 1 $(echo "$cpu_usage/5" | bc))) $cpu_usage
    
    # Memory
    mem_info=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2}')
    printf "Memory Usage:  [%-20s] %.1f%%\n" $(printf '#%.0s' $(seq 1 $(echo "$mem_info/5" | bc))) $mem_info
    
    # Disk
    disk_usage=$(df -h / | awk 'NR==2{print $(NF-1)}' | sed 's/%//')
    printf "Disk Usage:    [%-20s] %s%%\n" $(printf '#%.0s' $(seq 1 $(echo "$disk_usage/5" | bc))) $disk_usage
    
    echo ""
    echo "🌐 WEB SERVICE STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Nginx status
    if systemctl is-active --quiet nginx; then
        echo "Nginx:         ✅ Running"
        
        # Connections
        connections=$(ss -ant | grep :443 | wc -l)
        echo "HTTPS Conns:   $connections"
    else
        echo "Nginx:         ❌ Stopped"
    fi
    
    # Response time
    response_time=$(curl -s -o /dev/null -w '%{time_total}' --max-time 5 https://divita.ae 2>/dev/null | awk '{print int($1*1000)}')
    if [ -n "$response_time" ]; then
        echo "Response Time: ${response_time}ms"
    fi
    
    echo ""
    echo "📈 TRAFFIC STATISTICS (Last 5 min)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -f /var/www/html/proxy/logs/access.log ]; then
        # Requests in last 5 minutes
        requests=$(awk -v d1="$(date -d '5 minutes ago' '+%d/%b/%Y:%H:%M')" '$4 > "["d1' /var/www/html/proxy/logs/access.log | wc -l)
        echo "Total Requests: $requests"
        
        # Status codes
        echo "Status Codes:"
        awk -v d1="$(date -d '5 minutes ago' '+%d/%b/%Y:%H:%M')" '$4 > "["d1' /var/www/html/proxy/logs/access.log | \
            awk '{print $9}' | sort | uniq -c | sort -rn | head -5 | \
            while read count code; do
                printf "  %s: %d\n" "$code" "$count"
            done
        
        # Top endpoints
        echo ""
        echo "Top Endpoints:"
        awk -v d1="$(date -d '5 minutes ago' '+%d/%b/%Y:%H:%M')" '$4 > "["d1' /var/www/html/proxy/logs/access.log | \
            awk '{print $7}' | grep -E '^/proxy/' | \
            sed 's/\?.*$//' | sort | uniq -c | sort -rn | head -3 | \
            while read count endpoint; do
                printf "  %-40s %d\n" "${endpoint:0:40}" "$count"
            done
    fi
    
    echo ""
    echo "⚠️  ALERTS & WARNINGS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Recent errors
    if [ -f /var/www/html/proxy/logs/error.log ]; then
        recent_errors=$(tail -100 /var/www/html/proxy/logs/error.log | wc -l)
        if [ "$recent_errors" -gt 0 ]; then
            echo "Recent Errors: $recent_errors (last 100 lines)"
            tail -3 /var/www/html/proxy/logs/error.log | sed 's/^/  /'
        else
            echo "No recent errors ✅"
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press Ctrl+C to exit | Refreshing in 5 seconds..."
    
    sleep 5
done
