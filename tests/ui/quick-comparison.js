const puppeteer = require('puppeteer');
const fs = require('fs');

async function quickComparison() {
    console.log('=== DIVITA Quick Comparison ===');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        args: [
            '--no-sandbox', 
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
        ]
    });
    
    const results = {
        timestamp: new Date().toISOString(),
        tests: []
    };

    // Test our local site
    console.log('\n🔍 Testing LOCAL site: https://80.93.61.62');
    
    const page = await browser.newPage();
    const localTest = {
        site: 'local',
        url: 'https://80.93.61.62',
        loadTime: 0,
        title: '',
        errors: [],
        elements: {},
        status: 'unknown'
    };

    try {
        const startTime = Date.now();
        
        await page.goto('https://80.93.61.62', { 
            waitUntil: 'domcontentloaded',
            timeout: 15000 
        });
        
        localTest.loadTime = Date.now() - startTime;
        localTest.title = await page.title();
        
        // Count basic elements
        const elements = {
            'images': 'img',
            'links': 'a[href]',
            'buttons': 'button, .button',
            'scripts': 'script'
        };

        for (const [elementName, selector] of Object.entries(elements)) {
            try {
                const count = await page.$$eval(selector, els => els.length);
                localTest.elements[elementName] = count;
            } catch (e) {
                localTest.elements[elementName] = 0;
            }
        }

        // Take screenshot
        await page.screenshot({ 
            path: `tests/screenshots/local-${Date.now()}.png`,
            fullPage: false 
        });

        localTest.status = 'success';
        console.log(`✅ LOCAL: ${localTest.loadTime}ms, title: "${localTest.title}"`);
        console.log(`   Images: ${localTest.elements.images}, Links: ${localTest.elements.links}`);
        
    } catch (error) {
        localTest.errors.push(error.message);
        localTest.status = 'error';
        console.log(`❌ LOCAL: ${error.message}`);
    }

    results.tests.push(localTest);
    await page.close();
    await browser.close();

    // Ensure reports directory exists
    if (!fs.existsSync('tests/reports')) {
        fs.mkdirSync('tests/reports', { recursive: true });
    }

    // Save results
    fs.writeFileSync(
        'tests/reports/quick-comparison.json', 
        JSON.stringify(results, null, 2)
    );

    // Generate summary
    console.log('\n📊 LOCAL SITE SUMMARY:');
    console.log(`  Status: ${localTest.status}`);
    console.log(`  Load Time: ${localTest.loadTime}ms`);
    console.log(`  Title: ${localTest.title}`);
    console.log(`  Elements: ${JSON.stringify(localTest.elements, null, 2)}`);
    if (localTest.errors.length > 0) {
        console.log(`  Errors: ${localTest.errors.join(', ')}`);
    }

    return results;
}

quickComparison()
    .then(results => {
        console.log('\n✅ Local site analysis complete!');
        process.exit(0);
    })
    .catch(error => {
        console.error('❌ Analysis failed:', error);
        process.exit(1);
    });
