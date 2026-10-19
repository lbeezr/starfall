// Approved location names/order; proposed storyboard notes for the concept explorer.
// Design data only; this file is not part of the app target.
window.STARFALL_WORLD = {
  "title": "Starfall",
  "subtitle": "A journey to bring the light back",
  "status": "Map and Murk approved; restoration storyboards proposed · 18 October 2026",
  "premise": "Murk travels from place to place, swallowing the starlight that keeps each small realm alive. The star cast rains down to share its light, restore each place, and follow the trail to Murk’s hoard.",
  "regions": [
    {
      "id": 1,
      "name": "Soft Skies",
      "range": "01–03",
      "tone": "Welcome, movement and the first small victories",
      "materials": "Cloud cloth, cream ceramic, rosewood and lavender ribbons"
    },
    {
      "id": 2,
      "name": "Wild Moons",
      "range": "04–06",
      "tone": "Life, flowing water and a quieter kind of wonder",
      "materials": "Leafy moonstone, mint water, opal frost and soft roots"
    },
    {
      "id": 3,
      "name": "Clockwork Belt",
      "range": "07–09",
      "tone": "Craft, music and a world starting to move again",
      "materials": "Rounded copper, slate, golden glass and warm timber"
    },
    {
      "id": 4,
      "name": "Night’s Edge",
      "range": "10–12",
      "tone": "Approach the source of the gloom and return the stolen light",
      "materials": "Dark glass, pale petals, silver moonstone and restrained aurora"
    }
  ],
  "locations": [
    {
      "id": 1,
      "name": "Lantern Landing",
      "region": 1,
      "x": 6.8,
      "y": 77.8,
      "verb": "Rekindle",
      "purpose": "Give the little stars a safe place to gather.",
      "states": [
        "A leaning lantern mast stands over a cold, faded landing dock. The gangway is visible but quiet.",
        "A small wick catches. One warm reflection reaches the nearest plank.",
        "Light reconnects the dock’s star-shaped fittings; the mast straightens and pennants loosen.",
        "The dock is almost welcoming. Only the lantern’s upper chamber remains dark.",
        "The lantern opens fully and casts a welcoming circle. The star cast gathers beneath it."
      ],
      "puzzle": "Introduce an ordinary legal clear and the connection between collected light and restoration.",
      "story": "First theft vignette: Murk spots the lantern, drinks its light, gloats and leaves.",
      "payoff": "A safe, glowing gathering place.",
      "connection": "The lit landing reveals the broken Ribbon Crossing."
    },
    {
      "id": 2,
      "name": "Ribbon Crossing",
      "region": 1,
      "x": 47.95,
      "y": 76.8,
      "verb": "Reconnect",
      "purpose": "Join two separated banks of cloud.",
      "states": [
        "Loose ribbon spans hang between two small cloud banks. A visible gap interrupts the route.",
        "The first anchor lights and a short section unfurls.",
        "Two spans rise toward one another; stitched star patterns reconnect.",
        "Almost the entire crossing holds its shape. The final middle seam is still loose.",
        "The final seam joins and the crossing is restored."
      ],
      "puzzle": "Make the consequence of freeing a crowded column easy to recognize.",
      "story": "Murk’s smoky trail points across the gap; no repeated theft scene.",
      "payoff": "The restored ribbon reconnects the two cloud banks.",
      "connection": "The repaired crossing reaches Kite Harbor."
    },
    {
      "id": 3,
      "name": "Kite Harbor",
      "region": 1,
      "x": 73.7,
      "y": 78.1,
      "verb": "Launch",
      "purpose": "Give stranded paper-kite boats their wind again.",
      "states": [
        "Folded boats sit at a still harbor, sails drooping and mooring stars unlit.",
        "Light returns to the nearest mooring and one sail lifts.",
        "Several sails unfold; breeze draws long curves through the harbor flags.",
        "The lead boat is ready except for its dark mast star.",
        "The mast catches light and the kite fleet lifts gently into the sky."
      ],
      "puzzle": "A first combined round: notice useful groups while keeping room for arrivals.",
      "story": "Murk sees the fleet take off, double-takes and streaks away toward the next region.",
      "payoff": "A small departure ceremony with a clear destination.",
      "connection": "The fleet carries the cast to Seed Moon."
    },
    {
      "id": 4,
      "name": "Seed Moon",
      "region": 2,
      "x": 75.1,
      "y": 58.4,
      "verb": "Awaken",
      "purpose": "Help a tiny bare moon grow shelter.",
      "states": [
        "A tightly curled seed rests in a small cracked moon, its root patterns barely visible.",
        "One root tip lights and reaches into a seam.",
        "Roots reconnect below the surface and a shoot rises.",
        "Leaves unfold around a still-closed central bud.",
        "The bud opens into a glowing canopy with a little sheltered space beneath."
      ],
      "puzzle": "Use the existing growth rule to make larger stars feel valuable; no new gardening mechanic.",
      "story": "A short arrival shows the stars noticing life rather than another villain interruption.",
      "payoff": "A moon that can shelter its inhabitants.",
      "connection": "The awakened roots guide the route toward Silver Pools."
    },
    {
      "id": 5,
      "name": "Silver Pools",
      "region": 2,
      "x": 42.7,
      "y": 57.4,
      "verb": "Restore flow",
      "purpose": "Reconnect a sequence of suspended pools.",
      "states": [
        "Dry bowl-like terraces sit beneath a silent water arch. Pale tide marks show where water belongs.",
        "The first basin fills and reflects a small patch of color.",
        "A thin stream crosses to a second pool; lily steps lift into place.",
        "The pools connect, but the upper arch still holds a motionless droplet.",
        "The arch releases its water thread; a continuous silver cascade feeds every pool."
      ],
      "puzzle": "Explore clearing order and the effect of settling survivors, only where an authored sequence makes the choice visible.",
      "story": "A few stolen-color flecks in the water hint that the cast is following the right trail.",
      "payoff": "One uninterrupted flow through the whole place.",
      "connection": "The stream points toward Frostfruit Orchard."
    },
    {
      "id": 6,
      "name": "Frostfruit Orchard",
      "region": 2,
      "x": 5.9,
      "y": 57.4,
      "verb": "Revive",
      "purpose": "Wake an orchard without melting away its winter identity.",
      "states": [
        "Glass-like branches carry opaque, silent bell fruit. The snow remains soft and readable.",
        "One fruit becomes translucent and gives a small pulse.",
        "Light travels along branches; a few fruit lanterns sway.",
        "Most fruit glows, while the high central cluster remains closed.",
        "The last cluster opens into a brief gentle chime and a drift of luminous seeds."
      ],
      "puzzle": "Introduce an authored dark-star obstruction and a readable neighboring clear; dark stars are not yet villain minions.",
      "story": "A brief Murk appearance tries to take the newly glowing fruit; the released chime startles him away.",
      "payoff": "A living winter orchard, still cool and wintry.",
      "connection": "One drifting seed lights the path into the Clockwork Belt."
    },
    {
      "id": 7,
      "name": "Sunwheel Mill",
      "region": 3,
      "x": 7.23,
      "y": 38,
      "verb": "Restart",
      "purpose": "Return a little mill to useful motion.",
      "states": [
        "Rounded copper vanes hang still above a cold mill. Its light channels are empty.",
        "The center bearing glows and a single vane twitches.",
        "The wheel completes a slow turn; short channels begin carrying light.",
        "The wheel turns steadily, but the outlet remains dark.",
        "The outlet opens and the mill sends one golden pulse along the route."
      ],
      "puzzle": "Create a round where clearing for space and preserving a useful group have distinguishable consequences.",
      "story": "The light pulse is a sign that places can help one another recover.",
      "payoff": "A purposeful mechanism working again.",
      "connection": "The mill’s pulse reaches the nearby Bell Choir."
    },
    {
      "id": 8,
      "name": "Bell Choir",
      "region": 3,
      "x": 41.3,
      "y": 37.76,
      "verb": "Harmonize",
      "purpose": "Let separated voices answer each other.",
      "states": [
        "Three large hanging chimes sit out of alignment, their star-shaped clappers dull.",
        "The smallest chime settles into place and lights.",
        "A second chime answers with a visible pulse; the frame relaxes into alignment.",
        "The first two share a rhythm. The largest chime is still waiting.",
        "The final chime answers and all three perform one short phrase before settling."
      ],
      "puzzle": "Offer more than one useful clear and test whether players can explain their choice; sound never encodes a required move.",
      "story": "Murk listens from the edge, irritated that the world is becoming cheerful behind him.",
      "payoff": "A brief ensemble performance that also reads with sound off.",
      "connection": "The shared pulse wakes the departure star at Starferry Station."
    },
    {
      "id": 9,
      "name": "Starferry Station",
      "region": 3,
      "x": 70.9,
      "y": 38,
      "verb": "Depart",
      "purpose": "Carry the cast across the dark gap ahead.",
      "states": [
        "A little ferry waits on an unlit circular launch rail; its folded canopy is still.",
        "Platform lights come on and the ferry rises slightly.",
        "The canopy unfurls and the circular rail begins to glow.",
        "Everything is ready except the departure beacon.",
        "The beacon lights and the ferry makes a short luminous departure arc."
      ],
      "puzzle": "A region capstone combining established matching, growth and space management without adding a new rule.",
      "story": "Murk’s trail is visible beyond the gap; the cast chooses to follow.",
      "payoff": "A tangible journey into the final region.",
      "connection": "The ferry arrives at Aurora Falls."
    },
    {
      "id": 10,
      "name": "Aurora Falls",
      "region": 4,
      "x": 78.6,
      "y": 18,
      "verb": "Release",
      "purpose": "Free a ribbon of sky that has become still.",
      "states": [
        "A pale curtain hangs frozen over a dark glass arch, its colors barely visible.",
        "A small patch of aqua moves within the curtain.",
        "Color begins traveling in separate bands; the arch regains detail.",
        "The bands nearly connect, but a knot at the top holds the flow.",
        "The knot releases and the aurora falls in one gentle, continuous ribbon."
      ],
      "puzzle": "A calmer readable round after the region capstone; darkness must not increase input or identification difficulty.",
      "story": "The aurora reveals a glimpse of the hoard ahead, so the destination becomes clear.",
      "payoff": "Large-scale movement returning without a camera shake.",
      "connection": "The moving light reveals Petal Beacon."
    },
    {
      "id": 11,
      "name": "Petal Beacon",
      "region": 4,
      "x": 43.26,
      "y": 17.5,
      "verb": "Reveal",
      "purpose": "Find the way to the stolen light.",
      "states": [
        "A flower-shaped tower closes around a dark central lens.",
        "The lowest petals brighten and begin to part.",
        "Half the tower opens and the lens catches a small reflection.",
        "The lens gathers light; one final ring of petals obscures the path.",
        "The last petals open and a narrow beam reveals the route into Hollow Crown."
      ],
      "puzzle": "A final preparation round with clearly signaled pressure and a recoverable obstruction.",
      "story": "Murk briefly tries to hide his hoard behind his body, then retreats when the beam finds him.",
      "payoff": "The destination becomes visible through the player’s work.",
      "connection": "The beam connects directly to Hollow Crown."
    },
    {
      "id": 12,
      "name": "Hollow Crown",
      "region": 4,
      "x": 6.84,
      "y": 15.43,
      "verb": "Return",
      "purpose": "Restore the light reservoir and release what Murk hoarded.",
      "states": [
        "A cracked ring surrounds a hollow reservoir, crowded with light trapped by Murk’s hoard.",
        "One segment reconnects and a small current begins circulating.",
        "Several segments join; the trapped colors separate into readable streams.",
        "The ring is almost whole. One gap keeps the reservoir from releasing the light.",
        "The last segment joins; the reservoir opens, stolen light returns across the map, and Murk deflates with a small startled hiccup."
      ],
      "puzzle": "A satisfying final test of established rules. No separate boss health, required timed gesture or surprise objective after 100%.",
      "story": "Proposed chapter ending: Murk loses the hoard and his inflated grandeur; all twelve restored places answer in a gentle wave of light.",
      "payoff": "A complete chapter with a visibly restored universe.",
      "connection": "Return to the restored map; revisit any completed location."
    }
  ]
};
