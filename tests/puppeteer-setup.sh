#!/bin/bash

echo "=== Настройка Puppeteer для DIVITA ==="
echo ""

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Проверка Node.js
echo "1. Проверка Node.js..."
if command -v node > /dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✓ Node.js установлен: $NODE_VERSION${NC}"
else
    echo -e "${RED}✗ Node.js не установлен${NC}"
    echo "Установка Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Создание структуры
echo ""
echo "2. Создание структуры тестов..."
mkdir -p /var/www/html/tests/{ui,screenshots,reports}

# Инициализация npm проекта
cd /var/www/html/tests
if [ ! -f package.json ]; then
    npm init -y
fi

# Установка зависимостей
echo ""
echo "3. Установка Puppeteer и зависимостей..."
npm install puppeteer puppeteer-extra puppeteer-extra-plugin-stealth
npm install pixelmatch pngjs # для визуального сравнения
npm install chalk # для красивого вывода

# Установка зависимостей для headless Chrome
echo ""
echo "4. Установка системных зависимостей для Chrome..."
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils

echo ""
echo -e "${GREEN}✓ Puppeteer установлен и готов к использованию${NC}"
echo ""
echo "Следующие шаги:"
echo "1. Создать тестовые скрипты в /var/www/html/tests/ui/"
echo "2. Запустить тесты: node tests/ui/visual-comparison.js"
echo "3. Проверить результаты в tests/screenshots/ и tests/reports/"
