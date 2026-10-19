// Offline illustration only; native StarCast.swift remains authoritative.
(()=>{
const bodies = '../../../../App/Assets.xcassets/';
const names=['Spark','Sunny','Pip','Twinkle','Nova','Dusk','Opal'];
let faceId=0;
function face(name) {
  const sleepy=name==='Nova'||name==='Dusk',dark=name==='Dusk',ink='#141a38',id=`eyes${faceId++}`;
  const height=sleepy?30:40,top=117-height/2;
  let eyes=[104,152].map(x=>`<ellipse cx="${x}" cy="117" rx="12.5" ry="${height/2}" fill="url(#${id})"/><ellipse cx="${x}" cy="${top+5+height*.295}" rx="7" ry="${height*.295}" fill="${ink}"/><ellipse cx="${x-1.5}" cy="${top+8.5}" rx="3.5" ry="4.5" fill="white"/><circle cx="${x+4.5}" cy="${top+height-5.5}" r="1.5" fill="cyan" opacity=".8"/>${sleepy?`<path d="M${x-13.5} ${top+3}L${x+13.5} ${top+(dark?-1:3)}"/>`:''}`).join('');
  const brow=['Pip','Twinkle','Dusk'].includes(name)?`<path d="M140 88Q151 ${name==='Twinkle'?95:78}163 ${dark?82:88}" stroke-width="4"/>`:'';
  return `<svg viewBox="0 0 256 256" aria-hidden="true"><defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop stop-color="${ink}"/><stop offset=".62" stop-color="#040a47"/><stop offset="1" stop-color="#0f6efa"/></linearGradient></defs><g stroke="${ink}" stroke-width="5" stroke-linecap="round" fill="none">${eyes}${brow}<path d="M119 142Q129 155 137 141" stroke="${dark?'#e5d9ff':ink}" stroke-width="4.5"/></g>${dark?'':'<g fill="#f04a66" opacity=".24"><ellipse cx="91" cy="137" rx="7" ry="3"/><ellipse cx="165" cy="137" rx="7" ry="3"/></g>'}</svg>`;
}
function star(name,classes='') {
  return `<div class="star ${classes}" role="img" aria-label="${name}${classes.includes('grown')?', grown':''}${classes.includes('drained')?', drained':''}"><img src="${bodies}StarCast${name}.imageset/body.png" alt="">${face(name)}</div>`;
}
window.StarfallConceptCast={star,names};
})();
