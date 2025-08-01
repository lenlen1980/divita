#!/bin/bash

# Script to download all images from index_reference.html

echo "=== DIVITA Image Downloader ==="
echo "Extracting images from index_reference.html..."

# Create target directory
mkdir -p assets/images/framerusercontent

# Extract image URLs
grep -o 'https://framerusercontent.com/images/[^"?]*\.\(jpg\|jpeg\|png\|gif\|webp\|svg\)' index_reference.html | sort | uniq > images_list.txt

echo "Found $(wc -l < images_list.txt) unique images to download"

# Download each image
count=0
total=$(wc -l < images_list.txt)

while read -r url; do
    count=$((count + 1))
    filename=$(basename "$url")
    local_path="assets/images/framerusercontent/$filename"
    
    echo "[$count/$total] Downloading: $filename"
    
    if [ ! -f "$local_path" ]; then
        if curl -s -L -o "$local_path" "$url"; then
            echo "  ✓ Downloaded: $local_path"
        else
            echo "  ✗ Failed: $url"
        fi
    else
        echo "  ✓ Already exists: $local_path"
    fi
done < images_list.txt

echo "=== Download Complete ==="
echo "Images saved to: assets/images/framerusercontent/"
ls -la assets/images/framerusercontent/
