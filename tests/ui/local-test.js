const puppeteer = require('puppeteer');

async function testLocal() {
    console.log('=== Testing Puppeteer Setup ===');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--disable-dev-shm-usage'
        ]
    });
    
    try {
        const page = await browser.newPage();
        
        // Тест простой HTML страницы
        await page.setContent(`
            <html>
                <head><title>Test Page</title></head>
                <body>
                    <h1>DIVITA Test</h1>
                    <p>Land is an opportunity</p>
                    <button id="test-btn">Click me</button>
                </body>
            </html>
        `);
        
        const title = await page.title();
        const h1Text = await page.$eval('h1', el => el.textContent);
        
        console.log('✅ Puppeteer working correctly');
        console.log(`📄 Title: ${title}`);
        console.log(`📝 H1 text: ${h1Text}`);
        
        // Тест скриншота
        await page.screenshot({
            path: '/var/www/html/tests/screenshots/test-page.png',
            fullPage: true
        });
        console.log('📸 Screenshot saved: screenshots/test-page.png');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await browser.close();
    }
}

testLocal().catch(console.error);
