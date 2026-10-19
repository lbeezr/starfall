const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const http=require('node:http');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..'),pack=path.join(root,'pack');
const hash=s=>crypto.createHash('sha256').update(s).digest('hex');
let browser,server;
async function main(){
 server=http.createServer((req,res)=>{const requested=decodeURIComponent(new URL(req.url,'http://localhost').pathname),file=path.resolve(pack,'.'+requested);if(!file.startsWith(pack+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',({'.html':'text/html','.png':'image/png','.webp':'image/webp','.json':'application/json'})[path.extname(file)]||'text/plain');fs.createReadStream(file).pipe(res);});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const url=`http://127.0.0.1:${server.address().port}/preview.html`;
 browser=await chromium.launch({executablePath:process.argv[2]||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 const checks=[],errors=[],page=await browser.newPage({viewport:{width:900,height:900},deviceScaleFactor:2});page.on('pageerror',e=>errors.push(e.message));
 await page.goto(url);await page.waitForSelector('body[data-ready="true"]');
 for(const width of [900,390,320]){
  await page.setViewportSize({width,height:900});
  for(const tilt of ['-12','0','12']){
   await page.locator('#pitch').selectOption(tilt);await page.waitForSelector('body[data-ready="true"]');
   for(const turn of ['-35','0','35']){
    await page.locator('#yaw').fill(turn);await page.locator('#copy').fill('AZaz gjpq 019 ?! ÷');
    const result=await page.locator('#stage').evaluate(c=>{const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let n=0,edge=0;for(let i=0;i<d.length;i+=4)if(d[i+3]>0){n++;const x=i/4%c.width,y=Math.floor(i/4/c.width);if(x<3||y<3||x>c.width-4||y>c.height-4)edge++;}return{n,edge,overflow:document.documentElement.scrollWidth>innerWidth};});
    assert.ok(result.n>500);assert.equal(result.edge,0);assert.equal(result.overflow,false);
   }
  }
 }
 checks.push('27 viewport/yaw/pitch combinations render populated, unclipped text without horizontal overflow.');
 await page.setViewportSize({width:900,height:900});await page.locator('#pitch').selectOption('0');await page.waitForSelector('body[data-ready="true"]');await page.locator('#copy').fill('Starfall! +128');await page.locator('#yaw').fill('0');
 const before=await page.locator('#stage').evaluate(c=>c.toDataURL());await page.locator('#play').click();await page.waitForFunction(()=>document.body.dataset.view==='yaw-p30_pitch-z00');const after=await page.locator('#stage').evaluate(c=>c.toDataURL());assert.notEqual(hash(before),hash(after));await page.locator('#pause').click();const view=await page.locator('body').getAttribute('data-view');await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));assert.equal(await page.locator('body').getAttribute('data-view'),view);checks.push('Playback changes exported-sprite pixels and pause holds the selected view.');
 await page.locator('#play').click();await page.waitForSelector('body[data-playing="true"]');await page.waitForSelector('body[data-playing="false"]',{timeout:7000});assert.equal(await page.locator('#yaw').inputValue(),'0');checks.push('Replay returns to front and stops.');
 await page.locator('#play').click();await page.locator('#pitch').selectOption('12');await page.waitForSelector('body[data-ready="true"]');assert.equal(await page.locator('body').getAttribute('data-playing'),'false');assert.ok((await page.locator('body').getAttribute('data-view')).endsWith('pitch-p12'));checks.push('Changing pitch interrupts playback.');
 await page.evaluate(()=>{const p=document.getElementById('pitch');for(const value of ['-12','0','12']){p.value=value;p.dispatchEvent(new Event('change'));}});await page.waitForSelector('body[data-ready="true"]');assert.ok((await page.locator('body').getAttribute('data-view')).endsWith('pitch-p12'));checks.push('Rapid pitch changes settle on the latest requested angle plane.');
 await page.locator('#copy').fill('é');assert.match(await page.locator('#status').innerText(),/Outside this character set/);await page.locator('#copy').fill('Starfall! +128');await page.locator('#pitch').selectOption('0');await page.waitForSelector('body[data-ready="true"]');await page.locator('#yaw').fill('30');await page.screenshot({path:'/tmp/crystal-comet-preview-reviewed.png',fullPage:true});checks.push('Unsupported characters are identified explicitly.');
 const quiet=await browser.newPage({viewport:{width:390,height:900},reducedMotion:'reduce'});await quiet.goto(url);await quiet.waitForSelector('body[data-ready="true"]');assert.equal(await quiet.locator('body').getAttribute('data-playing'),'false');await quiet.locator('#yaw').focus();await quiet.keyboard.press('ArrowRight');assert.equal(await quiet.locator('#yaw').inputValue(),'5');checks.push('Reduced-motion view remains static; keyboard angle inspection works.');assert.deepEqual(errors,[]);checks.push('No browser JavaScript errors.');
 const offline=await browser.newPage();offline.on('pageerror',e=>errors.push(e.message));await offline.goto(require('node:url').pathToFileURL(path.join(pack,'preview.html')).href);await offline.waitForSelector('body[data-ready="true"]');await offline.locator('#play').click();await offline.waitForSelector('body[data-playing="true"]');await offline.waitForSelector('body[data-playing="false"]',{timeout:7000});assert.equal(await offline.locator('#yaw').inputValue(),'0');assert.deepEqual(errors,[]);checks.push('Direct file opening loads all front-plane images and completes playback without a server.');
 const report={browser:await browser.version(),configuration:'Headless Chrome over loopback for canvas inspection, 2× desktop raster; 900/390/320 CSS px; normal and reduced-motion contexts; direct file opening also checked',checks,limits:'Offline asset viewer only; no native gameplay, GPU-budget or actual VoiceOver acceptance.'};fs.writeFileSync(path.join(pack,'browser-validation.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{await browser?.close();server?.close();});
