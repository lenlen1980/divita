const puppeteer = require('puppeteer');
const fs = require('fs');

async function httpComparison() {
    console.log('=== DIVITA HTTP Comparison ===');
    
    const browser = await puppeteer.launch({
        headless: true,
ignoreHTTPSErrors: true,
        args: [
            '--no-sandbox', 
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage'
        ]
    });
    
    const page = await browser.newPage();
    
    try {
        console.log('\n🔍 Testing LOCAL site: https://80.93.61.62');
        
        const startTime = Date.now();
        await page.goto('https://80.93.61.62', { 
            waitUntil: 'domcontentloaded',
            timeout: 15000 
        });
        
        const loadTime = Date.now() - startTime;
        const title = await page.title();
        const finalUrl = page.url();
        
        console.log(`✅ SUCCESS: ${loadTime}ms`);
        console.log(`   Final URL: ${finalUrl}`);
        console.log(`   Title: "${title}"`);
        
        // Take screenshot
        await page.screenshot({ 
            path: `tests/screenshots/working-site-${Date.now()}.png`,
            fullPage: false 
        });
        
        console.log(`📸 Screenshot saved to tests/screenshots/`);
        
    } catch (error) {
        console.log(`❌ ERROR: ${error.message}`);
    }

    await browser.close();
    console.log('\n✅ Analysis complete!');
}

httpComparison();
