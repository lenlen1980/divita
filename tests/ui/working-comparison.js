const puppeteer = require('puppeteer');
const fs = require('fs');

async function workingComparison() {
    console.log('=== DIVITA Working Comparison ===');
    console.log('🔗 Original: https://divita.ae');
    console.log('🏠 Our site: https://80.93.61.62 (self-signed SSL)');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        ignoreDefaultArgs: ['--disable-extensions'],
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--disable-dev-shm-usage',
            '--ignore-certificate-errors',
            '--ignore-ssl-errors',
            '--ignore-certificate-errors-spki-list',
            '--disable-gpu'
        ]
    });
    
    try {
        // Тест оригинального сайта
        console.log('\n🌍 Testing ORIGINAL site...');
        const originalPage = await browser.newPage();
        await originalPage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        
        const originalStart = Date.now();
        try {
            await originalPage.goto('https://divita.ae', { 
                waitUntil: 'networkidle0',
                timeout: 15000 
            });
            const originalLoadTime = Date.now() - originalStart;
            const originalTitle = await originalPage.title();
            
            console.log(`✅ ORIGINAL loaded in ${originalLoadTime}ms`);
            console.log(`📄 Title: "${originalTitle}"`);
            
            // Скриншот оригинала
            await originalPage.screenshot({
                path: '/var/www/html/tests/screenshots/original-site.png',
                fullPage: true
            });
            console.log('📸 Screenshot saved: screenshots/original-site.png');
            
        } catch (error) {
            console.log(`❌ ORIGINAL error: ${error.message}`);
        }
        
        // Тест нашего сайта
        console.log('\n🏠 Testing OUR site...');
        const ourPage = await browser.newPage();
        await ourPage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        
        const ourStart = Date.now();
        try {
            await ourPage.goto('https://80.93.61.62', { 
                waitUntil: 'networkidle0',
                timeout: 15000 
            });
            const ourLoadTime = Date.now() - ourStart;
            const ourTitle = await ourPage.title();
            
            console.log(`✅ OUR SITE loaded in ${ourLoadTime}ms`);
            console.log(`📄 Title: "${ourTitle}"`);
            
            // Проверим основные элементы
            const h1Elements = await ourPage.$$eval('h1', elements => 
                elements.map(el => el.textContent.trim()).filter(text => text.length > 0)
            );
            
            console.log(`📝 Found ${h1Elements.length} H1 elements:`, h1Elements.slice(0, 3));
            
            // Скриншот нашего сайта
            await ourPage.screenshot({
                path: '/var/www/html/tests/screenshots/our-site.png',
                fullPage: true
            });
            console.log('📸 Screenshot saved: screenshots/our-site.png');
            
            // Проверка ключевой фразы
            const bodyText = await ourPage.evaluate(() => document.body.innerText);
            const hasKeyPhrase = bodyText.toLowerCase().includes('land is an opportunity');
            console.log(`🔍 Key phrase "land is an opportunity": ${hasKeyPhrase ? '✅ Found' : '❌ Not found'}`);
            
        } catch (error) {
            console.log(`❌ OUR SITE error: ${error.message}`);
        }
        
        await originalPage.close();
        await ourPage.close();
        
    } catch (error) {
        console.error('❌ General error:', error.message);
    } finally {
        await browser.close();
        console.log('\n🏁 Comparison complete!');
    }
}

workingComparison().catch(console.error);
