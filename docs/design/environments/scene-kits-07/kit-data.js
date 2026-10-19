// Planning data only. Asset IDs are proposed outputs, not claims that files exist.
window.StarfallSceneKits = [
{
 id:'moonwake',name:'Moonwake',subtitle:'Skimming the night side of a pearl moon',
 premise:'The travelers pass so close to a moon that its curved edge fills one side of the sky. A small chart-sail farther away makes the scale feel enormous and the route feel inhabited.',
 silhouette:'One broad lunar curve and one fine triangular sail.',palette:['#0b122b','#283e68','#9188b4','#e6decc','#d5ac69'],paletteNote:'Blue-black space, pearl stone and a small amber lantern. Keep the moon less bright than the cast where their silhouettes approach it.',
 reference:'../open-skies-05/moonwake-concept.png',referenceCaption:'Existing generated Moonwake mood reference; the moon and vessel are still baked into one painting.',
 camera:'Level view through open space. Moon cropped at the left edge; no ground plane or overhead camera looking down onto a board.',
 portrait:'Move the moon’s visible limb into the upper-left sky, above the HUD. Keep the sail at upper-right and one faint ice shard below the actions. Preserve the moon’s curvature; never squash the circle.',
 question:'Should the traveler craft feel like a delicate astronomical sail or a more organic seed vessel? The diagrams retain the existing sail idea as the working choice.',
 layers:[
  {name:'Distant night',purpose:'Continuous quiet space; no bright points inside the field.',assets:['mw-space'],motion:'Still.'},
  {name:'Pearl moon',purpose:'The identifying silhouette and light direction.',assets:['mw-moon','mw-limb'],motion:'Still; no spinning moon or camera orbit.'},
  {name:'Dust route',purpose:'A faint curved current gives the sail a believable direction.',assets:['mw-dust-route'],motion:'Very slow offset, at most 3 logical points; never through the field.'},
  {name:'Chart-sail',purpose:'One small sign that this route is traveled.',assets:['mw-hull','mw-sail','mw-lantern'],motion:'Sail changes angle by at most 2°; hull settles within 2 points.'},
  {name:'Near ice',purpose:'One cropped shard and sparse dust create foreground scale.',assets:['mw-ice'],motion:'One soft edge glint, no meteor streak.'}
 ],
 assets:[
  ['mw-space','Opaque space base',1,'Full viewport','Shared dark value target; unique distant color.'],
  ['mw-moon','Complete moon body',2,'Left edge / portrait upper-left','Full circular silhouette, center pivot; no baked halo.'],
  ['mw-limb','Lunar edge glow',2,'Registered to moon body','Separate alpha; light from upper-left, no pulse.'],
  ['mw-dust-route','Curved dust ribbon',3,'Right periphery','Separate soft strip; fade both ends.'],
  ['mw-hull','Chart-sail hull and mast',4,'Right upper margin','Pivot at mast foot; tiny unlit hull silhouette.'],
  ['mw-sail','Translucent triangular sail',4,'Attached to mast','Own pivot at mast foot; keep shape simpler than a jewel.'],
  ['mw-lantern','Single warm lantern glow',4,'Hull attachment','Separate low-intensity glow; no UI-like blinking.'],
  ['mw-ice','Cropped ice shard',5,'Lower corner','Complete offscreen shape, no inward-pointing sharp tip.']
 ],
 props:[
  {name:'Chart-sail',why:'Establishes travelers and scale without putting the cast on a ship.',behavior:'A small change of sail angle suggests a current. No tapping, boarding or navigation UI.',quiet:'Hold the sail in its relaxed pose; lantern stays softly lit.'},
  {name:'Pearl ice shard',why:'Repeats the moon’s material at a nearer depth.',behavior:'One restrained glint moves across an edge while the shard stays fixed.',quiet:'Use a dim, static rim; no glint.'}
 ],
 beats:[
  {name:'Arrival',caption:'The moon’s curve establishes scale; the small sail is already visible.',change:'No reveal animation required. This is the establishing composition.'},
  {name:'Settled play',caption:'The vessel holds in the current. Open space remains dominant.',change:'Sail relaxed; dust route faint. The cast and controls stay fixed.'},
  {name:'A current catches',caption:'The sail opens slightly and the lantern warms once.',change:'A 2–3 second local accent at the right margin, returning to rest. No screen-wide light change.'}
 ],
 reject:'A deck under the stars, a bright moon behind score text, pirate details, or a constantly orbiting ship.'
},
{
 id:'nebula',name:'The Nebula Cradle',subtitle:'A sheltered pocket in a living cloud',
 premise:'The cast drifts through an opening in vast folded gas. A curled pocket of light inside one bank suggests stars being born somewhere far away, without adding another character to the board.',
 silhouette:'Two unequal cloud banks with an open, dark gap between them.',palette:['#0b1028','#36305f','#79648e','#b77f9d','#e1ba99'],paletteNote:'Indigo, dusty violet and rose; warm light lives inside the gas folds. Avoid bright candy-colored clouds surrounding every edge equally.',
 reference:'../open-skies-05/nebula-concept.png',referenceCaption:'Existing generated Nebula mood reference. The prior five-plane study informs separation; its files need art-direction review before reuse.',
 camera:'Looking through a three-dimensional pocket of gas. The banks overlap in depth but never close into a circular basin.',
 portrait:'Use one recognizable cloud fold above the HUD and a different bank below the actions. A distant haze plane joins them without outlining a rectangular clear zone.',
 question:'How much of the gas should feel alive? Begin with a slow breath of light inside one fold; avoid faces, eyes or a second star cast in the clouds.',
 layers:[
  {name:'Deep space',purpose:'A clear, dark route through the middle.',assets:['nc-space'],motion:'Still; reuse candidate from the layer proof if its values pass.'},
  {name:'Distant veil',purpose:'A soft plane of gas behind both banks.',assets:['nc-haze'],motion:'At most 2 points of slow drift.'},
  {name:'Unequal cloud banks',purpose:'The main silhouette and shelter.',assets:['nc-left-bank','nc-right-bank'],motion:'Independent ±3-point drift; avoid matched breathing.'},
  {name:'Light pocket and dust curl',purpose:'A small birth-light and darker whorl imply gas activity.',assets:['nc-light-pocket','nc-dust-curl'],motion:'One local light breath; cloud edges do not swell into the field.'},
  {name:'Near wisps',purpose:'A faint, soft veil at two cropped corners.',assets:['nc-wisps'],motion:'Up to 4-point drift; no full-screen shimmer.'}
 ],
 assets:[
  ['nc-space','Opaque deep-space base',1,'Full viewport','Existing base is a reuse candidate, not automatically adopted.'],
  ['nc-haze','Distant haze',2,'Outer corners','Soft alpha; existing haze candidate needs lower-frequency detail.'],
  ['nc-left-bank','Tall indigo gas fold',3,'Left / portrait upper-left','Complete crop-safe bank; no painted floor edge.'],
  ['nc-right-bank','Shorter rose gas fold',3,'Right / portrait lower-right','Different contour and depth from left bank.'],
  ['nc-light-pocket','Warm light inside gas',4,'Nested in right bank','Separate diffuse glow, no star-shaped point or face.'],
  ['nc-dust-curl','Dark curled dust form',4,'Nested in left bank','Soft C-shaped silhouette; gives the light a physical surround.'],
  ['nc-wisps','Two near corner wisps',5,'Opposed corners','Sparse continuous alpha; the earlier thick near-mass output is only a reference.']
 ],
 props:[
  {name:'Birth-light pocket',why:'Makes the nebula a place where something is happening, rather than decorative colored fog.',behavior:'A slow increase and decrease in local warmth over 5 seconds. It does not pop, hatch or produce gameplay stars.',quiet:'Keep a small steady warm patch.'},
  {name:'Dust curl',why:'Adds a recognizable solid-looking gas silhouette and direction of flow.',behavior:'A fine wisp passes behind the curl; the curl itself stays fixed.',quiet:'Retain both silhouettes with no translation.'}
 ],
 beats:[
  {name:'Arrival',caption:'Two cloud banks frame an open route, with one noticeably nearer than the other.',change:'The silhouette establishes shelter without a rim or platform.'},
  {name:'Settled play',caption:'The banks rest at different depths. The birth-light remains faint.',change:'Only very slow edge drift; no symmetric pulsing around the field.'},
  {name:'A distant birth-light',caption:'One folded pocket warms and gently subsides.',change:'A local 5-second light breath. No flash, spawn, score cue or change to gameplay.'}
 ],
 reject:'A symmetrical cloud wreath, dense glitter, smiling gas, or a bright center that competes with the cast.'
},
{
 id:'shatterlight',name:'Shatterlight Reach',subtitle:'Life still glows in the remnants of a world',
 premise:'The travelers cross open space between pieces of an old planet. Repeated rock strata let the eye reconstruct its former curve. One tiny observatory shelter is still lit on a distant fragment.',
 silhouette:'A broken planetary arc, separated by generous dark gaps.',palette:['#0b1225','#30394d','#6e7186','#a79cb1','#d7ac70'],paletteNote:'Ink blue and muted lavender geology; one amber window. The tone is quiet resilience, not a disaster in progress.',
 camera:'Level passage through a debris field. Fragments are distant landmarks, not ledges aligned with the bottom row.',
 portrait:'Cluster three broken arc pieces above the HUD, with a small lit fragment below-right of the actions. Leave the middle entirely open; omit extra chips before shrinking the signature pieces.',
 question:'Should the surviving shelter be an observatory lens or a small conservatory? Start with a single round lens/window so it reads at small scale without a whole building.',
 layers:[
  {name:'Cold distant night',purpose:'The large open space between remnants.',assets:['sr-space'],motion:'Still.'},
  {name:'Broken planetary arc',purpose:'Makes the fragments feel like one former world.',assets:['sr-far-arc'],motion:'Still; distant scale should feel immense.'},
  {name:'Three shaped fragments',purpose:'Nearer silhouettes repeat the same geological bands.',assets:['sr-fragment-a','sr-fragment-b','sr-fragment-c'],motion:'At most 2 points of separation drift; no tumbling.'},
  {name:'Surviving lens',purpose:'A small sign of care and continued life.',assets:['sr-shelter','sr-window'],motion:'Window warms once; never blinks like a warning.'},
  {name:'Near mineral shard',purpose:'Links distant geology to a nearer plane.',assets:['sr-near-shard'],motion:'A faint local dust pass, no impacts.'}
 ],
 assets:[
  ['sr-space','Opaque blue-black space',1,'Full viewport','Sparse stars only at margins.'],
  ['sr-far-arc','Distant broken planetary curve',2,'Left / portrait upper edge','Three separated contour portions with matching strata; deep low contrast.'],
  ['sr-fragment-a','Large banded remnant',3,'Left mid margin','Complete form; no flat top parallel to the board.'],
  ['sr-fragment-b','Thin curved remnant',3,'Upper-left / portrait upper-right','Shares curvature and geology with the large remnant.'],
  ['sr-fragment-c','Shelter-bearing remnant',3,'Right / portrait below actions','Small distant mass; its apparent top must not become a play platform.'],
  ['sr-shelter','Round observatory lens housing',4,'Attached to fragment C','One curved silhouette; no elaborate buildings or telescope sweeping.'],
  ['sr-window','Warm circular window',4,'Registered to housing','Separate glow; matte rim keeps it from reading as a collectible.'],
  ['sr-near-shard','Cropped geological fragment',5,'Lower-left edge','Same strata, darker and simpler; no collision route.']
 ],
 props:[
  {name:'Surviving lens shelter',why:'Gives the broken world hope and a specific inhabitant-scale detail.',behavior:'A soft light warms behind the round window for 3 seconds, then returns to its baseline.',quiet:'The window remains dimly lit.'},
  {name:'Banded remnant',why:'Its repeated strata imply the history of a single planet without exposition.',behavior:'A tiny nearby dust thread drifts past, showing depth while the remnant stays steady.',quiet:'Use a still dust trace or omit it.'}
 ],
 beats:[
  {name:'Arrival',caption:'Separate fragments describe the missing planet’s curve.',change:'Large gaps carry the image. No explosion or arrival through dangerous debris.'},
  {name:'Settled play',caption:'The lit shelter is small but visible; the remnants hang almost still.',change:'The field is stable. The scene reads as an old place, not an imminent hazard.'},
  {name:'Someone is still there',caption:'A warm light briefly strengthens inside the distant lens.',change:'One 3-second local accent, unrelated to score or input. No distress signal.'}
 ],
 reject:'An exploding planet, rubble everywhere, aggressive spires, a flashing distress beacon or fragments directly supporting the stars.'
},
{
 id:'garden',name:'The Night Garden',subtitle:'Open air above a luminous alien canopy',
 premise:'The travelers float well above a nocturnal forest. Broad unfamiliar leaves overlap far below; attached lantern pods and a small winged silhouette make this a living planetary night.',
 silhouette:'Large branching fans and dangling oval pods, seen from above and beside.',palette:['#091c29','#163e48','#36636b','#8aa7a0','#c4bc85'],paletteNote:'Deep teal and blue-violet foliage with tiny pale mint and warm-ivory lights. Avoid bright green surfaces or anything that resembles daytime grass.',
 camera:'An elevated oblique view through open air, not a top-down garden board. Canopy fragments enter at the corners with dark air between them.',
 portrait:'Keep one canopy fan in the upper-left sky and a second below-right of the actions. The pod stays attached to its branch; do not float it near the playable stars.',
 question:'Can the vegetation read as alien at thumbnail scale while remaining gentle? Favor broad branching silhouettes; remove fine leaves before increasing brightness.',
 layers:[
  {name:'Planetary night',purpose:'Dark air and a few distant stars establish a real sky.',assets:['ng-sky'],motion:'Still.'},
  {name:'Atmospheric veil',purpose:'Depth between the travelers and the forest far below.',assets:['ng-mist'],motion:'Very slow 2-point shift at the margins.'},
  {name:'Alien canopy',purpose:'Broad fan-shaped branches identify the ecology.',assets:['ng-canopy-a','ng-canopy-b'],motion:'At most 1° sway at an offscreen stem pivot.'},
  {name:'Lantern pod and glider',purpose:'One attached plant light and one small living silhouette.',assets:['ng-pod','ng-pod-light','ng-glider-body','ng-glider-wings'],motion:'One slow wing opening near the pod; no flight across the field.'},
  {name:'Near spores',purpose:'Two soft drifting specks suggest air between depth planes.',assets:['ng-spore'],motion:'At most two visible; a short local arc, never star-shaped.'}
 ],
 assets:[
  ['ng-sky','Opaque nocturnal atmosphere',1,'Full viewport','No horizon under the bottom row; avoid a garden floor.'],
  ['ng-mist','Distant cool mist',2,'Outer edges','Low contrast; do not obscure cast or controls.'],
  ['ng-canopy-a','Broad branching fan',3,'Left / portrait upper-left','Complete branch, pivot at offscreen stem; few large lobes.'],
  ['ng-canopy-b','Narrower canopy silhouette',3,'Right / portrait lower-right','Different species silhouette with consistent lighting.'],
  ['ng-pod','Attached oval lantern pod',4,'Canopy B branch tip','Include stem and shell; no detached collectible shape.'],
  ['ng-pod-light','Light within pod shell',4,'Registered to pod','Low-intensity inner glow, no floating halo.'],
  ['ng-glider-body','Small seed-moth body',4,'Near pod, outside field','One simple body silhouette, no face; paired wing attachment points.'],
  ['ng-glider-wings','Seed-moth wing pair',4,'Attached to body','Separate left/right wings with pivots at the thorax; quiet pose closed.'],
  ['ng-spore','Soft asymmetrical spore',5,'Corner air only','One reusable alpha sprite; no five-point silhouette.']
 ],
 props:[
  {name:'Attached lantern pod',why:'A visible local light source explains the nearby leaf edges and makes the ecology specific.',behavior:'Steady light; a slight plant sway only. No pulsing cluster of collectible-looking objects.',quiet:'Hold the branch and its glow still.'},
  {name:'Seed-moth glider',why:'A tiny inhabitant makes the setting feel alive without becoming another cast member.',behavior:'Open and close its wings once over 4 seconds beside the pod, then settle. Do not cross the game.',quiet:'Keep the wings in their closed silhouette.'}
 ],
 beats:[
  {name:'Arrival',caption:'Large canopy fans far below establish height and a planetary atmosphere.',change:'The dark open air is the route. Leaves never encircle the field as a tray.'},
  {name:'Settled play',caption:'An attached lantern pod lights a few neighboring edges.',change:'A quiet, localized light source; the forest remains darker than the cast.'},
  {name:'A visitor opens its wings',caption:'One tiny glider beside the pod unfolds and settles.',change:'A single 4-second silhouette change at the edge. No new character, touch target or reward.'}
 ],
 reject:'A flowerbed beneath the stars, mushrooms as pedestals, floating collectible pods, bright foliage or swarms of insects.'
},
{
 id:'ringdrift',name:'Ringdrift',subtitle:'Passing through the shadow of an immense ringed planet',
 premise:'The cast crosses a quiet region beside a ringed planet. Broad parallel arcs, a small shepherd moon and a distant version of the Moonwake sail imply an enormous navigable system.',
 silhouette:'A dark planetary limb crossed by two or three sweeping parallel arcs.',palette:['#080f23','#26364c','#788da5','#c4d3d6','#bd8b99'],paletteNote:'Blue-black shadow, icy cyan rings and a narrow dusty-rose rim. Warm gold is limited to the very distant sail’s lantern.',
 camera:'Oblique view beside the rings. The arcs wrap the planet at one coherent angle; no horizontal ring shelf beneath the cast.',
 portrait:'Crop the planet and ring system together into the upper sky. Put the small shepherd moon below-right of the actions. Do not bend the rings into a border around the field.',
 question:'How can the rings remain unmistakable on a phone without becoming a decorative frame? Test broad elliptical arcs in the top corner before adding any ice detail.',
 layers:[
  {name:'Deep shadow',purpose:'Open dark space inside the planet’s shadow.',assets:['rd-space'],motion:'Still.'},
  {name:'Planet and rear ring',purpose:'Draw the rear band first, then the planet and rim in front of it.',assets:['rd-ring-far','rd-planet','rd-rim'],motion:'Still.'},
  {name:'Near ring band',purpose:'A foreground arc completes the same orbital perspective.',assets:['rd-ring-near'],motion:'Still overall; only a local edge glint may travel.'},
  {name:'Shepherd moon and sail',purpose:'Two scale references link this stop to the wider journey.',assets:['rd-moon','mw-hull','mw-sail','mw-lantern'],motion:'Sail held mostly still; use a smaller, more distant placement than Moonwake.'},
  {name:'Near ice sliver',purpose:'A cropped piece of the ring material at a nearer distance.',assets:['rd-ice'],motion:'A 3-second local glint, not a moving star or shower trail.'}
 ],
 assets:[
  ['rd-space','Opaque deep-space base',1,'Full viewport','Darkest of the set; sufficient separation from dark stars.'],
  ['rd-planet','Dark planet body',2,'Left / portrait upper-left','Complete circular silhouette; separate from rings.'],
  ['rd-rim','Narrow planetary rim light',2,'Registered to planet','Muted rose alpha, no full glowing outline.'],
  ['rd-ring-far','Far elliptical ring band',2,'Registered to planet', 'Draw behind the planet body within plane 2; share the near band’s orbital perspective.'],
  ['rd-ring-near','Near elliptical ring band',3,'Registered to planet','Own alpha and local glint mask; leave broad negative space.'],
  ['rd-moon','Small shepherd moon',4,'Right / portrait below actions','Complete round body; same light direction as planet.'],
  ['mw-hull','Reuse Moonwake hull and mast',4,'Distant right margin','Reuse only after its silhouette is accepted; no second craft design.'],
  ['mw-sail','Reuse Moonwake sail',4,'Attached to reused mast','Scale uniformly with hull; keep attachment and pivot.'],
  ['mw-lantern','Reuse Moonwake lantern',4,'Hull attachment','Lower intensity at this distance.'],
  ['rd-ice','Near cropped ice sliver',5,'Lower-left edge','Simple dark shape and a separate glint region.']
 ],
 props:[
  {name:'Shepherd moon',why:'A modest round body makes the rings’ enormous scale legible.',behavior:'Still; no obvious orbit during a round.',quiet:'Identical still pose.'},
  {name:'Distant chart-sail',why:'A restrained recurrence from Moonwake makes the universe feel connected.',behavior:'A small lantern remains visible, with no repeated sail flourish in this setting.',quiet:'Identical still pose; omit fine sail movement.'}
 ],
 beats:[
  {name:'Arrival',caption:'Parallel rings cross the planet’s dark limb at one strong angle.',change:'The orbital geometry establishes the location even without color.'},
  {name:'Settled play',caption:'A small shepherd moon and distant sail reveal the scale.',change:'Large forms stay still; the rings are scenery, never a board frame.'},
  {name:'Ice catches the light',caption:'One short section of a ring edge brightens and fades.',change:'A 3-second local glint outside the field. No long comet trail or shower-like direction cue.'}
 ],
 reject:'A ring-shaped playfield frame, a bright diagonal through the stars, spinning planets, or meteor rain that resembles incoming gameplay.'
}
];
