#!/bin/bash
# Умный скрипт для скачивания заблокированных ресурсов, которые не удалось проксировать
# Version: 2.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOWNLOAD_DIR="/var/www/html/assets/external"
LOG_FILE="/var/www/html/proxy/logs/download-$(date +%Y%m%d-%H%M%S).log"
ERROR_LOG="/var/www/html/proxy/logs/download-errors.log"
TEMP_DIR="/tmp/divita-downloads"
HTML_FILE="/var/www/html/index.html"
BACKUP_DIR="/var/www/html/backups"

# Create necessary directories
mkdir -p "$DOWNLOAD_DIR" "$TEMP_DIR" "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

error_log() {
    echo -e "$1" | tee -a "$ERROR_LOG"
}

# Function to download resource with retry logic
download_resource() {
    local url=$1
    local output_path=$2
    local max_retries=3
    local retry_count=0
    
    # Create directory if needed
    mkdir -p "$(dirname "$output_path")"
    
    while [ $retry_count -lt $max_retries ]; do
        log "${BLUE}Downloading:${NC} $url (attempt $((retry_count + 1)))"
        
        # Try different methods based on the domain
        if [[ "$url" == *"framerusercontent.com"* ]]; then
            # Special handling for Framer (CloudFront)
            curl -L -s -o "$output_path" \
                 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
                 -H "Accept: */*" \
                 -H "Accept-Language: en-US,en;q=0.9" \
                 -H "Accept-Encoding: gzip, deflate, br" \
                 -H "Origin: https://divita.ae" \
                 -H "Referer: https://divita.ae/" \
                 --compressed \
                 --connect-timeout 30 \
                 --max-time 60 \
                 "$url"
        else
            # Standard download
            curl -L -s -o "$output_path" \
                 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
                 --connect-timeout 20 \
                 --max-time 40 \
                 "$url"
        fi
        
        if [ $? -eq 0 ] && [ -f "$output_path" ] && [ -s "$output_path" ]; then
            log "${GREEN}✓ Saved to:${NC} $output_path"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log "${YELLOW}⚠ Retry in 2 seconds...${NC}"
                sleep 2
            fi
        fi
    done
    
    error_log "${RED}✗ Failed to download after $max_retries attempts:${NC} $url"
    return 1
}

# Function to extract resources from HTML
extract_resources() {
    local pattern=$1
    local domain=$2
    
    grep -oE "$pattern" "$HTML_FILE" | \
    sed 's/[");\s]*$//' | \
    sort | uniq | \
    while read -r resource_path; do
        if [[ "$resource_path" == /proxy/* ]]; then
            # Convert proxy path to actual URL
            resource_path=$(echo "$resource_path" | sed "s|/proxy/[^/]*/|$domain/|")
        fi
        echo "$resource_path"
    done
}

# Main execution
log "${GREEN}=== Smart Resource Downloader v2.0 ===${NC}"
log "Starting at: $(date)"
log "Download directory: $DOWNLOAD_DIR"
echo

# Backup current HTML
cp "$HTML_FILE" "$BACKUP_DIR/index.html.$(date +%Y%m%d-%H%M%S)"

# 1. Download Framer fonts
log "${BLUE}=== Downloading Framer Fonts ===${NC}"
mkdir -p "$DOWNLOAD_DIR/framer/assets"

# Extract all Framer font URLs
FRAMER_FONTS=$(extract_resources "/proxy/framer/assets/[a-zA-Z0-9]+\.woff2" "https://framerusercontent.com")

total_fonts=$(echo "$FRAMER_FONTS" | wc -l)
current=0

echo "$FRAMER_FONTS" | while read -r font_url; do
    if [ -n "$font_url" ]; then
        current=$((current + 1))
        filename=$(basename "$font_url")
        log "[$current/$total_fonts] Processing: $filename"
        
        # Try to download from original URL
        original_url="https://framerusercontent.com/assets/$filename"
        download_resource "$original_url" "$DOWNLOAD_DIR/framer/assets/$filename"
    fi
done

# 2. Download other blocked resources
log "${BLUE}=== Downloading Other Blocked Resources ===${NC}"

# unpkg resources
log "${BLUE}Checking for unpkg resources...${NC}"
UNPKG_RESOURCES=$(grep -oE '/proxy/unpkg/[^"]+' "$HTML_FILE" | sort | uniq || true)
if [ -n "$UNPKG_RESOURCES" ]; then
    mkdir -p "$DOWNLOAD_DIR/unpkg"
    echo "$UNPKG_RESOURCES" | while read -r resource; do
        if [ -n "$resource" ]; then
            clean_path=$(echo "$resource" | sed 's|/proxy/unpkg/||')
            download_resource "https://unpkg.com/$clean_path" "$DOWNLOAD_DIR/unpkg/$clean_path"
        fi
    done
fi

# 3. Create replacement script
log "${BLUE}=== Creating URL replacement script ===${NC}"
cat > "$DOWNLOAD_DIR/replace-urls.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Auto-generated script to replace proxy URLs with local paths

HTML_FILE="/var/www/html/index.html"
BACKUP_FILE="/var/www/html/index.html.backup-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup: $BACKUP_FILE"
cp "$HTML_FILE" "$BACKUP_FILE"

echo "Replacing URLs..."

# Replace Framer URLs
sed -i 's|/proxy/framer/assets/|/assets/external/framer/assets/|g' "$HTML_FILE"

# Replace unpkg URLs
sed -i 's|/proxy/unpkg/|/assets/external/unpkg/|g' "$HTML_FILE"

echo "URL replacement complete!"
echo "Backup saved to: $BACKUP_FILE"
SCRIPT_EOF

chmod +x "$DOWNLOAD_DIR/replace-urls.sh"

# 4. Generate download report
log "${BLUE}=== Generating Download Report ===${NC}"
REPORT_FILE="$DOWNLOAD_DIR/download-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "$REPORT_FILE" << REPORT_EOF
DIVITA Resource Download Report
Generated: $(date)

Downloaded Files:
-----------------
$(find "$DOWNLOAD_DIR" -type f -name "*.woff2" -o -name "*.js" -o -name "*.css" | sort)

Total Files: $(find "$DOWNLOAD_DIR" -type f | wc -l)
Total Size: $(du -sh "$DOWNLOAD_DIR" | cut -f1)

Failed Downloads:
-----------------
$(tail -20 "$ERROR_LOG" 2>/dev/null || echo "No errors")

Next Steps:
-----------
1. Run the URL replacement script:
   $DOWNLOAD_DIR/replace-urls.sh

2. Test the website:
   - Check that all fonts load correctly
   - Verify no 404 errors in browser console
   - Test from Russian IP if possible

3. Update Nginx configuration to serve local files:
   location /assets/external/ {
       alias /var/www/html/assets/external/;
       expires 30d;
       add_header Cache-Control "public, immutable";
   }
REPORT_EOF

# 5. Summary
echo
log "${GREEN}=== Download Summary ===${NC}"
log "Total files downloaded: $(find "$DOWNLOAD_DIR" -type f | wc -l)"
log "Total size: $(du -sh "$DOWNLOAD_DIR" | cut -f1)"
log "Report saved to: $REPORT_FILE"
log "URL replacement script: $DOWNLOAD_DIR/replace-urls.sh"
echo
log "${YELLOW}Next steps:${NC}"
log "1. Review the download report: cat $REPORT_FILE"
log "2. Run URL replacement if all resources downloaded: $DOWNLOAD_DIR/replace-urls.sh"
log "3. Test the website functionality"

# Cleanup
rm -rf "$TEMP_DIR"

log "${GREEN}Script completed at: $(date)${NC}"
