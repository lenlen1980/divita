const puppeteer = require('puppeteer');
const fs = require('fs');

async function analyzeLocalSite() {
    console.log('=== DIVITA Local Site Analysis ===');
    console.log('Подробный анализ нашего сайта\n');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox', 
            '--disable-dev-shm-usage',
            '--disable-web-security',
            '--allow-running-insecure-content',
            '--ignore-certificate-errors'
        ]
    });
    
    const page = await browser.newPage();
    
    try {
        console.log('🔍 Загрузка локального сайта...');
        
        const startTime = Date.now();
        
        await page.goto('https://80.93.61.62', { 
            waitUntil: 'domcontentloaded',
            timeout: 15000 
        });
        
        const loadTime = Date.now() - startTime;
        
        console.log(`✅ Сайт загружен за ${loadTime}ms`);
        
        // Detailed analysis
        const analysis = await page.evaluate(() => {
            return {
                // Basic info
                title: document.title,
                url: window.location.href,
                lang: document.documentElement.lang,
                
                // Meta info
                description: document.querySelector('meta[name="description"]')?.content || '',
                generator: document.querySelector('meta[name="generator"]')?.content || '',
                
                // Content structure
                hasMain: !!document.querySelector('main, [role="main"]'),
                hasNav: !!document.querySelector('nav, .nav'),
                hasFooter: !!document.querySelector('footer, .footer'),
                
                // Element counts
                elements: {
                    images: document.querySelectorAll('img').length,
                    links: document.querySelectorAll('a[href]').length,
                    buttons: document.querySelectorAll('button, .button').length,
                    forms: document.querySelectorAll('form').length,
                    scripts: document.querySelectorAll('script').length,
                    stylesheets: document.querySelectorAll('link[rel="stylesheet"]').length,
                    divs: document.querySelectorAll('div').length
                },
                
                // Content analysis
                bodyTextLength: document.body.innerText.length,
                containsFramer: document.body.innerHTML.includes('framer'),
                containsDivita: document.body.innerHTML.toLowerCase().includes('divita'),
                
                // First few lines of visible text
                visibleText: document.body.innerText.split('\n')
                    .filter(line => line.trim().length > 0)
                    .slice(0, 10)
                    .join('\n')
            };
        });
        
        // Performance analysis
        const performance = await page.evaluate(() => {
            if (window.performance && window.performance.timing) {
                const timing = window.performance.timing;
                return {
                    domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
                    loadComplete: timing.loadEventEnd - timing.navigationStart,
                    domInteractive: timing.domInteractive - timing.navigationStart
                };
            }
            return null;
        });
        
        // Take screenshot
        const screenshotPath = `tests/screenshots/local-detailed-${Date.now()}.png`;
        await page.screenshot({ 
            path: screenshotPath,
            fullPage: true 
        });
        
        // Network analysis
        const networkInfo = await page.evaluate(() => {
            if (window.performance && window.performance.getEntriesByType) {
                const resources = window.performance.getEntriesByType('resource');
                return {
                    totalResources: resources.length,
                    resourceTypes: resources.reduce((acc, resource) => {
                        const type = resource.name.split('.').pop()?.toLowerCase() || 'other';
                        acc[type] = (acc[type] || 0) + 1;
                        return acc;
                    }, {}),
                    totalTransferSize: resources.reduce((total, r) => total + (r.transferSize || 0), 0)
                };
            }
            return null;
        });
        
        const result = {
            timestamp: new Date().toISOString(),
            loadTime: loadTime,
            analysis: analysis,
            performance: performance,
            network: networkInfo,
            screenshot: screenshotPath
        };
        
        // Save results
        if (!fs.existsSync('tests/reports')) {
            fs.mkdirSync('tests/reports', { recursive: true });
        }
        
        fs.writeFileSync(
            'tests/reports/local-site-analysis.json', 
            JSON.stringify(result, null, 2)
        );
        
        // Display results
        console.log('\n📊 РЕЗУЛЬТАТЫ АНАЛИЗА:');
        console.log(`   Заголовок: "${analysis.title}"`);
        console.log(`   URL: ${analysis.url}`);
        console.log(`   Генератор: ${analysis.generator}`);
        console.log(`   Язык: ${analysis.lang || 'не указан'}`);
        console.log(`   Описание: ${analysis.description || 'отсутствует'}`);
        console.log('\n📈 СТРУКТУРА:');
        console.log(`   Главный контент: ${analysis.hasMain ? '✅' : '❌'}`);
        console.log(`   Навигация: ${analysis.hasNav ? '✅' : '❌'}`);
        console.log(`   Футер: ${analysis.hasFooter ? '✅' : '❌'}`);
        console.log('\n🔢 ЭЛЕМЕНТЫ:');
        Object.entries(analysis.elements).forEach(([type, count]) => {
            console.log(`   ${type}: ${count}`);
        });
        console.log('\n⚡ ПРОИЗВОДИТЕЛЬНОСТЬ:');
        console.log(`   Время загрузки: ${loadTime}ms`);
        if (performance) {
            console.log(`   DOM готов: ${performance.domContentLoaded}ms`);
            console.log(`   Полная загрузка: ${performance.loadComplete}ms`);
        }
        console.log('\n📝 СОДЕРЖИМОЕ:');
        console.log(`   Длина текста: ${analysis.bodyTextLength} символов`);
        console.log(`   Содержит Framer: ${analysis.containsFramer ? '✅' : '❌'}`);
        console.log(`   Содержит Divita: ${analysis.containsDivita ? '✅' : '❌'}`);
        console.log('\n📸 Скриншот сохранен: ' + screenshotPath);
        
        return result;
        
    } catch (error) {
        console.log(`❌ Ошибка: ${error.message}`);
        return { error: error.message };
    } finally {
        await browser.close();
    }
}

analyzeLocalSite()
    .then(result => {
        console.log('\n✅ Анализ локального сайта завершен!');
        if (!result.error) {
            console.log('📋 Отчет сохранен: tests/reports/local-site-analysis.json'); 
        }
        process.exit(0);
    })
    .catch(error => {
        console.error('❌ Анализ не удался:', error.message);
        process.exit(1);
    });
