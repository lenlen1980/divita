#!/bin/bash
# create-missing-module-stubs.sh - Создание заглушек для отсутствующих JS модулей

echo "=== Creating stubs for missing JS modules ==="

# Директория для заглушек
STUB_DIR="/var/www/html/assets/stubs/js-modules"
mkdir -p "$STUB_DIR"

# Анализируем логи для поиска 404 ошибок на .mjs файлы
echo "Analyzing logs for missing modules..."
missing_modules=$(grep "404" /var/www/html/proxy/logs/access.log | grep -E "\.mjs " | awk '{print $7}' | sort -u)

if [[ -z "$missing_modules" ]]; then
    echo "No missing modules found in logs."
    exit 0
fi

echo "Found missing modules:"
echo "$missing_modules"
echo ""

# Создаем заглушки
created=0
for module in $missing_modules; do
    # Убираем начальный слеш
    module_path="${module#/}"
    
    # Создаем директорию если нужно
    module_dir=$(dirname "/var/www/html/$module_path")
    mkdir -p "$module_dir"
    
    # Создаем файл-заглушку
    stub_file="/var/www/html/$module_path"
    
    if [[ ! -f "$stub_file" ]]; then
        echo "// Stub for $module" > "$stub_file"
        echo "export default {};" >> "$stub_file"
        echo "Created stub: $stub_file"
        ((created++))
    else
        echo "Stub already exists: $stub_file"
    fi
done

echo ""
echo "Summary: Created $created stub(s)"

# Проверяем права доступа
chown -R www-data:www-data /var/www/html/assets/

echo "Done!"
