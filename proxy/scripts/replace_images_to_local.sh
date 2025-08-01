#!/bin/bash

# Script to replace framerusercontent.com image URLs with local paths in index.html

echo "=== DIVITA Image URL Replacer ==="

# Create backup
backup_file="index.html.backup-$(date +%Y%m%d-%H%M%S)"
cp index.html "$backup_file"
echo "✓ Backup created: $backup_file"

# List of image replacements
declare -A replacements=(
    ["https://framerusercontent.com/images/4p0Uaz3G2wEEwqZ8Br01zIgYHFw.png"]="assets/images/framerusercontent/4p0Uaz3G2wEEwqZ8Br01zIgYHFw.png"
    ["https://framerusercontent.com/images/BAI1gULRJaRoCXDlXs9VXINqE.jpg"]="assets/images/framerusercontent/BAI1gULRJaRoCXDlXs9VXINqE.jpg"
    ["https://framerusercontent.com/images/fEZ0Rd0twQu85anZ8LXS2VdhEbY.jpg"]="assets/images/framerusercontent/fEZ0Rd0twQu85anZ8LXS2VdhEbY.jpg"
    ["https://framerusercontent.com/images/HiWCAjYzPxokY5YwDQmhS7kk9Ns.jpg"]="assets/images/framerusercontent/HiWCAjYzPxokY5YwDQmhS7kk9Ns.jpg"
    ["https://framerusercontent.com/images/ileRuSgT47uzLY1fDKZONVAGM.png"]="assets/images/framerusercontent/ileRuSgT47uzLY1fDKZONVAGM.png"
    ["https://framerusercontent.com/images/KlmuzHZYtHwGmwm3o0byf6kXAWM.jpg"]="assets/images/framerusercontent/KlmuzHZYtHwGmwm3o0byf6kXAWM.jpg"
    ["https://framerusercontent.com/images/kTpflOGZxcyWvbSzQyrMZu2LOo.png"]="assets/images/framerusercontent/kTpflOGZxcyWvbSzQyrMZu2LOo.png"
    ["https://framerusercontent.com/images/OWY1q6RHp0YA2vxeaCcnF6T4fYM.png"]="assets/images/framerusercontent/OWY1q6RHp0YA2vxeaCcnF6T4fYM.png"
    ["https://framerusercontent.com/images/Qc51Squ6AGn5OdsTtPtsL7nioT0.png"]="assets/images/framerusercontent/Qc51Squ6AGn5OdsTtPtsL7nioT0.png"
    ["https://framerusercontent.com/images/Vhn79gJiDlOa0r8fREZyMJPg.png"]="assets/images/framerusercontent/Vhn79gJiDlOa0r8fREZyMJPg.png"
    ["https://framerusercontent.com/images/xeXqctqbEAKrQmgkq2Q8nRARbRc.jpg"]="assets/images/framerusercontent/xeXqctqbEAKrQmgkq2Q8nRARbRc.jpg"
)

# Count replacements
total_replacements=0

# Perform replacements
for external_url in "${!replacements[@]}"; do
    local_path="${replacements[$external_url]}"
    
    # Check if file exists locally
    if [ -f "$local_path" ]; then
        # Count occurrences before replacement
        count_before=$(grep -c "$external_url" index.html || echo "0")
        
        if [ "$count_before" -gt 0 ]; then
            # Perform replacement using sed
            sed -i "s|$external_url|/$local_path|g" index.html
            
            # Count after replacement to verify
            count_after=$(grep -c "$external_url" index.html || echo "0")
            replaced=$((count_before - count_after))
            
            echo "✓ Replaced $replaced occurrences: $(basename "$external_url")"
            total_replacements=$((total_replacements + replaced))
        else
            echo "- No occurrences found: $(basename "$external_url")"
        fi
    else
        echo "✗ Local file not found: $local_path"
    fi
done

echo ""
echo "=== Replacement Summary ==="
echo "Total replacements made: $total_replacements"
echo "Backup file: $backup_file"
echo ""

# Verify some key replacements
echo "=== Verification (first 3 local image references) ==="
grep -n "assets/images/framerusercontent/" index.html | head -3

echo ""
echo "✓ Image URL replacement completed!"
