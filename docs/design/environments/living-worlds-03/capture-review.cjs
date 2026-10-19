const {chromium}=require('/Users/lbeezr/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
const root=process.env.STARFALL_REVIEW_ROOT || __dirname;
const all=process.env.STARFALL_REVIEW_WORLDS?.split(',') || ['observatory','cloudsea','hearth','grotto','archive'];
(async()=>{
 const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1400,height:1200},deviceScaleFactor:2});
 const reports=[];
 for(const world of all){
  await page.goto(`file://${root}/index.html?export=1&world=${world}&density=dense`);
  await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode().catch(()=>{}))));
  const missing=await page.evaluate(()=>[...document.images].filter(i=>!i.naturalWidth).map(i=>i.src));
  const stars=await page.locator('.stars .star').count(),cells=await page.locator('.geometry polygon').count();
  if(stars!==49||cells!==49||missing.length)throw Error(JSON.stringify({world,stars,cells,missing}));
  await page.locator('.stage').screenshot({path:`/tmp/starfall-${world}-dense.png`});
  await page.selectOption('#density','half',{force:true});
  await page.locator('.stage').screenshot({path:`${root}/${world}-composition.jpg`,type:'jpeg',quality:92});
  reports.push({world,stars,cells,missing});
 }
 if(reports.length===5){
  await page.setViewportSize({width:1680,height:1200});
  await page.goto(`file://${root}/index.html?compare=1&export=1`);
  await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
  const reviewBounds=await page.locator('#review').boundingBox();
  await page.screenshot({path:`${root}/five-worlds.jpg`,type:'jpeg',quality:92,clip:{x:0,y:0,width:1680,height:Math.ceil(reviewBounds.y+reviewBounds.height+28)}});
  await page.goto(`file://${root}/index.html`);
  for(const world of all){await page.locator(`[data-world="${world}"]`).first().click();if(await page.locator('.world-card').getAttribute('data-world')!==world)throw Error('World switching failed');}
  const proposedY=await page.locator('.stars .star').first().evaluate(n=>n.style.top);
  await page.selectOption('#layout','current');
  const currentY=await page.locator('.stars .star').first().evaluate(n=>n.style.top);
  if(proposedY===currentY)throw Error('Layout comparison did not change row positions');
  if(await page.locator('.geometry polygon').count()!==49)throw Error('Current mapping lost cells');
  await page.selectOption('#layout','proposed');
  await page.selectOption('#density','empty');
  if(await page.locator('.stars .star').count()!==0)throw Error('Empty sample failed');
  await page.selectOption('#density','sparse');
  if(await page.locator('.stars .star').count()!==8)throw Error('Sparse sample failed');
  await page.check('#geometry');
  if(!await page.locator('.geometry').isVisible())throw Error('Geometry toggle failed');
  await page.check('#large-copy');
  if(!await page.locator('.flowing-reading').isVisible())throw Error('Expanded copy failed');
  await page.setViewportSize({width:390,height:844});
  if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1))throw Error('Mobile horizontal overflow');
  await page.screenshot({path:'/tmp/starfall-review-mobile.png',fullPage:true});
  reports.push({reviewControls:'passed',layoutsCompared:['proposed','current'],mobileWidth:390,overflow:false});
 }
 console.log(JSON.stringify(reports,null,2));
 fs.writeFileSync(`${root}/review-checks.json`,JSON.stringify({date:'2026-10-18',kind:'Chromium HTML composition review, not native app verification',reports},null,2)+'\n');
 await browser.close();
})();
