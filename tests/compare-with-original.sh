#!/bin/bash

echo "=== DIVITA Site Comparison Tool ==="
echo "Сравнение нашего сайта с эталоном divita.ae"
echo ""

cd /var/www/html

# Проверим Puppeteer
if [ ! -d "tests/node_modules/puppeteer" ]; then
    echo "❌ Puppeteer не установлен. Запустите ./tests/puppeteer-setup.sh"
    exit 1
fi

echo "🚀 Запуск функционального сравнения..."
echo ""

# Запускаем тест
cd tests
node ui/functional-comparison.js

echo ""
echo "📁 Результаты сохранены в:"
echo "   - Скриншоты: tests/screenshots/"
echo "   - Отчеты: tests/reports/"
echo ""

# Показываем краткую статистику
if [ -f "reports/functional-comparison.json" ]; then
    echo "📊 Краткая статистика:"
    echo ""
    node -e "
        const data = JSON.parse(require('fs').readFileSync('reports/functional-comparison.json', 'utf8'));
        data.tests.forEach(test => {
            console.log(\`\${test.site.toUpperCase()}:\`);
            console.log(\`  ✓ Статус: \${test.status}\`);
            console.log(\`  ⏱ Время загрузки: \${test.loadTime}ms\`);
            console.log(\`  📝 Заголовок: \${test.title}\`);
            console.log(\`  🔢 Изображений: \${test.elements.images || 0}\`);
            console.log(\`  🔗 Ссылок: \${test.elements.links || 0}\`);
            console.log(\`  ❌ Ошибок: \${test.errors.length}\`);
            console.log('');
        });
    "
fi

echo "✅ Сравнение завершено!"
