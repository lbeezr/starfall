// Static art review. LandingGeometry.swift and StarCast.swift remain runtime owners.
(() => {
  const viewports = {
    phone: { label: 'Phone portrait', width: 393, height: 852, sourceWidth: 887, sourceHeight: 1774, assetPrefix: 'RibbonCrossing' },
    'tablet-portrait': { label: 'iPad portrait', width: 768, height: 1024, sourceWidth: 1086, sourceHeight: 1448, assetPrefix: 'RibbonCrossingTabletPortrait' },
    'tablet-landscape': { label: 'iPad landscape', width: 1024, height: 768, sourceWidth: 1448, sourceHeight: 1086, assetPrefix: 'RibbonCrossingTabletLandscape' }
  };
  const samples = { partly: [2, 4, 3, 5, 3, 4, 3], crowded: [7, 6, 5, 7, 5, 6, 4], dense: Array(7).fill(7), empty: Array(7).fill(0) };
  const families = ['Spark', 'Sunny', 'Pip', 'Twinkle', 'Nova'];
  const aquaGroup = new Set(['2,1', '3,1', '4,1', '3,2', '3,3']);
  const neighbors = { '2,0': 'Pip', '3,0': 'Sunny', '4,0': 'Twinkle', '1,1': 'Nova', '2,2': 'Sunny', '4,2': 'Nova', '3,4': 'Pip' };
  const percentStates = [0, 25, 50, 75, 100];
  const scores = [0, 5, 9, 14, 18];
  const stateNames = ['The route is broken', 'The first anchor', 'Stitching reconnects', 'One seam remains', 'Neighbors can cross'];
  const crossing = window.STARFALL_WORLD.locations.find(place => place.id === 2);
  const $ = id => document.getElementById(id);
  const query = new URLSearchParams(location.search);
  const requestedState = Number(query.get('state'));
  const requestedScore = Number(query.get('score'));
  let score = query.has('score') && Number.isFinite(requestedScore) ? Math.max(0, Math.min(18, Math.round(requestedScore))) :
    query.has('state') && percentStates.includes(requestedState) ? scores[percentStates.indexOf(requestedState)] : 18;
  let viewport = Object.hasOwn(viewports, query.get('view')) ? query.get('view') : 'phone';
  let percent = 100;
  if (Object.hasOwn(samples, query.get('density'))) $('density').value = query.get('density');

  function nameAt(column, row) {
    const key = `${column},${row}`;
    return aquaGroup.has(key) ? 'Spark' : neighbors[key] ?? families[(column * 2 + row * 3) % families.length];
  }

  function renderSample() {
    const canvas = viewports[viewport];
    // Mirror the existing seven-column native mapping at reference point sizes.
    const side = Math.min(canvas.width - 12, Math.max(308, canvas.height - 420), 620);
    const field = { x: (canvas.width - side) / 2, y: (canvas.height - side) / 2, side };
    const step = side / 7;
    const density = $('density').value;
    const positions = [];
    $('cast').replaceChildren();
    for (let column = 0; column < 7; column++) {
      for (let row = 0; row < samples[density][column]; row++) {
        const name = nameAt(column, row);
        const holder = document.createElement('div');
        // Shared renderer assumes environments/<study>; normalize only its asset root.
        holder.innerHTML = window.StarfallConceptCast.star(name).replaceAll('src="../../../../App/', 'src="../../../App/');
        const star = holder.firstElementChild;
        const x = field.x + (column + .5) * step;
        const y = field.y + (6 - row + .5) * step;
        const spriteSide = step * .7 * 256 / 212;
        Object.assign(star.style, { left: `${x / canvas.width * 100}%`, top: `${y / canvas.height * 100}%`, width: `${spriteSide / canvas.width * 100}%` });
        Object.assign(star.dataset, { row, column, family: name });
        $('cast').append(star);
        positions.push({ column, row, name, x, y });
      }
    }
    const count = positions.length;
    const progress = Math.round(score / 18 * 100);
    $('sample-caption').textContent = count ? `${count} stars · seven columns` : 'Environment only · board position unchanged';
    $('stage').setAttribute('aria-label', `${canvas.label}: Ribbon Crossing, ${score} of 18 light, ${progress} percent restored, ${percent} percent artwork${count ? `, ${count} crystal stars in seven gameplay columns` : ', environment only'}. Static composition concept, not a running game.`);
    $('canvas-caption').textContent = `${canvas.width} × ${canvas.height} reference canvas`;
    $('geometry-description').textContent = `A ${side} × ${side} field is centered at x=${field.x}, y=${field.y}.`;
    const lines = [];
    for (let i = 1; i < 7; i++) {
      const x = field.x + step * i, y = field.y + step * i;
      lines.push(`M${x} ${field.y}V${field.y + side}`, `M${field.x} ${y}H${field.x + side}`);
    }
    $('geometry').setAttribute('viewBox', `0 0 ${canvas.width} ${canvas.height}`);
    $('geometry').innerHTML = `<rect x="${field.x}" y="${field.y}" width="${side}" height="${side}"/><path d="${lines.join(' ')}"/>`;
    $('geometry').toggleAttribute('hidden', !$('show-geometry').checked);
    window.ribbonBoardReview = { viewport, canvas: { width: canvas.width, height: canvas.height }, score, progress, percent, density, count, field, step, positions, guides: $('show-geometry').checked };
  }

  function selectScore(value) {
    score = Math.max(0, Math.min(18, Math.round(value)));
    const index = scores.reduce((current, threshold, next) => score >= threshold ? next : current, 0);
    percent = percentStates[index];
    const canvas = viewports[viewport];
    const path = `../../../App/Assets.xcassets/${canvas.assetPrefix}${String(percent).padStart(3, '0')}.imageset/scene.png`;
    $('background').width = canvas.sourceWidth;
    $('background').height = canvas.sourceHeight;
    if ($('background').getAttribute('src') !== path) {
      $('image-error').hidden = true;
      $('background').src = path;
    }
    $('full-size').href = path;
    $('score').value = score;
    $('score-output').textContent = `${score} / 18 light · ${Math.round(score / 18 * 100)}%`;
    $('score').setAttribute('aria-valuetext', `${score} of 18 starlight, ${Math.round(score / 18 * 100)} percent restored`);
    $('state-kicker').textContent = `${percent}% scene · ${stateNames[index]}`;
    $('state-description').textContent = crossing.states[index];
    document.querySelectorAll('[data-state]').forEach(button => button.setAttribute('aria-pressed', String(Number(button.dataset.state) === percent)));
    renderSample();
  }

  function selectViewport(value) {
    viewport = value;
    $('review').dataset.viewport = viewport;
    document.querySelectorAll('button[data-viewport]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.viewport === viewport)));
    selectScore(score);
  }
  $('background').addEventListener('error', () => { $('image-error').hidden = false; });
  $('background').addEventListener('load', () => { $('image-error').hidden = true; });
  document.querySelectorAll('[data-state]').forEach(button => button.addEventListener('click', () => selectScore(scores[percentStates.indexOf(Number(button.dataset.state))])));
  document.querySelectorAll('button[data-viewport]').forEach(button => button.addEventListener('click', () => selectViewport(button.dataset.viewport)));
  $('score').addEventListener('input', event => selectScore(Number(event.target.value)));
  $('density').addEventListener('change', renderSample);
  $('show-geometry').addEventListener('change', renderSample);
  selectViewport(viewport);
})();
