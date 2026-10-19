const worlds={
  nebula:{name:'The Nebula Cradle',description:'A quiet pocket inside a vast cloud of star-forming gas. A sheltered stop on the same cast’s journey through the universe.',tradeoff:'Five independently generated planes test assembly and restrained depth. They do not reproduce the original painting exactly. The center stays open; cloud masses move outward around the centered field.'},
  moonwake:{name:'Moonwake',description:'The travelers pass a pearl moon at night. A distant sail suggests a route through a world much larger than the seven-column field.',tradeoff:'The original painting remains a reference. The moon and boat still need separate art layers so their identity survives portrait cropping. Ambient motion is available only in the Nebula layer study.'}
};
const devices={wide:[1180,820],tall:[820,1180],phone:[393,852]};
const layers=[['deep-space','Deep space'],['distant-haze','Distant haze'],['left-cloud','Left cloud'],['right-cloud','Right cloud'],['near-wisps','Near wisps']];
const query=new URLSearchParams(location.search),$=s=>document.querySelector(s);
let selected=worlds[query.get('world')]?query.get('world'):'nebula';
const {star,names}=window.StarfallConceptCast;
const screen=$('.screen'),preview=$('.preview'),field=$('.field'),reduced=matchMedia('(prefers-reduced-motion: reduce)');
let logicalWidth=1180,logicalHeight=820;
for(const [id,label] of layers){
  const node=document.createElement('div');node.className='scene-layer';node.dataset.layer=id;
  const img=document.createElement('img');img.src=`nebula-layers/${id}.png`;img.alt='';node.appendChild(img);$('.layer-stack').appendChild(node);
  const control=document.createElement('label');control.innerHTML=`<input type="checkbox" data-layer="${id}" checked>${label}`;$('#layer-controls').appendChild(control);
}
$('.incoming').innerHTML=window.StarfallForecastSnapshot.forecast.map(item=>star(item.character)).join('');
function scale(){const available=Math.min($('main').clientWidth,logicalWidth,logicalHeight>logicalWidth?540:1180),ratio=available/logicalWidth;preview.style.width=available+'px';preview.style.height=logicalHeight*ratio+'px';screen.style.transform=`scale(${ratio})`;}
function updateMotion(){screen.classList.toggle('animate',selected==='nebula'&&$('#composition').value==='layers'&&$('#motion').checked&&$('#scenery').checked&&!reduced.matches&&!document.hidden);}
function updateTrail(){
  const p=Number($('#progress').value)/100,w=$('.trail').clientWidth,items=[...$('.incoming').children];
  $('#progress-value').value=Math.round(p*100)+'%';$('.trail-tail').style.width=(p*100)+'%';$('.trail-head').style.left=(p*100)+'%';
  // Presentation mirror of App/SkyTrailMotion.swift. The core, not this slider, owns real showers.
  items.forEach((item,i)=>{const start=Math.min(.75,(items.length-1-i)*16/w),finish=.96-(items.length-1-i)*.045;item.style.left=((start+(1-start)*Math.min(1,p/finish))*100)+'%';item.style.opacity=Math.max(0,1-Math.max(0,p-finish)/.035);});
}
function layoutScenery(side){
  const layered=selected==='nebula'&&$('#composition').value==='layers';
  $('.scenery').hidden=!$('#scenery').checked;$('.backdrop').hidden=layered;$('.layer-stack').hidden=!layered;
  const img=$('.backdrop');img.src=selected+'-concept.png';img.alt=worlds[selected].name+' generated concept background';
  $('#composition').disabled=selected!=='nebula';$('#layer-controls').disabled=!layered;$('#motion').disabled=!layered;
  $('#layer-note').textContent=selected==='moonwake'?'Moonwake is still one painting; it has no separately movable props yet.':reduced.matches?'System Reduce Motion is active: all scenic drift is stopped.':'Five image planes. Only scenery drifts; the field, characters and HUD stay fixed. Uncheck Ambient motion for a static comparison.';
  const h=logicalHeight+40,w=h*4/3,left=(logicalWidth-side)/2;
  for(const [id] of layers){const el=$(`.scene-layer[data-layer="${id}"]`);el.hidden=!$(`input[data-layer="${id}"]`).checked;
    const edge=id==='left-cloud'||id==='right-cloud',portrait=logicalHeight>logicalWidth;
    if(edge&&portrait){
      // Portrait uses sky above the HUD and below the actions, preserving recognizable clouds.
      const cloudHeight=(logicalHeight-side)/2+90,cloudWidth=cloudHeight*4/3;
      el.style.maskImage=id==='left-cloud'?'linear-gradient(to bottom, #000 calc(100% - 28px), transparent)':'linear-gradient(to bottom, transparent, #000 34px)';
      Object.assign(el.style,{width:cloudWidth+'px',height:cloudHeight+'px',top:(id==='left-cloud'?-230:(logicalHeight+side)/2+110)+'px',left:(id==='left-cloud'?-30:logicalWidth-cloudWidth+30)+'px'});
    }else {el.style.maskImage='none';Object.assign(el.style,{width:(edge?w:logicalWidth+40)+'px',height:h+'px',top:'-20px',left:(id==='left-cloud'?Math.min(-20,left-18-w*.43):id==='right-cloud'?Math.max(logicalWidth-w+20,logicalWidth-left+18-w*.57):-20)+'px'});}
  }
  updateMotion();
}
function render(){
  [logicalWidth,logicalHeight]=devices[$('#device').value];
  const side=Math.min(588,logicalWidth-32,logicalHeight-296),step=side/7,top=(logicalHeight-side)/2;
  screen.style.width=logicalWidth+'px';screen.style.height=logicalHeight+'px';
  Object.assign(field.style,{width:side+'px',height:side+'px',left:(logicalWidth-side)/2+'px',top:top+'px'});
  const density=$('#density').value,heights={empty:[0,0,0,0,0,0,0],sparse:[1,1,2,1,0,2,1],half:[3,4,3,5,3,4,2],dense:[7,7,7,7,7,7,7]}[density],stars=$('.stars');stars.replaceChildren();
  for(let col=0;col<7;col++)for(let row=0;row<heights[col];row++){
    let family=(col*3+row*2)%5;if(col===5&&row===1)family=5;if(col===3&&row===2)family=6;
    const grown=col===1&&row===1,drained=(col===4&&row===1)||(col===5&&row===0),holder=document.createElement('div');holder.innerHTML=star(names[family],`${grown?'grown':''} ${drained?'drained':''}`);
    const piece=holder.firstElementChild;Object.assign(piece.style,{left:((col+.5)*step)+'px',top:((6-row+.5)*step)+'px',width:step*(grown?.96:.78)+'px'});piece.dataset.column=col;piece.dataset.row=row;stars.appendChild(piece);
  }
  $('.cell-guides').innerHTML='<i></i>'.repeat(49);
  const paused=$('#state').value==='paused',hud=$('.hud');hud.hidden=density==='empty';hud.style.width=side+'px';hud.classList.remove('score-wide');
  $('.score').textContent=BigInt($('#score').value).toLocaleString('en-US');
  hud.classList.toggle('score-wide',$('.score').scrollWidth>$('.score').clientWidth);
  $('.forecast').style.visibility=paused?'hidden':'visible';
  hud.style.top=(top-hud.offsetHeight-16)+'px';
  const guide=$('.guide');guide.hidden=density==='empty'||!paused;guide.style.width=side+'px';guide.style.top=(top+side+18)+'px';
  $('.actions').hidden=density==='empty';$('.actions').style.top=(top+side+58)+'px';$('.pause-action').textContent=paused?'Resume':'Pause';
  screen.classList.toggle('show-guides',$('#guides').checked);layoutScenery(side);updateTrail();
  $('#measurement').textContent=`${logicalWidth} × ${logicalHeight} concept canvas · field centered at ${logicalWidth/2}, ${logicalHeight/2} · seven ${step.toFixed(1)}-point cells per axis`;
  $('#world-name').textContent=worlds[selected].name;$('#world-description').textContent=worlds[selected].description;$('#world-tradeoff').textContent=worlds[selected].tradeoff;
  document.querySelectorAll('nav button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.world===selected)));
  window.conceptLayout={width:logicalWidth,height:logicalHeight,side,step,centerX:logicalWidth/2,centerY:logicalHeight/2,world:selected};scale();
}
document.querySelectorAll('nav button').forEach(b=>b.addEventListener('click',()=>{selected=b.dataset.world;render();}));
document.querySelectorAll('select,input').forEach(el=>el.addEventListener('change',render));$('#progress').addEventListener('input',updateTrail);
if(devices[query.get('device')])$('#device').value=query.get('device');
if(['empty','sparse','half','dense'].includes(query.get('density')))$('#density').value=query.get('density');
if(query.get('export')==='1')document.body.classList.add('export');
reduced.addEventListener('change',render);document.addEventListener('visibilitychange',updateMotion);
new ResizeObserver(scale).observe($('main'));render();
