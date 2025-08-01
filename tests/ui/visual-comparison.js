const puppeteer = require('puppeteer');
const fs = require('fs');

async function compareSites() {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    // Configure URL and paths
    const urls = {
        local: 'https://80.93.61.62',
        original: 'https://divita.ae'
    };

    const paths = {
        local: 'tests/screenshots/local.png',
        original: 'tests/screenshots/original.png'
    };

    try {
        console.log('Loading local site...');
        await page.goto(urls.local, { waitUntil: 'networkidle2' });
        await page.screenshot({ path: paths.local, fullPage: true });

        console.log('Loading original site...');
        await page.goto(urls.original, { waitUntil: 'networkidle2' });
        await page.screenshot({ path: paths.original, fullPage: true });

        console.log('Comparison screenshots saved.');
    } catch (error) {
        console.error('Error during comparison:', error);
    } finally {
        await browser.close();
    }
}

compareSites();
