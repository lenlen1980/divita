#!/bin/bash
# Скрипт для загрузки заблокированных ресурсов локально

DOWNLOAD_DIR="/var/www/html/assets/external"
mkdir -p "$DOWNLOAD_DIR"

echo "=== Downloading blocked resources ==="

# Функция для загрузки с обработкой ошибок
download_resource() {
    local url=$1
    local output_path=$2
    
    echo "Downloading: $url"
    curl -L -s -o "$output_path" \
         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
         --connect-timeout 10 \
         --max-time 30 \
         "$url"
    
    if [ $? -eq 0 ]; then
        echo "✓ Saved to: $output_path"
    else
        echo "✗ Failed to download: $url"
    fi
}

# Создаем структуру директорий
mkdir -p "$DOWNLOAD_DIR/framer/assets"
mkdir -p "$DOWNLOAD_DIR/framer/images"
mkdir -p "$DOWNLOAD_DIR/fonts/css"
mkdir -p "$DOWNLOAD_DIR/fonts/static"

# Примеры загрузки критичных ресурсов
# Можно расширить список по мере необходимости

echo ""
echo "Download complete. Resources saved to: $DOWNLOAD_DIR"
echo "Update your HTML files to use local paths: /assets/external/..."
