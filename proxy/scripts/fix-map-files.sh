#!/bin/bash

echo "=== Исправление проблемы с .map файлами ==="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Метод 1: Создание заглушек для .map файлов
echo -e "${YELLOW}Метод 1: Создание пустых .map файлов${NC}"
echo "Это остановит 404 ошибки, но DevTools не будут показывать source maps"
echo ""

# Найти все .mjs файлы и создать для них .map заглушки
count=0
for mjs_file in $(find /var/www/html/assets/external/framer -name "*.mjs"); do
    map_file="${mjs_file}.map"
    if [ ! -f "$map_file" ]; then
        # Создаем минимальный валидный source map
        echo '{"version":3,"sources":[],"mappings":""}' > "$map_file"
        count=$((count + 1))
    fi
done

echo -e "${GREEN}✓ Создано $count .map файлов${NC}"
echo ""

# Метод 2: Настройка nginx для игнорирования .map запросов
echo -e "${YELLOW}Метод 2: Настройка nginx (рекомендуется)${NC}"
echo "Добавьте в конфигурацию nginx следующий блок:"
echo ""
cat << 'NGINX'
# В секции server {} добавить:
location ~ \.map$ {
    # Логировать только в debug режиме
    access_log off;
    
    # Возвращать пустой ответ вместо 404
    return 204;
}
NGINX

echo ""
echo -e "${YELLOW}Для применения:${NC}"
echo "1. Отредактируйте /etc/nginx/sites-available/divita"
echo "2. Добавьте блок location выше"
echo "3. nginx -t && systemctl reload nginx"
echo ""

# Проверка текущего количества ошибок
current_errors=$(grep -c "\.map.*404" /var/www/html/proxy/logs/error.log)
echo -e "${YELLOW}Текущее количество .map ошибок в логах: $current_errors${NC}"

# Опционально: очистить старые ошибки из логов
echo ""
echo "Хотите очистить старые .map ошибки из логов? (y/n)"
read -r answer
if [ "$answer" = "y" ]; then
    # Создаем backup
    cp /var/www/html/proxy/logs/error.log /var/www/html/proxy/logs/error.log.backup
    
    # Удаляем строки с .map ошибками
    grep -v "\.map.*404" /var/www/html/proxy/logs/error.log.backup > /var/www/html/proxy/logs/error.log
    
    new_size=$(wc -l < /var/www/html/proxy/logs/error.log)
    echo -e "${GREEN}✓ Логи очищены. Осталось $new_size строк${NC}"
fi

echo ""
echo -e "${GREEN}Готово! Выберите один из методов выше для постоянного решения.${NC}"
