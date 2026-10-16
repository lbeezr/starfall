// Optional offline document-rendering check using an already installed Playwright.
// No user browser/session, network page, game or simulator is accessed.
const fs = require('node:fs/promises');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

async function main() {
  const output = path.resolve(process.argv[2]);
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const watchdog = setTimeout(() => { browser.close(); process.exitCode = 2; }, 45000);
  try {
    const context = await browser.newContext({ offline: true, serviceWorkers: 'block', viewport: { width: 900, height: 1200 } });
    const page = await context.newPage();
    await page.route('**/*', route => route.request().url().startsWith('file:') ? route.continue() : route.abort());
    const measurements = {};
    for (const name of ['participant-card', 'moderator-packet']) {
      await page.goto(pathToFileURL(path.join(__dirname, name + '.html')).href);
      await page.emulateMedia({ media: 'print' });
      measurements[name] = await page.locator('.page').evaluateAll(pages => pages.map(section => ({
        width: section.getBoundingClientRect().width,
        height: section.getBoundingClientRect().height,
        scrollWidth: section.scrollWidth,
      })));
      for (const format of ['Letter', 'A4']) {
        await page.pdf({ path: path.join(output, name + '-' + format + '.pdf'), format, printBackground: true, timeout: 15000 });
      }
      await page.screenshot({ path: path.join(output, name + '-print.png'), fullPage: true, timeout: 15000 });
    }
    await fs.writeFile(path.join(output, 'layout-measurements.json'), JSON.stringify(measurements, null, 2) + '\n');
    console.log('PASS: offline Letter/A4 print proofs and print-style screenshots generated; inspect pagination and appearance separately.');
  } finally {
    clearTimeout(watchdog);
    await browser.close();
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
