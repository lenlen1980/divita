#!/bin/bash

echo "=== DIVITA Project Optimization Script ==="
echo "Starting at: $(date)"
echo ""

# Functions
calculate_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

# 1. Clean old backups
echo "1. Cleaning old backups..."
old_backups=$(find /var/www/html -name "*.backup*" -mtime +7 2>/dev/null | wc -l)
if [ "$old_backups" -gt 0 ]; then
    echo "   Found $old_backups old backup files (>7 days)"
    # find /var/www/html -name "*.backup*" -mtime +7 -delete
    echo "   [DRY RUN] Would delete $old_backups files"
else
    echo "   ✓ No old backups to clean"
fi

# 2. Clear old cache
echo ""
echo "2. Checking cache..."
cache_size=$(calculate_size /var/www/html/proxy/cache)
echo "   Current cache size: $cache_size"
old_cache=$(find /var/www/html/proxy/cache -type f -mtime +30 2>/dev/null | wc -l)
if [ "$old_cache" -gt 0 ]; then
    echo "   Found $old_cache old cache files (>30 days)"
    # find /var/www/html/proxy/cache -type f -mtime +30 -delete
    echo "   [DRY RUN] Would delete $old_cache files"
else
    echo "   ✓ Cache is fresh"
fi

# 3. Check for duplicate images
echo ""
echo "3. Checking for duplicate images..."
declare -A checksums
duplicates=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        checksum=$(md5sum "$file" | cut -d' ' -f1)
        if [ -n "${checksums[$checksum]}" ]; then
            echo "   Duplicate found: $file == ${checksums[$checksum]}"
            duplicates=$((duplicates + 1))
        else
            checksums[$checksum]="$file"
        fi
    fi
done < <(find /var/www/html/assets -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) 2>/dev/null)

if [ "$duplicates" -eq 0 ]; then
    echo "   ✓ No duplicate images found"
else
    echo "   ⚠ Found $duplicates duplicate images"
fi

# 4. Check logs size
echo ""
echo "4. Checking logs..."
log_size=$(calculate_size /var/www/html/proxy/logs)
echo "   Current log size: $log_size"
large_logs=$(find /var/www/html/proxy/logs -type f -size +100M 2>/dev/null | wc -l)
if [ "$large_logs" -gt 0 ]; then
    echo "   ⚠ Found $large_logs large log files (>100MB)"
    echo "   Consider rotating logs with: logrotate"
else
    echo "   ✓ Log sizes are reasonable"
fi

# 5. Check for broken symlinks
echo ""
echo "5. Checking for broken symlinks..."
broken_links=$(find /var/www/html -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
if [ "$broken_links" -gt 0 ]; then
    echo "   ⚠ Found $broken_links broken symlinks"
else
    echo "   ✓ No broken symlinks"
fi

# 6. Performance recommendations
echo ""
echo "6. Performance Analysis..."
index_size=$(stat -c%s /var/www/html/index.html 2>/dev/null || echo 0)
index_size_mb=$(echo "scale=2; $index_size / 1048576" | bc)
echo "   index.html size: ${index_size_mb}MB"
if (( $(echo "$index_size_mb > 2" | bc -l) )); then
    echo "   ⚠ Consider splitting index.html - it's larger than 2MB"
else
    echo "   ✓ index.html size is reasonable"
fi

# 7. Check for unused scripts
echo ""
echo "7. Checking script usage..."
total_scripts=$(find /var/www/html/proxy/scripts -name "*.sh" -o -name "*.py" | wc -l)
echo "   Total scripts: $total_scripts"

# 8. Summary
echo ""
echo "=== Optimization Summary ==="
echo "Project root: /var/www/html"
echo "Total project size: $(calculate_size /var/www/html)"
echo "Assets size: $(calculate_size /var/www/html/assets)"
echo "Cache usage: $cache_size"
echo "Active Nginx workers: $(ps aux | grep -c '[n]ginx: worker')"
echo ""
echo "Recommendations:"
if [ "$old_backups" -gt 0 ]; then
    echo "- Remove old backup files to free up space"
fi
if [ "$duplicates" -gt 0 ]; then
    echo "- Review and remove duplicate images"
fi
if [ "$large_logs" -gt 0 ]; then
    echo "- Configure log rotation for large log files"
fi
if (( $(echo "$index_size_mb > 2" | bc -l) )); then
    echo "- Consider code splitting for index.html"
fi

echo ""
echo "To apply optimizations, run this script with --apply flag"
echo "Completed at: $(date)"
