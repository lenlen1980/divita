const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function comprehensiveComparison() {
    console.log('=== DIVITA Comprehensive HTTPS Comparison ===');
    console.log('🔗 Original: https://divita.ae (Framer)');
    console.log('🏠 Our site: https://80.93.61.62 (Static HTML + SSL)');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--disable-dev-shm-usage',
            '--ignore-certificate-errors',
            '--ignore-ssl-errors',
            '--ignore-certificate-errors-spki-list'
        ]
    });
    
    const results = {
        original: { status: 'pending', loadTime: 0, title: '', keyPhrase: false },
        ours: { status: 'pending', loadTime: 0, title: '', keyPhrase: false }
    };
    
    try {
        // Тест оригинального сайта
        console.log('\n🌍 Testing ORIGINAL site (divita.ae)...');
        const originalPage = await browser.newPage();
        await originalPage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        
        try {
            const originalStart = Date.now();
            await originalPage.goto('https://divita.ae', { 
                waitUntil: 'domcontentloaded',
                timeout: 8000 
            });
            results.original.loadTime = Date.now() - originalStart;
            results.original.title = await originalPage.title();
            results.original.status = 'success';
            
            console.log(`✅ ORIGINAL loaded in ${results.original.loadTime}ms`);
            console.log(`📄 Title: "${results.original.title}"`);
            
            // Проверка ключевой фразы
            try {
                const bodyText = await originalPage.evaluate(() => document.body.innerText);
                results.original.keyPhrase = bodyText.toLowerCase().includes('land is an opportunity');
            } catch (e) {
                console.log('⚠️  Could not check original body text');
            }
            
            // Скриншот оригинала
            await originalPage.screenshot({
                path: '/var/www/html/tests/screenshots/original-full.png',
                fullPage: true
            });
            console.log('📸 Original screenshot: screenshots/original-full.png');
            
        } catch (error) {
            console.log(`❌ ORIGINAL error: ${error.message}`);
            results.original.status = 'error';
        }
        
        // Тест нашего сайта
        console.log('\n🏠 Testing OUR HTTPS site...');
        const ourPage = await browser.newPage();
        await ourPage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        
        try {
            const ourStart = Date.now();
            await ourPage.goto('https://80.93.61.62', { 
                waitUntil: 'domcontentloaded',
                timeout: 8000 
            });
            results.ours.loadTime = Date.now() - ourStart;
            results.ours.title = await ourPage.title();
            results.ours.status = 'success';
            
            console.log(`✅ OUR SITE loaded in ${results.ours.loadTime}ms`);
            console.log(`📄 Title: "${results.ours.title}"`);
            
            // Детальная проверка элементов
            const elementCounts = await ourPage.evaluate(() => ({
                h1: document.querySelectorAll('h1').length,
                h2: document.querySelectorAll('h2').length,
                buttons: document.querySelectorAll('button').length,
                images: document.querySelectorAll('img').length,
                links: document.querySelectorAll('a').length
            }));
            
            console.log('📊 Element counts:', elementCounts);
            
            // Проверка ключевой фразы
            try {
                const bodyText = await ourPage.evaluate(() => document.body.innerText);
                results.ours.keyPhrase = bodyText.toLowerCase().includes('land is an opportunity');
            } catch (e) {
                console.log('⚠️  Could not check our body text');
            }
            
            // Скриншот нашего сайта
            await ourPage.screenshot({
                path: '/var/www/html/tests/screenshots/ours-full.png',
                fullPage: true
            });
            console.log('📸 Our screenshot: screenshots/ours-full.png');
            
        } catch (error) {
            console.log(`❌ OUR SITE error: ${error.message}`);
            results.ours.status = 'error';
        }
        
        await originalPage.close();
        await ourPage.close();
        
    } catch (error) {
        console.error('❌ General error:', error.message);
    } finally {
        await browser.close();
    }
    
    // Сводка результатов
    console.log('\n📊 COMPARISON SUMMARY:');
    console.log('═══════════════════════════════════════');
    
    console.log(`🌍 ORIGINAL (divita.ae):`);
    console.log(`   Status: ${results.original.status}`);
    console.log(`   Load Time: ${results.original.loadTime}ms`);
    console.log(`   Title: "${results.original.title}"`);
    console.log(`   Key Phrase: ${results.original.keyPhrase ? '✅' : '❌'}`);
    
    console.log(`🏠 OUR SITE (80.93.61.62):`);
    console.log(`   Status: ${results.ours.status}`);
    console.log(`   Load Time: ${results.ours.loadTime}ms`);
    console.log(`   Title: "${results.ours.title}"`);
    console.log(`   Key Phrase: ${results.ours.keyPhrase ? '✅' : '❌'}`);
    
    // Оценка соответствия
    let score = 0;
    if (results.ours.status === 'success') score += 25;
    if (results.ours.keyPhrase) score += 25;
    if (results.ours.title === results.original.title) score += 25;
    if (results.ours.loadTime < results.original.loadTime) score += 25;
    
    console.log(`\n🎯 COMPLIANCE SCORE: ${score}/100`);
    
    if (score >= 75) {
        console.log('🎉 EXCELLENT! Our site matches the original very well.');
    } else if (score >= 50) {
        console.log('👍 GOOD! Our site works but needs some improvements.');
    } else {
        console.log('⚠️  NEEDS WORK! Significant differences found.');
    }
    
    // Сохранение результатов
    const reportPath = '/var/www/html/tests/reports/comparison-report.json';
    fs.writeFileSync(reportPath, JSON.stringify({
        timestamp: new Date().toISOString(),
        results,
        score
    }, null, 2));
    
    console.log(`📄 Report saved: ${reportPath}`);
}

comprehensiveComparison().catch(console.error);
