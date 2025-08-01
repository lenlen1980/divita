const puppeteer = require('puppeteer');
const fs = require('fs');

async function comprehensiveComparison() {
    console.log('=== DIVITA Comprehensive Site Comparison ===');
    console.log('Сравнение с эталоном divita.ae\n');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-web-security',
            '--allow-running-insecure-content',
            '--ignore-certificate-errors',
            '--ignore-ssl-errors',
            '--ignore-certificate-errors-spki-list'
        ]
    });
    
    const results = {
        timestamp: new Date().toISOString(),
        comparison: {
            local: null,
            original: null
        },
        differences: [],
        summary: {}
    };

    // Test LOCAL site
    console.log('🔍 Анализ ЛОКАЛЬНОГО сайта (наш прокси)...');
    
    const localPage = await browser.newPage();
    
    try {
        const startTime = Date.now();
        
        // Direct HTTPS access to bypass redirect
        await localPage.goto('https://80.93.61.62', { 
            waitUntil: 'networkidle0',
            timeout: 20000 
        });
        
        const localData = {
            url: localPage.url(),
            loadTime: Date.now() - startTime,
            title: await localPage.title(),
            elements: {},
            content: {},
            performance: {},
            errors: []
        };

        // Count elements
        const elementSelectors = {
            'images': 'img',
            'links': 'a[href]',
            'buttons': 'button, .button, .btn',
            'forms': 'form',
            'inputs': 'input',
            'divs': 'div',
            'scripts': 'script[src]',
            'stylesheets': 'link[rel="stylesheet"]'
        };

        for (const [name, selector] of Object.entries(elementSelectors)) {
            try {
                localData.elements[name] = await localPage.$$eval(selector, els => els.length);
            } catch (e) {
                localData.elements[name] = 0;
            }
        }

        // Get content analysis
        localData.content = await localPage.evaluate(() => {
            return {
                bodyLength: document.body.innerText.length,
                hasFramerContent: document.body.innerHTML.includes('framer'),
                hasMainContent: !!document.querySelector('main, .main, [role="main"]'),
                hasNavigation: !!document.querySelector('nav, .nav, .navigation'),
                hasFooter: !!document.querySelector('footer, .footer'),
                metaDescription: document.querySelector('meta[name="description"]')?.content || '',
                lang: document.documentElement.lang || 'not-set'
            };
        });

        // Performance metrics
        const performanceMetrics = await localPage.evaluate(() => {
            const nav = performance.navigation;
            const timing = performance.timing;
            return {
                domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
                loadComplete: timing.loadEventEnd - timing.navigationStart,
                resourceCount: performance.getEntriesByType('resource').length
            };
        });
        localData.performance = performanceMetrics;

        // Take screenshot
        await localPage.screenshot({ 
            path: `tests/screenshots/local-comprehensive-${Date.now()}.png`,
            fullPage: true 
        });

        results.comparison.local = localData;
        
        console.log(`✅ ЛОКАЛЬНЫЙ сайт проанализирован:`);
        console.log(`   Время загрузки: ${localData.loadTime}ms`);
        console.log(`   Заголовок: "${localData.title}"`);
        console.log(`   Элементов найдено: ${Object.values(localData.elements).reduce((a,b) => a+b, 0)}`);
        console.log(`   Содержит Framer: ${localData.content.hasFramerContent}`);
        
    } catch (error) {
        console.log(`❌ Ошибка анализа локального сайта: ${error.message}`);
        results.comparison.local = { error: error.message };
    }
    
    await localPage.close();

    // Test ORIGINAL site
    console.log('\n🔍 Анализ ОРИГИНАЛЬНОГО сайта (divita.ae)...');
    
    const originalPage = await browser.newPage();
    
    try {
        const startTime = Date.now();
        
        await originalPage.goto('https://divita.ae', { 
            waitUntil: 'networkidle0',
            timeout: 30000 
        });
        
        const originalData = {
            url: originalPage.url(),
            loadTime: Date.now() - startTime,
            title: await originalPage.title(),
            elements: {},
            content: {},
            performance: {},
            errors: []
        };

        // Same analysis as local
        for (const [name, selector] of Object.entries(elementSelectors)) {
            try {
                originalData.elements[name] = await originalPage.$$eval(selector, els => els.length);
            } catch (e) {
                originalData.elements[name] = 0;
            }
        }

        originalData.content = await originalPage.evaluate(() => {
            return {
                bodyLength: document.body.innerText.length,
                hasFramerContent: document.body.innerHTML.includes('framer'),
                hasMainContent: !!document.querySelector('main, .main, [role="main"]'),
                hasNavigation: !!document.querySelector('nav, .nav, .navigation'),
                hasFooter: !!document.querySelector('footer, .footer'),
                metaDescription: document.querySelector('meta[name="description"]')?.content || '',
                lang: document.documentElement.lang || 'not-set'
            };
        });

        const performanceMetrics = await originalPage.evaluate(() => {
            const nav = performance.navigation;
            const timing = performance.timing;
            return {
                domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
                loadComplete: timing.loadEventEnd - timing.navigationStart,
                resourceCount: performance.getEntriesByType('resource').length
            };
        });
        originalData.performance = performanceMetrics;

        await originalPage.screenshot({ 
            path: `tests/screenshots/original-comprehensive-${Date.now()}.png`,
            fullPage: true 
        });

        results.comparison.original = originalData;
        
        console.log(`✅ ОРИГИНАЛЬНЫЙ сайт проанализирован:`);
        console.log(`   Время загрузки: ${originalData.loadTime}ms`);
        console.log(`   Заголовок: "${originalData.title}"`);
        console.log(`   Элементов найдено: ${Object.values(originalData.elements).reduce((a,b) => a+b, 0)}`);
        console.log(`   Содержит Framer: ${originalData.content.hasFramerContent}`);
        
    } catch (error) {
        console.log(`⚠️ Проблема с оригинальным сайтом: ${error.message}`);
        results.comparison.original = { error: error.message };
    }
    
    await originalPage.close();
    await browser.close();

    // Generate comparison analysis
    if (results.comparison.local && results.comparison.original && 
        !results.comparison.local.error && !results.comparison.original.error) {
        
        console.log('\n📊 СРАВНИТЕЛЬНЫЙ АНАЛИЗ:');
        
        const local = results.comparison.local;
        const original = results.comparison.original;
        
        // Compare titles
        if (local.title !== original.title) {
            results.differences.push({
                type: 'title',
                local: local.title,
                original: original.title
            });
            console.log(`   Заголовки: РАЗНЫЕ`);
            console.log(`     Локальный: "${local.title}"`);
            console.log(`     Оригинал: "${original.title}"`);
        } else {
            console.log(`   Заголовки: ОДИНАКОВЫЕ ✅`);
        }
        
        // Compare element counts
        for (const elementType of Object.keys(local.elements)) {
            const localCount = local.elements[elementType];
            const originalCount = original.elements[elementType];
            const diff = Math.abs(localCount - originalCount);
            
            if (diff > 0) {
                results.differences.push({
                    type: 'elements',
                    element: elementType,
                    local: localCount,
                    original: originalCount,
                    difference: diff
                });
                console.log(`   ${elementType}: Локальный ${localCount}, Оригинал ${originalCount} (разница: ${diff})`);
            }
        }
        
        // Compare performance
        const perfDiff = Math.abs(local.loadTime - original.loadTime);
        results.differences.push({
            type: 'performance',
            local: local.loadTime,
            original: original.loadTime,
            difference: perfDiff
        });
        console.log(`   Производительность: Локальный ${local.loadTime}ms, Оригинал ${original.loadTime}ms`);
        
        // Summary
        results.summary = {
            totalDifferences: results.differences.length,
            majorDifferences: results.differences.filter(d => d.type === 'title' || (d.type === 'elements' && d.difference > 5)).length,
            performanceDifference: perfDiff,
            functionallyIdentical: results.differences.filter(d => d.type === 'title').length === 0
        };
        
    } else {
        console.log('\n⚠️ Не удалось провести полное сравнение из-за ошибок подключения');
    }

    // Save results
    if (!fs.existsSync('tests/reports')) {
        fs.mkdirSync('tests/reports', { recursive: true });
    }
    
    fs.writeFileSync(
        'tests/reports/comprehensive-comparison.json', 
        JSON.stringify(results, null, 2)
    );

    console.log('\n✅ Анализ завершен! Результаты сохранены в tests/reports/comprehensive-comparison.json');
    console.log('📸 Скриншоты сохранены в tests/screenshots/');
    
    return results;
}

comprehensiveComparison()
    .then(results => {
        console.log('\n🎉 Comprehensive comparison complete!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Comparison failed:', error.message);
        process.exit(1);
    });
