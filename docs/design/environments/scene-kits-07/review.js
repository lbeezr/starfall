(()=>{
 const kits=window.StarfallSceneKits,diagram=window.StarfallKitDiagrams,$=s=>document.querySelector(s),query=new URLSearchParams(location.search);
 let kit=kits.find(k=>k.id===query.get('kit'))||kits[0],beat=1,visible=[true,true,true,true,true];
 for(const item of kits){const b=document.createElement('button');b.type='button';b.dataset.kit=item.id;b.textContent=item.name;b.addEventListener('click',()=>{kit=item;beat=1;visible.fill(true);renderBrief();});$('#kit-nav').appendChild(b);}
 if(diagram.profiles[query.get('device')])$('#device').value=query.get('device');
 function renderStage(){
  const profile=$('#device').value,g=diagram.geometry(profile),stage=$('.stage'),gray=$('#gray').checked;
  stage.style.aspectRatio=`${g.w}/${g.h}`;stage.style.maxWidth=g.portrait?'420px':'100%';stage.classList.toggle('gray',gray);
  $('.diagram').innerHTML=diagram.svg(kit,profile,beat,{guides:$('#guides').checked,visible,gray});
  const cast=$('.cast');Object.assign(cast.style,{width:(g.side/g.w*100)+'%',height:(g.side/g.h*100)+'%',left:(g.left/g.w*100)+'%',top:(g.top/g.h*100)+'%'});cast.replaceChildren();
  const count=$('#density').value==='dense'?49:$('#density').value==='empty'?0:6;
  for(let i=0;i<count;i++){
   const col=count===49?i%7:[0,1,3,4,5,6][i],row=count===49?Math.floor(i/7):[0,1,0,2,0,1][i];
   const name=count===49&&i===15?'Dusk':count===49&&i===30?'Opal':window.StarfallConceptCast.names[i%5],holder=document.createElement('div');
   holder.innerHTML=window.StarfallConceptCast.star(name,i===8?'grown':'');const star=holder.firstElementChild;
   Object.assign(star.style,{left:((col+.5)/7*100)+'%',top:((6-row+.5)/7*100)+'%',width:(100/7*(i===8?.96:.78))+'%'});cast.appendChild(star);
  }
  $('#beat-detail').textContent=kit.beats[beat].change;
  document.querySelectorAll('.story-frame').forEach((b,i)=>b.setAttribute('aria-pressed',String(i===beat)));
  window.kitReviewState={kit:kit.id,profile,beat,visible:[...visible],geometry:g,count};
 }
 function renderBrief(){
  document.querySelectorAll('#kit-nav button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.kit===kit.id)));
  $('#kit-number').textContent=`KIT ${String(kits.indexOf(kit)+1).padStart(2,'0')} / ${kit.silhouette}`;$('#kit-title').textContent=kit.name;$('#kit-subtitle').textContent=kit.subtitle;$('#premise').textContent=kit.premise;
  $('#palette').innerHTML=kit.palette.map(c=>`<span class="swatch" style="background:${c}" aria-label="${c}"></span>`).join('');$('#palette-note').textContent=kit.paletteNote;
  $('#camera').innerHTML='<strong>View:</strong> '+kit.camera;$('#portrait').innerHTML='<strong>Portrait plan:</strong> '+kit.portrait;
  $('#layer-list').replaceChildren();kit.layers.forEach((layer,i)=>{const box=document.createElement('div');box.className='layer';box.innerHTML=`<label><input type="checkbox" data-plane="${i}" ${visible[i]?'checked':''}><span><span class="plane">0${i+1}</span> ${layer.name}</span></label><p>${layer.purpose}</p><p class="motion">${layer.motion}</p>`;box.querySelector('input').addEventListener('change',e=>{visible[i]=e.target.checked;renderStage();});$('#layer-list').appendChild(box);});
  $('#story-grid').replaceChildren();kit.beats.forEach((frame,i)=>{const b=document.createElement('button');b.type='button';b.className='story-frame';b.innerHTML=diagram.svg(kit,'wide',i,{guides:false,detail:i===2})+`<span class="frame-copy"><strong>${i+1}. ${i===2?'Detail: ':''}${frame.name}</strong><span>${frame.caption}</span></span>`;b.addEventListener('click',()=>{beat=i;renderStage();});$('#story-grid').appendChild(b);});
  $('#prop-grid').innerHTML=kit.props.map(p=>`<article class="prop"><h4>${p.name}</h4><p>${p.why}</p><p><strong>Normal:</strong> ${p.behavior}</p><p><strong>Quiet:</strong> ${p.quiet}</p></article>`).join('');
  $('#question').textContent=kit.question;$('#reject').textContent=kit.reject;
  $('#asset-count').textContent=`${kit.assets.length} named asset entries across five planes. ${kit.id==='ringdrift'?'Three reuse the Moonwake vessel kit.':''} Components described in an entry may need separate files when they move independently.`;
  $('#asset-rows').innerHTML=kit.assets.map(([id,label,plane,anchor,note])=>`<tr><td>${label}<small>${id} · Plane ${plane}</small></td><td>${anchor}</td><td>${note}</td></tr>`).join('');
  $('#reference-details').hidden=!kit.reference;
  if(kit.reference){$('#reference-image').src=kit.reference;$('#reference-image').alt=kit.name+' existing generated mood reference';$('#reference-caption').textContent=kit.referenceCaption;}else $('#reference-image').removeAttribute('src');
  renderStage();
 }
 $('#restore').addEventListener('click',()=>{visible.fill(true);renderBrief();});
 document.querySelectorAll('.controls select,.controls input').forEach(el=>el.addEventListener('change',renderStage));
 renderBrief();
})();
