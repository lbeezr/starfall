#!/usr/bin/env node
/** Offline, deterministic normalization of the six Observatory raster masters. */
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const options = {};
for (let i = 0; i < args.length; i++) {
  const key = args[i];
  if (!['--node-modules', '--source-root', '--output-root'].includes(key) || !args[i + 1]) throw new Error(`Unknown or incomplete option: ${key}`);
  options[key] = args[++i];
}
const sharp = require(options['--node-modules'] ? path.join(path.resolve(options['--node-modules']), 'sharp') : 'sharp');
sharp.cache(false);
sharp.concurrency(1);
const sourceRoot = path.resolve(options['--source-root'] || here);
const outputRoot = path.resolve(options['--output-root'] || here);
const densities = [1, 2, 3];
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const round = n => Math.round(n * 10000) / 10000;
const pearl = [244, 236, 217];
const backgrounds = { midnight: [9, 19, 38], brightCloud: [237, 229, 201], white: [255, 255, 255] };
const specs = [
  { id: 'emblem-story', family: 'emblems', source: 'masters/illustrations/emblem-story.png', points: [48,48], padding: 2, display: [40,48], purpose: 'Story Mode lantern; aspect fit; separate native label.' },
  { id: 'emblem-freeplay', family: 'emblems', source: 'masters/illustrations/emblem-freeplay.png', points: [48,48], padding: 2, display: [40,48], purpose: 'Free Play comet; aspect fit; separate native label.' },
  { id: 'emblem-tutorial', family: 'emblems', source: 'masters/illustrations/emblem-tutorial.png', points: [48,48], padding: 2, display: [40,48], purpose: 'Tutorial constellation; aspect fit; separate native label.' },
  { id: 'button-action', family: 'skins', source: 'masters/skins/button-action.png', points: [320,64], padding: 2, display: [64], purpose: 'One horizontal action skin; 64-point fixed height, horizontal stretch only. 52-point compact is a uniform 52/64 scale before horizontal stretching.', caps: [0,48,0,48], content: [16,52,16,52], axis: 'horizontal', minimum: [120,64], notes: 'No vertical stretching: ornaments occupy the full-height fixed endcaps. Tall or multiline actions use panel-reading with native text reflow. Text and emblems may require width above the geometric minimum.' },
  { id: 'panel-reading', family: 'skins', source: 'masters/skins/panel-reading.png', points: [160,160], padding: 2, display: null, purpose: 'Reading surface, multiline action, pause and preference panel; stretch both axes.', caps: [32,32,32,32], content: [32,32,32,32], axis: 'both', minimum: [80,80], notes: 'Fixed corners contain all diamond fittings; native content determines actual minimum dimensions.' },
  { id: 'utility-bezel', family: 'skins', source: 'masters/skins/utility-bezel.png', points: [32,32], padding: 1, display: [32], purpose: 'Optional 32-point fitting around a 20-point glyph inside a native 44/45-point target. A 24-point glyph is unframed.', content: [6,6,6,6], contrastSample: [9,9,9,9] }
];
function bounds(data, w, h, threshold) {
  let l=w,t=h,r=-1,b=-1, count=0, total=0, cx=0,cy=0;
  for (let y=0;y<h;y++) for(let x=0;x<w;x++) {
    const a=data[(y*w+x)*4+3];
    if(a >= threshold) { l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);count++;total+=a;cx+=(x+.5)*a;cy+=(y+.5)*a; }
  }
  return { rect: count ? [l,t,r+1,b+1] : null, count, centroid: count ? [round(cx/total),round(cy/total)] : null };
}
function outerPadding(rect,w,h) { return [rect[1],rect[0],h-rect[3],w-rect[2]]; }
function luminance(rgb) { const c=rgb.map(v=>v/255).map(v=>v<=0.04045?v/12.92:((v+.055)/1.055)**2.4);return c[0]*.2126+c[1]*.7152+c[2]*.0722; }
function contrast(a,b) { const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05); }
function contrastRegion(data,w,h,rect) {
  const record={text:'#F4ECD9',regionPixels:rect,minimumAlpha:255,backdrops:{}};
  for(const [name,bg] of Object.entries(backgrounds)) {
    let minimum=Infinity,worst=null;
    for(let y=rect[1];y<rect[3];y++)for(let x=rect[0];x<rect[2];x++) {
      const p=(y*w+x)*4,a=data[p+3]/255;
      record.minimumAlpha=Math.min(record.minimumAlpha,data[p+3]);
      const rgb=[0,1,2].map(k=>data[p+k]*a+bg[k]*(1-a));
      const ratio=contrast(pearl,rgb);
      if(ratio<minimum){minimum=ratio;worst={pixel:[x,y],compositedRGB:rgb.map(round)};}
    }
    record.backdrops[name]={backgroundRGB:bg,minimumRatio:round(minimum),worst};
    if(minimum<4.5)throw new Error(`Pearl contrast below 4.5:1 on ${name}: ${minimum}`);
  }
  if(record.minimumAlpha<250)throw new Error(`Reading center alpha below 250: ${record.minimumAlpha}`);
  return record;
}
const prompts=JSON.parse(await fs.readFile(path.join(sourceRoot,'PROMPTS.json'),'utf8'));
const preflight=[];
for(const spec of specs) {
  const bytes=await fs.readFile(path.join(sourceRoot,spec.source));
  const metadata=await sharp(bytes,{failOn:'error'}).metadata();
  if(metadata.format!=='png'||metadata.channels!==4||!metadata.hasAlpha||metadata.width<96||metadata.height<96||metadata.width>8192||metadata.height>8192) throw new Error(`Invalid RGBA PNG or unsupported dimensions: ${spec.source}`);
  if(metadata.space!=='srgb') throw new Error(`Source must already be sRGB: ${spec.source}`);
  const prompt=prompts.assets.find(a=>a.key===spec.id);
  if(!prompt)throw new Error(`Missing provenance for ${spec.id}`);
  const declared=prompt.sourceSHA256;
  if(!declared||declared!==hash(bytes)||prompt.master!==spec.source)throw new Error(`Source hash or path does not match provenance: ${spec.id}`);
  const raw=await sharp(bytes).ensureAlpha().raw().toBuffer();
  const nonzero=bounds(raw,metadata.width,metadata.height,1),signal=bounds(raw,metadata.width,metadata.height,2),body=bounds(raw,metadata.width,metadata.height,128);
  if(!signal.rect||!body.rect)throw new Error(`Empty source: ${spec.id}`);
  const [l,t,r,b]=signal.rect;
  const crop=[Math.max(0,l-2),Math.max(0,t-2),Math.min(metadata.width,r+2),Math.min(metadata.height,b+2)];
  let discarded=0,discardedAlphaMax=0;
  for(let y=0;y<metadata.height;y++)for(let x=0;x<metadata.width;x++)if(x<crop[0]||x>=crop[2]||y<crop[1]||y>=crop[3]){const a=raw[(y*metadata.width+x)*4+3];if(a){discarded++;discardedAlphaMax=Math.max(discardedAlphaMax,a);}}
  if(discardedAlphaMax>1)throw new Error(`Crop would remove visible signal: ${spec.id}`);
  preflight.push({spec,bytes,metadata,nonzero,signal,body,crop,discarded,discardedAlphaMax,prompt});
}
const manifest={version:1,title:'Observatory Instruments raster handoff',sourceCommit:prompts.sourceCommit,status:'Ready for specimen review; not native adoption or validation',recipe:{script:'build_rasters.mjs',sharp:sharp.versions.sharp,vips:sharp.versions.vips,kernel:'lanczos3',color:'sRGB RGBA8; embedded sRGB ICC',crop:'Alpha >= 2 bounds + two source pixels; only detached alpha=1 outside crop discarded; all pixels inside crop retain RGBA until ordinary resampling.',padding:'Symmetric proportional fit in declared point canvas; no anisotropic source resize.',densities},coordinateConvention:'Top-left origin; bounds [left, top, right, bottom), right and bottom exclusive; insets [top, leading, bottom, trailing].',assets:[],totals:{encodedBytes:0,decodedRGBABytes:0,byDensity:{}},validation:{allSourcesDecode:true,sourceHashesMatchProvenance:true,allExportsDecode:true,transparentOuterEdges:true,pearlContrastMinimum:4.5,nativeImport:'not run',nativeInteraction:'not run',nativePerformance:'not run',actualVoiceOver:'not run'}};
for(const item of preflight) {
  const {spec,bytes,metadata,nonzero,signal,body,crop,discarded,discardedAlphaMax}=item;
  const record={id:spec.id,purpose:spec.purpose,source:{path:spec.source,sha256:hash(bytes),width:metadata.width,height:metadata.height,channels:metadata.channels,colorSpace:metadata.space,encodedBytes:bytes.length,alphaNonzeroBounds:nonzero.rect,alphaAtLeast2Bounds:signal.rect,alphaAtLeast128Bounds:body.rect,cropBounds:crop,discardedOutsideCrop:{pixelCount:discarded,maximumAlpha:discardedAlphaMax},provenance:'PROMPTS.json#'+spec.id},pointCanvas:spec.points,intendedDisplayPoints:spec.display,anchor:{canvasCenter:spec.points.map(v=>v/2),note:'Geometric registration; optical balance still requires native specimen review.'},exports:[]};
  if(spec.caps){const [t,l,b,r]=spec.caps;record.slicing={axis:spec.axis,fixedCapsPoints:spec.caps,stretchRectPoints:[l,t,spec.points[0]-r,spec.points[1]-b],geometricMinimumPoints:spec.minimum,notes:spec.notes};}
  if(spec.content)record.contentInsetsPoints=spec.content;
  for(const density of densities) {
    const width=spec.points[0]*density,height=spec.points[1]*density,padding=spec.padding*density;
    const cw=crop[2]-crop[0],ch=crop[3]-crop[1],factor=Math.min((width-padding*2)/cw,(height-padding*2)/ch);
    const fitWidth=Math.round(cw*factor),fitHeight=Math.round(ch*factor);
    if(fitWidth<1||fitHeight<1)throw new Error('Invalid fitted export size');
    const left=Math.floor((width-fitWidth)/2),top=Math.floor((height-fitHeight)/2);
    const fitted=await sharp(bytes).extract({left:crop[0],top:crop[1],width:cw,height:ch}).resize({width:fitWidth,height:fitHeight,fit:'fill',kernel:'lanczos3'}).toBuffer();
    const png=await sharp({create:{width,height,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:fitted,left,top}]).withIccProfile('srgb').png({compressionLevel:9,adaptiveFiltering:false,palette:false}).toBuffer();
    const {data,info}=await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    if(info.width!==width||info.height!==height||info.channels!==4)throw new Error(`Bad exported dimensions: ${spec.id}`);
    const nz=bounds(data,width,height,1),bd=bounds(data,width,height,128),pad=outerPadding(nz.rect,width,height);
    if(Math.min(...pad)<density)throw new Error(`Insufficient transparent padding: ${spec.id}@${density}x`);
    const relative=`exports/${spec.family}/${spec.id}@${density}x.png`;
    const result={path:relative,scale:density,width,height,colorMode:'RGBA8',profile:'sRGB',sha256:hash(png),encodedBytes:png.length,decodedRGBABytes:width*height*4,fitRectPixels:[left,top,left+fitWidth,top+fitHeight],alphaNonzeroBounds:nz.rect,alphaAtLeast128Bounds:bd.rect,outerTransparentPaddingPixels:pad,alphaWeightedCentroidPixels:nz.centroid,maximumAspectRoundingError:round(Math.abs(fitWidth/fitHeight-cw/ch)/(cw/ch))};
    if(spec.caps){result.fixedCapsPixels=spec.caps.map(v=>v*density);result.stretchRectPixels=record.slicing.stretchRectPoints.map(v=>v*density);}
    if(spec.content){
      const[t,l,b,r]=spec.content;result.contentBoundsPixels=[l*density,t*density,width-r*density,height-b*density];
      const[st,sl,sb,sr]=spec.contrastSample||spec.content;
      result.pearlContrast=contrastRegion(data,width,height,[sl*density,st*density,width-sr*density,height-sb*density]);
      if(spec.contrastSample)result.pearlContrast.scope='Central quiet region, distinct from the 20-point glyph content envelope. Actual glyph-ink contrast is checked separately.';
    }
    if(spec.id==='utility-bezel'){
      result.glyphInkContrast={glyphCanvasPoints:20,placementInsetPoints:6,unframedGlyphAlternativePoints:24,samples:[]};
      for(const name of ['pause','settings','trace']){
        const glyphBytes=await fs.readFile(path.join(sourceRoot,'masters/glyphs',name+'.svg'));
        const glyph=await sharp(glyphBytes).resize(20*density,20*density).ensureAlpha().raw().toBuffer();
        const sample={glyph:name,minimumRatio:Infinity,alphaThreshold:128};
        for(let y=0;y<20*density;y++)for(let x=0;x<20*density;x++)if(glyph[(y*20*density+x)*4+3]>=128){
          const px=x+6*density,py=y+6*density,p=(py*width+px)*4,a=data[p+3]/255;
          for(const[name,bg]of Object.entries(backgrounds)){
            const rgb=[0,1,2].map(k=>data[p+k]*a+bg[k]*(1-a)),ratio=contrast(pearl,rgb);
            if(ratio<sample.minimumRatio){sample.minimumRatio=ratio;sample.worst={backdrop:name,pixel:[px,py],compositedRGB:rgb.map(round)};}
          }
        }
        sample.minimumRatio=round(sample.minimumRatio);
        if(sample.minimumRatio<4.5)throw new Error(`Glyph ink contrast failed: ${name}`);
        result.glyphInkContrast.samples.push(sample);
      }
    }
    await fs.mkdir(path.dirname(path.join(outputRoot,relative)),{recursive:true});
    await fs.writeFile(path.join(outputRoot,relative),png);
    record.exports.push(result);
    manifest.totals.encodedBytes+=png.length;manifest.totals.decodedRGBABytes+=result.decodedRGBABytes;
    const total=manifest.totals.byDensity[density] ||= {encodedBytes:0,decodedRGBABytes:0};total.encodedBytes+=png.length;total.decodedRGBABytes+=result.decodedRGBABytes;
  }
  manifest.assets.push(record);
}
await fs.mkdir(outputRoot,{recursive:true});
await fs.writeFile(path.join(outputRoot,'raster-manifest.json'),JSON.stringify(manifest,null,2)+'\n');
if(densities.includes(3)) {
  const layers=[];
  const escaped=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
  const text=(s,x,y,size=18,color='#f4ecd9',serif=false)=>layers.push({input:Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1320" height="${size+14}"><text x="0" y="${size}" font-family="${serif?'Georgia':'Arial'}" font-size="${size}" fill="${color}">${escaped(s)}</text></svg>`),left:x,top:y});
  async function slice(id,width,height){
    const spec=specs.find(s=>s.id===id),source=path.join(outputRoot,`exports/${spec.family}/${id}@3x.png`);
    const meta=await sharp(source).metadata(),caps=spec.caps.map(v=>v*3);
    const [top,left,bottom,right]=caps;
    const sx=[0,left,meta.width-right,meta.width],sy=[0,top,meta.height-bottom,meta.height];
    const uniform=id==='button-action'?height/64:1;
    const dx=[0,Math.round(left/3*uniform),width-Math.round(right/3*uniform),width],dy=id==='button-action'?[0,0,height,height]:[0,top/3,height-bottom/3,height];
    if(dx[2]<=dx[1]||dy[2]<=dy[1])throw new Error('Stretch specimen below cap minimum');
    const parts=[];
    for(let y=0;y<3;y++)for(let x=0;x<3;x++){
      const sw=sx[x+1]-sx[x],sh=sy[y+1]-sy[y],dw=dx[x+1]-dx[x],dh=dy[y+1]-dy[y];
      if(!sw||!sh||!dw||!dh)continue;
      const image=await sharp(source).extract({left:sx[x],top:sy[y],width:sw,height:sh}).resize(dw,dh,{fit:'fill',kernel:'lanczos3'}).toBuffer();
      parts.push({input:image,left:dx[x],top:dy[y]});
    }
    return sharp({create:{width,height,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(parts).png().toBuffer();
  }
  text('OBSERVATORY INSTRUMENTS',40,24,30,'#f4ecd9',true);
  text('Actual exports / mechanical stretch specimen / CSS-pixel reference sizes / not native acceptance',40,68,17,'#b5c0d2');
  const actionSamples=[[120,64],[160,64],[240,64],[320,64],[120,52]];
  text('Action: full-height fixed ends; horizontal center only',40,112,20);
  let y=151;
  for(const [w,h]of actionSamples){layers.push({input:await slice('button-action',w,h),left:40,top:y});text(`${w} × ${h}`,385,y+14,17,'#b5c0d2');y+=h+17;}
  text('Three mode emblems · 40 / 48 px',610,112,20);
  let x=620;
  for(const id of ['emblem-story','emblem-freeplay','emblem-tutorial']){
    for(const size of [40,48]){layers.push({input:await sharp(path.join(outputRoot,`exports/emblems/${id}@3x.png`)).resize(size,size).toBuffer(),left:x,top:165});x+=size+18;}
    x+=32;
  }
  text('Utility bezel · 32 px + 20 px glyph',610,244,20);
  x=620;
  for(const name of ['pause','settings','trace']){
    layers.push({input:await sharp(path.join(outputRoot,'exports/skins/utility-bezel@3x.png')).resize(32,32).toBuffer(),left:x,top:291});
    const glyph=(await fs.readFile(path.join(sourceRoot,`masters/glyphs/${name}.svg`),'utf8')).replaceAll('currentColor','#f4ecd9');
    layers.push({input:await sharp(Buffer.from(glyph)).resize(20,20).png().toBuffer(),left:x+6,top:297});text(name,x-2,334,14,'#b5c0d2');x+=105;
  }
  text('Pearl labels are separate text',610,391,20);
  layers.push({input:await slice('button-action',320,64),left:610,top:433});
  text('Story Mode',710,449,24,'#f4ecd9',true);
  text('Panel skins keep fixed corners as text grows',40,586,20);
  for(const [w,h,left,top]of [[160,160,40,630],[320,240,232,630],[480,400,584,630]])layers.push({input:await slice('panel-reading',w,h),left,top});
  text('18 / 18',78,680,22);text('Settings',274,673,25,'#f4ecd9',true);text('Sound                 On',274,723,18);text('Haptics                Off',274,764,18);
  text('A longer action can wrap',626,673,25,'#f4ecd9',true);text('inside a reading surface.',626,708,25,'#f4ecd9',true);text('The action end ornaments stay',626,776,18);text('at their original proportions.',626,806,18);text('1,024',626,870,24);
  text('Bright backdrop / transparent edges',40,1064,20);
  layers.push({input:await sharp({create:{width:1270,height:130,channels:4,background:'#ede5c9'}}).png().toBuffer(),left:40,top:1104});
  layers.push({input:await slice('button-action',320,64),left:60,top:1137});
  text('Begin',190,1154,24,'#f4ecd9',true);
  x=455;
  for(const id of ['emblem-story','emblem-freeplay','emblem-tutorial']){layers.push({input:await sharp(path.join(outputRoot,`exports/emblems/${id}@3x.png`)).resize(48,48).toBuffer(),left:x,top:1146});x+=100;}
  text('No recoloring or matte removal. Original sources remain unchanged.',40,1263,17,'#b5c0d2');
  const preview=await sharp({create:{width:1400,height:1320,channels:4,background:'#091326'}}).composite(layers).withIccProfile('srgb').png({compressionLevel:9,adaptiveFiltering:false}).toBuffer();
  await fs.mkdir(path.join(outputRoot,'previews'),{recursive:true});
  await fs.writeFile(path.join(outputRoot,'previews/rasters.png'),preview);
}
console.log(JSON.stringify({assets:manifest.assets.length,exports:manifest.assets.reduce((n,a)=>n+a.exports.length,0),totals:manifest.totals,validation:manifest.validation},null,2));
