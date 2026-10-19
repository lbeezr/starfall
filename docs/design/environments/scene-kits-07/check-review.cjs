const {chromium}=require('/Users/lbeezr/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),crypto=require('crypto');
(async()=>{
 const b=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 const p=await b.newPage({viewport:{width:1440,height:1200}}),errors=[];p.on('pageerror',e=>errors.push(e.message));
 const ids=['moonwake','nebula','shatterlight','garden','ringdrift'],names=['Moonwake','The Nebula Cradle','Shatterlight Reach','The Night Garden','Ringdrift'],reports=[];
 fs.mkdirSync('/tmp/starfall-kit-checks',{recursive:true});
 for(const id of ids){
  await p.goto(`file://${__dirname}/index.html?kit=${id}`);await p.selectOption('#density','dense');
  for(const device of ['wide','tall','phone']){
   await p.selectOption('#device',device);await p.evaluate(()=>Promise.all([...document.querySelectorAll('img[src]')].map(i=>i.decode())));
   const result=await p.evaluate(()=>{const s=document.querySelector('.stage').getBoundingClientRect(),c=document.querySelector('.cast').getBoundingClientRect();return {kit:kitReviewState.kit,profile:kitReviewState.profile,cast:document.querySelectorAll('.cast .star').length,planes:document.querySelectorAll('.stage g[data-plane]').length,props:document.querySelectorAll('.prop').length,beats:document.querySelectorAll('.story-frame').length,assets:document.querySelectorAll('#asset-rows tr').length,dx:Math.abs(s.x+s.width/2-c.x-c.width/2),dy:Math.abs(s.y+s.height/2-c.y-c.height/2),invalidSvg:/NaN|undefined/.test(document.querySelector('.diagram').innerHTML),bodyOverflow:document.documentElement.scrollWidth>innerWidth+1};});
   if(result.cast!==49||result.planes!==5||result.props!==2||result.beats!==3||result.assets<7||result.dx>.1||result.dy>.1||result.invalidSvg||result.bodyOverflow)throw Error(JSON.stringify(result));reports.push(result);
   await p.selectOption('#density','sparse');await p.locator('.stage').screenshot({path:`/tmp/starfall-kit-checks/${id}-${device}.png`});await p.selectOption('#density','dense');
  }
  for(let i=0;i<5;i++){await p.uncheck(`#layer-list input[data-plane="${i}"]`);if(await p.locator(`.stage g[data-plane="${i}"]`).isVisible())throw Error('Plane toggle failed');await p.check(`#layer-list input[data-plane="${i}"]`);}
  for(let i=0;i<3;i++){await p.locator('.story-frame').nth(i).click();if((await p.evaluate(()=>kitReviewState.beat))!==i)throw Error('Storyboard selection failed');}
  await p.check('#gray');if(!(await p.locator('.stage svg').first().getAttribute('style')).includes('grayscale'))throw Error('Grayscale failed');
  await p.selectOption('#density','empty');if(await p.locator('.cast .star').count())throw Error('Empty failed');
  await p.uncheck('#guides');if(await p.locator('.stage .reservations').count())throw Error('Guide hide failed');
 }
 await p.setViewportSize({width:390,height:844});if(await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1))throw Error('Narrow page overflow');
 await p.locator('button[data-kit="moonwake"]').focus();await p.keyboard.press('Enter');if((await p.evaluate(()=>kitReviewState.kit))!=='moonwake')throw Error('Keyboard kit navigation failed');
 await p.emulateMedia({reducedMotion:'reduce'});if(await p.evaluate(()=>document.getAnimations().length))throw Error('Unexpected animation in static storyboard');
 await p.setViewportSize({width:1440,height:1200});await p.goto(`file://${__dirname}/index.html?kit=moonwake`);await p.evaluate(()=>Promise.all([...document.querySelectorAll('img[src]')].map(i=>i.decode())));await p.screenshot({path:'/tmp/starfall-kit-checks/desk.jpg',fullPage:true});
 // One compact contact sheet is retained as a planning diagram, not generated artwork.
 await p.setViewportSize({width:1440,height:920});await p.goto(`file://${__dirname}/index.html`);
 await p.setContent('<style>body{margin:0;background:#101522;color:#e6eafa;font:18px system-ui;padding:24px}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}figure{margin:0;background:#080d1b}img{width:100%;height:310px;object-fit:contain}figcaption{padding:12px}h1{font:32px Georgia;margin:0 0 12px}p{color:#afbcd1;margin:0 0 24px}</style><h1>Starfall · five scene kits</h1><p>Shape diagrams before generation · landscape composition and sparse existing cast</p><div class="grid">'+ids.map((id,i)=>`<figure><img src="file:///tmp/starfall-kit-checks/${id}-wide.png"><figcaption>${names[i]}</figcaption></figure>`).join('')+'</div>');await p.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));await p.screenshot({path:path.join(__dirname,'kit-overview.jpg'),fullPage:true,type:'jpeg',quality:90});
 await p.setContent('<style>body{margin:0;background:#101522;color:#e6eafa;font:18px system-ui;padding:24px}.grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:16px}figure{margin:0}img{width:100%;height:auto}figcaption{padding:12px}</style><div class="grid">'+ids.map((id,i)=>`<figure><img src="file:///tmp/starfall-kit-checks/${id}-phone.png"><figcaption>${names[i]}</figcaption></figure>`).join('')+'</div>');await p.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));await p.screenshot({path:'/tmp/starfall-kit-checks/phones.jpg',fullPage:true,type:'jpeg',quality:90});
 if(errors.length)throw Error(errors.join('\n'));
 const sourceHashes=Object.fromEntries(['index.html','kit-data.js','diagrams.js','review.js','review.css'].map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,f))).digest('hex')]));
 fs.writeFileSync(path.join(__dirname,'review-checks.json'),JSON.stringify({date:'2026-10-18',scope:'Static browser planning diagrams only; no native or new generated artwork evidence',sourceHashes,reports,layerSwitches:25,storyboardSelections:15,keyboardNavigation:'passed',narrow390px:'no page overflow; asset table scrolls locally',reduceMotion:'no automatic animation exists',images:'existing cast and applicable mood references decoded'},null,2)+'\n');
 await b.close();console.log('PASS: 15 centered compositions, 25 layer toggles, 15 storyboard selections, keyboard navigation and narrow-page layout.');
})().catch(e=>{console.error(e);process.exit(1)});
