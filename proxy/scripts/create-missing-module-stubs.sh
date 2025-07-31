#!/bin/bash

# Скрипт для создания заглушек недостающих .mjs модулей
# Usage: ./create-missing-module-stubs.sh [module-name]

MODULE_DIR="/var/www/html/assets/external/framer/sites/6f2zhLOQNAO3RzGM9yLEzZ"

create_stub() {
    local module_name="$1"
    local file_path="$MODULE_DIR/$module_name"
    
    if [ -f "$file_path" ]; then
        echo "✓ Module $module_name already exists"
        return 0
    fi
    
    echo "Creating stub for $module_name..."
    
    cat > "$file_path" << 'STUB_EOF'
// Auto-generated stub module
// This module was missing and has been replaced with a non-functional stub

console.info('Loading stub module:', import.meta.url);

// Default export
export default {};

// Common React patterns
export const Component = () => null;
export const provider = {};
export const config = {};
export const data = {};

// React hooks stubs
export function useEffect() {}
export function useState() { return [null, () => {}]; }
export function useContext() { return {}; }
export function useRef() { return { current: null }; }
export function useCallback(fn) { return fn; }
export function useMemo(fn) { return fn(); }

// Framer Motion stubs
export const motion = {
    div: ({ children, ...props }) => children,
    span: ({ children, ...props }) => children,
    img: ({ children, ...props }) => children
};

export const AnimatePresence = ({ children }) => children;
export const useAnimation = () => ({});
export const useMotionValue = () => ({ set: () => {}, get: () => 0 });

console.info('Stub module loaded successfully:', import.meta.url);
STUB_EOF
    
    echo "✓ Created stub: $module_name"
}

# Если передан аргумент, создаем заглушку для конкретного модуля
if [ "$1" ]; then
    create_stub "$1"
    exit 0
fi

# Иначе сканируем логи ошибок на предмет недостающих модулей
echo "=== Scanning error logs for missing modules ==="

MISSING_MODULES=$(grep -o "GET /assets/external/framer/sites/6f2zhLOQNAO3RzGM9yLEzZ/[^[:space:]]*.mjs HTTP" /var/www/html/proxy/logs/error.log 2>/dev/null | \
    grep -o "[^/]*\.mjs" | sort | uniq)

if [ -z "$MISSING_MODULES" ]; then
    echo "No missing modules found in error logs"
    exit 0
fi

echo "Found missing modules:"
echo "$MISSING_MODULES"
echo

for module in $MISSING_MODULES; do
    create_stub "$module"
done

echo
echo "=== Summary ==="
echo "Created stubs for missing modules. Check browser console for 'stub module loaded' messages."
