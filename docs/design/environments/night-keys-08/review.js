// Composition review only. Reuse the approved kit's geometry and shared cast assets.
(()=>{
 const $=s=>document.querySelector(s),kits=window.StarfallSceneKits,geometry=window.StarfallKitDiagrams;
 const query=new URLSearchParams(location.search);
 let kit=kits.find(k=>k.id===query.get('kit'))||kits[0];
 const notes={
  moonwake:['The broad pearl curve and small chart-sail make the route feel immense and inhabited. The phone arrangement lifts both above the controls.','For separated assets: reduce the bright lunar rim slightly and remove remaining comet-like vessel dust; keep the tiny lantern as the warm accent.'],
  nebula:['The unequal banks now have a recognizable dark curl and one sheltered birth-light. The empty route remains the principal space.','For separated assets: make the birth-light more diffuse, soften the remaining tiny central sky points and keep the two banks moving independently.'],
  shatterlight:['Repeated curved strata tie the fragments to one former planet. The single lit shelter suggests continued life. The portrait duplicate shelter was removed.','For separated assets: reduce tiny rubble and illumination on fracture edges; retain generous gaps so the broken sphere stays readable.'],
  garden:['The attached amber pod gives the place a local light source. Broad canopy fans and distant mist suggest open air above living terrain.','This is the densest scene. Simplify the distant canopy and keep the seed-moth as a tiny dark wing silhouette; the first outputs made it too character-like.'],
  ringdrift:['The oblique orbital silhouette reads clearly in landscape. A smaller complete planet and rings preserve identity above the phone HUD.','For separated assets: retain correct near/far ring order, simplify ice grit and export a complete planetary silhouette with crop-safe margins.']
 };
 const files=(id,profile)=>`${id}-${profile}-key.png`;
 for(const item of kits){const b=document.createElement('button');b.type='button';b.textContent=item.name;b.dataset.kit=item.id;b.addEventListener('click',()=>{kit=item;render();});$('#destinations').append(b);}
 function render(){
  document.querySelectorAll('#destinations button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.kit===kit.id)));
  $('#number').textContent=`DESTINATION ${String(kits.indexOf(kit)+1).padStart(2,'0')} / 05`;
  $('#name').textContent=kit.name;$('#subtitle').textContent=kit.subtitle;$('#premise').textContent=kit.premise;
  $('#judgment').textContent=notes[kit.id][0];$('#remaining').textContent=notes[kit.id][1];
  $('#planes').innerHTML=kit.layers.map((p,i)=>`<li><strong>${p.name}</strong> — ${p.purpose}<small>${p.motion} · ${kit.assets.filter(a=>a[2]===i+1).map(a=>a[1]).join('; ')}</small></li>`).join('');
  $('#kit-link').href=`../scene-kits-07/index.html?kit=${kit.id}`;
  $('#wide-link').href=files(kit.id,'wide');$('#phone-link').href=files(kit.id,'phone');
  const density=$('#density').value,count={sparse:6,gathering:24,dense:49,empty:0}[density];
  document.body.classList.toggle('gray',$('#gray').checked);
  document.querySelectorAll('.stage').forEach(stage=>{
   const profile=stage.dataset.profile,g=geometry.geometry(profile),painting=stage.querySelector('.painting');
   stage.style.aspectRatio=`${g.w}/${g.h}`;painting.src=files(kit.id,profile);painting.alt=`${kit.name}, generated ${profile==='wide'?'landscape':'phone'} nightscape composition`;
   stage.querySelector('.guides').innerHTML=$('#guides').checked?geometry.svg(kit,profile,1,{guides:true,visible:[false,false,false,false,false]}):'';
   const cast=stage.querySelector('.cast');Object.assign(cast.style,{width:g.side/g.w*100+'%',height:g.side/g.h*100+'%',left:g.left/g.w*100+'%',top:g.top/g.h*100+'%'});cast.replaceChildren();
   for(let i=0;i<count;i++){
    const col=count===6?[0,1,3,4,5,6][i]:i%7,row=count===6?[0,1,0,2,0,1][i]:Math.floor(i/7);
    const name=i===15?'Dusk':i===21?'Opal':window.StarfallConceptCast.names[(i*3+row)%5],holder=document.createElement('div');
    holder.innerHTML=window.StarfallConceptCast.star(name,i===8?'grown':'');const star=holder.firstElementChild;
    Object.assign(star.style,{left:(col+.5)/7*100+'%',top:(6-row+.5)/7*100+'%',width:100/7*(i===8?.96:.78)+'%'});cast.append(star);
   }
  });
  window.nightKeyReviewState={kit:kit.id,count,density,guides:$('#guides').checked,gray:$('#gray').checked};
 }
 document.querySelectorAll('.controls input,.controls select').forEach(e=>e.addEventListener('change',render));render();
})();
