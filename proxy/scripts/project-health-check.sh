#!/bin/bash

echo "=== DIVITA Project Health Check ==="
echo "Generated at: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Health metrics
health_score=100
issues=0

echo "1. INFRASTRUCTURE"
echo "=================="

# Nginx
nginx_status=$(systemctl is-active nginx 2>/dev/null)
if [ "$nginx_status" = "active" ]; then
    echo -e "   Nginx: ${GREEN}✓ Running${NC}"
else
    echo -e "   Nginx: ${RED}✗ Not running${NC}"
    health_score=$((health_score - 20))
    issues=$((issues + 1))
fi

# SSL
ssl_check=$(curl -s -o /dev/null -w "%{http_code}" https://divita.ae 2>/dev/null)
if [ "$ssl_check" = "200" ]; then
    echo -e "   SSL: ${GREEN}✓ Working${NC}"
else
    echo -e "   SSL: ${YELLOW}⚠ Check needed${NC}"
    health_score=$((health_score - 10))
    issues=$((issues + 1))
fi

echo ""
echo "2. PROXY SERVICES"
echo "=================="

# Check key proxy endpoints
endpoints=(
    "proxy/fonts/api/css?family=Inter:200"
    "proxy/jsdelivr/npm/jquery:200"
    "assets/external/framer/images/kTpflOGZxcyWvbSzQyrMZu2LOo.png:200"
)

for endpoint in "${endpoints[@]}"; do
    url="${endpoint%:*}"
    expected="${endpoint##*:}"
    status=$(curl -s -o /dev/null -w "%{http_code}" "https://divita.ae/$url" 2>/dev/null)
    
    if [ "$status" = "$expected" ]; then
        echo -e "   ${url%%/*}: ${GREEN}✓ OK${NC}"
    else
        echo -e "   ${url%%/*}: ${RED}✗ Error (HTTP $status)${NC}"
        health_score=$((health_score - 5))
        issues=$((issues + 1))
    fi
done

echo ""
echo "3. RESOURCES"
echo "=================="

# Images
total_images=$(find /var/www/html/assets -name "*.jpg" -o -name "*.png" | wc -l)
echo "   Images: $total_images files"

# Duplicates  
duplicates=$(find /var/www/html/assets/images/framerusercontent -type f 2>/dev/null | wc -l)
if [ "$duplicates" -gt 0 ]; then
    echo -e "   Duplicates: ${YELLOW}⚠ $duplicates duplicate images${NC}"
    health_score=$((health_score - 5))
else
    echo -e "   Duplicates: ${GREEN}✓ None${NC}"
fi

# Cache
cache_size=$(du -sh /var/www/html/proxy/cache 2>/dev/null | cut -f1)
echo "   Cache: $cache_size used"

echo ""
echo "4. PERFORMANCE"
echo "=================="

# Load time
load_time=$(curl -s -o /dev/null -w "%{time_total}" https://divita.ae 2>/dev/null)
load_ms=$(echo "$load_time * 1000" | bc | cut -d. -f1)

if [ "$load_ms" -lt 200 ]; then
    echo -e "   Load time: ${GREEN}✓ ${load_ms}ms${NC}"
elif [ "$load_ms" -lt 500 ]; then
    echo -e "   Load time: ${YELLOW}⚠ ${load_ms}ms${NC}"
    health_score=$((health_score - 5))
else
    echo -e "   Load time: ${RED}✗ ${load_ms}ms${NC}"
    health_score=$((health_score - 10))
    issues=$((issues + 1))
fi

# Page size
page_size=$(curl -s -o /dev/null -w "%{size_download}" https://divita.ae 2>/dev/null)
page_size_mb=$(echo "scale=2; $page_size / 1048576" | bc)
echo "   Page size: ${page_size_mb}MB"

echo ""
echo "5. METHODOLOGY"
echo "=================="

# Check critical scripts
critical_scripts=(
    "monitor.sh"
    "test-proxy-v2.sh"
    "deploy.sh"
    "create-missing-module-stubs.sh"
)

missing_scripts=0
for script in "${critical_scripts[@]}"; do
    if [ -f "/var/www/html/proxy/scripts/$script" ]; then
        echo -e "   $script: ${GREEN}✓${NC}"
    else
        echo -e "   $script: ${RED}✗ Missing${NC}"
        missing_scripts=$((missing_scripts + 1))
        health_score=$((health_score - 5))
    fi
done

echo ""
echo "6. RECENT ACTIVITY"
echo "=================="

# Recent errors
recent_errors=$(tail -100 /var/www/html/proxy/logs/error.log 2>/dev/null | grep -c "error")
if [ "$recent_errors" -gt 10 ]; then
    echo -e "   Recent errors: ${RED}✗ $recent_errors errors${NC}"
    health_score=$((health_score - 10))
    issues=$((issues + 1))
elif [ "$recent_errors" -gt 0 ]; then
    echo -e "   Recent errors: ${YELLOW}⚠ $recent_errors errors${NC}"
else
    echo -e "   Recent errors: ${GREEN}✓ None${NC}"
fi

# Last deployment
last_mod=$(stat -c %y /var/www/html/index.html 2>/dev/null | cut -d' ' -f1)
echo "   Last update: $last_mod"

echo ""
echo "=============================="
echo -e "OVERALL HEALTH SCORE: ${health_score}/100"
if [ "$health_score" -ge 90 ]; then
    echo -e "Status: ${GREEN}EXCELLENT${NC}"
elif [ "$health_score" -ge 70 ]; then
    echo -e "Status: ${YELLOW}GOOD (needs attention)${NC}"
else
    echo -e "Status: ${RED}POOR (immediate action required)${NC}"
fi
echo "Issues found: $issues"
echo "=============================="

if [ "$issues" -gt 0 ]; then
    echo ""
    echo "RECOMMENDATIONS:"
    [ "$duplicates" -gt 0 ] && echo "- Remove duplicate images from assets/images/framerusercontent/"
    [ "$recent_errors" -gt 10 ] && echo "- Investigate and fix recent errors in logs"
    [ "$missing_scripts" -gt 0 ] && echo "- Restore missing critical scripts"
fi
