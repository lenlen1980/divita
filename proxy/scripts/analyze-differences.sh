#!/bin/bash

echo "=== DIVITA Index Files Analysis ==="
echo ""

# Extract all external URLs from both files
echo "1. Extracting external resources..."
grep -o 'https://[^"]*' ../index_reference.html | sort | uniq > /tmp/ref_urls.txt
grep -o 'https://[^"]*' ../index.html | sort | uniq > /tmp/current_urls.txt

echo "   Reference URLs: $(wc -l < /tmp/ref_urls.txt)"
echo "   Current URLs: $(wc -l < /tmp/current_urls.txt)"

echo ""
echo "2. Missing external resources in current ../index.html:"
comm -23 /tmp/ref_urls.txt /tmp/current_urls.txt > /tmp/missing_urls.txt
cat /tmp/missing_urls.txt | head -10
echo "   ... and $(( $(wc -l < /tmp/missing_urls.txt) - 10 )) more"

echo ""
echo "3. Resource categories missing:"
echo "   Framer User Content: $(grep -c "framerusercontent.com" /tmp/missing_urls.txt)"
echo "   Google Fonts: $(grep -c "fonts.googleapis.com\|fonts.gstatic.com" /tmp/missing_urls.txt)"
echo "   Framer Assets: $(grep -c "framer.com/m/" /tmp/missing_urls.txt)"
echo "   AtList Map: $(grep -c "my.atlist.com" /tmp/missing_urls.txt)"

echo ""
echo "4. Checking local replacements:"
for domain in "framerusercontent.com" "fonts.googleapis.com" "fonts.gstatic.com" "my.atlist.com"; do
    ref_count=$(grep -c "$domain" ../index_reference.html)
    current_count=$(grep -c "$domain" ../index.html)
    local_count=$(grep -c "${domain//./}" ../index.html 2>/dev/null || echo 0)
    proxy_count=$(grep -c "proxy.*$domain" ../index.html 2>/dev/null || echo 0)
    
    echo "   $domain:"
    echo "     Reference: $ref_count occurrences"
    echo "     Current: $current_count occurrences"
    echo "     Via proxy: $proxy_count"
done

echo ""
echo "5. Content differences:"
# Check for specific content blocks
echo -n "   Map iframe in reference: "
grep -q "iframe.*my.atlist.com" ../index_reference.html && echo "YES" || echo "NO"
echo -n "   Map iframe in current: "
grep -q "iframe.*my.atlist.com" ../index.html && echo "YES" || echo "NO"

# Clean up
rm -f /tmp/ref_urls.txt /tmp/current_urls.txt /tmp/missing_urls.txt

echo ""
echo "=== Analysis Complete ==="
