"""Original Soft Landing round-two lettering. No fonts or external packages."""
from pathlib import Path
R=Path(__file__).resolve().parent
# Fuller bowls, shorter crossbars, rising f shoulder, descending paired l tails.
letters=[(0,'M61 48 C49 34 18 35 16 51 C13 67 58 61 60 80 C62 101 28 110 11 92'),(72,'M24 15 V80 Q24 103 45 96 M9 44 H43'),(128,'M62 45 V99 M61 63 C53 34 15 39 14 73 C13 108 52 113 61 83'),(203,'M15 99 V45 M15 66 Q25 39 49 45'),(264,'M22 99 V31 Q22 4 49 14 M9 46 H47'),(326,'M62 45 V99 M61 63 C53 34 15 39 14 73 C13 108 52 113 61 83'),(408,'M17 13 V84 Q17 101 31 101'),(459,'M17 19 V93 Q17 110 33 110')]
paths=''.join(f'<path transform="translate({x} 10)" d="{d}"/>' for x,d in letters)
glint='<path d="M532 8 Q536 29 549 34 Q536 39 532 60 Q528 39 515 34 Q528 29 532 8Z"/>'
def make(treatment):
    defs=''
    fill='#f4f1ff'
    back=''
    if treatment=='pearl':
        defs='<linearGradient id="pearl" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#fffdf5"/><stop offset=".55" stop-color="#f4f1ff"/><stop offset="1" stop-color="#bcb6ed"/></linearGradient>'
        fill='url(#pearl)'
        back=f'<g transform="translate(0 5)" fill="none" stroke="#675c9e" stroke-width="17" stroke-linecap="round" stroke-linejoin="round">{paths}</g>'
    elif treatment=='ink': fill='#171c3c'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="566" height="154" viewBox="0 0 566 154" role="img" aria-label="Starfall Soft Bloom custom wordmark"><defs>{defs}</defs>{back}<g fill="none" stroke="{fill}" stroke-width="17" stroke-linecap="round" stroke-linejoin="round">{paths}</g><g fill="{fill}">{glint}</g></svg>\n'
for treatment in ['flat','pearl','ink']:
    (R/f'wordmark-soft-bloom-{treatment}.svg').write_text(make(treatment))
print('Generated three Soft Bloom SVG treatments')
