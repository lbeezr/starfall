// Shape studies only: no new painted artwork and no production geometry contract.
window.StarfallKitDiagrams=(()=>{
 const profiles={wide:[1180,820],tall:[820,1180],phone:[393,852]};
 const ellipse=(x,y,rx,ry,fill,extra='')=>`<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${fill}" ${extra}/>`;
 const path=(d,fill,extra='')=>`<path d="${d}" fill="${fill}" ${extra}/>`;
 const shard=(x,y,s,fill,angle=0)=>`<g transform="translate(${x} ${y}) rotate(${angle}) scale(${s})">${path('M-44 -16L-6 -46L38 -19L48 12L4 44L-38 22Z',fill)}${path('M-35 -9L24 13M-26 9L15 26','none','stroke="#b7bed0" stroke-opacity=".25" stroke-width="3"')}</g>`;
 function geometry(profile){const [w,h]=profiles[profile],side=Math.min(588,w-32,h-296),left=(w-side)/2,top=(h-side)/2;return {w,h,side,left,top,portrait:h>w,hud:{x:left,y:top-132,w:side,h:112},actions:{x:left+side*.16,y:top+side+58,w:side*.68,h:44}};}
 function sail(x,y,s,p,beat){return `<g transform="translate(${x} ${y}) scale(${s})">${path('M-33 19Q0 32 28 16L13 30L-18 30Z',p[2])}${path('M0 20L0 -42','none',`stroke="${p[3]}" stroke-width="2"`)}<g transform="rotate(${beat===2?-8:0} 0 15)">${path('M-3 -40Q-48 -13 -9 13Z',p[3],'opacity=".8"')}${path('M4 -32L29 12L4 12Z',p[2])}</g>${ellipse(11,22,4,4,p[4],`opacity="${beat===2?1:.6}"`)}</g>`;}
 function cloud(x,y,s,color,flip=1){return `<g transform="translate(${x} ${y}) scale(${s*flip} ${s})">${path('M-180 -150Q-115 -216 -72 -149Q-18 -207 24 -130Q96 -146 93 -66Q168 -26 108 40Q152 116 60 126Q13 202 -53 144Q-135 182 -145 102Q-218 40 -160 -18Q-221 -85 -180 -150Z',color)}${path('M-143 -106Q-81 -148 -40 -94Q48 -104 40 -33Q101 -14 60 50','none','stroke="#d1b7d3" stroke-opacity=".26" stroke-width="4"')}</g>`;}
 function canopy(x,y,s,color,flip=1,single=false){return `<g transform="translate(${x} ${y}) scale(${s*flip} ${s})">${path(single?'M-70 75Q-20 40 0 18':'M-180 150Q-35 56 68 -60','none',`stroke="${color}" stroke-width="22"`)}${(single?[0]:[-1,0,1]).map((v,i)=>`<g transform="translate(${v*62} ${-v*45}) rotate(${-28+i*28})">${path('M-24 40Q-140 10 -112 -78Q-58 -62 0 4Q-58 -126 27 -130Q70 -66 14 7Q130 -84 146 -4Q122 66 3 36Z',color)}${path('M-12 42L20 -102M0 21L-93 -56M4 24L122 7','none','stroke="#a3b9b4" stroke-opacity=".24" stroke-width="3"')}</g>`).join('')}</g>`;}
 function artwork(kit,g,beat){
  const {w,h,portrait:P,top,side}=g,p=kit.palette;
  const layers=[`<rect width="${w}" height="${h}" fill="${p[0]}"/>`,'','','',''];
  // Only a few large, quiet distant marks; none resembles the five-point cast.
  layers[0]+=Array.from({length:16},(_,i)=>{const x=(i*193+31)%w,y=(i*137+49)%h;return ellipse(x,y,1.4,1.4,p[3],'opacity=".17"');}).join('');
  if(kit.id==='moonwake'){
   const x=P?-48:-30,y=P?-64:196,r=P?165:315;
   layers[1]=ellipse(x,y,r,r,p[2])+ellipse(x-28,y-12,r*.94,r*.94,p[1])+path(`M${x+r*.62} ${y-r*.76}A${r} ${r} 0 0 1 ${x+r*.73} ${y+r*.68}`,'none',`stroke="${p[3]}" stroke-width="${P?5:8}" opacity=".7"`);
   layers[2]=path(P?`M${w-80} 14Q${w-20} 40 ${w+10} 119`:`M${w-70} 62Q${w-260} 250 ${w-70} 440`,'none',`stroke="${p[2]}" stroke-width="8" opacity=".3"`);
   layers[3]=sail(P?w-64:w-158,P?65:228,P?.55:1.1,p,beat);
   layers[4]=shard(P?38:116,P?h-61:h-85,P?.5:1.2,p[1],-22)+path(P?`M23 ${h-80}L45 ${h-67}`:`M80 ${h-118}L130 ${h-94}`,'none',`stroke="${p[3]}" stroke-width="3" opacity="${beat===2?.9:.24}"`);
  }
  if(kit.id==='nebula'){
   layers[1]=ellipse(P?35:90,P?20:250,P?170:200,P?80:370,p[1],'opacity=".6"')+ellipse(w-10,h-5,P?130:260,P?100:310,p[1],'opacity=".7"');
   layers[2]=P?cloud(1,-12,.62,p[1])+cloud(w+12,h+25,.68,p[2],-1):cloud(70,134,1.18,p[1])+cloud(w-50,h-105,1.1,p[2],-1)+cloud(16,h-66,.65,p[2]);
   const x=P?w-44:w-130,y=P?h-42:h-146;
   layers[3]=ellipse(x,y,P?24:42,P?10:17,p[4],`opacity="${beat===2?.9:.35}"`)+path(P?'M7 37Q73 20 77 58Q46 88 29 63':`M50 206Q195 160 205 243Q136 309 96 256`,'none',`stroke="${p[0]}" stroke-width="${P?11:27}" opacity=".65"`);
   layers[4]=path(P?`M0 ${h-106}Q80 ${h-76} 117 ${h+10}`:`M0 ${h-188}Q180 ${h-160} 260 ${h+10}`,'none',`stroke="${p[3]}" stroke-width="${P?8:15}" opacity=".25"`);
  }
  if(kit.id==='shatterlight'){
   layers[1]=P?path('M-20 28Q110 -32 270 32','none',`stroke="${p[1]}" stroke-width="32" stroke-dasharray="70 24"`):path('M235 -90Q-100 290 188 590','none',`stroke="${p[1]}" stroke-width="80" stroke-dasharray="135 55"`);
   const shelterX=P?w-64:w-157,shelterY=P?h-62:h-194;
   layers[2]=P?shard(58,43,.8,p[2],20)+shard(180,26,.55,p[2],-10)+shard(shelterX,shelterY,.72,p[2],-18):shard(140,290,2.6,p[2],30)+shard(215,62,1.15,p[2],-10)+shard(shelterX,shelterY,1.5,p[2],-18);
   layers[3]=`<g transform="translate(${shelterX} ${shelterY-(P?24:48)}) scale(${P?.6:1})">${path('M-30 18L-25 -13Q0 -48 25 -13L30 18Z',p[1])}${ellipse(0,-4,12,12,p[4],`opacity="${beat===2?.95:.5}"`)}${ellipse(0,-4,17,17,'none',`stroke="${p[3]}" stroke-width="3"`)}</g>`;
   layers[4]=shard(P?14:25,h-19,P?.75:1.9,p[1],35);
  }
  if(kit.id==='garden'){
   layers[1]=ellipse(0,P?30:h*.45,P?160:280,P?110:360,p[1],'opacity=".45"')+ellipse(w,h,P?160:300,P?135:250,p[1],'opacity=".5"');
   layers[2]=P?canopy(70,62,.4,p[2],1,true)+canopy(w+28,h-2,.56,p[1],-1):canopy(72,270,.9,p[2])+canopy(w-45,h-160,.92,p[1],-1);
   const x=P?w-79:w-165,y=P?h-68:h-210,s=P?.6:1.1;
   layers[3]=`<g transform="translate(${x} ${y}) scale(${s})">${path('M0 -34Q8 -18 0 1','none',`stroke="${p[2]}" stroke-width="4"`)}${ellipse(0,14,14,24,p[3])}${ellipse(0,17,8,16,p[4],'opacity=".7"')}<g transform="translate(-42 8)">${ellipse(-7,0,beat===2?15:5,beat===2?9:12,p[3])}${ellipse(7,0,beat===2?15:5,beat===2?9:12,p[3])}${ellipse(0,4,3,12,p[0])}</g></g>`;
   layers[4]=ellipse(P?35:130,h-100,3,5,p[3],'opacity=".5"')+ellipse(P?58:165,h-62,2,4,p[4],'opacity=".4"');
  }
  if(kit.id==='ringdrift'){
   const x=P?12:-40,y=P?30:225,r=P?72:220;
   const far=P?`<g transform="rotate(-18 12 30)">${ellipse(12,30,166,28,'none',`stroke="${p[2]}" stroke-width="13" opacity=".65"`)}</g>`:`<g transform="rotate(-35 -40 225)">${ellipse(-40,225,350,85,'none',`stroke="${p[2]}" stroke-width="24" opacity=".65"`)}</g>`;
   layers[1]=far+ellipse(x,y,r,r,p[1])+ellipse(x-12,y+7,r*.96,r*.96,p[0]);
   layers[2]=P?`<g transform="rotate(-18 12 30)">${ellipse(12,30,182,35,'none',`stroke="${p[3]}" stroke-width="5" opacity=".5"`)}</g>`:`<g transform="translate(-40 225) rotate(-35)">${path('M-375 0A375 96 0 0 0 375 0','none',`stroke="${p[3]}" stroke-width="10" opacity=".65"`)}${path('M180 84Q225 78 260 69','none',`stroke="${p[3]}" stroke-width="7" opacity="${beat===2?1:.18}"`)}</g>`;
   if(P)layers[2]+=path('M135 14L158 5','none',`stroke="${p[3]}" stroke-width="5" opacity="${beat===2?.95:.2}"`);
   layers[3]=ellipse(P?w-62:w-130,P?h-64:160,P?28:54,P?28:54,p[2])+ellipse(P?w-73:w-152,P?h-70:151,P?23:47,P?23:47,p[1])+sail(P?w-53:w-142,P?70:h-178,P?.38:.65,p,1);
   layers[4]=shard(P?24:75,h-35,P?.5:1.15,p[1],-15);
  }
  return layers;
 }
 function svg(kit,profile,beat,{guides=true,visible=[true,true,true,true,true],gray=false,detail=false}={}){
  const g=geometry(profile),{w,h,side,left,top,hud,actions}=g;
  let body=artwork(kit,g,beat).map((content,i)=>`<g data-plane="${i}" ${visible[i]?'':'style="display:none"'}>${content}</g>`).join('');
  if(guides){body+=`<g class="reservations" fill="none" stroke="#c1cbd3" stroke-opacity=".38" stroke-dasharray="7 7" stroke-width="1.5"><rect x="${left}" y="${top}" width="${side}" height="${side}" rx="4"/><rect x="${hud.x}" y="${hud.y}" width="${hud.w}" height="${hud.h}" rx="12"/><rect x="${actions.x}" y="${actions.y}" width="${actions.w}" height="${actions.h}" rx="12"/></g><g fill="#c3cedb" font-family="system-ui" font-size="${g.portrait?17:20}" opacity=".8" text-anchor="middle"><text x="${w/2}" y="${hud.y+hud.h/2+5}">HUD reserved</text><text x="${w/2}" y="${top+28}">Centered 7 × 7 field</text><text x="${w/2}" y="${actions.y+actions.h/2+6}">Actions reserved</text></g>`;}
  const focus={moonwake:[w-235,130,220,180],nebula:[w-265,h-280,220,210],shatterlight:[w-240,h-320,220,230],garden:[w-290,h-340,240,220],ringdrift:[95,80,180,190]};
  const view=detail?focus[kit.id].join(' '):`0 0 ${w} ${h}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${view}" role="img" aria-label="${kit.name}: ${kit.beats[beat].name}. ${kit.silhouette}" style="${gray?'filter:grayscale(1)':''}"><title>${kit.name} — schematic composition, not final art</title>${body}</svg>`;
 }
 return {profiles,geometry,svg};
})();
