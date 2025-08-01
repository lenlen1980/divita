#!/bin/bash

echo "=== DIVITA Images Availability Check ==="
echo "Checking all images from ../assets/external/framer/images/..."
echo ""

# Test each image locally
total_images=0
available_images=0
missing_images=0

for image_file in ../assets/external/framer/images/*.{png,jpg,jpeg,gif,webp,svg}; do
    if [ -f "$image_file" ]; then
        total_images=$((total_images + 1))
        filename=$(basename "$image_file")
        
        echo -n "[$total_images] $filename: "
        
        if [ -r "$image_file" ]; then
            size=$(du -h "$image_file" | cut -f1)
            echo "✓ Available ($size)"
            available_images=$((available_images + 1))
        else
            echo "✗ Not readable"
            missing_images=$((missing_images + 1))
        fi
    fi
done

echo ""
echo "=== Summary ==="
echo "Total images: $total_images"
echo "Available: $available_images"
echo "Missing/Unreadable: $missing_images"

if [ $missing_images -eq 0 ]; then
    echo "✅ All images are available!"
else
    echo "⚠️  Some images are missing or unreadable"
fi

echo ""
echo "=== Web Accessibility Test ==="
# Test a few key images via HTTP
test_images=(
    "kTpflOGZxcyWvbSzQyrMZu2LOo.png"
    "OWY1q6RHp0YA2vxeaCcnF6T4fYM.png"
    "Qc51Squ6AGn5OdsTtPtsL7nioT0.png"
)

for img in "${test_images[@]}"; do
    echo -n "Testing web access for $img: "
    status=$(curl -s -k -o /dev/null -w "%{http_code}" "https://127.0.0.1/../assets/external/framer/images/$img")
    if [ "$status" = "200" ]; then
        echo "✓ HTTP $status"
    else
        echo "✗ HTTP $status"
    fi
done

echo ""
echo "✓ Image availability check completed!"
