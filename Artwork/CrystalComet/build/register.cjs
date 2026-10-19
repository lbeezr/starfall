const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const target = [...Array.from({length:94},(_,i)=>String.fromCharCode(i+33)), ...'–—‘’“”…×÷−•'];

function simplify(points,tolerance) {
  if(points.length<3)return points;
  const a=points[0],b=points.at(-1),dx=b[0]-a[0],dy=b[1]-a[1];let max=0,index=0;
  for(let i=1;i<points.length-1;i++) {
    const p=points[i],t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1)));
    const d=Math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy);if(d>max){max=d;index=i;}
  }
  return max>tolerance?[...simplify(points.slice(0,index+1),tolerance).slice(0,-1),...simplify(points.slice(index),tolerance)]:[a,b];
}

function contoursFor(ids,labels,imageWidth,rect) {
  const [left,top,width,height]=rect,step=2,w=Math.ceil(width/step),h=Math.ceil(height/step);
  const mask=new Uint8Array(w*h);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)mask[y*w+x]=ids.has(labels[(top+y*step+1)*imageWidth+left+x*step+1])?1:0;
  const edges=new Map(),inside=(x,y)=>x>=0&&y>=0&&x<w&&y<h&&mask[y*w+x];
  const add=(a,b)=>{const k=a.join(',');if(!edges.has(k))edges.set(k,[]);edges.get(k).push(b);};
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(inside(x,y)){
    if(!inside(x,y-1))add([x,y],[x+1,y]);if(!inside(x+1,y))add([x+1,y],[x+1,y+1]);
    if(!inside(x,y+1))add([x+1,y+1],[x,y+1]);if(!inside(x-1,y))add([x,y+1],[x,y]);
  }
  const loops=[];
  while(edges.size){
    const start=edges.keys().next().value,loop=[start.split(',').map(Number)];let key=start,closed=false;
    for(let count=0;count<100000;count++){
      const choices=edges.get(key);if(!choices)break;const next=choices.pop();if(!choices.length)edges.delete(key);
      loop.push(next);key=next.join(',');if(key===start){closed=true;break;}
    }
    if(!closed)throw Error('Unclosed contour in source registration');
    if(loop.length>10){const half=Math.floor(loop.length/2);const points=[...simplify(loop.slice(0,half+1),.8).slice(0,-1),...simplify(loop.slice(half),.8).slice(0,-1)];loops.push(points.map(([x,y])=>[x*step,y*step]));}
  }
  return loops;
}

async function registerSheet(sheet) {
  const filename=path.join(root,'sources',sheet.file),{data,info}=await sharp(filename).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  if(info.channels!==4)throw Error('Expected RGBA source');
  const w=info.width,h=info.height,labels=new Int32Array(w*h),parts=[];
  for(let p=0;p<labels.length;p++){
    if(labels[p]||data[p*4+3]<128)continue;
    const id=parts.length+1,queue=[p];labels[p]=id;
    let x0=w,y0=h,x1=0,y1=0,sumX=0,sumY=0;
    for(let i=0;i<queue.length;i++){
      const k=queue[i],x=k%w,y=Math.floor(k/w);x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);sumX+=x;sumY+=y;
      for(const n of [x>0?k-1:-1,x<w-1?k+1:-1,y>0?k-w:-1,y<h-1?k+w:-1])if(n>=0&&!labels[n]&&data[n*4+3]>=128){labels[n]=id;queue.push(n);}
    }
    parts.push({id,area:queue.length,x0,y0,x1,y1,cx:sumX/queue.length,cy:sumY/queue.length});
  }
  return [...sheet.chars].map((character,index)=>{
    const candidates=parts.filter(p=>Math.min(sheet.columns-1,Math.floor(p.cx/w*sheet.columns))===index%sheet.columns&&Math.min(sheet.rows-1,Math.floor(p.cy/h*sheet.rows))===Math.floor(index/sheet.columns));
    const maximum=Math.max(...candidates.map(p=>p.area));
    const selected=candidates.filter(p=>p.area>=Math.max(120,maximum*.012));
    if(!selected.length||maximum<1000)throw Error(`Empty or undersized ${sheet.id} ${character}`);
    const left=Math.max(0,Math.min(...selected.map(p=>p.x0))-3),top=Math.max(0,Math.min(...selected.map(p=>p.y0))-3);
    const right=Math.min(w,Math.max(...selected.map(p=>p.x1))+4),bottom=Math.min(h,Math.max(...selected.map(p=>p.y1))+4),rect=[left,top,right-left,bottom-top];
    const contours=contoursFor(new Set(selected.map(p=>p.id)),labels,w,rect);
    return {character,source:`sources/${sheet.file}`,rect,contours,componentCount:selected.length};
  });
}

function metrics(g) {
  const c=g.character;let height=160,bottom=0,targetWidth=null;
  if(/[a-z]/.test(c)){
    if('gpqy'.includes(c)){height=158;bottom=40;}
    else if(c==='j'){height=200;bottom=40;}
    else if(c==='t')height=142;
    else if(!'bdfhik l'.replaceAll(' ','').includes(c))height=118;
  }
  if('.•'.includes(c)){height=c==='.'?20:26;bottom=c==='.'?0:-65;}
  if(c===','){height=44;bottom=18;}
  if(c===':'){height=93;bottom=-8;}
  if(c===';'){height=119;bottom=18;}
  if('"\'‘’“”`'.includes(c)){height=56;bottom=-104;}
  if(c==='*'){height=76;bottom=-72;}
  if('()[]{}'.includes(c)){height=190;bottom=20;}
  if(c==='|'){height=180;bottom=10;}
  if(c==='^'){height=52;bottom=-108;}
  if(c==='~'){targetWidth=106;bottom=-58;}
  if(c==='-'){targetWidth=76;bottom=-62;}
  if(c==='–'){targetWidth=104;bottom=-62;}
  if(c==='—'){targetWidth=160;bottom=-62;}
  if(c==='−'){targetWidth=116;bottom=-62;}
  if(c==='_'){targetWidth=112;bottom=20;}
  if(c==='='){targetWidth=116;bottom=-42;}
  if(c==='+'){height=116;bottom=-22;}
  if(c==='×'){height=95;bottom=-32;}
  if(c==='÷'){targetWidth=116;bottom=-28;}
  if(c==='…'){targetWidth=96;bottom=0;}
  let width=height*g.rect[2]/g.rect[3];if(targetWidth!==null){width=targetWidth;height=width*g.rect[3]/g.rect[2];}
  const advance=Math.ceil(width+14);
  return {width:+width.toFixed(3),height:+height.toFixed(3),bottom:+bottom.toFixed(3),advance,...(/[0-9]/.test(c)?{tabularAdvance:174}:{}),bearingX:+((advance-width)/2).toFixed(3),pivot:{x:advance/2,y:+(bottom-height/2).toFixed(3)}};
}

async function main(){
  const generated=JSON.parse(fs.readFileSync(path.join(root,'sources/generation.json'),'utf8'));
  const originalPath=path.resolve(root,'../../docs/design/celebration-lettering/motion-specimen-01/registration.json');
  const original=JSON.parse(fs.readFileSync(originalPath,'utf8'));
  const byCharacter=new Map(original.glyphs.map(g=>[g.character,{...g,source:'../../docs/design/celebration-lettering/motion-specimen-01/glyph-master.png',componentCount:g.character==='!'?2:1}]));
  for(const sheet of generated.sheets){const glyphs=await registerSheet(sheet);for(const g of glyphs)if(sheet.replace||!byCharacter.has(g.character))byCharacter.set(g.character,g);}
  const glyphs=target.map(c=>{const g=byCharacter.get(c);if(!g)throw Error(`Missing ${c}`);return {...g,id:`u${c.codePointAt(0).toString(16).padStart(4,'0')}`,metrics:metrics(g)};});
  if(new Set(glyphs.map(g=>g.character)).size!==105)throw Error('Coverage mismatch');
  const sources=Object.fromEntries([...new Set(glyphs.map(g=>g.source))].map(file=>[file,hash(fs.readFileSync(path.resolve(root,file)))]));
  const result={schema:'starfall.crystal-comet.source.v1',sourceHashes:sources,capHeight:160,xHeight:118,descender:40,lineHeight:230,glyphs};
  fs.writeFileSync(path.join(root,'sources/registration.json'),JSON.stringify(result));
  console.log(JSON.stringify({glyphCount:glyphs.length,components:glyphs.map(g=>[g.character,g.componentCount,g.contours.length]),sourceHashes:sources},null,2));
}
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1;});
module.exports={target,metrics,registerSheet};
