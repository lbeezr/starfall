// Static art review. LandingGeometry.swift and StarCast.swift remain the runtime owners.
(() => {
  const viewports = {
    phone: { label: 'Phone portrait', width: 393, height: 852, sourceWidth: 887, sourceHeight: 1774 },
    'tablet-portrait': { label: 'iPad portrait', width: 768, height: 1024, sourceWidth: 1086, sourceHeight: 1448, assetPrefix: 'LanternLandingTabletPortrait' },
    'tablet-landscape': { label: 'iPad landscape', width: 1024, height: 768, sourceWidth: 1448, sourceHeight: 1086, assetPrefix: 'LanternLandingTabletLandscape' }
  };
  const bodiesPerColumn = [2, 4, 3, 5, 3, 4, 3];
  const families = ['Spark', 'Sunny', 'Pip', 'Twinkle', 'Nova'];
  const aquaGroup = new Set(['2,1', '3,1', '4,1', '3,2', '3,3']);
  const neighbors = { '2,0': 'Pip', '3,0': 'Sunny', '4,0': 'Twinkle', '1,1': 'Nova', '2,2': 'Sunny', '4,2': 'Nova', '3,4': 'Pip' };
  const percentStates = [0, 25, 50, 75, 100];
  const stateNames = ['A clear need', 'The first response', 'Light reconnects', 'Almost welcoming', 'Purpose restored'];
  const landing = window.STARFALL_WORLD.locations.find(location => location.id === 1);
  const $ = id => document.getElementById(id);
  const query = new URLSearchParams(location.search);
  const requested = Number(query.get('state'));
  let percent = query.has('state') && percentStates.includes(requested) ? requested : 100;
  let viewport = Object.hasOwn(viewports, query.get('view')) ? query.get('view') : 'phone';
  if (['partly', 'dense', 'empty'].includes(query.get('density'))) $('density').value = query.get('density');

  function nameAt(column, row) {
    const key = `${column},${row}`;
    return aquaGroup.has(key) ? 'Spark' : neighbors[key] ?? families[(column * 2 + row * 3) % families.length];
  }

  function renderSample() {
    const canvas = viewports[viewport];
    // Mirror the shared native mapping at these reference point sizes. Scenery
    // never changes the board sample, column count or row direction.
    const side = Math.min(canvas.width - 12, Math.max(308, canvas.height - 420), 620);
    const field = { x: (canvas.width - side) / 2, y: (canvas.height - side) / 2, side };
    const step = side / 7;
    const density = $('density').value;
    const heights = density === 'empty' ? Array(7).fill(0) : density === 'dense' ? Array(7).fill(7) : bodiesPerColumn;
    const layer = $('cast');
    layer.replaceChildren();
    const positions = [];
    for (let column = 0; column < 7; column++) {
      for (let row = 0; row < heights[column]; row++) {
        const name = nameAt(column, row);
        const holder = document.createElement('div');
        // The shared review renderer assumes docs/design/environments/<study>/.
        // Normalize its asset prefix for this shallower folder before creating DOM.
        holder.innerHTML = window.StarfallConceptCast.star(name).replaceAll('src="../../../../App/', 'src="../../../App/');
        const star = holder.firstElementChild;
        const x = field.x + (column + .5) * step;
        const y = field.y + (6 - row + .5) * step;
        // Native ordinary-star canvas: radius .35*step, 256px canvas / 212px silhouette.
        const spriteSide = step * .7 * 256 / 212;
        Object.assign(star.style, { left: `${x / canvas.width * 100}%`, top: `${y / canvas.height * 100}%`, width: `${spriteSide / canvas.width * 100}%` });
        star.dataset.row = row;
        star.dataset.column = column;
        star.dataset.family = name;
        layer.append(star);
        positions.push({ column, row, name, x, y });
      }
    }
    const count = positions.length;
    $('sample-caption').textContent = count ? `${count} stars · seven columns` : 'Environment only · board position unchanged';
    $('stage').setAttribute('aria-label', `${canvas.label}: Lantern Landing at ${percent} percent restored${count ? ` with ${count} crystal stars arranged in seven gameplay columns` : ', environment only'}. Static composition concept, not a running game.`);
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
    window.lanternBoardReview = { viewport, canvas: { width: canvas.width, height: canvas.height }, percent, density, count, field, step, positions, guides: $('show-geometry').checked };
  }

  function selectState(value) {
    percent = value;
    const index = percentStates.indexOf(percent);
    const canvas = viewports[viewport];
    const suffix = String(percent).padStart(3, '0');
    const path = canvas.assetPrefix ? `../../../App/Assets.xcassets/${canvas.assetPrefix}${suffix}.imageset/scene.png` : `background-${suffix}-v2.png`;
    $('image-error').hidden = true;
    $('background').width = canvas.sourceWidth;
    $('background').height = canvas.sourceHeight;
    $('background').src = path;
    $('full-size').href = path;
    $('state-kicker').textContent = `${percent}% · ${stateNames[index]}`;
    $('state-description').textContent = landing.states[index];
    document.querySelectorAll('[data-state]').forEach(button => button.setAttribute('aria-pressed', String(Number(button.dataset.state) === percent)));
    renderSample();
  }

  function selectViewport(value) {
    viewport = value;
    $('review').dataset.viewport = viewport;
    document.querySelectorAll('button[data-viewport]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.viewport === viewport)));
    selectState(percent);
  }
  $('background').addEventListener('error', () => { $('image-error').hidden = false; });
  $('background').addEventListener('load', () => { $('image-error').hidden = true; });
  document.querySelectorAll('[data-state]').forEach(button => button.addEventListener('click', () => selectState(Number(button.dataset.state))));
  document.querySelectorAll('button[data-viewport]').forEach(button => button.addEventListener('click', () => selectViewport(button.dataset.viewport)));
  $('density').addEventListener('change', renderSample);
  $('show-geometry').addEventListener('change', renderSample);
  selectViewport(viewport);
})();
