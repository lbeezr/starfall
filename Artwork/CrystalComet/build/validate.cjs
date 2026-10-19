const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto'),sharp=require('sharp');
const {target}=require('./register.cjs');
const root=path.resolve(__dirname,'..'),pack=path.join(root,'pack');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const walk=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
function components(data,width,height){
 const seen=new Uint8Array(width*height);let count=0;
 for(let i=0;i<seen.length;i++)if(!seen[i]&&data[i*4+3]>=128){const q=[i];seen[i]=1;for(let n=0;n<q.length;n++){const p=q[n],x=p%width,y=Math.floor(p/width);for(const j of [x>0?p-1:-1,x<width-1?p+1:-1,y>0?p-width:-1,y<height-1?p+width:-1])if(j>=0&&!seen[j]&&data[j*4+3]>=128){seen[j]=1;q.push(j);}}if(q.length>=4)count++;}
 return count;
}
async function main(){
 const font=JSON.parse(fs.readFileSync(path.join(pack,'font.json'))),visible=Object.values(font.glyphs).filter(g=>g.visible),checks=[];
 assert.equal(Object.keys(font.glyphs).length,106);assert.equal(visible.length,105);assert.deepEqual(new Set(visible.map(g=>g.character)),new Set(target));assert.equal(font.glyphs.u0020.advance,64);assert.equal(font.glyphs.u0020.visible,false);
 assert.equal(font.views.length,45);assert.equal(new Set(font.views.map(v=>`${v.yaw}/${v.pitch}`)).size,45);checks.push('All 106 characters, 105 visible glyphs and 45 unique angle pairs present.');
 let total=0,maximumTextureEdge=0,atlasBytes=0;const componentResults={};
 for(const view of font.views){
  const filename=path.join(pack,view.image),{data,info}=await sharp(filename).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  assert.equal(info.width,view.width);assert.equal(info.height,view.height);assert.ok(info.width<=2048&&info.height<=2048);atlasBytes+=fs.statSync(filename).size;maximumTextureEdge=Math.max(maximumTextureEdge,info.width,info.height);
  const metadata=JSON.parse(fs.readFileSync(path.join(pack,view.metadata))),frames=metadata.frames;assert.equal(metadata.view,view.id);assert.equal(Object.keys(frames).length,105);
  const entries=Object.entries(frames);
  for(const [id,f]of entries){
   const g=font.glyphs[id];assert.ok(g?.visible);const r=f.rect;assert.ok(r.x>=2&&r.y>=2&&r.x+r.w<=info.width-2&&r.y+r.h<=info.height-2);
   assert.ok(Math.abs(f.pivot.x+f.originOffset.x-g.pivot.x)<.002);assert.ok(Math.abs(f.pivot.y+f.originOffset.y-g.pivot.y)<.002);
   let nonempty=0;
   for(let y=0;y<r.h;y++)for(let x=0;x<r.w;x++){const alpha=data[((y+r.y)*info.width+x+r.x)*4+3];if(alpha)nonempty++;if(x<2||y<2||x>=r.w-2||y>=r.h-2)assert.equal(alpha,0,`Nontransparent frame margin ${view.id} ${id}`);}
   assert.ok(nonempty>=16,`Empty frame ${view.id}/${id}`);total++;
   if(view.yaw===0&&view.pitch===0&&'!?÷%:;i j"“”…'.includes(g.character)){
    const crop=await sharp(filename).extract({left:r.x,top:r.y,width:r.w,height:r.h}).raw().toBuffer();componentResults[g.character]=components(crop,r.w,r.h);
   }
  }
  for(let i=0;i<entries.length;i++)for(let j=i+1;j<entries.length;j++){const a=entries[i][1].rect,b=entries[j][1].rect;assert.ok(a.x+a.w<=b.x||b.x+b.w<=a.x||a.y+a.h<=b.y||b.y+b.h<=a.y,'Atlas frame overlap');}
 }
 assert.equal(total,4725);checks.push('All 4,725 sprites nonempty, inside bounded textures, non-overlapping and surrounded by two transparent pixels.');checks.push('Every frame resolves to the same glyph baseline/pivot and invariant advance at all angles.');
 for(const [c,count]of Object.entries({'!':2,'?':2,'÷':3,'%':3,':':2,';':2,i:2,j:2,'"':2,'“':2,'”':2,'…':3}))assert.equal(componentResults[c],count,`Disconnected components for ${c}`);
 checks.push('Front-view detached components verified for punctuation, quotes, percent, i and j, including the repaired question and division glyphs.');
 const motion=await sharp(path.join(pack,'previews/motion.webp'),{animated:true}).metadata();assert.ok(motion.pages>=15&&motion.pages<=44);assert.equal(motion.pageHeight,360);assert.equal(motion.width,900);assert.equal(motion.delay.reduce((a,b)=>a+b,0),3080);checks.push('Animated preview preserves the 3.08-second exported-sprite sequence; WebP coalesces identical consecutive angle frames.');
 const source=JSON.parse(fs.readFileSync(path.join(root,'sources/registration.json')));for(const [file,sha]of Object.entries(source.sourceHashes))assert.equal(hash(fs.readFileSync(path.resolve(root,file))),sha);checks.push('All registered source artwork hashes match.');
 const report={status:'Asset checks passed; native integration not run',characters:106,visibleGlyphs:105,angleViews:45,sprites:total,maximumTextureEdge,atlasBytes,frontComponentCounts:componentResults,checks,limits:['Painted front facets, geometric edges; no physical refraction.','No native app/device import or performance acceptance.','Review artistic legibility separately from structural validation.']};
 fs.writeFileSync(path.join(pack,'validation.json'),JSON.stringify(report,null,2)+'\n');
 const files=walk(pack).filter(f=>path.basename(f)!=='manifest.json').sort().map(file=>({path:path.relative(pack,file).split(path.sep).join('/'),bytes:fs.statSync(file).size,sha256:hash(fs.readFileSync(file))}));
 const manifest={schema:'starfall.asset-package.v1',name:'crystal-comet-sprites',version:'1.0.0',files};fs.writeFileSync(path.join(pack,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 for(const file of manifest.files)assert.equal(hash(fs.readFileSync(path.join(pack,file.path))),file.sha256);
 assert.deepEqual(walk(pack).map(f=>path.relative(pack,f).split(path.sep).join('/')).sort(),[...manifest.files.map(f=>f.path),'manifest.json'].sort());
 console.log(JSON.stringify({...report,packageFiles:files.length,packageBytes:files.reduce((n,f)=>n+f.bytes,0)},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
