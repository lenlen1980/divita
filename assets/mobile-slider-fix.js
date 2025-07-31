// Исправление автоматического закрытия слайдера блока 05 на мобильных устройствах
(function() {
    'use strict';
    
    console.log('📱 Mobile Slider Auto-Close Fix v1.0 loading...');
    
    let isFixActive = false;
    let block05 = null;
    let observer = null;
    
    // Критические брейкпоинты
    const CRITICAL_BREAKPOINTS = [700, 699, 768, 767];
    
    function findBlock05() {
        block05 = document.querySelector('[data-framer-name="05"]');
        if (block05) {
            console.log('✅ Found Block 05 slider:', block05);
            return true;
        }
        console.log('❌ Block 05 not found, retrying...');
        return false;
    }
    
    function preventSliderHiding() {
        if (!block05) return;
        
        // Находим все элементы слайдера в блоке 05
        const sliderElements = block05.querySelectorAll(`
            [data-framer-component-type],
            .framer-slide,
            [class*="slide"],
            [class*="slider"],
            [class*="carousel"],
            .hidden,
            [style*="display: none"],
            [style*="opacity: 0"],
            [style*="visibility: hidden"]
        `);
        
        sliderElements.forEach(element => {
            // Принудительно показываем элемент
            element.style.display = '';
            element.style.opacity = '';
            element.style.visibility = '';
            element.style.transform = '';
            
            // Убираем скрывающие классы
            element.classList.remove('hidden', 'hide', 'mobile-hidden', 'closed');
            
            // Добавляем важные стили
            element.style.setProperty('display', 'block', 'important');
            element.style.setProperty('opacity', '1', 'important');
            element.style.setProperty('visibility', 'visible', 'important');
        });
        
        console.log(`🔧 Fixed ${sliderElements.length} slider elements`);
    }
    
    function setupMutationObserver() {
        if (observer) observer.disconnect();
        
        observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.type === 'attributes') {
                    const element = mutation.target;
                    
                    // Если элемент находится в блоке 05
                    if (block05 && block05.contains(element)) {
                        const style = element.style;
                        const classList = element.classList;
                        
                        // Проверяем, пытается ли кто-то скрыть элемент
                        if (style.display === 'none' || 
                            style.opacity === '0' || 
                            style.visibility === 'hidden' ||
                            classList.contains('hidden')) {
                            
                            console.log('🚫 Preventing element hide in Block 05:', element);
                            
                            // Отменяем скрытие
                            style.display = '';
                            style.opacity = '';
                            style.visibility = '';
                            classList.remove('hidden', 'hide', 'mobile-hidden');
                        }
                    }
                }
            });
        });
        
        // Наблюдаем за всем документом
        observer.observe(document.body, {
            attributes: true,
            attributeFilter: ['style', 'class'],
            subtree: true
        });
        
        console.log('👁️ MutationObserver activated');
    }
    
    function handleResize() {
        const width = window.innerWidth;
        
        // Особое внимание критическим брейкпоинтам
        if (CRITICAL_BREAKPOINTS.includes(width)) {
            console.log(`🎯 Critical breakpoint detected: ${width}px`);
            setTimeout(preventSliderHiding, 10);
            setTimeout(preventSliderHiding, 100);
            setTimeout(preventSliderHiding, 500);
        }
        
        preventSliderHiding();
    }
    
    function overrideMatchMedia() {
        // Перехватываем window.matchMedia для критических запросов
        const originalMatchMedia = window.matchMedia;
        
        window.matchMedia = function(query) {
            const result = originalMatchMedia.call(this, query);
            
            // Если это запрос, который может скрывать слайдер
            if (query.includes('max-width') && (
                query.includes('700px') || 
                query.includes('699px') || 
                query.includes('768px')
            )) {
                console.log(`🔍 Intercepted critical media query: ${query}`);
                
                // Переопределяем addListener/addEventListener
                const originalAddListener = result.addListener || result.addEventListener;
                if (originalAddListener) {
                    result.addListener = result.addEventListener = function(callback) {
                        const wrappedCallback = function(e) {
                            console.log(`📺 Media query changed: ${query}, matches: ${e.matches}`);
                            
                            // Запускаем оригинальный callback
                            callback.call(this, e);
                            
                            // Но сразу же исправляем слайдер
                            setTimeout(preventSliderHiding, 0);
                            setTimeout(preventSliderHiding, 10);
                            setTimeout(preventSliderHiding, 100);
                        };
                        
                        originalAddListener.call(result, wrappedCallback);
                    };
                }
            }
            
            return result;
        };
        
        console.log('🎭 matchMedia intercepted');
    }
    
    function activateFix() {
        if (isFixActive) return;
        
        console.log('🚀 Activating mobile slider fix...');
        
        if (!findBlock05()) {
            // Пробуем найти блок еще раз через короткое время
            setTimeout(activateFix, 500);
            return;
        }
        
        isFixActive = true;
        
        // Активируем все защитные механизмы
        preventSliderHiding();
        setupMutationObserver();
        overrideMatchMedia();
        
        // Отслеживаем изменения размера окна
        window.addEventListener('resize', handleResize);
        
        // Периодическая проверка и исправление
        setInterval(preventSliderHiding, 2000);
        
        console.log('✅ Mobile slider auto-close fix fully activated!');
    }
    
    // Запуск
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', activateFix);
    } else {
        activateFix();
    }
    
    // Дополнительные запуски с задержкой
    setTimeout(activateFix, 1000);
    setTimeout(activateFix, 3000);
    setTimeout(activateFix, 5000);
    
})();
