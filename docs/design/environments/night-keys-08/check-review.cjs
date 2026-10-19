const {chromium}=require('/Users/lbeezr/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto'),assert=require('assert');
(async()=>{
 const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:1200}}),errors=[],reports=[];
 page.on('pageerror',e=>errors.push(e.message));const ids=['moonwake','nebula','shatterlight','garden','ringdrift'];
 const out='/tmp/starfall-night-key-checks';fs.mkdirSync(out,{recursive:true});
 const decoded=()=>page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
 for(const id of ids){
  await page.goto(`file://${__dirname}/index.html?kit=${id}`);
  for(const density of ['sparse','gathering','dense','empty']){
   await page.selectOption('#density',density);await decoded();
   const result=await page.evaluate(()=>[...document.querySelectorAll('.stage')].map(s=>{
    const r=s.getBoundingClientRect(),c=s.querySelector('.cast').getBoundingClientRect();
    return {kit:nightKeyReviewState.kit,density:nightKeyReviewState.density,profile:s.dataset.profile,count:s.querySelectorAll('.cast .star').length,dx:Math.abs(r.x+r.width/2-c.x-c.width/2),dy:Math.abs(r.y+r.height/2-c.y-c.height/2),overflow:document.documentElement.scrollWidth>innerWidth+1};
   }));
   result.forEach(r=>{assert.equal(r.count,{sparse:6,gathering:24,dense:49,empty:0}[density]);assert(r.dx<.1&&r.dy<.1&&!r.overflow,JSON.stringify(r));});reports.push(...result);
  }
  await page.selectOption('#density','dense');await page.check('#guides');await decoded();
  assert.equal(await page.locator('.stage .reservations').count(),2);
  await page.locator('.comparisons').screenshot({path:`${out}/${id}-dense-guides.jpg`,type:'jpeg',quality:90});
  await page.uncheck('#guides');await page.check('#gray');await decoded();
  assert((await page.locator('.stage').first().evaluate(s=>getComputedStyle(s).filter)).includes('grayscale'));
  await page.locator('.comparisons').screenshot({path:`${out}/${id}-grayscale.jpg`,type:'jpeg',quality:90});
  await page.uncheck('#gray');await page.selectOption('#density','gathering');await decoded();
  for(const profile of ['wide','phone'])await page.locator(`.stage[data-profile="${profile}"]`).screenshot({path:path.join(__dirname,`${id}-${profile}-cast.jpg`),type:'jpeg',quality:93});
 }
 await page.setViewportSize({width:390,height:844});assert(!(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1)));
 await page.locator('button[data-kit="moonwake"]').focus();await page.keyboard.press('Enter');assert.equal(await page.evaluate(()=>nightKeyReviewState.kit),'moonwake');
 await page.emulateMedia({reducedMotion:'reduce'});assert.equal(await page.evaluate(()=>document.getAnimations().length),0);await decoded();await page.screenshot({path:`${out}/mobile-review.jpg`,fullPage:true,type:'jpeg',quality:85});
 await page.setViewportSize({width:1440,height:1200});await page.goto(`file://${__dirname}/index.html`);await decoded();await page.screenshot({path:`${out}/desk.jpg`,fullPage:true,type:'jpeg',quality:90});
 await page.setViewportSize({width:1480,height:900});
 await page.setContent('<style>body{margin:0;background:#090e1b;color:#dfe5f2;padding:20px;font:16px system-ui}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}figure{margin:0}img{width:100%;height:auto}figcaption{padding:9px 0}h1{font:32px Georgia;margin:0 0 14px}p{color:#aebbd0}</style><h1>Five night journeys · color and composition</h1><p>Generated environments + existing crystal bodies / illustrative faces · browser concepts, not native screens</p><div class="grid">'+ids.map(id=>`<figure><img src="file://${__dirname}/${id}-wide-cast.jpg"><figcaption>${({moonwake:'Moonwake',nebula:'The Nebula Cradle',shatterlight:'Shatterlight Reach',garden:'The Night Garden',ringdrift:'Ringdrift'})[id]}</figcaption></figure>`).join('')+'</div>');await decoded();await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await page.locator('body').screenshot({path:path.join(__dirname,'overview.jpg'),type:'jpeg',quality:90});
 await page.setContent('<style>body{margin:0;background:#090e1b;color:#dfe5f2;padding:20px;font:16px system-ui}.grid{display:grid;grid-template-columns:repeat(5,1fr);gap:18px}figure{margin:0}img{width:100%;height:auto}figcaption{padding:9px 0}</style><div class="grid">'+ids.map(id=>`<figure><img src="file://${__dirname}/${id}-phone-cast.jpg"><figcaption>${({moonwake:'Moonwake',nebula:'The Nebula Cradle',shatterlight:'Shatterlight Reach',garden:'The Night Garden',ringdrift:'Ringdrift'})[id]}</figcaption></figure>`).join('')+'</div>');await decoded();await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await page.locator('body').screenshot({path:`${out}/phones.jpg`,type:'jpeg',quality:90});
 assert.equal(errors.length,0,errors.join('\n'));
 const sources=['index.html','review.js','review.css','check-review.cjs','../scene-kits-07/kit-data.js','../scene-kits-07/diagrams.js','../concept-cast.js','manifest.json','prompts.json'];
 const sourceHashes=Object.fromEntries(sources.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,f))).digest('hex')]));
 fs.writeFileSync(path.join(__dirname,'review-checks.json'),JSON.stringify({date:'2026-10-18',scope:'Static browser composition; no native or animation acceptance',sourceKitCommit:'003433f',sourceHashes,reports,generatedArtwork:'All selected images decoded',regions:'HUD, centered full field and action reservations toggled',grayscale:'all five sampled with dense cast',keyboard:'Enter selects destination',narrow390px:'no horizontal page overflow',reducedMotion:'no animations exist',errors},null,2)+'\n');
 await browser.close();console.log('PASS: 40 centered cast compositions, 10 generated images decoded, all five dense/grayscale/reservation views, keyboard and 390px layout.');
})().catch(e=>{console.error(e);process.exit(1)});
