const {chromium}=require('/Users/lbeezr/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
(async()=>{
 const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:1200},deviceScaleFactor:1});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));const reports=[];
 for(const world of ['nebula','moonwake'])for(const device of ['wide','tall','phone']){
   await page.goto(`file://${__dirname}/index.html?world=${world}&device=${device}&density=dense`);
   await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
   const result=await page.evaluate(()=>{const s=document.querySelector('.screen').getBoundingClientRect(),f=document.querySelector('.field').getBoundingClientRect(),h=document.querySelector('.hud').getBoundingClientRect();return {...window.conceptLayout,stars:document.querySelectorAll('.field .star').length,cells:document.querySelectorAll('.cell-guides i').length,dx:Math.abs((f.x+f.width/2)-(s.x+s.width/2)),dy:Math.abs((f.y+f.height/2)-(s.y+s.height/2)),missing:[...document.images].filter(i=>!i.naturalWidth).length,actionsInside:document.querySelector('.actions').getBoundingClientRect().bottom<s.bottom-5,hudAbove:h.bottom<f.top,hudInside:h.top>=s.top,forecast:[...document.querySelectorAll('.incoming img')].map(i=>i.src.match(/StarCast(.*?)\.imageset/)[1])};});
   if(result.stars!==49||result.cells!==49||result.dx>.1||result.dy>.1||result.missing||!result.actionsInside||!result.hudAbove||!result.hudInside||result.step<44||result.forecast.join()!=='Sunny,Sunny,Opal')throw Error(JSON.stringify(result));
   reports.push(result);await page.locator('summary').click();
   for(const score of ['0','99999','100000','999999','1000000','999999999','9223372036854775807']){
     await page.selectOption('#score',score);
     const valid=await page.evaluate(value=>{const v=document.querySelector('.score'),r=v.getBoundingClientRect(),m=document.querySelector('.menu').getBoundingClientRect(),h=document.querySelector('.hud').getBoundingClientRect();return v.textContent===BigInt(value).toLocaleString('en-US')&&v.scrollWidth<=v.clientWidth+1&&r.right<=h.right+1&&(r.right<=m.left||r.top>=m.bottom);},score);
     if(!valid)throw Error(`Score collision or lost precision: ${world}/${device}/${score}`);
   }
   await page.selectOption('#score','100000');await page.selectOption('#state','paused');
   if(await page.locator('.forecast').isVisible()||!await page.locator('.guide').isVisible()||await page.locator('.pause-action').textContent()!=='Resume')throw Error('Paused HUD failed');
   await page.selectOption('#state','playing');if(!await page.locator('.forecast').isVisible()||await page.locator('.guide').isVisible())throw Error('Playing HUD failed');
   if(world==='nebula')await page.uncheck('#motion');await page.selectOption('#density','half');await page.locator('.screen').screenshot({path:path.join(__dirname,`${world}-${device}-v2-concept.jpg`),type:'jpeg',quality:92});
 }
 await page.locator('button[data-world="nebula"]').click();
 for(const layer of ['deep-space','distant-haze','left-cloud','right-cloud','near-wisps']){await page.uncheck(`input[data-layer="${layer}"]`);if(await page.locator(`.scene-layer[data-layer="${layer}"]`).isVisible())throw Error('Layer hide failed');await page.check(`input[data-layer="${layer}"]`);}
 await page.check('#motion');
 const fixed=await page.locator('.field').boundingBox(),before=await page.locator('.scene-layer[data-layer="near-wisps"]').evaluate(e=>getComputedStyle(e).transform);
 await page.waitForFunction(old=>getComputedStyle(document.querySelector('.scene-layer[data-layer="near-wisps"]')).transform!==old,before,{timeout:2000});
 if(JSON.stringify(await page.locator('.field').boundingBox())!==JSON.stringify(fixed))throw Error('Scenery moved the field');
 await page.emulateMedia({reducedMotion:'reduce'});if(await page.locator('.scene-layer[data-layer="near-wisps"]').evaluate(e=>getComputedStyle(e).animationName)!=='none')throw Error('Reduce Motion failed');
 await page.emulateMedia({reducedMotion:'no-preference'});await page.uncheck('#motion');
 await page.selectOption('#density','empty');if(await page.locator('.field .star').count()||await page.locator('.hud').isVisible())throw Error('Empty failed');
 await page.selectOption('#density','sparse');if(await page.locator('.field .star').count()!==8)throw Error('Sparse failed');
 await page.check('#guides');if(!await page.locator('.cell-guides').isVisible())throw Error('Guides failed');
 await page.uncheck('#scenery');if(await page.locator('.scenery').isVisible())throw Error('Scenery hide failed');
 await page.setViewportSize({width:390,height:844});if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1))throw Error('Narrow page overflow');
 for(const folder of ['living-worlds-03','celestial-worlds-04']){await page.goto(`file://${path.join(__dirname,'..',folder,'index.html')}?density=dense`);await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));if(await page.locator('.stars .star').count()!==49)throw Error(folder+' shared cast regression');}
 if(errors.length)throw Error(errors.join('\n'));
 const sourceHashes=Object.fromEntries(['index.html','review.js','review.css','forecast-snapshot.js'].map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,f))).digest('hex')]));
 fs.writeFileSync(path.join(__dirname,'review-v2-checks.json'),JSON.stringify({date:'2026-10-18',kind:'Local Chrome browser concept only; not native evidence',sourceHashes,reports,scoreCases:42,maximumScore:'9,223,372,036,854,775,807',forecast:'Seed 23, five committed showers: Sunny, Sunny, Opal; paused hides trail',layers:'5 independent visibility controls',motion:'CSS transform changes while field stays fixed; Reduce Motion disables animation',controls:'passed',legacyCastPreviews:'49 stars and no missing images in both earlier viewers',narrowPageOverflow:false},null,2)+'\n');
 console.log('PASS: six centered compositions, 42 exact-score cases, forecast states, five layers and browser motion/Reduce Motion.');await browser.close();
})().catch(e=>{console.error(e);process.exit(1);});
