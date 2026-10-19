// Authoritative offline projection of the accepted shallow-depth treatment.
const {createCanvas,Path2D}=require('@napi-rs/canvas');
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
function transform(p,yaw,pitch){
  const cy=Math.cos(yaw),sy=Math.sin(yaw),cx=Math.cos(pitch),sx=Math.sin(pitch);
  const x=p[0]*cy+p[2]*sy,z=-p[0]*sy+p[2]*cy;
  return [x,p[1]*cx-z*sx,p[1]*sx+z*cx];
}
function normal(a,b,c){
  const u=b.map((v,i)=>v-a[i]),v=c.map((q,i)=>q-a[i]);
  const n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]],length=Math.hypot(...n)||1;
  return n.map(x=>x/length);
}
function prepareGlyph(g,image){
  const [, ,w,h]=g.rect,face=createCanvas(w,h),ctx=face.getContext('2d'),clip=new Path2D();
  for(const loop of g.contours){loop.forEach(([x,y],i)=>i?clip.lineTo(x,y):clip.moveTo(x,y));clip.closePath();}
  ctx.clip(clip,'evenodd');ctx.drawImage(image,...g.rect,0,0,w,h);
  const depth=h*.18,facets=[];
  for(const loop of g.contours)for(let i=0;i<loop.length;i++){
    const a=loop[i],b=loop[(i+1)%loop.length],dx=b[0]-a[0],dy=b[1]-a[1],length=Math.hypot(dx,dy);if(length<1)continue;
    const nx=dy/length,ny=-dx/length,frontA=[a[0]-w/2,a[1]-h/2,0],frontB=[b[0]-w/2,b[1]-h/2,0];
    // Depth must not dilate the front silhouette: a tiny expansion can join
    // punctuation dots or close narrow counters when rasterized at text size.
    const midA=[frontA[0],frontA[1],-depth*.22],midB=[frontB[0],frontB[1],-depth*.22];
    const backA=[frontA[0]-nx*.9,frontA[1]-ny*.9,-depth],backB=[frontB[0]-nx*.9,frontB[1]-ny*.9,-depth];
    facets.push({points:[frontA,midA,midB,frontB],bevel:true,phase:(a[0]+a[1])*.015});
    facets.push({points:[midA,backA,backB,midB],bevel:false,phase:(a[0]+a[1])*.015});
  }
  return {...g,face,facets};
}
function drawGlyph(ctx,g,x,y,yawDegrees,pitchDegrees,scale=1){
  const yaw=yawDegrees*Math.PI/180,pitch=pitchDegrees*Math.PI/180,w=g.rect[2],h=g.rect[3],visible=[];
  ctx.save();ctx.translate(x,y);ctx.scale(g.metrics.height/h*scale,g.metrics.height/h*scale);
  for(const f of g.facets){
    const points=f.points.map(p=>transform(p,yaw,pitch)),n=normal(points[0],points[1],points[2]);if(n[2]<=.001)continue;
    visible.push({...f,points,n,z:points.reduce((s,p)=>s+p[2],0)/points.length});
  }
  visible.sort((a,b)=>a.z-b.z);
  for(const f of visible){
    const light=clamp(.38+Math.max(0,-.35*f.n[0]-.45*f.n[1]+.82*f.n[2])*.66,.28,1.1);
    const hue=242+Math.sin(f.phase)*32,saturation=f.bevel?67:56,luminosity=clamp((f.bevel?72:58)*light,25,86);
    ctx.fillStyle=`hsl(${hue} ${saturation}% ${luminosity}%)`;ctx.beginPath();f.points.forEach((p,i)=>i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]));ctx.closePath();ctx.fill();
  }
  const origin=transform([-w/2,-h/2,0],yaw,pitch),ax=transform([1,0,0],yaw,pitch),ay=transform([0,1,0],yaw,pitch);
  ctx.transform(ax[0],ax[1],ay[0],ay[1],origin[0],origin[1]);ctx.drawImage(g.face,0,0);ctx.restore();
}
function alphaBounds(canvas){
  const {width,height}=canvas,data=canvas.getContext('2d').getImageData(0,0,width,height).data;let x0=width,y0=height,x1=-1,y1=-1,count=0;
  for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(data[(y*width+x)*4+3]>0){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);count++;}
  return count?{x:x0,y:y0,w:x1-x0+1,h:y1-y0+1,pixels:count}:null;
}
module.exports={prepareGlyph,drawGlyph,alphaBounds,transform};
