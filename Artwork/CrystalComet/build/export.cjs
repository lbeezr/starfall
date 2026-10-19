const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const sharp=require('sharp');
const {createCanvas,loadImage}=require('@napi-rs/canvas');
const {prepareGlyph,drawGlyph,alphaBounds}=require('./render.cjs');
const root=path.resolve(__dirname,'..'),out=path.join(root,'pack');
const registration=JSON.parse(fs.readFileSync(path.join(root,'sources/registration.json'),'utf8'));
const code=c=>`u${c.codePointAt(0).toString(16).padStart(4,'0')}`;
const degree=v=>(v<0?'m':v>0?'p':'z')+String(Math.abs(v)).padStart(2,'0');
const viewID=(yaw,pitch)=>`yaw-${degree(yaw)}_pitch-${degree(pitch)}`;
const writeJSON=(name,value)=>fs.writeFileSync(path.join(out,name),JSON.stringify(value)+'\n');
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
async function savePNG(canvas,file){await sharp(canvas.toBuffer('image/png')).png({compressionLevel:9,adaptiveFiltering:true}).toFile(file);}

async function main(){
  for(const dir of ['','atlases','frames','previews'])fs.mkdirSync(path.join(out,dir),{recursive:true});
  const imageCache=new Map();
  for(const source of Object.keys(registration.sourceHashes))imageCache.set(source,await loadImage(path.resolve(root,source)));
  const glyphs=registration.glyphs.map(g=>prepareGlyph(g,imageCache.get(g.source)));
  const scratch=createCanvas(512,512),scratchContext=scratch.getContext('2d');
  const font={schema:'starfall.crystal-comet.sprites.v1',name:'Crystal Comet',version:'1.0.0',units:'source pixels; positive y points down',capHeight:160,xHeight:118,descender:40,lineHeight:230,spaceAdvance:64,projection:'orthographic',alpha:'straight',colorSpace:'sRGB',filtering:'linear; no mipmaps',transparentFrameMargin:2,atlasSeparation:2,angles:{yaw:Array.from({length:15},(_,i)=>i*5-35),pitch:[-12,0,12]},glyphs:{u0020:{character:' ',advance:64,pivot:{x:32,y:-80},visible:false}},views:[]};
  for(const g of glyphs)font.glyphs[g.id]={character:g.character,visible:true,...g.metrics};
  let total=0;const allViews=new Map();
  for(const pitch of font.angles.pitch)for(const yaw of font.angles.yaw){
    const id=viewID(yaw,pitch),sprites=[];
    for(const g of glyphs){
      scratchContext.clearRect(0,0,512,512);drawGlyph(scratchContext,g,256,256,yaw,pitch);
      const b=alphaBounds(scratch);if(!b||b.x<8||b.y<8||b.x+b.w>504||b.y+b.h>504)throw Error(`Clipped/empty ${g.character} ${id}`);
      const crop={x:b.x-2,y:b.y-2,w:b.w+4,h:b.h+4},canvas=createCanvas(crop.w,crop.h);
      canvas.getContext('2d').drawImage(scratch,crop.x,crop.y,crop.w,crop.h,0,0,crop.w,crop.h);
      sprites.push({g,crop,canvas});
    }
    // Stable height-first shelves; each view is a bounded, independently loadable atlas.
    sprites.sort((a,b)=>b.crop.h-a.crop.h||a.g.id.localeCompare(b.g.id));
    let x=2,y=2,shelfHeight=0;
    const atlasWidth=1536;
    for(const s of sprites){if(x+s.crop.w+2>atlasWidth){x=2;y+=shelfHeight+2;shelfHeight=0;}s.x=x;s.y=y;x+=s.crop.w+2;shelfHeight=Math.max(shelfHeight,s.crop.h);}
    const height=Math.ceil((y+shelfHeight+2)/64)*64;if(height>2048)throw Error('Atlas exceeds policy');
    const atlas=createCanvas(atlasWidth,height),ctx=atlas.getContext('2d'),frames={};
    for(const s of sprites){
      ctx.drawImage(s.canvas,s.x,s.y);
      const m=s.g.metrics,baselineY=256+m.height/2-m.bottom;
      frames[s.g.id]={rect:{x:s.x,y:s.y,w:s.crop.w,h:s.crop.h},originOffset:{x:+(s.crop.x-(256-m.advance/2)).toFixed(3),y:+(s.crop.y-baselineY).toFixed(3)},pivot:{x:256-s.crop.x,y:256-s.crop.y}};
    }
    const view={id,yaw,pitch,image:`atlases/${id}.png`,metadata:`frames/${id}.json`,width:atlasWidth,height};
    await savePNG(atlas,path.join(out,view.image));writeJSON(view.metadata,{schema:'starfall.crystal-comet.frames.v1',view:id,frames});
    font.views.push(view);allViews.set(id,{...view,frames,atlas});total+=sprites.length;
    console.log(`${id}: ${sprites.length} sprites, ${atlasWidth}×${height}`);
  }
  writeJSON('font.json',font);
  const front=allViews.get(viewID(0,0));
  function packedGlyph(ctx,character,x,baseline,scale,view=front){
    const key=code(character),g=font.glyphs[key],f=view.frames[key];if(!g)return 0;
    if(f){const r=f.rect;ctx.drawImage(view.atlas,r.x,r.y,r.w,r.h,x+f.originOffset.x*scale,baseline+f.originOffset.y*scale,r.w*scale,r.h*scale);}return g.advance*scale;
  }
  function packedText(ctx,text,x,baseline,scale,view=front){for(const c of text)x+=packedGlyph(ctx,c,x,baseline,scale,view);}
  // Human-readable labels are outside the generated artwork and never become glyph pixels.
  const contact=createCanvas(1440,1600),cc=contact.getContext('2d');cc.fillStyle='#0d1128';cc.fillRect(0,0,contact.width,contact.height);
  cc.fillStyle='#edeafa';cc.font='500 30px sans-serif';cc.fillText('CRYSTAL COMET · CHARACTER SET',40,54);
  cc.font='18px sans-serif';cc.fillStyle='#bdb4d8';cc.fillText('Uppercase · lowercase · numerals · punctuation   /   Front view',40,86);
  const sections=[['UPPERCASE','ABCDEFGHIJKLMNOPQRSTUVWXYZ'],['LOWERCASE','abcdefghijklmnopqrstuvwxyz'],['NUMERALS','0123456789'],['PUNCTUATION',registration.glyphs.filter(g=>!/[A-Za-z0-9]/.test(g.character)).map(g=>g.character).join('')]];
  let yy=132;
  for(const [title,chars]of sections){
    cc.fillStyle='#c6bfdf';cc.font='16px sans-serif';cc.fillText(title,40,yy);yy+=18;
    for(let start=0;start<chars.length;start+=13){
      const row=[...chars].slice(start,start+13);
      row.forEach((c,i)=>{const g=font.glyphs[code(c)],cellX=40+i*105,scale=Math.min(.46,92/g.advance);packedGlyph(cc,c,cellX+(95-g.advance*scale)/2,yy+94,scale);cc.fillStyle='#bdb4d8';cc.font='14px sans-serif';cc.fillText(c==='−'?'minus':c,cellX+(c==='−'?25:44),yy+125);});
      yy+=142;
    }
    yy+=15;
  }
  // Crop unused bottom space; the capture is an asset contact sheet, not app evidence.
  const trimmedContact=createCanvas(1440,yy+25);trimmedContact.getContext('2d').drawImage(contact,0,0);await savePNG(trimmedContact,path.join(out,'previews/character-set.png'));
  const angles=createCanvas(1440,990),ac=angles.getContext('2d');ac.fillStyle='#0d1128';ac.fillRect(0,0,1440,990);ac.fillStyle='#edeafa';ac.font='500 28px sans-serif';ac.fillText('CRYSTAL COMET · REGISTERED ANGLE VIEWS',40,52);
  const cases=[[-35,-12],[0,-12],[35,-12],[-35,0],[0,0],[35,0],[-35,12],[0,12],[35,12]];
  for(let i=0;i<cases.length;i++){
    const [yaw,pitch]=cases[i],v=allViews.get(viewID(yaw,pitch)),left=35+(i%3)*475,top=100+Math.floor(i/3)*290;
    ac.fillStyle='#bdb4d8';ac.font='18px sans-serif';ac.fillText(`Turn ${yaw}° · Tilt ${pitch}°`,left,top);
    packedText(ac,'Relay!',left,top+117,.49,v);packedText(ac,'+128 g? ÷',left,top+215,.34,v);
  }
  await savePNG(angles,path.join(out,'previews/angle-views.png'));
  const provenance={generator:'built-in image_gen.imagegen',generation:JSON.parse(fs.readFileSync(path.join(root,'sources/generation.json'))),sourceHashes:registration.sourceHashes,projection:'Same front texture and contour-derived shallow sides for every angle; no independent angle image generation.',sourceGeometrySHA256:hash(fs.readFileSync(path.join(root,'sources/registration.json'))),rendererSHA256:hash(fs.readFileSync(path.join(__dirname,'render.cjs'))),limitations:['Painted front facets; no physical refraction.','English keyboard plus listed typographic symbols; no accented alphabet or universal Unicode coverage.','No native app import, device performance or actual VoiceOver validation.']};
  writeJSON('provenance.json',provenance);
  writeJSON('export-summary.json',{visibleGlyphs:glyphs.length,characters:Object.keys(font.glyphs).length,views:font.views.length,sprites:total,maximumTextureEdge:Math.max(...font.views.flatMap(v=>[v.width,v.height]))});
  console.log(`Exported ${total} sprites. Contact sheet height ${yy+25}.`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
