const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {createCanvas,loadImage}=require('@napi-rs/canvas');
const root=path.resolve(__dirname,'..'),pack=path.join(root,'pack');
async function main(){
 const font=JSON.parse(fs.readFileSync(path.join(pack,'font.json')));
 fs.mkdirSync(path.join(pack,'previews/views'),{recursive:true});
 for(const v of font.views){
  v.preview=`previews/views/${v.id}.webp`;
  await sharp(path.join(pack,v.image)).resize({width:v.width/2,height:v.height/2}).webp({quality:88,alphaQuality:100,effort:5}).toFile(path.join(pack,v.preview));
  v.frames=JSON.parse(fs.readFileSync(path.join(pack,v.metadata))).frames;
 }
 const template=fs.readFileSync(path.join(__dirname,'preview.template.html'),'utf8');
 fs.writeFileSync(path.join(pack,'preview.html'),template.replace('__MODEL__',JSON.stringify(font)));
 const plane=font.views.filter(v=>v.pitch===0),images=new Map();
 for(const v of plane)images.set(v.id,await loadImage(path.join(pack,v.preview)));
 const width=900,height=360,totalFrames=44,canvas=createCanvas(width,height),ctx=canvas.getContext('2d'),frames=[];
 const key=c=>'u'+c.codePointAt(0).toString(16).padStart(4,'0');
 function row(text,baseline,scale,view){
  const sum=[...text].reduce((n,c)=>n+(font.glyphs[key(c)]?.advance||64),0);let x=(width-sum*scale)/2;
  for(const c of text){const g=font.glyphs[key(c)],f=view.frames[key(c)];if(f){const r=f.rect;ctx.drawImage(images.get(view.id),r.x*.5,r.y*.5,r.w*.5,r.h*.5,x+f.originOffset.x*scale,baseline+f.originOffset.y*scale,r.w*scale,r.h*scale);}x+=(g?.advance||64)*scale;}
 }
 for(let i=0;i<totalFrames;i++){
  const yaw=i<36?Math.round(35*Math.sin(i/35*Math.PI*2)/5)*5:0,view=plane.find(v=>v.yaw===yaw);
  ctx.fillStyle='#10132b';ctx.fillRect(0,0,width,height);ctx.fillStyle='#bfb6d5';ctx.font='17px sans-serif';ctx.fillText('CRYSTAL COMET · PACKED SPRITES',28,34);
  row('Starfall!',164,.58,view);row('+128  Az  gjpq  ?!',273,.32,view);ctx.fillStyle='#bfb6d5';ctx.font='14px sans-serif';ctx.fillText('Angle-frame preview · not native gameplay',28,337);
  frames.push(Buffer.from(ctx.getImageData(0,0,width,height).data));
 }
 await sharp(Buffer.concat(frames),{raw:{width,height:height*totalFrames,channels:4,pageHeight:height}}).webp({quality:88,loop:0,delay:Array(totalFrames).fill(70),effort:5}).toFile(path.join(pack,'previews/motion.webp'));
 console.log('Offline preview written with all 45 angle views.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
