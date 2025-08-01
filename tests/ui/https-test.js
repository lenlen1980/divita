const puppeteer = require('puppeteer');

async function testHttps() {
    console.log('=== Testing HTTPS Setup ===');
    
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
    
    try {
        const page = await browser.newPage();
        
        console.log('🔗 Testing: https://80.93.61.62');
        
        const start = Date.now();
        await page.goto('https://80.93.61.62', { 
            waitUntil: 'domcontentloaded',
            timeout: 10000 
        });
        const loadTime = Date.now() - start;
        
        const title = await page.title();
        const url = page.url();
        
        console.log(`✅ Page loaded successfully in ${loadTime}ms`);
        console.log(`📄 Title: "${title}"`);
        console.log(`🔗 Final URL: ${url}`);
        
        // Проверим основные элементы
        const bodyExists = await page.$('body') !== null;
        console.log(`🏗️  Body element: ${bodyExists ? '✅ Found' : '❌ Missing'}`);
        
        // Простой скриншот
        await page.screenshot({
            path: '/var/www/html/tests/screenshots/https-test.png',
            clip: { x: 0, y: 0, width: 1200, height: 800 }
        });
        console.log('📸 Screenshot saved: screenshots/https-test.png');
        
        // Проверка ключевой фразы
        try {
            const bodyText = await page.evaluate(() => document.body.innerText);
            const hasKeyPhrase = bodyText.toLowerCase().includes('land is an opportunity');
            console.log(`🔍 Key phrase check: ${hasKeyPhrase ? '✅ Found' : '❌ Not found'}`);
            
            if (hasKeyPhrase) {
                console.log('🎉 HTTPS site is working correctly!');
            }
        } catch (e) {
            console.log('⚠️  Could not check body text');
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await browser.close();
    }
}

testHttps().catch(console.error);
