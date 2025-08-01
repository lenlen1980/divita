#!/bin/bash

echo "=== DIVITA Comprehensive Health Check (v2) ==="
echo "Generated at: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Health metrics
total_checks=0
passed_checks=0
warnings=0
errors=0

# Function to perform check
check() {
    local name="$1"
    local command="$2"
    local expected="$3"
    local is_critical="$4"
    
    total_checks=$((total_checks + 1))
    echo -n "   $name: "
    
    result=$(timeout 5 bash -c "$command" 2>/dev/null)
    
    if [ "$result" = "$expected" ]; then
        echo -e "${GREEN}✓ OK${NC}"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (got: $result)"
        if [ "$is_critical" = "true" ]; then
            errors=$((errors + 1))
        else
            warnings=$((warnings + 1))
        fi
        return 1
    fi
}

# Function for warning checks
check_warn() {
    local name="$1"
    local command="$2"
    local threshold="$3"
    local comparison="$4"  # -lt, -gt, -eq
    
    total_checks=$((total_checks + 1))
    echo -n "   $name: "
    
    result=$(timeout 5 bash -c "$command" 2>/dev/null)
    
    if [ -z "$result" ]; then
        echo -e "${RED}✗ No data${NC}"
        errors=$((errors + 1))
        return 1
    fi
    
    if [ "$result" "$comparison" "$threshold" ]; then
        echo -e "${GREEN}✓ $result (OK)${NC}"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${YELLOW}⚠ $result (Warning)${NC}"
        warnings=$((warnings + 1))
        return 1
    fi
}

echo -e "${BLUE}1. INFRASTRUCTURE (CRITICAL)${NC}"
echo "==============================="
check "Nginx Status" "systemctl is-active nginx" "active" "true"
check "HTTPS Response" "curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://divita.ae" "200" "true"
check "HTTP Redirect" "curl -s -o /dev/null -w '%{http_code}' http://divita.ae" "301" "true"

echo ""
echo -e "${BLUE}2. PROXY ENDPOINTS${NC}"
echo "===================="
check "Google Fonts API" "curl -s -o /dev/null -w '%{http_code}' --max-time 5 'https://divita.ae/proxy/fonts/api/css?family=Inter'" "200" "false"
check "jsDelivr CDN" "curl -s -o /dev/null -w '%{http_code}' --max-time 5 'https://divita.ae/proxy/jsdelivr/npm/jquery@3.6.4/dist/jquery.min.js'" "200" "false"
check "Local Assets" "test -d /var/www/html/assets && echo 'exists'" "exists" "true"

echo ""
echo -e "${BLUE}3. PERFORMANCE METRICS${NC}"
echo "========================"
check_warn "Page Load Time (ms)" "curl -s -o /dev/null -w '%{time_total}' --max-time 10 https://divita.ae | awk '{print int($1*1000)}'" "1000" "-lt"
check_warn "Cache Size (MB)" "du -sm /var/www/html/proxy/cache 2>/dev/null | cut -f1" "100" "-lt"
check_warn "Error Rate (last hour)" "grep \"\$(date '+%d/%b/%Y:%H' -d '1 hour ago')\" /var/www/html/proxy/logs/access.log 2>/dev/null | wc -l" "10" "-lt"

echo ""
echo -e "${BLUE}4. RESOURCE AVAILABILITY${NC}"
echo "=========================="
check_warn "Local Images" "find /var/www/html/assets -name '*.png' -o -name '*.jpg' | wc -l" "1" "-gt"
check_warn "404 Errors (last 100)" "tail -100 /var/www/html/proxy/logs/access.log 2>/dev/null | grep ' 404 ' | wc -l" "5" "-lt"
check "Critical Dirs" "test -d /var/www/html/proxy/logs && test -d /var/www/html/proxy/cache && test -d /var/www/html/assets && echo 'ok'" "ok" "true"

echo ""
echo -e "${BLUE}5. SECURITY CHECKS${NC}"
echo "===================="
check "Nginx Config" "nginx -t 2>&1 | grep -q 'syntax is ok' && echo 'ok'" "ok" "true"
check_warn "Failed Logins" "grep 'Failed' /var/log/auth.log 2>/dev/null | grep \"$(date '+%b %e')\" | wc -l" "10" "-lt"
check "Firewall Active" "ufw status | grep -q 'Status: active' && echo 'ok' || echo 'inactive'" "ok" "true"

echo ""
echo "======================================="
echo -e "${BLUE}SUMMARY${NC}"
echo "======================================="
echo "Total Checks: $total_checks"
echo -e "Passed: ${GREEN}$passed_checks${NC}"
echo -e "Warnings: ${YELLOW}$warnings${NC}"
echo -e "Errors: ${RED}$errors${NC}"

# Calculate health score
health_score=$(( (passed_checks * 100) / total_checks ))
echo ""
echo -n "Overall Health Score: "
if [ $health_score -ge 90 ]; then
    echo -e "${GREEN}${health_score}% - EXCELLENT${NC}"
elif [ $health_score -ge 70 ]; then
    echo -e "${YELLOW}${health_score}% - GOOD${NC}"
else
    echo -e "${RED}${health_score}% - NEEDS ATTENTION${NC}"
fi

# Export metrics
cat > /var/www/html/proxy/logs/health-metrics.json << METRICS
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "health_score": $health_score,
  "total_checks": $total_checks,
  "passed": $passed_checks,
  "warnings": $warnings,
  "errors": $errors
}
METRICS
