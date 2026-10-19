// Offline packaging only. The generated front artwork is not repainted.
// Usage: NODE_PATH=<bundled node_modules> node prepare.cjs <output-fragment.html>
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');

function simplify(points, tolerance) {
  if (points.length < 3) return points;
  const a = points[0], b = points[points.length - 1];
  let max = 0, index = 0;
  for (let i = 1; i < points.length - 1; i++) {
    const p = points[i], dx = b[0] - a[0], dy = b[1] - a[1];
    const t = Math.max(0, Math.min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy || 1)));
    const distance = Math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy);
    if (distance > max) { max = distance; index = i; }
  }
  return max > tolerance ? [...simplify(points.slice(0, index + 1), tolerance).slice(0, -1), ...simplify(points.slice(index), tolerance)] : [a, b];
}

async function main() {
  const master = path.join(__dirname, 'glyph-master.png');
  const { data, info } = await sharp(master).raw().toBuffer({ resolveWithObject: true });
  const { width: w, height: h } = info;
  const labels = new Int16Array(w * h), components = [];
  for (let p = 0; p < labels.length; p++) {
    if (labels[p] || data[p * 4 + 3] < 128) continue;
    const id = components.length + 1, queue = [p]; labels[p] = id;
    let x0 = w, y0 = h, x1 = 0, y1 = 0;
    for (let i = 0; i < queue.length; i++) {
      const k = queue[i], x = k % w, y = Math.floor(k / w);
      x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y);
      for (const n of [x > 0 ? k - 1 : -1, x < w - 1 ? k + 1 : -1, y > 0 ? k - w : -1, y < h - 1 ? k + w : -1]) {
        if (n >= 0 && !labels[n] && data[n * 4 + 3] >= 128) { labels[n] = id; queue.push(n); }
      }
    }
    components.push({ id, area: queue.length, x0, y0, x1, y1 });
  }
  const top = components.filter(c => c.area > 5000 && c.y0 < 560).sort((a, b) => a.x0 - b.x0);
  const bottom = components.filter(c => c.area > 5000 && c.y0 >= 560).sort((a, b) => a.x0 - b.x0);
  if (top.length !== 5 || bottom.length !== 6) throw Error('Unexpected source components; inspect generation before repackaging.');
  const groups = [...top.map(c => [c]), [bottom[0], bottom[1]], ...bottom.slice(2).map(c => [c])];
  const characters = Array.from('Relay!+128');
  const glyphs = groups.map((parts, index) => {
    const ids = new Set(parts.map(p => p.id));
    const x0 = Math.min(...parts.map(p => p.x0)) - 3, y0 = Math.min(...parts.map(p => p.y0)) - 3;
    const x1 = Math.max(...parts.map(p => p.x1)) + 4, y1 = Math.max(...parts.map(p => p.y1)) + 4;
    const step = 3, gw = Math.ceil((x1 - x0) / step), gh = Math.ceil((y1 - y0) / step);
    const mask = new Uint8Array(gw * gh);
    for (let y = 0; y < gh; y++) for (let x = 0; x < gw; x++) {
      const sx = x0 + x * step + 1, sy = y0 + y * step + 1;
      mask[y * gw + x] = ids.has(labels[sy * w + sx]) ? 1 : 0;
    }
    const edges = new Map(), occupied = (x, y) => x >= 0 && y >= 0 && x < gw && y < gh && mask[y * gw + x];
    const add = (a, b) => { const key = a.join(','); if (!edges.has(key)) edges.set(key, []); edges.get(key).push(b); };
    for (let y = 0; y < gh; y++) for (let x = 0; x < gw; x++) if (occupied(x, y)) {
      if (!occupied(x, y - 1)) add([x, y], [x + 1, y]);
      if (!occupied(x + 1, y)) add([x + 1, y], [x + 1, y + 1]);
      if (!occupied(x, y + 1)) add([x + 1, y + 1], [x, y + 1]);
      if (!occupied(x - 1, y)) add([x, y + 1], [x, y]);
    }
    const contours = [];
    while (edges.size) {
      const first = edges.keys().next().value, start = first.split(',').map(Number), loop = [start];
      let key = first;
      for (let n = 0; n < 50000; n++) {
        const options = edges.get(key); if (!options) break;
        const next = options.pop(); if (!options.length) edges.delete(key);
        loop.push(next); key = next.join(','); if (key === first) break;
      }
      if (loop.length > 12) {
        const half = Math.floor(loop.length / 2);
        const points = [...simplify(loop.slice(0, half + 1), .65).slice(0, -1), ...simplify(loop.slice(half), .65).slice(0, -1)];
        contours.push(points.map(([x, y]) => [x * step, y * step]));
      }
    }
    return { character: characters[index], rect: [x0, y0, x1 - x0, y1 - y0], contours };
  });
  const geometry = { sourceSize: [w, h], glyphs, sourceSHA256: crypto.createHash('sha256').update(fs.readFileSync(master)).digest('hex') };
  fs.writeFileSync(path.join(__dirname, 'registration.json'), JSON.stringify(geometry));
  const webp = await sharp(master).webp({ quality: 90, alphaQuality: 100, effort: 6 }).toBuffer();
  const template = fs.readFileSync(path.join(__dirname, 'specimen.template.html'), 'utf8');
  const output = template.replace('__GEOMETRY__', JSON.stringify(geometry)).replace('__ATLAS__', `data:image/webp;base64,${webp.toString('base64')}`);
  if (Buffer.byteLength(output) >= 1000000) throw Error('Fragment exceeds inline size limit.');
  fs.writeFileSync(process.argv[2], output);
  console.log(JSON.stringify({ output: process.argv[2], bytes: Buffer.byteLength(output), glyphs: glyphs.map(g => ({ character: g.character, rect: g.rect, contours: g.contours.length })), sourceSHA256: geometry.sourceSHA256 }, null, 2));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
