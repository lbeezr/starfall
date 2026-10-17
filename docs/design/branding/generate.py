"""Regenerate original vector branding studies; Python standard library only.
Design studies only: no app resources or project membership are changed.
"""
from pathlib import Path
from html import escape
import math

ROOT = Path(__file__).resolve().parent
INK = '#f4f1ff'
# Original hand-drawn centerlines. No font is embedded or required by the marks.
GLYPHS = {
's': (56, 'M47 43 C39 33 12 32 10 47 C7 62 46 57 47 73 C48 91 19 96 8 83'),
't': (38, 'M16 15 V73 Q16 92 34 85 M4 38 H33'),
'a': (62, 'M49 39 V88 M49 53 C44 31 9 32 8 63 C7 94 42 100 49 75'),
'r': (42, 'M10 88 V39 M10 58 Q18 33 36 39'),
'f': (40, 'M14 88 V27 Q14 6 35 12 M4 39 H33'),
'l': (27, 'M10 10 V74 Q10 87 19 88'),
}

def mark(color=INK, variant='soft'):
    if variant == 'orbit':
        ds=['M51 14 C22 -4 3 20 17 36 L44 53 C65 73 30 96 8 76', 'M69 7 H123 M96 7 V86', 'M135 86 L163 7 L191 86 M145 60 H181', 'M208 86 V7 H230 C263 7 263 47 230 47 H208 M230 47 L261 86', 'M281 86 V7 H326 M281 45 H316', 'M338 86 L366 7 L394 86 M348 60 H384', 'M411 7 V86 H453', 'M470 7 V86 H512']
        return '<g transform="translate(12 18)" fill="none" stroke="'+color+'" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">'+''.join(f'<path d="{d}"/>' for d in ds)+'</g>'
    x=10; out=[]
    for i,c in enumerate('starfall'):
        w,d=GLYPHS[c]
        dy=3 if i==6 else 9 if i==7 else 0
        out.append(f'<path transform="translate({x} {dy+12})" d="{d}"/>')
        x+=w+7
    return f'<g fill="none" stroke="{color}" stroke-width="11" stroke-linecap="round" stroke-linejoin="round">'+''.join(out)+'</g><path fill="'+color+'" d="M435 10 Q438 29 449 33 Q438 37 435 55 Q432 37 421 33 Q432 29 435 10Z"/>'

def svg(w,h,body,title,defs=''):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" aria-labelledby="title"><title id="title">{escape(title)}</title><defs>{defs}</defs>{body}</svg>\n'

def save(name,w,h,body,title,defs=''):
    (ROOT/name).write_text(svg(w,h,body,title,defs))

DEFS='''<linearGradient id="sky" x2=".7" y2="1"><stop stop-color="#090e2b"/><stop offset="1" stop-color="#2e1a4a"/></linearGradient><radialGradient id="aura"><stop stop-color="#7161b9" stop-opacity=".36"/><stop offset="1" stop-color="#7161b9" stop-opacity="0"/></radialGradient><linearGradient id="spark" x2=".65" y2="1"><stop stop-color="#d8ffff"/><stop offset=".45" stop-color="#60dff3"/><stop offset="1" stop-color="#278abc"/></linearGradient><linearGradient id="sunny" x2=".6" y2="1"><stop stop-color="#fff5b0"/><stop offset=".55" stop-color="#ffce51"/><stop offset="1" stop-color="#f99835"/></linearGradient>'''

def star(x,y,s=1,kind='spark',face=True,angle=0):
    d='M0 -68 Q9 -20 18 -13 L56 0 L18 14 Q8 24 0 68 Q-9 24 -18 14 L-56 0 L-18 -13 Q-9 -20 0 -68Z'
    if kind=='sunny':
        pts=[(math.sin(i*math.pi/5)*(64 if i%2==0 else 35),-math.cos(i*math.pi/5)*(64 if i%2==0 else 35)) for i in range(10)]
        d='M'+' L'.join(f'{a:.2f} {b:.2f}' for a,b in pts)+'Z'
    body=f'<path d="{d}" fill="url(#{kind})" stroke="{ "#bdffff" if kind=="spark" else "#fff0a2"}" stroke-width="2.5" stroke-linejoin="round"/>'
    if face:
        body+='''<g fill="#19203c"><ellipse cx="-12" cy="-3" rx="4.1" ry="7.5"/><ellipse cx="12" cy="-3" rx="4.1" ry="7.5"/><path d="M-7 13 Q0 23 7 13" fill="none" stroke="#19203c" stroke-width="3" stroke-linecap="round"/></g><g fill="#fff"><ellipse cx="-13" cy="-6" rx="1.3" ry="2"/><ellipse cx="11" cy="-6" rx="1.3" ry="2"/></g>'''
    return f'<g transform="translate({x} {y}) rotate({angle}) scale({s})">{body}</g>'

def sky(w,h):
    out=f'<path fill="url(#sky)" d="M0 0H{w}V{h}H0Z"/><ellipse cx="{w*.5}" cy="{h*.52}" rx="{w*.8}" ry="{h*.48}" fill="url(#aura)"/>'
    for i in range(28):
        x=(i*137+31)%(w-32)+16; y=(i*191+47)%(h-50)+25
        out+=f'<circle cx="{x}" cy="{y}" r="{.8 if i%4 else 1.3}" fill="#d8dbfa" opacity="{.18 if i%3 else .45}"/>'
    return out

def text(x,y,s,content,color='#c5c7dd',extra=''):
    return f'<text x="{x}" y="{y}" font-family="-apple-system, Helvetica, sans-serif" font-size="{s}" fill="{color}" {extra}>{escape(content)}</text>'

def logo_at(x,y,w,variant='soft'):
    return f'<g transform="translate({x} {y}) scale({w/(540 if variant=="orbit" else 450)})">{mark(variant=variant)}</g>'

save('wordmark.svg',450,132,mark(),'Starfall — Soft Landing custom wordmark')
save('wordmark-ink.svg',450,132,mark('#090e2b'),'Starfall — single-color dark wordmark')
save('wordmark-orbit.svg',540,132,mark(variant='orbit'),'Starfall — Night Observatory alternative wordmark')

cover=sky(390,844)+logo_at(49,149,292)+text(195,267,14,'A little light. A sky of your own.',extra='text-anchor="middle"')
cover+='<path d="M268 298 Q258 360 218 408" fill="none" stroke="#b0edff" stroke-opacity=".15" stroke-width="2"/>'
cover+=star(195,437,1.15)+star(94,543,.40,'sunny',angle=-15)+star(291,572,.33,angle=18)
cover+='<rect x="47" y="675" width="296" height="56" rx="20" fill="#b0edff"/>'+text(195,710,17,'Play','#090e2b','text-anchor="middle" font-weight="600"')
cover+=text(195,773,13,'Settings',extra='text-anchor="middle"')
save('cover-soft-landing.svg',390,844,cover,'Soft Landing — cover concept, not implemented UI',DEFS)
launch=sky(390,844)+star(195,362,.65,face=False)+logo_at(78,451,234)
save('launch-quiet.svg',390,844,launch,'Quiet native launch composition — static concept',DEFS)
loading=sky(390,844)+star(195,362,.65)+logo_at(78,451,234)+text(195,575,14,'Gathering starlight',extra='text-anchor="middle"')
for i in range(3): loading+=f'<circle cx="{181+i*14}" cy="599" r="2.5" fill="#b0edff" opacity="{1-i*.3}"/>'
save('loading-starlight.svg',390,844,loading,'Starlight loading — optional genuine-work state, static frame',DEFS)
for kind in ['spark','sunny']:
    body=sky(1024,1024)+star(512,505,4.7 if kind=='spark' else 4.9,kind)
    save(f'icon-{kind}.svg',1024,1024,body,f'{kind.title()} icon exploration — opaque unmasked source',DEFS)

# Board uses the same canonical SVGs, with local IDs isolated by nested SVG images in HTML.
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Starfall / Soft Landing</title><style>*{box-sizing:border-box}body{margin:0;background:#0b1026;color:#f4f1ff;font:15px/1.6 -apple-system,BlinkMacSystemFont,Arial,sans-serif}main{max-width:1380px;margin:auto;padding:64px 52px}small,.eyebrow{color:#a8b7d3;letter-spacing:.18em;font-size:11px;text-transform:uppercase}h1{font-size:48px;line-height:1.08;font-weight:500;letter-spacing:-.04em;margin:15px 0 20px}h2{font-size:26px;font-weight:500;margin:0}p{color:#bec4dc;max-width:680px}header{display:flex;justify-content:space-between;gap:50px;padding-bottom:45px;border-bottom:1px solid #29304b}header p{max-width:430px}.section{margin-top:44px}.marks{display:grid;grid-template-columns:1.3fr 1fr;gap:22px;margin-top:20px}.card{border:1px solid #303650;border-radius:22px;padding:27px;background:#121830}.card img{width:100%;height:140px;object-fit:contain;margin:24px 0}.light{background:#f4f1ff}.light small{color:#545b79}.screens{display:grid;grid-template-columns:repeat(3,1fr);gap:28px;margin-top:25px}.screens img{width:100%;border-radius:28px;border:1px solid #3c3d5b}.screens h3{font-size:16px;margin-bottom:4px;font-weight:500}.screens p{font-size:13px;margin-top:4px}.icons{display:flex;gap:38px;align-items:start;margin-top:25px}.icon{width:150px}.icon img{width:112px;border-radius:25px}.icon p{font-size:12px}.sizes{display:flex;align-items:center;gap:12px}.sizes img{border-radius:22%;margin:0}.note{border-left:2px solid #b0edff;padding-left:18px;margin-top:28px}footer{margin-top:42px;padding-top:20px;border-top:1px solid #29304b;color:#9ca8c8;font-size:12px}@media(max-width:700px){main{padding:30px 20px}header{display:block}.marks,.screens{grid-template-columns:1fr}.icons{flex-wrap:wrap}h1{font-size:36px}}</style><main><header><div><div class="eyebrow">Starfall · Brand exploration 01 · 17 October 2026</div><h1>Soft landing.<br>A little light, with personality.</h1></div><p>A quiet night sky meets the expressive new cast. Custom rounded lettering gives the game a warmer signature; a single falling glint adds motion without making the title hard to read.</p></header><section class="section"><small>01 / The signature</small><div class="marks"><div class="card"><small>A · Soft Landing / Recommended</small><img src="wordmark.svg" alt="Custom lowercase Starfall wordmark"><p>Open counters, soft terminals, and two gently descending l stems. The glint is an accent; every letter stays intact.</p></div><div class="card"><small>B · Night Observatory / Alternative</small><img src="wordmark-orbit.svg" alt="Thin uppercase Starfall alternative"><p>More celestial and architectural. Quieter, but less connected to the friendly cast and less robust when small.</p></div></div><div class="card light" style="margin-top:22px;padding:18px 30px"><small>A / Single-color proof — no gradients or font dependency</small><img src="wordmark-ink.svg" alt="Dark wordmark on moonlight" style="height:82px;margin:12px 0"></div></section><section class="section"><small>02 / Arrival sequence</small><h2>One composition, three honest states.</h2><div class="screens">'''
for name,title,desc in [('cover-soft-landing.svg','Cover / A welcoming sky','The character earns the spotlight. One clear Play action; settings stay secondary. Tagline is exploration copy.'),('launch-quiet.svg','Launch / Quiet continuity','Static mark and silhouette only. Match the real first frame; no spinner, CTA, or manufactured delay.'),('loading-starlight.svg','Loading / Only when needed','A proposed real-work state, not an extra screen to add by default. No fake progress percentage.')]:
    html+=f'<article><img src="{name}" alt="{title}"><h3>{title}</h3><p>{desc}</p></article>'
html+='''</div></section><section class="section"><small>03 / The home screen</small><h2>Keep the glass, or introduce the cast?</h2><div class="icons"><div class="icon"><img src="../../../scripts/starfall-app-icon.svg" alt="Existing glass icon"><p>Current · Approved glass<br>Continuity; more jewel-like.</p></div><div class="icon"><img src="icon-spark.svg" alt="Spark candidate icon"><p>A · Spark / Recommended<br>Aqua signature, friendly face.</p></div><div class="icon"><img src="icon-sunny.svg" alt="Sunny candidate icon"><p>B · Sunny<br>Warm and approachable; more familiar silhouette.</p></div><div><small>Spark / Size proof</small><div class="sizes" style="margin-top:22px"><img src="icon-spark.svg" width="60" height="60" alt="Spark at 60 pixels"><img src="icon-spark.svg" width="40" height="40" alt="Spark at 40 pixels"><img src="icon-spark.svg" width="24" height="24" alt="Spark at 24 pixels"></div><p style="font-size:12px;max-width:240px">Masks here are presentation only. Source icons are opaque square SVGs; native exports and Home Screen testing remain pending.</p></div></div><p class="note">Recommendation: develop Soft Landing + Spark. Keep the approved icon until a native size comparison supports replacing it. The vector cast studies interpret the existing characters; runtime artwork remains authoritative.</p></section><footer>Original vector studies · No font files, paid assets, app changes, or new dependencies · Static design review, not simulator or accessibility acceptance</footer></main></html>'''
(ROOT/'index.html').write_text(html)
print('Generated 8 SVG studies and index.html')
