const puppeteer = require('puppeteer');
const fs = require('fs');

async function functionalComparison() {
    console.log('=== DIVITA Functional Comparison ===');
    
    const browser = await puppeteer.launch({
        headless: true,
        ignoreHTTPSErrors: true,
        ignoreDefaultArgs: ["--disable-extensions"],
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const results = {
        timestamp: new Date().toISOString(),
        tests: []
    };

    const urls = {
        local: 'https://80.93.61.62',
        original: 'https://divita.ae'
    };

    for (const [name, url] of Object.entries(urls)) {
        console.log(`\n🔍 Testing ${name} site: ${url}`);
        
        const page = await browser.newPage();
        const test = {
            site: name,
            url: url,
            loadTime: 0,
            title: '',
            errors: [],
            elements: {},
            status: 'unknown'
        };

        try {
            const startTime = Date.now();
            
            // Navigate to site
            await page.goto(url, { 
                waitUntil: 'networkidle2',
                timeout: 30000 
            });
            
            test.loadTime = Date.now() - startTime;
            test.title = await page.title();
            
            // Check for key elements
            const elements = {
                'main content': 'main, [role="main"], .main-content',
                'navigation': 'nav, .nav, .navigation',
                'footer': 'footer, .footer',
                'buttons': 'button, .button, .btn',
                'images': 'img',
                'links': 'a[href]'
            };

            for (const [elementName, selector] of Object.entries(elements)) {
                try {
                    const count = await page.$$eval(selector, els => els.length);
                    test.elements[elementName] = count;
                } catch (e) {
                    test.elements[elementName] = 0;
                }
            }

            // Capture console errors
            page.on('console', msg => {
                if (msg.type() === 'error') {
                    test.errors.push(msg.text());
                }
            });

            // Take screenshot
            await page.screenshot({ 
                path: `tests/screenshots/${name}-${Date.now()}.png`,
                fullPage: true 
            });

            test.status = 'success';
            console.log(`✅ ${name}: ${test.loadTime}ms, title: "${test.title}"`);
            
        } catch (error) {
            test.errors.push(error.message);
            test.status = 'error';
            console.log(`❌ ${name}: ${error.message}`);
        }

        results.tests.push(test);
        await page.close();
    }

    await browser.close();

    // Save results
    fs.writeFileSync(
        'tests/reports/functional-comparison.json', 
        JSON.stringify(results, null, 2)
    );

    // Generate summary
    console.log('\n📊 COMPARISON SUMMARY:');
    results.tests.forEach(test => {
        console.log(`\n${test.site.toUpperCase()}:`);
        console.log(`  Status: ${test.status}`);
        console.log(`  Load Time: ${test.loadTime}ms`);
        console.log(`  Title: ${test.title}`);
        console.log(`  Elements: ${JSON.stringify(test.elements, null, 2)}`);
        if (test.errors.length > 0) {
            console.log(`  Errors: ${test.errors.length}`);
        }
    });

    return results;
}

functionalComparison()
    .then(results => {
        console.log('\n✅ Comparison complete! Check tests/reports/ for details.');
        process.exit(0);
    })
    .catch(error => {
        console.error('❌ Comparison failed:', error);
        process.exit(1);
    });
