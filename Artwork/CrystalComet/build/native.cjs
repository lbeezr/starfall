// Derive the shipping profile from the validated full-resolution sprite pack.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),pack=path.join(root,'pack'),assets=path.resolve(root,'../../App/Assets.xcassets');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
async function main(){
 const font=JSON.parse(fs.readFileSync(path.join(pack,'font.json'))),manifest=JSON.parse(fs.readFileSync(path.join(pack,'manifest.json')));
 for(const f of manifest.files)assert.equal(hash(fs.readFileSync(path.join(pack,f.path))),f.sha256,f.path);
 const profile={version:1,capHeight:160,lineHeight:230,rasterScale:.6,glyphs:font.glyphs,views:[]},outputs={};let decodedBytes=0,pngBytes=0;
 for(const view of font.views.filter(v=>v.pitch===0)){
  const source=path.join(pack,view.image),frames=JSON.parse(fs.readFileSync(path.join(pack,view.metadata))).frames,sprites=[];
  for(const [id,frame]of Object.entries(frames)){
   const r=frame.rect,w=Math.ceil(r.w*.6),h=Math.ceil(r.h*.6);
   const data=await sharp(source).extract({left:r.x,top:r.y,width:r.w,height:r.h}).resize(w,h,{fit:'fill'}).extend({top:2,bottom:2,left:2,right:2,background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
   sprites.push({id,frame,data,w:w+4,h:h+4,logicalWidth:r.w*(w+4)/w,logicalHeight:r.h*(h+4)/h,offsetX:frame.originOffset.x-2*r.w/w,offsetY:frame.originOffset.y-2*r.h/h});
  }
  sprites.sort((a,b)=>b.h-a.h||a.id.localeCompare(b.id));let x=2,y=2,row=0;
  for(const s of sprites){if(x+s.w+2>1024){x=2;y+=row+2;row=0;}s.x=x;s.y=y;x+=s.w+2;row=Math.max(row,s.h);}
  const height=Math.ceil((y+row+2)/64)*64;assert.ok(height<=1024);
  const name='CrystalDepth'+(view.yaw<0?'M':view.yaw>0?'P':'Z')+String(Math.abs(view.yaw)).padStart(2,'0'),folder=path.join(assets,name+'.imageset');fs.mkdirSync(folder,{recursive:true});
  const png=await sharp({create:{width:1024,height,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(sprites.map(s=>({input:s.data,left:s.x,top:s.y}))).png({compressionLevel:9}).toBuffer();
  fs.writeFileSync(path.join(folder,'atlas.png'),png);write(path.join(folder,'Contents.json'),{images:[{filename:'atlas.png',idiom:'universal'}],info:{author:'xcode',version:1}});
  profile.views.push({yaw:view.yaw,asset:name,width:1024,height,frames:Object.fromEntries(sprites.map(s=>[s.id,{x:s.x,y:s.y,w:s.w,h:s.h,width:s.logicalWidth,height:s.logicalHeight,offsetX:s.offsetX,offsetY:s.offsetY}]))});
  outputs[path.relative(assets,path.join(folder,'atlas.png'))]=hash(png);decodedBytes+=1024*height*4;pngBytes+=png.length;
 }
 assert.equal(profile.views.length,15);assert.ok(decodedBytes<=64*1024*1024);
 const folder=path.join(assets,'CrystalDepthMetrics.dataset');fs.mkdirSync(folder,{recursive:true});write(path.join(folder,'font.json'),profile);write(path.join(folder,'Contents.json'),{data:[{filename:'font.json',idiom:'universal'}],info:{author:'xcode',version:1}});outputs['CrystalDepthMetrics.dataset/font.json']=hash(fs.readFileSync(path.join(folder,'font.json')));
 write(path.join(root,'native-profile.json'),{sourceManifestSHA256:hash(fs.readFileSync(path.join(pack,'manifest.json'))),generatorSHA256:hash(fs.readFileSync(__filename)),characters:106,visibleGlyphs:105,views:15,rasterCapHeight:96,decodedAtlasBytes:decodedBytes,pngBytes,outputs});
 console.log(JSON.stringify({views:15,decodedAtlasBytes:decodedBytes,pngBytes},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
