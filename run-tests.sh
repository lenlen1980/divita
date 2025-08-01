#!/bin/bash

# DIVITA Testing Script
# Запуск Puppeteer тестов для сравнения с эталоном

cd /var/www/html/tests

echo "🧪 DIVITA Testing Suite"
echo "======================="
echo

case "${1:-default}" in
    "quick"|"q")
        echo "⚡ Running quick HTTPS test..."
        node ui/https-test.js
        ;;
    "full"|"f")
        echo "🔬 Running full comparison test..."
        node ui/comprehensive-https-comparison.js
        ;;
    "local"|"l")
        echo "🏠 Running local Puppeteer test..."
        node ui/local-test.js
        ;;
    "npm")
        echo "📦 Running via npm test..."
        npm test
        ;;
    "screenshots"|"s")
        echo "📸 Available screenshots:"
        ls -la screenshots/
        ;;
    "reports"|"r")
        echo "📊 Latest test report:"
        if [ -f "reports/comparison-report.json" ]; then
            cat reports/comparison-report.json | head -20
        else
            echo "No reports found. Run tests first."
        fi
        ;;
    "help"|"h")
        echo "Available commands:"
        echo "  ./run-tests.sh quick     - Quick HTTPS test"
        echo "  ./run-tests.sh full      - Full comparison"
        echo "  ./run-tests.sh local     - Local Puppeteer test"
        echo "  ./run-tests.sh npm       - Run via npm"
        echo "  ./run-tests.sh screenshots - Show screenshots"
        echo "  ./run-tests.sh reports   - Show latest report"
        echo "  ./run-tests.sh help      - This help"
        ;;
    *)
        echo "🎯 Running default comprehensive test..."
        node ui/comprehensive-https-comparison.js
        echo
        echo "💡 Use './run-tests.sh help' for more options"
        ;;
esac

echo
echo "✅ Test run complete!"
