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
