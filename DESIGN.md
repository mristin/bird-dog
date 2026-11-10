# Bird Dog: Design

*Status: the design is agreed. The pose test (section 8) is being built.*

**Bird Dog is a sailing and detective game for children of about ten, played by doing the "bird dog" exercise in front of a webcam.**
You are a haiduk (Liso, unless you give yourself another name) who lives in Pula for now. Around the year 1600, you sail a small boat across the Adriatic, talk to people in the ports, follow their clues, and spoil the plans of the greedy Aga Grdan, who squeezes the peasants of the coast.
Nobody fights. You win by being clever, fast and kind.

Each mission takes about ten minutes, and most of it is sailing. Every turn of the wheel is a bird-dog hold, so sailing means exercising.
One or two players play **together**, side by side on a split screen, as one crew.

# Game design

## 1. Pillars

1. **The exercise is the controller.** You steer with the bird dog: stretching an arm turns the wheel, and the higher the arm, the harder the turn. The sailing follows *Pirates!*, only slower-paced, since steering with the whole body is harder than with a mouse. Tacking against the wind, dodging corsairs and rocks, and following the changing wind need many turns to both sides.
2. **Detective work, not combat.** The game plays like *Where in the World is Carmen Sandiego?*: you get clues in conversations in a port, work out where to go next, and sail there.
3. **Real geography, real history, gently told.** The coastlines, ports, landmarks, goods, winds and powers are those of around 1600. They are simplified for ten-year-olds, but not made up.
4. **No violence and no humiliation.** Corsairs chase you, but a catch only costs time. The Aga is beaten by evidence, a judge and the people, never by a sword.
5. **Stars are what matters.** After a mission, we show only the stars, never exercise statistics.
6. **Together, not against each other.** With two players, both work on the same mission, share the clues, the clock, the stars and the ducats, and get a bonus for sailing side by side.
7. **Offline and private**, like `head-invaders`, `splash-n-splat` and `ergo-chaos`. The webcam images stay in memory and never leave the computer.

## 2. Setting: the Adriatic around 1600

This is the time of the uskoks of Senj.
Haiduks (in the hinterland), uskoks (in Senj), gusari (corsairs) and agas (Ottoman local lords) all belong to it.
Many powers share one small sea, which gives the clues their variety: every power has its own flag, coins, language, buildings and goods.

* The Republic of Venice holds Istria, Dalmatia, Kotor and Corfu.
* The Habsburgs hold Trieste, Rijeka and Senj.
* The Republic of Ragusa (Dubrovnik) is independent.
* The Ottoman Empire holds Herceg Novi, Bar, Ulcinj, Albania and mainland Greece.
* The Papal States hold Rimini and Ancona.
* The Kingdom of Naples, under the Spanish crown, holds Ortona, Vieste, Bari, Brindisi and Otranto.

### Tone around the history

* Aga Grdan is **one greedy man**, not a stand-in for the Ottomans, the Muslims or anybody else. In every power's ports there are helpful people and a few crooks.
* Agas on the frontier were often local people, so a Slavic nickname ("Grdan", roughly "the ugly-hearted") fits historically and avoids pointing at any ethnic or religious group.
* The final resolution goes through the Ottoman legal system: a *kadı* (judge) in Preveza rules against the Aga once the crew brings the evidence. The empire's own law corrects him.
* Uskoks are the crew's friends and helpers. We don't show their raiding, but the Venetian patrols suspect every small fast boat of being an uskok one.
* Gusari (corsairs) are the "danger" at sea, everywhere on it. They fly a black flag with a skull (and a badge with the skull floats over them), chase you, and if they catch you, they take 20 ducats (or all on board, if fewer; a day, if there are none) and sail off in a random direction. They fear the Venetian patrols and flee from them.
* The Venetian patrols wear a sheriff's star (on the sail, the flag and a floating badge). They are no friends of the haiduks: if they catch you, they take 10 ducats as a bribe (or all on board, if fewer; half a day, if there are none) and sail off in a random direction. They hunt the corsairs near them, for 15 to 25 seconds.

### Ports

The chart covers the Adriatic and the north of the Ionian Sea, down to Preveza.

| Port | Today | Power (c. 1600) | Things for clues |
|---|---|---|---|
| **Pula** | Croatia | Venice | **The captains' home port** (nobody knows where Liso is from, but Liso lives here for now). The Roman Arena, the Arch of the Sergii, Istrian stone |
| Rovinj | Croatia | Venice | The old town on its island (joined to the land only in 1763), the coffin of St. Euphemia washed ashore, Istrian stone for Venice |
| Venice | Italy | Venice | The Doge, the Arsenal, gondolas, glass from Murano |
| Trieste | Italy | Habsburg | Salt, the Habsburg eagle |
| Rijeka | Croatia | Habsburg | The city clock tower, paper and timber trade |
| Senj | Croatia | Habsburg | The Nehaj fortress, the uskoks, the bura wind |
| Pag | Croatia | Venice | The salt pans, the lace makers (for the salt of mission 3) |
| Zadar | Croatia | Venice | The Roman forum, St. Donatus, maraschino cherries |
| **Grebaštica** | Croatia | Venice | A small bay of fishermen, stone walls, figs |
| Šibenik | Croatia | Venice | St. James' Cathedral and its stone heads, the St. Nicholas fortress |
| Split | Croatia | Venice | Diocletian's Palace |
| Hvar | Croatia | Venice | Lavender, the arsenal, the theatre (1612) |
| **Korčula** | Croatia | Venice | The Moreška dance, stonemasons and shipwrights, the Marco Polo legend |
| Ston | Croatia | Ragusa | Salt pans, the long walls, oysters |
| Dubrovnik (Ragusa) | Croatia | Ragusa | Libertas flag, Stradun, the quarantine (Lazaretto) |
| Herceg Novi | Montenegro | Ottoman | The fortress, the entrance to the bay |
| Kotor | Montenegro | Venice | The walls up the mountain, St. Tryphon, the fjord-like bay |
| Ulcinj | Montenegro | Ottoman | The corsair harbour (the gusari base), olive groves |
| Durrës | Albania | Ottoman | The Roman amphitheatre, the start of the Via Egnatia |
| Vlorë | Albania | Ottoman | Sazan island, the Kanina castle |
| **Corfu** | Greece | Venice | The old fortress, St. Spyridon, olives |
| Parga | Greece | Venice | A tiny Venetian town under the castle, oranges and lemons |
| **Preveza** | Greece | Ottoman | The fortress at the narrow strait, the seat of the kadı in our story. **The finale** |
| Rimini | Italy | Papal States | The Roman bridge of Tiberius, the Arch of Augustus |
| Ancona | Italy | Papal States | The Arch of Trajan, the papal keys |
| Ortona | Italy | Naples (Spain) | The bones of St. Thomas the Apostle (brought from Chios in 1258), the Aragonese castle on the cliff |
| Vieste | Italy | Naples (Spain) | The white rock of Pizzomunno, the tip of the Gargano |
| Bari | Italy | Naples (Spain) | The bones of St. Nicholas, the Swabian castle |
| Brindisi | Italy | Naples (Spain) | The Roman column at the end of the Via Appia |
| Otranto | Italy | Naples (Spain) | The cathedral mosaic, the easternmost point of Italy |

Kala Nera is dropped, since it lies in the Aegean and would be too far away. Preveza takes its place as the finale. It is the closest Ottoman town with a fortress just outside the Adriatic.

## 3. Characters

* **The players' captains**, haiduks who live in Pula for now. Nobody knows where Liso is from; Pula is just the home port for now. Each player creates their own captain (section 6):
  * a name, by default **Liso** for player 1 and **Mare**, Liso's sister, for player 2,
  * a gender (haiduk or haidukess),
  * an appearance.

  They are clever and cheerful, and never armed in the pictures. The texts address them by their names and with the right grammatical gender.
* **Aga Grdan.** He is greedy, vain and a bit ridiculous, and he collects double taxes with forged papers.
* **His helpers**, who run away with things and people. Each mission has one or two, and each has easy-to-recognize traits (a red sash, a parrot, a limp, a lute) for the final line-up.
* **People in the ports**: an innkeeper (konobar), a market woman, a fisherman, a harbour master, a monk or an imam, children. They give the clues in the conversations.
* **Baba Stana**, the wise grandmother of Pula. She gives the briefings (in person in Pula, or by carrier pigeon) and the hints.
* **Master Ivan**, the shipwright you rescue in mission 2. From then on, his shipyard in Pula decorates your boats (section 10).
* **Uskok captain Juraj** in Senj. When asked, he scouts ahead and reveals one port.

### The Bird Dog emblem

The captains sail under one flag: **the Bird Dog**. It is the crew's flag, the game's icon and its symbol everywhere (the title screen, the save slots, the stars, the loading screens).

* **The figure:** a dog in the bird-dog pose, seen from the side, with the stretched "arm" (front leg) reaching forward and the stretched hind leg reaching back. The back carries a seagull's wing, so the dog half-flies. The figure is the exercise and the name at once.
* **The shape:** a swallow-tailed pennant, as flown on the boats of the time.
* **The colours:** a cream field with the figure in deep red and a thin red border, so that it reads at a glance on blue water and at 16 px as an icon.
* Each boat flies it from the mast. The players can change the colours in the shipyard, but the emblem stays, so that both boats are recognizably one crew.
* `icon.svg` holds the first version.

## 4. Missions

### Structure of a mission (about 10 minutes)

1. **Briefing** (about 30 s). Baba Stana tells you what happened and gives the first clue. In Pula, she does it in person. When the mission starts in another port, her pigeon brings a letter.
2. **Sail** to the port you think the clue points at (1 to 2 minutes per leg).
3. **A conversation in the port** (about 30 to 45 s). There are no places to choose from. When you enter a port, a local person greets you, and you talk.
   * Every line of the conversation offers 2 or 3 big answer buttons, for example:
     * "Have you seen a man with a red sash?"
     * "Where did he sail to?"
     * "Thank you, goodbye!"
   * The answers give:
     * **destination clues** ("He asked the way to the city where they keep the bones of St. Nicholas" → Bari),
     * **trait clues** ("She had a blue scarf and smelled of lavender"),
     * **items** (a sack of salt, a letter, a seal),
     * or **ducats**.
     You can also buy boosters ("What do you sell?", see section 10).
   * The clues you've collected so far stay in the crew's **logbook**, one button away.
4. **Wrong port?** The local shrugs ("This is the wrong port, captain!", and where to sail), and you've lost the days of the voyage. Baba Stana's pigeon can bring one free hint per mission.
5. After **4 to 6 ports, the finale**: in the last port, you pick the right person out of three, using the traits you collected, or you deliver the items to the right person.
6. **The stars** (1 to 3), for the days left on the mission clock and the wrong ports. There is also a fun fact about a place you visited. There are no exercise statistics.

**The mission clock** counts in days, for example 7 days per mission. Time on the water turns into days, and so do the corsair tolls and the patrol inspections.
Running out is gentle: "The trail went cold. Let's try again!" You restart the mission with no other penalty.

To keep the replays fresh, every mission has a fixed goal and story, but the route and the clue wording are drawn from a pool. A replay goes through 4 to 6 of about 8 possible ports.

### The missions (they unlock in order)

| # | Title | Starts in | Kind | Region | Summary |
|---|---|---|---|---|---|
| 1 | The Bell of Grebaštica | Pula | Find an item, *tutorial* | Pula, Zadar, Grebaštica, Šibenik | The Aga's men "borrowed" the bell of Grebaštica as a "tax". Learn to steer, to talk and to read the clues. Calm wind, a single corsair and a single patrol at a time. |
| 2 | The Shipwright of Korčula | Pula | Find a person | Korčula, Hvar, Split, Zadar, Venice, Pula | Master Ivan hides from the Aga's recruiter. Find him before the recruiter does, and bring him to Pula, where he opens his shipyard and decorates your boats from then on. |
| 3 | Salt for the Winter | Pula | Collect and deliver | Ston, Pag, Trieste, Grebaštica, Senj | The Aga hoards the salt. Buy salt in Trieste and Ston and get it to the villages before winter. Meet the uskoks of Senj, and learn the bura. |
| 4 | Oak for Master Ivan | Pula | Collect and deliver | Rijeka, Senj, Pula | The Aga bought up the oak. Fetch oak from Rijeka and a fir mast from Senj, so that Master Ivan can build boats for the fishermen of Pula. Through the islands of Kvarner. |
| 5 | The Uskok and the Doge | Senj | Collect, deliver and a hearing | Pag, Rijeka, Trieste, Venice | A Venetian patrol caught Juraj. Collect the letters of his friends, answer the questions of the Doge's council, and bring Juraj home. The first hearing. |
| 6 | The Doctor of Ragusa | Split | Find a person and deliver | Dubrovnik, Kotor, Herceg Novi | A fever in the villages. Find the doctor who knows the quarantine of Ragusa, and bring the medicine across the Bay of Kotor. |
| 7 | The Theatre of Hvar | Split | Collect people and deliver | Zadar, Šibenik, Korčula, Hvar | The Aga's men scared the actors away. Bring the jester, the singer and the storyteller to Hvar for the opening of the theatre for everybody. |
| 8 | Across the Sea | Dubrovnik | Deliver | Ancona, Bari, Brindisi, Otranto | Bring the villages' complaint to the Pope's envoy in Ancona and to the Viceroy's man in Bari. The first crossing to Italy, against the wind. |
| 9 | The Pilgrims of St. Nicholas | Bari | Find a person and deliver | Brindisi, Otranto, Dubrovnik | The Aga's men took the pilgrims' money. Find little Luka along the coast of Italy and take him and the pilgrims home to Ragusa across the open sea. |
| 10 | The Corsairs of Ulcinj | Kotor | Find an item | Ulcinj, Durrës, Vlorë | The gusari took the olive oil the villages traded. Talk them into giving it back: the clues tell you what they want in exchange. |
| 11 | The Oranges of Parga | Corfu | A chain of trades and deliver | Parga, Vlorë, Corfu | The Aga wants the oranges of Parga as a tax. Trade a rope for baskets and baskets for the oranges, and bring them to the market of Corfu. |
| 12 | The Forged Ledger | Corfu | The Carmen chase | Corfu, Vlorë, Durrës, Kotor, Dubrovnik… | The Aga's scribe flees with the ledger that proves the double taxes. A chase along the whole coast, ending in a line-up. |
| 13 | The Secret Script | Split | Find a person and deliver | Zadar, Pag, Senj, Rijeka | The scribe wrote the list of the villages in Glagolitic and can not read it any more. Find Don Grgur, who knows the old letters. |
| 14 | The Witnesses | Dubrovnik | Collect people and deliver | Ulcinj, Herceg Novi, Kotor, Corfu | Bring Crooked Mast, Mustafa and Jele to Corfu as witnesses for the judge. |
| 15 | The Kadı of Preveza | Corfu | Finale | Corfu, Parga, **Preveza** | Bring the ledger and the witnesses to the kadı in Preveza. The judge orders the taxes returned. Then the voyage back to Pula and a celebration in the Arena. |

Missions 1 to 3 teach the controls gently, but the corsairs and the Venetian patrols are out in every mission (fewer in mission 1). The missions follow each other as one story: each one wins a friend, a proof or a witness for the hearing before the kadı in the finale.

### How a mission fits into ten minutes

A mission takes about ten minutes: about **five legs** at sea of 1 to 1.5 minutes each (mostly exercise), and about **five port conversations** of 30 to 45 seconds. The speed of the boat is tuned per mission so that the legs stay this long, whatever the distances on the chart.

**The stars** of a mission: three for finishing with at least a third of the mission clock left, two with any days left, one for finishing at all. Every wrong port and every wrong pick in a line-up only costs time, never the mission.

**The line-ups give nothing away:** the crew has to remember the hallmarks it heard (the line-up never repeats them). A wrong pick lets the target slip away to another port: the trail goes on there (`TrailStep.flee`), and the line-up comes again, in a new order. **The routes of the trails are drawn anew** for every mission: a random walk through a pool of ports, every leg 40 to 230 km, the whole route within `TrailStep.max_route_km`, so that the mission clock fits every route.

**The ducats** of a mission come from the barrels and the chests at sea (5 to 15 each), the gratitude in the right ports (10), the riddles (10), the deliveries (20), and the stars at the end (20 per new star, see section 10).

### The facts of the ports

The destination clues are assembled from a clue template ("He asked the way to {fact}.") and a fact of the next port (section 14). Every port has several facts, so that the clues vary between the replays; every fact belongs to exactly one port, which the tests check.

| Port | Facts (as they appear in the clues) |
|---|---|
| Pula | the town with the great Roman arena; the town with the arch of the Sergii; the harbour at the very tip of Istria |
| Venice | the city of the Doge; the city whose streets are canals; the city of the great Arsenal, where they build a galley in a day; the city of the glassblowers of Murano |
| Trieste | the town of the Habsburg salt pans; the harbour of the double-headed eagle at the top of the sea |
| Rijeka | the town with the clock tower of the Habsburgs; the town where the paper and the timber are traded |
| Senj | the town under the Nehaj fortress; the home of the uskoks; the town where the bura blows hardest |
| Pag | the island of the salt pans of Venice; the island of the lace makers |
| Zadar | the town with the round church of St. Donatus; the town on the old Roman forum; the town of the cherry liqueur |
| Grebaštica | the little bay of the fishermen near Šibenik; the village of the figs and the stone walls |
| Šibenik | the town whose cathedral wears a crown of stone heads; the town under the fortress of St. Nicholas |
| Split | the town which grew inside an emperor's palace; the town of Diocletian |
| Hvar | the island of the lavender; the town with a theatre for everybody |
| Korčula | the island town where they dance the Moreška; the town of the stonemasons and the shipwrights; the town where Marco Polo was born, as they say |
| Ston | the town with the longest walls of Ragusa; the salt pans of Ragusa; the town of the oysters |
| Dubrovnik | the free city whose flag says Libertas; the city of the Stradun; the city which keeps its sick guests apart for forty days |
| Herceg Novi | the fortress at the gate of the Bay of Kotor; the town of the mimosa |
| Kotor | the town at the end of the bay which looks like a fjord; the town of St. Tryphon; the town whose walls climb the mountain |
| Ulcinj | the harbour of the corsairs; the town of the olive groves |
| Durrës | the town with the old Roman amphitheatre; the town where the Via Egnatia begins |
| Vlorë | the bay with the island of Sazan; the town under the castle of Kanina |
| Corfu | the island of St. Spyridon; the island of the old fortress on two peaks; the island of the olives of Venice |
| Parga | the little Venetian town under the castle; the town of the oranges and the lemons |
| Preveza | the fortress at the narrow strait; the town where the kadı holds court |
| Rimini | the town with the Roman bridge of five arches; the town of the arch of Augustus |
| Ancona | the town with the arch of Trajan; the harbour of the Pope |
| Ortona | the town where they keep the bones of St. Thomas the Apostle; the town of the castle on the cliff |
| Vieste | the town of the tall white rock in the sea; the town at the tip of the Gargano |
| Bari | the town where they keep the bones of St. Nicholas; the town of the Swabian castle |
| Brindisi | the town at the end of the Via Appia; the town of the Roman column |
| Otranto | the easternmost town of Italy; the town of the great mosaic of the tree of life |

Pag joins the list of the ports (section 2) for the salt of mission 3.

### The missions in detail

Each mission lists its **building blocks** (section 14): `Briefing`, `Trail`, `Collect`, `Deliver`, `Lineup`, `Return` and `Celebration`, plus two which the later missions need: `Trade` (give an item to get another one, in a chain) and `Hearing` (a hand-written conversation in which the players answer questions from their logbook).

#### 1. The Bell of Grebaštica (the tutorial)

* **The goal:** find the church bell which the Aga's men took from Grebaštica as a "tax", and bring it back.
* **Start:** Pula. **Clock:** 6 days. **Ports:** Pula, Zadar, Šibenik, Grebaštica.
* **The sea:** a gentle maestral, at first from behind and then from the side, so that the players learn to steer with an easy wind before they meet a harder one. At most one corsair and one patrol at a time, no clouds.
* **The steps:**
  1. `Briefing` in Pula. Baba Stana: "The children of Grebaštica wrote to me: the Aga's men took their bell and sailed south. They asked the way to the town with the round church of St. Donatus."
  2. `Trail` with a fixed route (Zadar, Šibenik), so that the tutorial always plays the same. In Zadar, a fisherman remembers the boat with the heavy load, its **patched red sail**, and the town "whose cathedral wears a crown of stone heads".
  3. `Lineup` in Šibenik: three boats in the harbour, one with a patched red sail. The players pick it, and the Aga's men hand over the bell with a grumble ("It was only borrowed!").
  4. `Deliver` the bell to Grebaštica, a short leg down the coast.
  5. `Celebration`: the bell rings again over the bay, and the children wave from the stone walls.
* **New for the players:** steering, a port conversation, the logbook, a line-up, a delivery.
* **The fun fact:** the cathedral of St. James in Šibenik was built only of stone, without wood or bricks, and its outer wall carries 71 carved heads of the people of the time.

#### 2. The Shipwright of Korčula

* **The goal:** find Master Ivan, the best shipwright of Korčula, before the Aga's recruiter does, and bring him safely to Pula.
* **Start:** Pula. **Clock:** 21 days. **Ports:** Korčula, then 2 of Hvar, Split, Zadar, Šibenik; then Pula.
* **The sea:** the maestral and, toward the south, the first jugo; the first clouds to row around.
* **The steps:**
  1. `Briefing` in Pula: a letter from Ivan's daughter Katarina: "Father hid from the Aga's recruiter, who wants him to build the Aga's tax boats. He left clues which only friends understand. Start where they dance the Moreška."
  2. `Trail` of three ports from the pool, starting in Korčula. Ivan's friends give the clues: "He bought lavender oil for his tools" (Hvar), "He wanted to see the palace which became a town" (Split), "He went to the merchants of the great Arsenal for oak" (Venice). They also reveal his **traits**: a grey beard, a carpenter's pencil behind his ear, a leather apron.
  3. The recruiter's boat sails the same way and shows on the minichart. If it reaches the last port first, Ivan has moved on once more (one more port, one more day), never a lost mission.
  4. `Lineup` in the last port: three men; the players pick Ivan by his traits.
  5. `Return` to Pula with Ivan on board.
  6. `Celebration`: Ivan opens his shipyard in Pula, which unlocks the decorations of the boats (section 10).
* **New for the players:** clouds, the traits of a person, a rival boat on the minichart.
* **The fun fact:** the shipwrights of Korčula were famous all over the Adriatic, and the stonemasons of the island built in Venice and Dubrovnik.

#### 3. Salt for the Winter

* **The goal:** the Aga hoards the salt, and without salt the villages can not keep their fish and their meat for the winter. Buy two loads of salt and bring them to the villages.
* **Start:** Pula. **Clock:** 13 days. **Ports:** 2 of Ston, Pag, Trieste; then Grebaštica and Senj.
* **The sea:** the bura, strong and gusty around Senj (the first strong wind); the first Venetian patrols, which inspect boats with salt, since Venice keeps the salt trade for itself.
* **The steps:**
  1. `Briefing` in Pula.
  2. `Collect` two loads of salt, from any two of Ston (Ragusa sells at a fair price), Pag (Venice sells, but dearly) and Trieste (the Habsburgs sell, but far to the north). The salt costs ducats, so the players learn to spend them; the conversations tell the prices.
  3. `Deliver` one load to Grebaštica and one to the villages behind Senj.
  4. In Senj, the players meet the uskok captain Juraj, who explains the bura ("When it blows, stay close to the islands"), and who will scout for them from now on.
  5. `Celebration` in Senj.
* **New for the players:** buying, the strong bura, the patrols, the right flag (a booster) against the inspections.
* **The fun fact:** the walls of Ston, more than five kilometres long, were built by Ragusa to protect its salt pans, which still give salt today.

#### 4. Oak for Master Ivan

* **The goal:** the Aga bought up the oak to build his tax boats. Fetch oak and a mast, so that Master Ivan can build new boats for the fishermen of Pula.
* **Start:** Pula. **Clock:** 6 days. **Ports:** Rijeka, Senj, Pula.
* **The sea:** the bura of Kvarner and the Venetian patrols; the islands of Kvarner, where the camera zooms in.
* **The steps:** `Briefing` by Master Ivan; `Collect` the oak from Leopold in Rijeka and a fir mast from Juraj in Senj (in any order); `Deliver` both to Master Ivan in Pula; `Celebration`.
* **The fun fact:** Venice stands on wooden piles of alder, a wood which does not rot in the water, and its houses rest on stone from Istria ([Venice](https://en.wikipedia.org/wiki/Venice)).

#### 5. The Uskok and the Doge

* **The goal:** a Venetian patrol caught Juraj and took him to Venice as a pirate. Speak for him before the Doge's council.
* **Start:** Senj (his sister Ika). **Clock:** 18 days. **Ports:** Pag, Rijeka, Trieste, Venice, Senj.
* **The sea:** the bura of Kvarner and the Venetian patrols.
* **The steps:** `Briefing`; `Collect` the letters of the people Juraj helped (the salt merchant of Pag, Leopold of Rijeka, Gertraud of Trieste); `Deliver` them to Messer Alvise in Venice; a `Hearing` of the council about the letters and the bura; `Deliver` Juraj home to Senj; `Celebration`.
* **New for the players:** the first hearing, which the finale asks again.
* **The fun fact:** the Nehaj fortress in Senj was finished in 1558 on the ruins of churches, monasteries and houses outside the town walls, as a base for the uskoks ([Nehaj Fortress](https://en.wikipedia.org/wiki/Nehaj_Fortress)).

#### 6. The Doctor of Ragusa

* **The goal:** a fever spreads in the villages around the Bay of Kotor. Find Doctor Marin of Ragusa, who knows how to stop it, and bring his medicine across the bay.
* **Start:** Split (the carrier pigeon brings the letter). **Clock:** 12 days. **Ports:** 3 of Korčula, Ston, Dubrovnik, Herceg Novi; then Kotor.
* **The sea:** the jugo, steady and wet; clouds; the first corsairs, coming up from Ulcinj.
* **The steps:**
  1. `Briefing` by pigeon in Split.
  2. `Trail` of three ports: Doctor Marin goes from patient to patient along the coast. The people describe him (a black cap, a bag of herbs, a cheerful laugh).
  3. `Lineup` in the last port: the players find the doctor among three people.
  4. `Collect` the medicine in Dubrovnik (the doctor sends the crew to the apothecary of the Franciscans).
  5. `Deliver` the medicine through the narrow strait of the Bay of Kotor to Kotor: a leg which needs careful steering.
  6. `Celebration` in Kotor.
* **New for the players:** corsairs, a narrow passage, a mission which starts away from Pula.
* **The fun fact:** in 1377, Ragusa was the first city to keep travellers apart for a while before they could enter (a quarantine), to keep illnesses out. The pharmacy of the Franciscans in Dubrovnik, from 1317, still sells medicine today.

#### 7. The Theatre of Hvar

* **The goal:** Hvar opens a theatre for everybody, but the Aga's men scared the actors away. Bring them to Hvar for the opening night.
* **Start:** Split (Lucija's letter by pigeon). **Clock:** 10 days. **Ports:** Zadar, Šibenik, Korčula, Hvar.
* **The sea:** the maestral and the jugo, with clouds.
* **The steps:** `Collect` Pero the jester in Zadar, Dora the singer in Šibenik and Old Toma, the storyteller, in Korčula (passengers, in any order); `Deliver` them to Lucija in Hvar; `Celebration`.
* **The fun fact:** Hvar's theatre opened in 1612 above the town's galley shed; it is one of the oldest public theatres in Europe, paid for by the town for all the people of Hvar ([Hvar (town)](https://en.wikipedia.org/wiki/Hvar_(town)), [Hvar Arsenal](https://en.wikipedia.org/wiki/Hvar_Arsenal)).

#### 8. Across the Sea

* **The goal:** cross the Adriatic to Italy and bring the villages' complaint about the Aga to the Pope's envoy in Ancona and to the Viceroy's man in Bari, who can speak to the Sultan's court.
* **Start:** Dubrovnik. **Clock:** 21 days. **Ports:** Dubrovnik, Ancona, Bari (and, for wrong guesses, Brindisi and Otranto).
* **The sea:** the open sea: long legs against the wind (tacking), storms, and the Venetian patrols, which call the whole Adriatic "the Gulf of Venice".
* **The steps:**
  1. `Briefing` in Dubrovnik: the Rector of Ragusa gives the crew a letter of recommendation.
  2. `Deliver` the complaint and the letter to the Pope's envoy in Ancona. He asks a riddle about his town ("Which emperor's arch stands at our harbour?") and sends the crew on: "Only the Viceroy's man can carry this to Constantinople."
  3. `Trail` of one port: the clue points to "the town where they keep the bones of St. Nicholas".
  4. `Deliver` to the Viceroy's man in Bari, who gives a sealed answer.
  5. `Return` to Dubrovnik with the answer.
  6. `Celebration`: the Rector reads the answer: the Aga will be heard by a judge.
* **New for the players:** the open sea, long tacking legs, a riddle.
* **The fun fact:** the bones of St. Nicholas, the saint of the sailors (and of the children), were brought to Bari by its sailors in 1087.

#### 9. The Pilgrims of St. Nicholas

* **The goal:** the Aga's men took the money of the pilgrims from Ragusa. Find little Luka, who ran off along the coast of Italy, and take everybody home.
* **Start:** Bari, with the pilgrims on board. **Clock:** 11 days. **Ports:** Brindisi and Otranto (in a random order), then Dubrovnik.
* **The sea:** the open sea with storms and the patrols.
* **The steps:** `Trail` of two ports, revealing a straw hat and a wooden whistle; `Lineup` of three ship's boys; `Deliver` the pilgrims and Luka to his mother Pava in Dubrovnik; `Celebration`.
* **The fun fact:** the whole floor of Otranto cathedral is one huge mosaic, made in the 1160s by artists led by a monk called Pantaleon, with a great Tree of Life running along it ([Otranto Cathedral](https://en.wikipedia.org/wiki/Otranto_Cathedral)).

#### 10. The Corsairs of Ulcinj

* **The goal:** the corsairs took the olive oil which the villages traded for the winter. Nobody fights: find out what the corsairs want, and trade the oil back.
* **Start:** Kotor. **Clock:** 12 days. **Ports:** Ulcinj, Durrës, Vlorë, Kotor.
* **The sea:** the jugo, corsairs everywhere (sailing side by side keeps them away), clouds.
* **The steps:**
  1. `Briefing` in Kotor.
  2. In Ulcinj, the corsair captain "Crooked Mast" (a grumpy, but fair old sailor) says: "Oil for oil? No. Bring me a new sail, and you get your oil."
  3. `Trade` chain: the sailmaker of Durrës makes a sail, but wants honey from Vlorë for his cough; the beekeeper of Vlorë gives honey for a sack of salt (from the crew's stores, or bought in Durrës).
  4. `Deliver` the sail to Ulcinj; the captain gives the oil back.
  5. `Return` to Kotor with the oil.
  6. `Celebration`: the captain even sends a warning: "The Aga's scribe sails south with a heavy book. Watch out for him."
* **New for the players:** a chain of trades, many corsairs at once.
* **The fun fact:** the olive trees of the Adriatic grow very old; around Bar in Montenegro stands an olive tree said to be more than two thousand years old.

#### 11. The Oranges of Parga

* **The goal:** the Aga wants the oranges of Parga as a tax. Get them to the market of Corfu, so that the money stays with the people.
* **Start:** Corfu. **Clock:** 15 days. **Ports:** Parga, Vlorë, Corfu.
* **The sea:** the jugo, the corsairs and clouds.
* **The steps:** `Trade` chain: Eleni of Parga gives the oranges for baskets; Ilir of Vlorë weaves baskets, but needs a rope; Spiros, the harbour master of Corfu, gives a rope. `Deliver` the oranges to the market of Corfu; `Celebration`.
* **The fun fact:** Parga was a little Venetian town on the Greek coast for almost 400 years, with Ottoman lands all around it, and it was often raided by its neighbours ([Parga](https://en.wikipedia.org/wiki/Parga)).

#### 12. The Forged Ledger (the chase)

* **The goal:** the Aga's scribe flees with the ledger which proves the double taxes. Chase him along the whole coast, as in *Carmen Sandiego*, and take the ledger.
* **Start:** Corfu. **Clock:** 22 days. **Ports:** 4 of a pool of 8 (Vlorë, Durrës, Ulcinj, Kotor, Herceg Novi, Dubrovnik, Bari, Brindisi), drawn anew for every replay.
* **The sea:** everything at once: changing winds, clouds, corsairs and patrols.
* **The steps:**
  1. `Briefing` in Corfu: the warning of the corsair captain came true.
  2. `Trail` of four ports with the hardest facts: the scribe hides his way well. Every port also gives one of his **traits**: ink-stained fingers, a green hat, spectacles from Venice, a goose quill behind his ear.
  3. `Lineup` in the last port: four people this time.
  4. The scribe gives the ledger up ("I only wrote what he told me!") and promises to tell the truth to the judge.
  5. `Celebration`: the crew holds the proof.
* **New for the players:** the longest trail, a line-up of four, a different route every time.
* **The fun fact:** spectacles were made in Venice since about 1300; the glassmakers of Murano were so precious that they were not allowed to leave the republic.

#### 13. The Secret Script

* **The goal:** the scribe wrote the list of the villages and of the double taxes in the old Glagolitic letters, so that the Aga could not read it, and now he can not read it either. Find a priest who knows the old letters.
* **Start:** Split. **Clock:** 17 days. **Ports:** 3 of Zadar, Pag, Senj and Rijeka; then Split.
* **The sea:** the bura of Kvarner and the patrols.
* **The steps:** `Briefing` by the scribe; `Trail` of three ports, revealing a long white beard, a book with a brass clasp and a walking stick; `Lineup` of four old men; Don Grgur reads the list; `Deliver` it to the scribe in Split; `Celebration`.
* **The fun fact:** Glagolitic is the oldest known Slavic alphabet; on the islands of Kvarner, like Krk, and on the islands near Zadar, Croatian priests and scribes kept writing in it for centuries ([Glagolitic script](https://en.wikipedia.org/wiki/Glagolitic_script)).

#### 14. The Witnesses

* **The goal:** the judge wants to hear witnesses, not only the ledger. Bring them to Corfu, where the voyage to the judge begins.
* **Start:** Dubrovnik (the Rector). **Clock:** 10 days. **Ports:** Ulcinj, Herceg Novi, Kotor, Corfu.
* **The sea:** the corsair coast.
* **The steps:** `Collect` Crooked Mast in Ulcinj, Mustafa, the gatekeeper of Castelnuovo, and Jele, the olive grower of Kotor (in any order); `Deliver` them to Spiros in Corfu; `Celebration`.
* **The fun fact:** the Republic of Ragusa banned the slave trade in 1416, and valued freedom very highly: the word Libertas stands on its flag ([Republic of Ragusa](https://en.wikipedia.org/wiki/Republic_of_Ragusa)).

#### 15. The Kadı of Preveza (the finale)

* **The goal:** bring the ledger and the witnesses to the kadı, the judge, in Preveza, so that the Aga's double taxes go back to the people.
* **Start:** Corfu. **Clock:** 21 days. **Ports:** Corfu, Parga, Preveza; then the long way home to Pula.
* **The sea:** the narrow strait of Preveza, a calm evening sea for the voyage home.
* **The steps:**
  1. `Briefing` in Corfu.
  2. `Collect` the witnesses: Master Ivan (mission 2) waits in Parga, Doctor Marin (mission 6) in Corfu. Old friends come back.
  3. `Deliver` the ledger and the witnesses to Preveza, through the narrow strait.
  4. `Hearing` before the kadı: he asks questions which the players answer from their logbook and from what they lived through ("Which village lost its bell?", "Who hoarded the salt?", "Where did the scribe flee?"). A wrong answer only makes him ask again.
  5. The kadı rules: the Aga gives back the double taxes and loses his post, and the villages are free of him. Aga Grdan is not punished in any cruel way; he goes, grumbling, to look after his goats.
  6. `Return` to Pula: the longest voyage, with a fair wind.
  7. `Celebration` in the Arena of Pula: everybody from the voyage comes (the children of Grebaštica, Ivan, Katarina, Juraj, Doctor Marin, even the corsair captain), the bell of Grebaštica rings, and the crew gets a medal of the Bird Dog.
* **The fun fact:** in the Ottoman Empire, a kadı judged by the law, and the people could bring a complaint even against a powerful aga.

## 5. Controls: the bird dog

### The exercise

You kneel on all fours, facing the camera. You stretch one arm forward and the opposite leg backward, hold, and switch sides. The camera only has to see the head and the hands. **We assume the leg is stretched** and never check it.

### The set-up

* The laptop stands on a table or a chair, with the camera 1.5 to 2.5 m away from the player, a bit higher than the player's back and looking slightly down.
  Then a hand stretched forward appears **above the head** in the image, and a hand on the floor appears below it.
  The pose test (section 8) checks this before we build anything else.
* **With two players**, they kneel side by side. As in `ergo-chaos`, we split the camera image in the middle, and each half belongs to one player. In each half, we track the largest head and ignore everybody else.

### Recognizing the poses

We reuse the YOLOX-Body-Head-Hand detector from `splash-n-splat`. It finds the heads and the hands in one run.

* **Scale:** the height of the head box `h` is the unit of every threshold. That way the game works whether the player kneels close to the camera or far away. If `h` is too small or too large, the game says "come closer" or "move back".
* **The head line** runs low, 5% above the bottom of the face (about the chin). The first tests showed that the line at the top of the head, and then through the middle of the head, were too strict.
* **Hand raised:** the hand's center is above the head line, and within about `4·h` sideways from the head.
* **How hard you steer** follows how high the raised hand is above the head line. It grows from 0 just above the line to full steering at `1.5·h` above it, and it is smoothed so that the wheel turns without jitter. The controls are not binary: a hand stretched a little turns gently, a hand stretched high turns hard.
* **Hand down:** the hand is below the head line, or it isn't detected at all (a hand on the floor is often hidden by the body).
* **The poses**, mirrored, so that the screen matches what the player sees:
  * left hand raised and right hand down → **LEFT**,
  * right hand raised and left hand down → **RIGHT**,
  * both down → **REST**,
  * both raised → **INVALID**. The boat doesn't react, and a gentle hint says "one arm at a time".
* **Smoothing:** a pose counts after it has been stable for 0.12 s, and stops counting after 0.12 s of something else (hysteresis). The first live test showed that 0.3 s felt slow. Brief misses of the detector are bridged by the hand tracker.
* **Calibration** at the start of each leg (3 s): "Get on all fours and look at the camera." We take the resting head size and position, so that a later crawl closer to the camera doesn't break the thresholds.

The pose classifier is a small, pure-C# state machine with no Godot dependency (`BirdDogPoseClassifier`). We unit-test it on the recordings from the pose test.

### Steering and sailing

Each captain's boat is a small, fast uskok-style boat with a sail. There is no rowing: **raising a hand simply steers**, and the wind moves the boat, as in *Pirates!*.

* **Steering:**
  * **The hands push the wheel.** The wheel is pinned to your head, and your stretched arm lifts its side of the rim. While you hold LEFT (the hand on the left of the mirrored picture), it lifts the left side of the wheel, which turns clockwise, and the boat turns to starboard (right). While you hold RIGHT, the wheel turns counter-clockwise, and the boat turns to port (left). This is how a real ship's wheel works, and the wheel never turns against the hand that pushes it.
  * **The higher the raised hand, the harder the turn.** The rate of turning goes from almost nothing (hand just above the nose) to the full rate of about 51° per second (67° felt too twitchy) (hand high above the head), and the wheel turns just as far.
  * The boat turns only while the arm is up. A turn of 90° at the full rate takes about 1.3 s; the play-tests showed that slower turns were frustrating.
  * At REST (hands down), the wheel rolls back to the middle and the boat keeps its course.
* **Sailing, as in *Pirates!*:** the boat always sails, and its speed depends on the angle between its course and the wind:

  | Point of sail | Wind comes from | Speed |
  |---|---|---|
  | Running | behind | 85% |
  | Broad reach | behind, at an angle | 100% (the fastest) |
  | Beam reach | the side | 80% |
  | Close-hauled | ahead, at an angle | 50% |
  | Into the wind | straight ahead (±35°) | 25%, the sail flaps |

  The speed is multiplied by the intensity of the wind: light ×0.6, fresh ×1, strong ×1.3.
  * **Against the wind, you tack:** you zig-zag close-hauled, left and right, which is slow, and is exactly the exercise of both sides. A dotted arc in front of the boat shows the "into the wind" zone, and the sail flaps when you are in it.
  * The boat never stops completely, so a child is never stuck.
  * **The best speed** is 6.75 km/s of the chart (times the `speed_scale` of the mission); the play-tests showed that 3 and then 4.5 km/s felt too slow.
* **Slow-paced:** the boat speeds up and slows down gently (over about 3 s), and it turns gently, so that the slower and coarser body controls are enough. The ships of the corsairs and the patrols are slow too, and the hazards give warning in time.
* **The sail** sets itself. There is no sail trim to learn.

### Ports: hand cursor and fist

In the port, the player kneels up or sits on their heels.

* **Cursor:** the first open hand that shows up in the player's half of the camera controls a cursor (a seagull). The aim mapping comes from `splash-n-splat`'s `HandVisionService`. The cursor is calm and sticky (the play-tests found it jittery and frustrating): it is smoothed strongly and ignores shakes of up to 10 px (`PointSmoother.dead_zone`); on a button, it is drawn towards the middle (it moves only 35% of the hand's way) and leaves only when the hand is clearly beyond the edge (70 px, less for small keys); and it stands still while the fist is held, so that closing the hand never moves it off the button.
* **Click:** close an open hand into a fist and hold it for **1.5 s**. A golden ring fills around the cursor while the fist is held, sparks stream into it, and the card or button under it fills with gold. The rules are strict, so that a calm hand never clicks by itself:
  * a hold starts only when the vision sees an open hand close into a fist (the open-to-fist transition of `GestureStateMachine`); a hand which merely looks like a fist for a while never starts one,
  * the fist must stay clear (a smoothed fist probability of at least 0.75) during the whole hold; brief doubts of up to 0.25 s are forgiven, longer ones empty the ring,
  * a fist clicks only once; the hand opens and closes again for the next click.

  The fists come from our fist classifier of `splash-n-splat` (`FistClassifier`), which was trained on standing players. If kneeling players still trigger false fists, we record them and retrain it (see the contributing guide of `splash-n-splat`).
* The answer buttons are big, with at most 3 per conversation line and at most 5 on a screen (with the logbook and "Set sail"). Hovering grows a button, and clicking it plays a sound.

### Fallbacks

* **Keyboard and mouse** for development and the tests.
  * Player 1 uses A/D to turn the wheel left and right, player 2 uses ←/→, and pressing nothing means REST.
  * In the ports, the mouse and a click.
* Without a camera, the game offers the keyboard mode.

## 6. Screens and HUD

### The start screen

1. **Choose the language:** English first, then the others alphabetically (Deutsch, Español, Français, Hrvatski (po dalmatinski), Italiano, Português, Русский, Shqip, Türkçe), as cards with the name of each language in itself (text, not flags), under the Bird Dog flag and "Choose your language" cycling through all the languages. A pictogram shows how to choose: point with an open hand, hold a fist until the golden ring is full. The choice is remembered for the next start. **(Built: `scenes/language_select/`.)**
2. **Your voyages** (built: `scenes/session_select/`): **Continue** the last voyage (it shows its name, its captains and its stars), start a **New voyage**, or go on with one of the other recent voyages. A voyage which goes on skips straight to the mission select.
3. For a new voyage, **name the voyage** (built: `scenes/session_name/`). The name starts as the date and the time (e.g., "2026-11-07 13:41"), so "OK" is enough; the keyboard on the screen has the letters, the digits, "-", ":" and a space.
4. **Choose 1 or 2 players** and **create the captains**.
5. **The instruction** (below). There is no story intro; the story starts with Baba Stana's briefing in mission 1.
6. **The mission select.**

### The instruction (instead of an intro)

An animation of about 90 s shows how to do the bird dog properly and how it steers the boat.
It plays once for every new crew, and can be watched again at any time from the mission select ("How to steer").

**Part 1: the bird dog, done right** (about 45 s). A **3D figure of the captain**, dressed as a haiduk-sailor (in the looks the player just chose), shows the exercise on the deck of the boat. The camera circles slowly around the figure, so that it is seen from the side (to show the flat back) and from the front (as the webcam sees it). Short captions and arrows mark each point:

1. **Get on all fours:** hands under the shoulders, knees under the hips, back flat like a table.
2. **Look at the floor,** a little ahead of your hands, so that your neck stays long.
3. **Stretch one arm forward and the opposite leg back,** for example the right arm and the left leg, until both are straight and level with your back.
4. **Hold still** for a moment, with your belly tight and your hips level. Don't tip to the side.
5. **Bring them back slowly,** and switch: the other arm and the other leg.
6. **Common mistakes,** each shown briefly with a red ✗ and then the right way with a green ✓:
   * the back sags or arches,
   * the head is thrown up,
   * the hip of the lifted leg rolls open,
   * the leg kicks up too high,
   * the movement is jerky and fast.

The figure moves calmly and smoothly, holding each side for about 2 s.

**Part 2: how it steers the boat** (about 45 s). The screen splits: the animated captain on the left, the boat with the wheel on the right.

1. **The arm on the left of the picture** (as in a mirror) lifts the wheel on the left, so the wheel and the boat turn to the right. **The arm on the right** turns them to the left.
2. **The higher the arm, the harder the turn.** The captain raises the arm slowly from the nose line to high above the head, and the wheel turns farther and farther.
3. **The boat turns as long as the arm is up.** Hands down, and the boat keeps its course.
4. **The wind moves the boat.** Fast with the wind from behind, slow against it. Against the wind, zig-zag: left, right, left, right.
5. **Both arms up at once does nothing.** One arm at a time!

Then the crew goes on to the mission select.

* **Captions:** big, at most one line at a time, in the chosen language, and timed so that a ten-year-old can read them. The movements carry the meaning even without reading.
* **Making it in 3D** (built, `scenes/instruction/`):
  * **The figure** (`Captain3D`) is a toy-like captain built in code from simple rounded shapes, with flat, painted eyes like a toy figure (round eyes which stick out look spooky): a red cap (*crvenkapa*), a white shirt, a blue vest with golden trim, a red sash, dark trousers and *opanci*. There are no downloaded models and no license questions. The joints are plain pivots: the hips, the spine and the chest (so that the back can sag), the neck and the head, the shoulders, the elbows, the hips, the knees and the ankles.
  * **The captain's looks** are colours and parts in code, so the captain creator can change them later.
  * **The poses** (`BirdDogPoses`) are computed rather than keyed by hand: standing, kneeling, on all fours, the bird dog on each side with any arm height, and the mistakes. The arms are given by their angle in the world, so they stay right however the back bends. The captain tweens smoothly between the poses.
  * **The scene:** the deck of the boat with the Bird Dog flag on the mast, the sea (a small water shader), Pula with the Arena in the distance, warm evening light with a little haze, a camera which circles the captain, and the captions on top.
* **Skipping:** only Space skips (an adult at the keyboard). A fist does not skip, since the hands of a player on all fours are often recognized as fists.

### How many captains (built: `scenes/player_count/`)

Two big cards, "1 · One captain" and "2 · Two captains", each with as many Bird Dog flags, chosen with the hand cursor like everything else.

### Creating a captain (built: `scenes/captain_creator/`)

Every player creates their captain on their own half of the screen. A preview of the captain stands on the deck of their boat and changes right away.

* **The name.** It can be typed on the keyboard, or on a big on-screen keyboard with the hand cursor and fist clicks.
  * The on-screen keyboard has the letters of the chosen language, from its `alphabet` in `translations/languages.json`: Latin with č, ć, đ, š, ž, or Cyrillic. The name starts with a capital letter and goes on in small letters, so the players only pick the letters. The default name stays until the first letter, which replaces it as a whole; Delete clears an untouched default as a whole, too.
  * While typing, the keyboard takes the whole panel, with keys as big as possible. The keys are octagons with gaps between them, and only a point inside an octagon counts, so a hand resting between two keys presses neither.
  * A name has 1 to 12 letters.
  * The default is Liso (player 1) or Mare (player 2), written in the language of the game (e.g., Лисо and Маре in Russian), so a click on "Ready!" is enough.
* **The gender:** haiduk or haidukess.
  * It changes the clothes and the hair styles on offer.
  * It also changes the grammatical forms in the texts: in Croatian and Russian the past tense and the adjectives depend on it ("došao/došla", "пришёл/пришла"), and in most languages the word for the captain itself ("Kapitän/Kapitänin", "capitán/capitana"). See "The gender in the texts" in section 11.
* **The appearance:** each option is a row of big buttons with arrows (◀ ▶), and the middle shows the current choice (a swatch of colour or a word):
  * the skin tone (5),
  * the hair style (haiduk: short, curly, ponytail, long; haidukess: braid, bun, long, curly) and the hair colour (5),
  * the cap (the red Lika cap, the tall fur kalpak, a headscarf, a cap with a feather, none),
  * the colour of the vest (*jačerma*) and of the sash (6 each, the dyes of the time: madder red, indigo, verdigris, black, ochre, undyed wool),
  * the face: a moustache, freckles, both or plain (haidukess: freckles or plain),
  * an eye patch: none, over the left eye or over the right eye.
* **Random** mixes new looks, and **Ready!** finishes (**Change** goes back while the other player is still choosing). When all the players are ready, the crew goes on, with no way back.
* **The layout:** the 3D preview (the captain turning slowly on a piece of deck) stands left of the rows. With two players, each player has a narrower panel on their own half of the screen, where they kneel in the mirrored camera picture.
* **The data:** the looks are a plain dictionary (`CaptainOptions`), kept by the `Crew` autoload, so that the save slots (section 7) can store them as they are. The instruction shows the first player's captain.
* **Texts which do not fit** (e.g., in a longer language) shrink until they fit their button.
* The captains can be changed later in the shipyard in Pula, for free.

### The mission select (built: `scenes/mission_select/`)

* For now, a grid of cards, one per mission, with its number, its title and the crew's best stars; a locked mission is greyed out and shows a padlock. Below them, "How to steer" plays the instruction again, and "Voyages" goes back to the voyages. Later, a chart of the Adriatic with a pin for each mission replaces the grid.
* Since the missions are still to be built, a mission opens a placeholder screen with its title and summary, "Back", and "Finish the mission (test)", which records three stars and so unlocks the next mission.
* The missions are described in `data/missions/<nn>_<id>/mission.tres` (`Mission`, see section 15); the translator tools collect all their texts.
* Any finished mission can be replayed.
* Finishing mission *n* unlocks *n*+1.
* The crew's ducats and the shipyard in Pula (from mission 2 on) are reachable from here.

### Rendering fast

The game has to run on old school laptops (we test on an Intel HD Graphics 520) while the camera and the vision run, too. So:

* **What does not move is drawn once:** Godot keeps the drawing commands of a canvas item until it is told to redraw. The coasts, the port icons, the cliffs and the coasts of the minimap are drawn once; only small overlays redraw every frame (the rings of the targets, the surf at the cliffs, the boats and the marks on the minimap).
* **The sea's wave strokes, the reefs and the clouds are shaders** (`sea.gdshader`, `reef.gdshader`, `storm_cloud.gdshader`), so they cost the GPU a little and the CPU nothing. The shaders compute every noise only once per pixel, and the shadows of the clouds use fewer octaves.
* With two storm clouds, a field of reefs and the whole HUD on the screen, the mission screen runs at 60 frames per second on the HD Graphics 520 (about 70 without vsync).

### Two players: a half of the screen each

The two players play **together, as one crew**, but each has **a half of the screen** (960 × 1080), as in `ergo-chaos`: two SubViewports share one world (the chart, the wind, the hazards), and each has a camera which follows its player's boat (`SeaView`).

* **Each player steers their own boat** (red pennant and stripe for the first captain, blue for the second, with "1" and "2" on the main sails) and sees their own HUD in their half: the clue and the target, the days, the food and water, the hull, the ducats and the cargo of **their** boat, the boosters, the wind and the minimap. The panels of the right half are mirrored, so that the webcam fits between the halves at the bottom.
* **The webcam** is one panel at the bottom between the halves, with a line down its middle, as in `ergo-chaos`: the player on the left of the mirrored picture steers the red boat, the one on the right the blue boat. Each player's wheel is pinned to their own head, with a rim in their colour.
* **The boats sail on their own.** There is no leash: one player can follow the story while the other carries errands or fetches provisions.
* **A port is only for the player who enters it.** Its scene opens in that player's half (`StoryCard` in its compact layout), with a hand cursor which follows only that player's hands (the half of the camera picture); the other player sails on meanwhile. The briefing at the start, the meeting at sea and the screen at the end are for both, on the whole screen.
* **Every boat has its own hold** (`BoatHold`): food and water, the hull, the ducats it earned and spent, and its cargo, including **passengers** (Master Ivan rides in the boat which found him) and witnesses. The cargo panel of the HUD shows them as pictures and portraits. A delivery needs the boat which carries the thing or the person: when the other boat comes, the port says so ("Your other boat carries Master Ivan. Meet at sea and hand it over!").
* **Meeting at sea:** when the boats come closer than 4 km, the screen of the meeting opens for both: each side can give the other half of its food and water, ten ducats, or anything and anybody it carries (who carries whom). It opens again only after the boats were 14 km apart.
* **The bonuses for sailing together:** within 8 km, both sail 25% faster and a golden rope is drawn between them, and the corsairs don't dare to come close.
* **The mission clock** runs while a boat is at sea, as fast as the boat which sails the farthest.
* **Without a camera**, A/D steer the red boat and the arrow keys the blue one.

### Errands

While one boat follows the story, the other can earn ducats (`Errands`): in every port, "Any work for us?" brings an offer of the local, e.g., "Could you bring a barrel of wine to Split? They will pay you 25 ducats there." The goods (wine, dried figs, cloth, the lace of Pag, a letter) ride in the boat which took them, can be handed over at sea, and are paid to whichever boat brings them (10 ducats and 5 more for every 20 km). Their ports get a blue ring on the chart and the minimap, and the cargo panel says where the goods go ("a barrel of wine → to Split"); a crew carries at most two errands at a time. Every delivered errand gets its own line of thanks, with the picture of the goods beside it.

**The start port:** after the briefing, every crew is still in the start port, with its merchant and its errands, until it says "Set sail!".

### The people of the regions

The locals and the characters carry the names of their regions: Albanians in the Ottoman ports of the south (Agim in Ulcinj, Besa in Durrës, Ilir in Vlorë, the sailmaker Gjergj, the beekeeper Drita, and the corsair captain Lekë the Crooked Mast), Turks (Mustafa, the gatekeeper of Castelnuovo; Yusuf, a coffee seller of Preveza; the kadı Ahmed Efendi), Austrians in the Habsburg ports (Gertraud, an innkeeper of Trieste; Leopold, a timber merchant of Rijeka; the salt clerk Matthias Hofer), Italians across the sea (Marco in Ancona, Nicola in Bari, and the fishermen, porters and market women of Rimini, Ortona and Vieste, Rosa in Brindisi, Salvatore in Otranto, Zuane the gondolier of Venice), Greeks (Spiros in Corfu, Eleni in Parga), and Croatians, Dalmatians and Ragusans along the eastern coast.

### Where to go

It is the year 1600, but the players are ten: they need not remember the clues. The clue still tells the story ("They asked the way to the town with the round church of St. Donatus"), but the step also names its **target port** (`MissionStep.target_port`), and the game points to it:

* the clue banner says it big and red: "Sail to Zadar!", and the people in the ports say it after the clue, too (`MissionRun.line_then`),
* the key **C** shows the chart of the whole Adriatic (`FullChart`), with the names of all the ports, the target ports in red rings and the ports of the errands in blue rings (the same colours everywhere: on the sea, the minimap, the chart and the arrow; `ChartView.TARGET_COLOR`, `ChartView.ERRAND_COLOR`); the game waits until C (or Esc) closes it,
* the port on the chart gets a pulsing red ring and a red pennant,
* the minimap rings it,
* and when it is off the screen, a golden arrow on a ring around the middle of the screen points to it, with its name.

### Provisions

The food and the water on board run out with the days. The HUD shows them as a column of round tokens, like the cargo, one per **ration** which the ship stows (the gajeta every captain starts with one, a bracera three, a galleon five; see section 10): a barrel of water, a loaf of bread, a wheel of cheese, a salted fish, figs. The crew eats them from the top down; the token in use empties like a clock, and an eaten one stays as a dashed ring. Every port gives **one ration** for free (and the local says "Your crew takes on bread and fresh water." when they were low); a ship with more rations has to buy the others ("Fresh bread and water", section 10).

* **Three rations (a bracera) last `Mission.provisions_days`**, 10.8 days (1080 km, at 100 km a day) by default (the play-tests showed that 2.4 and then 3.6 days ran out too fast): at least 1.2 times the widest crossing of the Adriatic (Bari to Dubrovnik, about 200 km), so that the crew can always cross the sea. `tests/godot/test_missions.gd` checks it for every mission.
* **Running low** (below 30%), the panel blinks, and the crew hears once per leg: "Running low! Stop in a port!" (The gajeta which every captain starts with has a single ration, 3.6 days or 360 km: enough to cross the open sea once, but a long voyage needs a stop in every port on the way, which is one more reason to save for a bigger ship.)
* **Without provisions** (or with a broken hull), a small fishing boat with a red lateen sail comes and tows the crew to the port nearest by sea (not as the crow flies: of the five closest ports, the one with the shortest way), around the islands (`SeaRoute`, A* on a 1 km grid of the chart), clear of the reefs and the clouds (the storms the most; they cost more to sail through, but never block the way, since a hull usually breaks on a reef; when a cloud drifts across the way, the fishermen take another), slowly, while the crew watches, a little bored ("z z z" rises from the boat; `TowBoat`). Towing is half as fast as sailing and costs half a day on top. Nobody starves; the crew just loses time, and maybe a star.
* **Leaving a port,** the boat keeps the heading it came in with, on the far side of the port, unless the land or a reef is right ahead there; then it heads away from the port. **Herceg Novi and Kotor** lie in the same bay, whose way in is too narrow to tack: each has a button "Sail on to …" to the other (`Port.bay_port_id`).
* **The edge of the chart:** beyond its bounds, the world is black, and a boat stops there as at a coast (the land beyond is not on the chart).
* **The port scenes** keep their buttons away from the edges of the screen (at least 200 px from the bottom, 60 px from the sides), where the hand detection is weak.
* So a long mission (e.g., *Across the Sea*) forces the crew to stop in ports on the way to the main target. In mission 1 the legs are short (Pula to Zadar is 140 km), so it only teaches the barrels.

### The view at sea (per player)

```
┌──────────────────────────────────────────────┐
│ 📜 logbook      ☀ Day 3 / 7       WIND (rose)│
│                                   ➶ JUGO ●●○ │
│                                              │
│              ~~~   ⛵   ~~~                  │
│         (top-down sea and coastline)         │
│                                              │
│ ┌─────────────┐                  ┌────────┐  │
│ │ webcam,     │                  │minichart│ │
│ │ mirrored,   │                  └────────┘  │
│ │ with WHEEL  │                              │
│ │ on the head │                              │
│ └─────────────┘                              │
└──────────────────────────────────────────────┘
```

* **The wheel (lower left):** a panel with the mirrored webcam crop of this player (as in `ergo-chaos`) and a ship's wheel drawn on top, **pinned to the player's head**: its center follows the head, and its size follows the head's size. Behind the wheel, the player's face wears the cap of their captain (pulled down to the eyebrows, so that it hides the forehead and the hair on top), the eye patch, the moustache and the freckles, if any. They are composed in a layer of their own, which is faded as a whole (to 45 %), so that the wheel stays clearly visible on top. They are fitted to five landmarks of the face (the eyes, the tip of the nose and the corners of the mouth), which YuNet finds on a small crop around every head that YOLOX detected (about a millisecond per head), so they tilt with the head; without the landmarks, we guess them from the head box.
  * Raising the left hand lifts the left side of the wheel and turns it clockwise (to the right), and raising the right hand turns it counter-clockwise (to the left), the farther the higher the hand. At REST, it rolls back to the middle.
  * The head line is drawn clearly across the wheel at the nose: a dashed golden line with arrows pointing up and the words "Lift your hand above the line". The detected hands are marked with the same symbol as the hand cursor of the menus (a ring with a seagull) and of the same fixed size, whatever the size of the hand in the picture: white when down and green when above the line, so the player sees at once whether the game sees the raised hand. The wheel, the hand markers and the hand cursors of the menus are smoothed (`PointSmoother`): strongly while they move slowly, so that they stand calm instead of jittering with every detection, and only a little while they move fast, so that they do not lag behind a real move.
  * **Reaction:** the wheel must follow the hand without a noticeable delay. A pose counts after 0.12 s, the steering is smoothed over about 0.08 s, and the wheel follows within about 0.06 s.
  * **The wheel must be beautiful.** The pose test draws only a quick sketch; the game's wheel is a crafted piece of art:
    * warm, polished wood with a visible grain, a darker rim and lighter, turned (lathe-shaped) spokes with rounded handles,
    * a brass hub with a small engraved compass rose, and brass bands where the spokes meet the rim,
    * the king spoke (the one on top when the rudder is straight) marked with a wrapped rope, so that the player sees the rudder at a glance,
    * soft shading in the wood and the brass, but no drop shadow and no reflections around it, since a second outline confuses,
    * a little weight in its motion: it eases into a turn and overshoots slightly when it rolls back,
    * small effects: the brass glints when the boat enters a port or picks up a barrel, and water drops fly off in a storm,
    * semi-transparent in the middle, so that the player's face stays visible through it.
    
    It is painted as a layered asset (rim, spokes, hub, rope, highlight) or drawn in a shader, and looks good from 200 to 600 px.
  * When nobody is seen, the wheel greys out and says "Kneel in front of the camera".
* **The wind (upper right),** always visible and impossible to miss:
  * **A big wind rose with an arrow** that shows where the wind blows **to**, relative to the chart (north is up).
  * **The intensity in three levels** (light, fresh, strong), shown as dots, as the colour of the arrow (green, yellow, orange) and as the arrow's thickness.
  * **The name of the wind** by its direction: Bura (NE), Jugo (SE), Maestral (NW), Tramontana (N), Levant (E), Lebić (SW), Oštro (S), Pulenat (W).
  * On the sea itself, the streaks and white caps get denser with stronger wind, and the flag on the mast blows the same way.
* **How the wind changes:**
  * Every 40 to 90 s, the direction changes and the intensity rises or falls by one level.
  * 5 s before a change, the arrow starts to wobble, and the captain calls out, for example "The bura is coming!" or "Jugo is coming!".
  * The wind is the same for both players, and each mission sets its typical winds (the bura around Senj, the jugo in the south, the maestral in summer).
* **The mission clock (top):** the days used and the days left, the ducats on board, and the icons of the active boosters.
* **The minichart (lower right):** the boat, the other player's boat, the known ports, and the corsairs when they are near.

### The port

* The port's picture (the Arena in Pula, the walls of Dubrovnik…) with the local person in front, a speech bubble and the answer buttons.
* The webcam panel stays in the lower left, but without the wheel. It shows the seagull cursor.

## 7. Saving and loading (built: the `Session` autoload, `scenes/session/`)

* **A voyage** is one playthrough of a crew: its name, the crew (the number of players and the looks of the captains) and how far it came in the missions. The players can keep as many voyages as they like; the voyages screen shows the last one to continue and the four most recent others.
* **The file** of a voyage is JSON in `user://saves/<id>.json`, with a format version (so that later versions of the game can convert old saves), the name, the times it was created and updated, the crew, and per mission the best stars and whether it was completed. The id is the date and the time of its creation. A save is written to a temporary file first and then renamed, so that a crash during saving never destroys the last good save. `user://settings.cfg` remembers the last voyage.
* **Which missions are unlocked** is not stored but derived: the first mission is always open, and every completed mission opens the next one. So a save can never disagree with itself.
* **Saving:** when a voyage starts, when the captains are ready, after every mission, and whenever a player presses **F5** ("Saved" shows for two seconds). **F6** loads the last save of the voyage again and goes to the mission select.
* **Later:** the ducats, the decorations and the mission in progress (the plan's seed, the step, the clock, the logbook, the boats) join the file, and an old voyage can be deleted after a confirmation.
* `tests/godot/test_session.gd` checks the saving, the listing, the unlocking and the loading, in a directory of its own.

## 8. The pose test (the first thing we build)

Before the game, we build a small Godot scene, `scenes/tests/pose_test/`, and a recording protocol. Together they check that "a hand above the nose" works with a real set-up.

* **The scene** shows the mirrored webcam, the head and hand boxes, the head line, the pose it recognizes (LEFT, RIGHT, REST or INVALID), how hard it steers, and the wheel pinned to the head. It also shows the camera split in the middle, for two players.
* **The recordings:** with `--record=DIR`, the scene saves the detections (the head and hand boxes with their scores, per frame) as JSON Lines, plus a few low-resolution thumbnails. These stay on the local disk, only with explicit consent, and are never part of the game.
* **The protocol** (about 3 minutes per child):
  1. Kneel and rest.
  2. 5 × left, then 5 × right, holding for 2 s each.
  3. Alternate for 30 s.
  4. Raise each arm slowly from the nose to high above the head, and back (for the steering range).
  5. Kneel up and wave.
  6. Move closer and farther.

  Repeat at 1.5 m, 2 m and 2.5 m, and with two children side by side.
* **The questions it answers:**
  * Is the stretched hand reliably above the nose?
  * How often is the hand on the floor lost?
  * Are the thresholds (the line at the nose, `1.5·h` for full steering, `4·h` sideways) right?
  * Is the steering range (from the nose to 1.5 head heights above it) comfortable for ten-year-olds?
* The recordings become the test fixtures for `BirdDogPoseClassifier`.

## 9. Sailing details

Inspired by the sailing in *Pirates!* and *Pirates! Gold*:

* **The view** is top-down, with the boat in the middle and the coastline scrolling.
* **The chart** is a parchment map with the real coastlines from Natural Earth (10 m, since the Croatian islands matter). We generate it with a script like `splash-n-splat/dev/maps/make_travel_map.py`, and the ports you already know are marked.
* **Entering a port:** sail close to it, and the conversation opens.
* **Zooming in among the islands** (`ChartZoom`): at the zoom of 1, a channel a few kilometres wide is only a few dozen pixels, so the camera of each player zooms in by itself where the way gets tight. Only the camera zooms; the boat sails as fast as ever (in kilometres), so the legs take as long as before. Two measures, of which the larger zoom wins:
  * **crowded:** how much coast lies within 15 km of the boat; from 50 km of coast (a straight coast has about 35) up to 150 km (Zadar, Pag), the camera zooms in up to 2.5×,
  * **narrow:** the shortest way from land to land through the boat, measured with rays in 12 directions; from 14 km down to 3 km (the Pašman channel), the camera zooms in up to 4×.

  The mission measures five times a second (a measure takes well under a millisecond), the camera eases in over about a second and out over about two, so that it does not pump among the islands, and when zoomed in it looks ahead of the boat. The boats keep one small size on the screen at every zoom, so that they fit into the channels; the ships, the ports with their names and the rings of the targets keep their size on the screen; the coast, the reefs and the waves grow with the zoom. With two players, every view zooms on its own; the shared ports keep their size in the view which zoomed in the most.
* **The time scale:** a typical leg takes 1 to 2 minutes of real time. The distances on the chart are real, but the boat's speed is tuned per sea (`SeaConditions.speed_scale`) so that the legs stay near that range. Measured over 30 routes per mission (a good crew, 30% longer than the straight line): the legs of missions 1, 6 and 10 are short (about 100 km), so their seas sail a little slower (0.8 and 0.85, about 50–55 s a leg); missions 3 and 12 take about 75 s a leg; the long legs of missions 2, 8 and 15 are broken by the stops for provisions every 240 km at most, so no stretch between two ports takes much more than 100 s.
* **Hazards** (none of them hurt anyone):
  * **The coasts never hurt:** a boat which runs onto the coast slides along it, keeping the speed which goes along the coast, and its bow turns gently with the coast (`Helm._slide`); only running nearly head-on stops it. Stopping at every touch was too frustrating for novice sailors. The only exceptions are **the cliffs** at eight special, named places (`data/world/cliffs/*.tres`, `CliffField`): Telašćica, Cres, Vis, Lastovo, Mljet, Monte Conero, the Gargano and the white cliffs of Lefkada. They are drawn as a grey rocky rim with the engraved hatching of a steep face and surf at its foot; running ashore there at speed damages the hull (25%).
  * **Reefs** (*hridi*) lie only at about ten special, named places (none in front of a port: the shallows of the Neretva closed the only way to Ston and were removed) (`data/world/reefs/*.tres`, `ReefField`): the rocks of Cape Kamenjak, the shallows of the Po, the reefs of the Kornati, the Pakleni islands, Palagruža, the Tremiti, Cape Oštro, the shallows of the Buna, Karaburun and Sivota. They are drawn by a shader (`reef.gdshader`), in the manner of the reefs of *Pirates! Gold*: a lagoon of turquoise shallow water over pale sand, with a darker drop-off into the deep sea, the sunlight rippling on the bottom, dark broken rocks lit from the top left, and white foam which keeps breaking around them. The rocks of the shader are exactly the rocks which the boats hit. The name of the field stands under it; none lies within 10 km of a port. Running onto a rock damages the hull (35% at full speed), shown by the **hull panel** under the provisions (a little ship which gets cracks and patches, and a bar which starts full and empties with the damage); at 100%, a fishing boat tows the crew to the nearest port. Every port repairs the hull (up to half a day for a hull which was nearly broken).
  * **Gusari** ships chase you within a radius. If they catch you, they steal 20 ducats (or all on board, if fewer; all the ducats of the crew are on board), or, with nothing to steal, take a toll of one day. No ship chases you for long: after 10 to 15 seconds it gives up and roams away for a while. At most one corsair and one patrol are out at once, and they come three times less often than at first (the play-tests found far too many). They flee from the Venetian patrols. They sail at 64% of the best speed of a boat, the patrols at 56%. They are as slow against the wind as you, so the right course (and a good look at the wind rose) lets you outrun them.
  * **Venetian patrols** stop "suspected uskoks" for an inspection, which costs half a day.
  * **Storm clouds**, as in *Pirates!*:
    * **How they look:** big storm clouds seen from above, drawn by a shader (`storm_cloud.gdshader`): billowing fractal noise which churns slowly, a dark core with edges lit from the top left, the shadow of the cloud on the sea with the rain falling in it, and a soft flash of lightning inside now and then (never frightening). They are also marked on the minichart.
    * **How they move:** they drift slowly with the wind, so a change of the wind changes their course too, and reading the wind rose helps to avoid them.
    * **Half transparent:** the clouds are drawn at half opacity at most, so that the sea, the coast and the boats show through them.
    * **Inside a cloud:** the boat sails at half speed, and gusts push it off course now and then, so you have to steer to keep it. You see less around the boat (the edges of the view darken), and the wind rose shows a grey cloud icon.
    * **Coming out:** steer out of the cloud. The clouds are slow, so you can always get out, and a cloud never costs more than the time it takes.
    * **How many:** a mission has 0 to 3 clouds at a time. Mission 1 has none, and the later missions and the strong winds bring more. A cloud lives for 1 to 3 minutes, then it rains itself out and fades away.
    * **With two players,** a cloud slows both boats if they are inside. Sailing side by side still gives its bonus, so the crew gets out together.
* **Little joys:** dolphins swim along when you sail fast, and you can pick up floating barrels and chests with ducats (see section 10).

## 10. Ducats, boosters and decorations

Along the way, you collect **ducats** (*dukati*), the gold coin everybody on the Adriatic accepted around 1600. In the ports, you spend them on boosters, and in Pula, on decorations for your boats.

### Earning ducats

* **Floating barrels and small chests** on the water (5 to 15 ducats). They lie a little off the direct route, so it pays to sail a detour.
* **The errands** of the ports (25 to 65, the further, the more).
* **The yataks** give 20 ducats at the end of every mission (once per mission and voyage).
* **Every task of a mission** (every step but the briefing and the celebration) pays 10 ducats, once, to the boat which did it.

### Spending ducats

* "What do you sell?" is one of the answers in the port conversation. It opens a small **merchant's stall** with 4 of the 20 boosters, drawn anew at every visit, so we still need no places.
* One of the four is a speciality of the power of the port: Venice sells flags, the Ottoman ports figs for the corsairs, and so on.
* Ten of the twenty are practical (the table below), ten are **decorations** which stay on the boat for good and show at sea: a mermaid, a lion or a dolphin figurehead, a checkered flag, a flag with a golden sun, a crescent flag, a striped flag, lanterns, streamers, a parrot. A decoration is paid from the ducats on board, at once.

| Booster | Price | Effect | Lasts |
|---|---|---|---|
| New sails | 30 | The boat sails 20% faster | the next leg |
| Weather-wise fisherman | 20 | The wind change is announced 20 s ahead instead of 5 s, with the new direction | the next leg |
| Local pilot | 25 | Shoals and rocks are marked and don't stop the boat | the next leg |
| The right flag | 20 | The Venetian patrols let you pass without an inspection | the next leg |
| Figs for the corsairs | 25 | The next time corsairs catch you, they take the figs instead of a day | until used |
| Fresh bread and water | 15 | One more ration of food and water; offered only when a whole ration fits into the barrels | at once |
| Lots of cannons | 45 | The corsairs turn and flee (boom!) | the next leg |
| A skilled helmsman | 25 | The boat turns 60% quicker | the next leg |
| A barrel of salted fish | 20 | The food lasts longer (eaten at 60%) | the next leg |
| Strong rowers | 30 | Into the wind, the boat sails at least at 60% | the next leg |

* You can hold at most two boosters for the next leg, and they show as icons next to the mission clock. This cap keeps a big purse from making a mission trivial.
* With two players, a booster bought in a port works for both boats.
* A mission yields only a few dozen ducats, so a crew has to choose between boosters now and decorations or a new ship later.

### The ducats of the crew

* **There is no chest at home:** the crew carries all its ducats on board, so the corsairs and the patrols can take them. At the start of a mission, the ducats go on board (with two players, split between the boats); at its end, what is left on board is the crew's (`Session.ducats`, `MissionRun.bring`). A mission which is not finished changes nothing, except for the decorations, which are paid at once.
* **One ration of food and water is free:** every port gives one, and a towing costs only time; a crew without ducats is never stuck, but a big ship needs ducats to fill all its barrels.
* **A new voyage starts with 40 ducats**, so that the first merchant is already worth a visit.
* **The yataks** (in Croatian "jataci"; from the Turkish "yatak", a shelter: the haiduks' secret friends, who hid and fed them over the winter) collect 20 ducats for the crew in every mission and give them at its end, once per mission; the end of the mission says so.

* The ducats **carry over between missions**. They are saved with the crew and shared by both players.
* They are shown on the mission select and in the shipyard as a leather purse, with its coins piling up visibly beside it (`Purse`).

### Ships from Master Ivan's shipyard

Every captain starts with the smallest ship, a **gajeta**: one sail, nimble, but with a single ration (360 km), so that it just crosses the open sea, and a long voyage needs a stop in a port (or a tow). In the shipyard (the tab "Ship"), a captain can buy a new ship for very many ducats; a bought ship stays bought, and the captain may switch back for free. Unlike the decorations, a ship changes how the boat sails (`data/world/ships/`, `Ship`):

| Ship | Price | Masts | Speed | Turning | Rations | Goods of errands | Oars |
|---|---|---|---|---|---|---|---|
| Gajeta | (start) | 1, small | 105% | 160% | 1 | 1 | |
| Bracera | 300 | 2 | 100% | 100% | 3 | 2 | |
| Uskok boat | 700 | 2 | 112% | 130% | 2 | 1 | yes |
| Trabakul | 800 | 3 | 125% | 95% | 3 | 2 | |
| Galleon | 900 | 3, big | 85% | 75% | 5 | 4 | |
| Galley | 1000 | 1 and oars, big | 100% | 110% | 4 | 3 | yes |

With oars, a ship sails into the wind at least at 60% of its speed.

### Decorating the boats in Master Ivan's shipyard

After mission 2, Master Ivan opens his shipyard in Pula. It is reachable from the mission select. Each player decorates their own boat, paid from the shared ducats, and the preview shows the boat at once.

| Kind | Examples | Price |
|---|---|---|
| Sail | colours, stripes, a sun, a star, a seagull, the crew's initials | 30 to 80 |
| Hull paint | blue, green, red, with a coloured stripe | 30 to 60 |
| Flag on the mast | the colours of the Bird Dog flag (the emblem itself always stays, see section 3) | 30 |
| Figurehead | a dolphin, a lion, a seagull, a mermaid, a goat | 80 to 120 |
| Streamers | colourful ribbons on the yard | 20 |
| Lanterns | at the stern, glowing at dusk | 40 |
| A friend on board | a cat, a parrot, a dog, a goat (they walk on the deck and lean into the turns) | 100 to 150 |

* Decorations are only for looks, and never change the speed. A child who bought none is never at a disadvantage.
* What has been bought stays bought. You can switch back and forth between the bought decorations for free.
* The decorations are visible at sea (top-down), in the ports (side view) and on the mission select.

## 11. Languages and text

* **The languages:**
  * English,
  * Russian,
  * Croatian in the Dalmatian ikavian dialect, which gives the game its local flavour ("di si", "lipo", "mliko", "divojka"),
  * German, Spanish (of Spain), French, Italian, Portuguese (of Portugal), Albanian and Turkish, as machine-made drafts which wait for a native speaker's review.
* **The order on the language select:** English first, then the others alphabetically by their code (Deutsch, Español, Français, Hrvatski, Italiano, Português, Русский, Shqip, Türkçe).
* **Adding a language** is one entry in `translations/languages.json` (the code, the name in itself, an optional second line such as the dialect, and "Choose your language" in itself), then `dev/translations/extract.py` creates its `.po` file for the translators. Nothing in the game's code names a language: the language select lays out the cards in rows of up to four and cycles "Choose your language" through all the languages, and the font must cover the letters of every language (Latin with the Croatian, German, Romance, Albanian (ç, ë) and Turkish (ğ, ı, İ, ş) letters, and Cyrillic). Open Sans has them all, but not the narrow no-break space (U+202F), so French uses the no-break space (U+00A0) before ! ? : ;.
* For ten-year-olds, every line of the conversation is at most two short sentences, with a portrait and an icon (an item, a landmark, a flag), so that pictures carry as much of the clue as possible.
* All the texts live in Godot translation files (`.po` per language), keyed by the line. The clue pools are written once, with placeholders for the port and the captain's name, and then translated. See "Translations from the start" in section 14 for the tools and the workflow.
* **The gender in the texts (built):** a translation chooses the words which depend on the addressed captains right in the text: `{crew|došao si|došla si|došli ste|došle ste}` gives the form for one haiduk, one haidukess, several captains with a haiduk among them, and several haidukesses (the last two may be left out: several haidukesses then take the third form, several captains the first). A translation needs it only where its language changes ("Ahoi, {crew|Kapitän|Kapitänin|Kapitäne|Kapitäninnen}!"); English and Turkish need none. The whole crew is addressed, except in the half of the screen of one boat, which addresses that boat's captain alone. We chose this over doubling every line in Godot's translation contexts (`m`, `f`, `pl`): the English stays one message, and a translator writes the forms only where they differ.
* **Proofreading:** Marko checks the Russian and the Dalmatian ikavian; the other languages need native speakers.
* The sounds are waves, gulls, creaking ropes and timber, the flapping sail and wind (louder with intensity). There are no voices.

### Music

The music is from the Adriatic around 1600, like the pictures (section 12): the end of the Renaissance and the start of the Baroque.

* **The pieces (built):** the six sonatas of Adriano Banchieri's *L'organo suonarino*, printed by Ricciardo Amadino in Venice in 1605, and the *Saltarello*, a lute dance of Vincenzo Galilei (around 1580). They come as MIDI files from the Mutopia Project, each marked as Public Domain (no rights reserved).
* **The sound:** Godot can not play MIDI, so `dev/assets/fetch_music.py` downloads the MIDI files (pinned by SHA-256), gives the parts instruments of the time (church organ, harpsichord, a consort of recorders, a plucked string for the lute) and renders them to Ogg Vorbis with TiMidity++ and the FluidR3 General MIDI sound font (MIT). `assets/music/manifest.json` records the provenance of every piece; the MIDI files stay in `assets/music/midi/`.
* **Playing:** the `Music` autoload plays the pieces in a shuffled order through the whole game, quietly in the background. M mutes the music, and the game remembers it.
* **Later:** more pieces with a local colour, if we find them as public domain or CC0, e.g., the dances of Giorgio Mainerio (Aquileia, 1578), the motets of Ivan Lukačić (Šibenik, 1620), the sonatas of Dario Castello (Venice, 1621) or Ottoman music as written down by Ali Ufki (17th century). A region could then have its own music: Venetian sonatas in Venice and Dalmatia, dances in the ports, Ottoman tunes in the Ottoman ports.

## 12. Art direction: period art

The game looks like the Adriatic of around 1600, because most of its pictures **are** from that time: public-domain maps, town views, costume books and paintings, which museums and libraries publish as CC0 or public-domain scans. We draw only what period art cannot give us: the 3D captain of the instruction, the wheel, the boats at sea, the effects and the interface.

### Where the pictures come from

| Use | Period source (all long in the public domain) |
|---|---|
| **The chart** (the mission select, the minichart, the travel map) | Sea charts and maps of the Adriatic from the 16th and 17th centuries, e.g., Ortelius' *Theatrum Orbis Terrarum* (1570 on), Mercator's atlas maps of Dalmatia and Sclavonia (1589), Coronelli's maps of the Adriatic (1688), portolan charts. We use the scan as the paper and the decoration, and draw the real coastline (Natural Earth) on top, so that the sailing stays accurate. |
| **The ports** (the backgrounds of the conversations) | Town views: Braun and Hogenberg's *Civitates Orbis Terrarum* (1572–1617), with Venice, Pula, Zadar, Šibenik, Split, Dubrovnik, Kotor, Corfu and others; Camocio's *Isole famose* (1571–1574) with the islands and fortresses of the Adriatic; engravings of Venice, Ragusa and Corfu. |
| **The people in the ports** (the portraits) | Costume books: Cesare Vecellio's *Habiti antichi et moderni* (1590), with Venetians, Dalmatians, Albanians, Greeks, Ottomans and many more; Nicolas de Nicolay's *Navigations* (1567); Jean-Jacques Boissard's *Habitus variarum orbis gentium* (1581). We crop a figure, clean it up and colour it gently. |
| **The ships** (the corsairs, the patrols, the decoration) | Engravings and drawings of galleys, *brazzere* and other ships in the atlases and town views, and in prints of the time. |
| **The items, the flags and the coins** | Woodcuts and engravings of the objects (a bell, a ledger, salt, olive oil), coins of Venice, Ragusa and the Ottomans, and the flags as shown on period maps. |
| **The decoration** | Cartouches, compass roses, sea monsters and ornamented borders from the period maps. |

### The rules

* **Only CC0 or public domain.** We take the scans from institutions which publish them as CC0 or under the Public Domain Mark: the Rijksmuseum, the Metropolitan Museum of Art (Open Access), the Library of Congress, the Smithsonian, the Nationalmuseum Stockholm, the Biodiversity Heritage Library, and Wikimedia Commons files marked as public domain (old works, with a public-domain scan). Scans with any restriction (e.g., non-commercial) are out.
* **Every picture is recorded** in `assets/period/manifest.json`: the file, what it shows, the original work, its author and year, the institution, the source URL, the license statement and the SHA-256 of the downloaded original. A script (`dev/assets/fetch_period_art.py`) downloads the originals into `.cache/`, checks their hashes, and writes the cropped and cleaned versions into `assets/period/`. The THIRD_PARTY_NOTICES list them all.
* **We curate.** Period art sometimes shows other peoples as caricatures or as enemies. We only use pictures which show people with dignity, and every power gets friendly faces. The people of the period prints may carry the weapons of their time (hardly any print shows a man without one); only the captains of the players are never armed.
* **Cleaning up:** we crop, remove stains and colour the engravings lightly (in the style of the hand-coloured prints of the time), so that ten-year-olds see clearly what matters. The scans stay recognizable as old prints.
* **No text in the pictures** which a player needs to read, since the game is translated. The Latin and Italian inscriptions of the maps are decoration only.
* **The style of what we draw ourselves** matches the prints: warm paper colours, ink outlines, a limited palette of the colours of the time (madder red, indigo, ochre, verdigris).

# Software architecture

## 13. Technical outline

The project follows `splash-n-splat`, and the split screen follows `ergo-chaos`:

* **Godot 4.6 (.NET).** The vision is in C#, and the game is in GDScript.
* **The vision** is reused from `splash-n-splat/scenes/hand_tracker/`: `YoloxHandDetector` (heads and hands), `MultiHandTracker`, `FistClassifier`, `GestureStateMachine`, `HandVisionService` and `AdaptiveScheduler`.
* **New in C#:**
  * `PlayerSplit` assigns the detections to player 1 or 2 by the half of the image, like `PoseToPlayerSuppression` in `ergo-chaos`.
  * `BirdDogPoseClassifier` turns each player's head and hands into LEFT, RIGHT, REST or INVALID, with how hard they steer (in [-1, 1]).
  * `HandVisionService.GetPose(player)` and `GetCursor(player)` give the game the pose and the cursor per player.
* **The scenes** (in GDScript):
  * `game`: the flow, the language and the number of players,
  * `crew`: the captains, the ducats, the decorations and the save slots, with F5 and F6,
  * `captain_creator`: the name (with the on-screen keyboard), the gender and the appearance,
  * `shipyard`: Master Ivan's decorations,
  * `pose_test`,
  * `mission_select`,
  * `briefing`,
  * `split_screen`,
  * `sailing`: the boat, the steering, the points of sail, the wind and the hazards,
  * `instruction`: the 3D captain on the deck, its bird-dog animations and the steering demo,
  * `wheel_panel`: the webcam and the wheel pinned to the head,
  * `wind_indicator`,
  * `port`: the conversation and the line-up,
  * `logbook`,
  * `merchant`: the booster stall,
  * `stars`,
  * `calibration`,
  * `sound`.
* **The data:**
  * `data/world/`: the ports with their facts, the powers, the people, the traits, the items and the sea conditions, as typed resources (section 14),
  * `data/missions/<id>/`: each mission, assembled from steps (section 14),
  * `data/shop/`: the boosters and the decorations, with their prices and effects or looks,
  * `assets/period/`: the period pictures with their manifest (section 12),
  * `adriatic_map.json`: generated,
  * `translations/`: `languages.json`, `messages.pot` and a `<code>.po` per language (section 14).
* **The tests:**
  * .NET unit tests for the pose classifier, on the recordings,
  * GDScript tests that a mission's clue graph is solvable (every clue points to exactly one port, and the route is reachable within the clock),
  * a headless run of a mission in keyboard mode, with one and with two players,
  * a round trip of a save (save, load and compare) and the reading of the saves of older format versions.
* There is no network access, as in the sibling games.

## 14. Mission architecture: building blocks

The missions are the most complex part of the game, and we will add and change many of them. We do **not** write a domain-specific language. Instead, the code and the data are made of **building blocks which mirror the mission logic**: ports and their facts, people, clues, conversations and steps. A mission is assembled from these blocks, mostly as data, and the code which runs them knows nothing about any particular mission.

### The data: typed Godot resources

All the building blocks are custom Godot `Resource` classes (`class_name … extends Resource`) and live as `.tres` files under `data/`. They are typed, editable in the Godot inspector, can refer to each other, and are checked by tests. There is no free-form JSON for the missions.

**The world** (shared by all missions, `data/world/`):

* `Port`: the id, the name, the position (latitude and longitude), the power, the picture, the local people who can greet you, and its **facts**.
* `PortFact`: one thing which identifies a port, as a phrase for the clues: "the city where they keep the bones of St. Nicholas" (Bari), "the town with the big Roman arena" (Pula). Each fact has a kind (landmark, saint, goods, power, flag, famous person) and a difficulty.
* `Power`: Venice, Ragusa, the Ottomans, …, with its flag, its coin and its patrols.
* `Person`: a portrait, a name, a role (innkeeper, fisherman, harbour master…) and the greeting.
* `Trait`: a recognizable trait of a person for the line-ups ("a red sash", "a parrot"), with a phrase and an icon.
* `Item`: a thing to fetch or deliver (the bell, a sack of salt, the ledger), with a picture.
* `SeaConditions`: the typical winds, the clouds, the corsairs and the patrols of a region or a mission.

**A mission** (`data/missions/<id>/mission.tres`) is a `Mission` resource with the title, the start port, the mission clock, the sea conditions, the rewards and an ordered list of **steps**. A step is one of a small set of `MissionStep` subclasses:

| Step | What the player does | What it is made of |
|---|---|---|
| `Briefing` | Hears what happened and gets the first clue. | The speaker (Baba Stana), the lines, the first destination. |
| `Trail` | Follows a person or a thing through several ports, each port pointing to the next. The heart of the detective work. | Who or what is followed, the number of ports, the pool of candidate ports, the traits to reveal on the way, how hard the facts may be. |
| `Collect` | Fetches items from several ports, in any order. | The items and where they can be had (and what they cost). |
| `Deliver` | Brings items or a person to someone in a port. | The items, the recipient, the port. |
| `Lineup` | Picks the right person out of three, by the traits gathered. | The person, the decoys, the traits. |
| `Return` | Sails back to a port (e.g., home to Pula). | The port. |
| `Celebration` | Sees the happy end. | The lines, the picture. |

Steps are kept generic, and a new mission usually needs no new code. When it does, the new behaviour becomes a new reusable step (or a new effect, below), never a special case inside the runner.

**Conversations** are trees of `DialogueNode`s: a speaker, a line, and up to three `Answer`s. Each answer has a label and a list of **effects**, small typed blocks such as `GiveClue`, `RevealTrait`, `GiveItem`, `TakeItem`, `GiveDucats`, `AskRiddle`, `OpenShop`, `CompleteStep` and `Goodbye`. Most conversations are not written by hand: each step builds them from templates. For example, a `Trail` creates the "right port" conversation (a greeting, "Have you seen…?", the destination clue from the next port's fact, perhaps a trait or a riddle) and the "wrong port" conversation ("This is the wrong port, captain!", and where to sail). Hand-written conversations are only for the special moments of a story.

**Clues are assembled, not written per mission:** a `ClueTemplate` ("He asked the way to {fact}.", "She bought a ticket to {fact}.") plus a `PortFact` gives the line. A mission chooses which templates and which kinds of facts it uses. That way, a new port immediately works in every mission, and the texts are translated once.

### The code: a runner which knows no mission

* **`MissionPlanner`** (pure logic, no nodes) turns a `Mission` and a random seed into a concrete **plan**: the route through the ports, the facts and templates chosen for each clue, the traits, the decoys of the line-up. The same seed always gives the same plan, so a saved game only needs the seed and the progress.
* **`MissionRunner`** (a node) holds the **`MissionState`**: the plan, the current step, the clock, the visited ports, the logbook, the items and the ducats. The sailing, the port and the logbook screens only ask the runner and react to its signals (`step_started`, `clue_found`, `clock_changed`, `mission_won`, `mission_failed`). They never contain mission logic.
* Each step implements a small interface: `start(state)`, `conversation_at(port, state)`, `objective(state)` (for the logbook) and `is_done(state)`.
* **Saving** writes the `MissionState` (section 7), which is plain data: the seed, the step index, the progress, but no node.

### Checking the missions

The structure makes the missions checkable before anyone plays them. Tests (`tests/godot/test_missions.gd`) plan every mission with many seeds and check that:

* every destination clue points to exactly one port: no other port has the same fact,
* the route can be sailed within the mission clock, with some time to spare for a wrong port,
* every item is obtainable before it must be delivered,
* the traits of a line-up single out exactly one of the three people,
* every text which a mission uses exists in every language (see below),
* every port, person, item and picture which the mission refers to exists.

A small tool (`dev/missions/print_plan.gd`) prints the plan of a mission for a seed in plain text, so a mission can be read and reviewed like a story.

### Translations from the start

* **The source language is English.** Every text that a player sees goes through Godot's translation: `tr()` in the scripts, and translatable fields in the resources. Nothing is ever glued together from pieces. A whole sentence is one message, with **named placeholders** (`{captain}`, `{port}`, `{fact}`, `{item}`, `{ducats}`), so that every language can order the words its own way.
* **The grammatical gender** of the addressed captains is a choice in the translation, `{crew|...}` (section 11, "The gender in the texts"; `AddressedTranslation` picks the form whenever a message is translated, so it works in every text of the game). Facts and items keep the gender and the cases they need in their own messages.
* **The files:** `translations/messages.pot` (the template) and a `translations/<code>.po` per language, which translators edit with any PO editor (e.g., Poedit). Every message carries a comment saying where it appears and how long it may be ("caption, at most 2 lines").
* **The tools:**
  * `dev/translations/extract.py` collects the messages from the scripts, the scenes and the resources into `messages.pot`, and updates the `.po` files with `msgmerge`, keeping the existing translations.
  * `dev/translations/check.py` reports, per language, the missing and the fuzzy (to be reviewed) messages, and fails on errors: a placeholder missing or misspelled in a translation, a gender variant missing, a text too long for its place, a character the font cannot show.
  * The pre-commit checks run both, so a new text never goes unnoticed.
* **Trying it out:** `-- --lang=<code>` (e.g., `--lang=ru`) starts the game in a language, and Godot's pseudo-localization (longer, accented texts) shows where a text would not fit.
* **Status:** the tools are built, and all the texts exist as drafts in every language, waiting for review (Marko for Russian and Dalmatian ikavian, native speakers for the others).
* **Reviewing:** a draft translation stays marked as *fuzzy* until a native speaker (Marko, for Russian and Dalmatian ikavian) has read it in the game. The game shows the fuzzy messages, too, so that the players always see the language they chose; the mark only tracks the review.
* **No text in pictures,** and the font covers the Latin letters of every language and Cyrillic (a period-flavoured typeface with both, e.g., Alegreya, under the SIL Open Font License).

## 15. Mission structure

This section turns the building blocks of section 14 into a concrete plan: which data structures hold a mission, how its texts are translated, how it runs, how it is saved, and how we check it. The missions of section 4 are written in exactly these structures.

### The principles

1. **Missions are data, assembled from typed building blocks.** A mission is a set of Godot resources (`.tres`) which refer to each other: the ports, the people, the items, the clues, the steps. There is no mission language to parse and no mission code to write; the code knows the *kinds* of building blocks, never a particular mission.
2. **The data mirror the story.** Every class is a word of the mission's own language: a `Port` has `facts`, a `TrailStep` follows a `target` through `ports`, a `LineupStep` shows `decoys`. Reading a mission's files reads like reading the mission.
3. **The world is shared, the missions are thin.** Ports, powers, people, traits and items live once in `data/world/`; a mission refers to them. A new port works at once in every mission; a fact or a name is translated once.
4. **Static data and running state are separate.** The resources are never changed while playing. A mission is turned into a concrete **plan** (the route, the clues, the decoys) and played with a **state**; only the plan and the state go into the save.
5. **Every text is an English message ID, translated at the last moment.** No sentence is ever glued together from pieces; placeholders are named, and the grammatical gender and case are chosen by context (below).
6. **Everything is checked before anybody plays.** A validator plans every mission with many seeds and checks the rules of the story (one port per clue, the clock, the items, the line-ups, the texts in every language).

### The files

```
data/
  world/
    powers/      venice.tres, ragusa.tres, ottomans.tres, habsburgs.tres, ...   (Power)
    ports/       pula.tres, zadar.tres, sibenik.tres, ...                       (Port, with its PortFacts)
    people/      baba_stana.tres, master_ivan.tres, doctor_marin.tres, ...      (Person)
    traits/      red_sash.tres, patched_red_sail.tres, ink_stained_fingers.tres (Trait)
    items/       bell.tres, salt.tres, ledger.tres, sail.tres, honey.tres, ...  (Item)
    clues/       destination.tres, trait.tres, wrong_port.tres                  (ClueTemplateSet)
    seas/        calm_maestral.tres, bura_kvarner.tres, open_sea.tres, ...      (SeaConditions)
  missions/
    01_bell_of_grebastica/
      mission.tres                      (Mission: the header, the sea, the clock and the steps)
      conversations/*.tres              (hand-written conversations, if any)
    02_shipwright_of_korcula/
      ...
assets/period/ports/<port>.png, assets/period/people/<person>.png, ...
```

The ids of the resources (`id = "bell"`) are stable forever: the saves refer to them. A file may be renamed or moved; its `id` never changes.

### The world: the classes

All the classes are GDScript `Resource`s with `class_name`, in `scenes/missions/data/`, so that the Godot inspector edits them and the type checker knows them.

| Class | Fields | Notes |
|---|---|---|
| `Power` | `id`, `name`, `flag: Texture2D`, `coin: Texture2D`, `patrols: bool` | Venice, Ragusa, the Ottomans, the Habsburgs, the Papal States, Naples. |
| `Port` | `id`, `name`, `location: Vector2` (longitude, latitude), `power: Power`, `facts: Array[PortFact]`, `picture: Texture2D`, `locals: Array[Person]`, `riddles: Array[Riddle]`, `shop: Array[Offer]` | `locals` greet the crew in turn, so that a port has several faces. |
| `PortFact` | `kind` (landmark, saint, goods, power, famous person, nature), `phrase`, `difficulty` (1 to 3) | `phrase` is a noun phrase which fits every clue template: "the town with the great Roman arena". |
| `Person` | `id`, `name`, `role` (innkeeper, fisherman, doctor, ...), `portrait`, `gender`, `greeting` | `gender` picks the grammatical forms of the lines which mention them. |
| `Trait` | `id`, `phrase` ("a patched red sail"), `icon`, `kind` (clothes, hair, thing, boat) | The traits of the line-ups. |
| `Item` | `id`, `name`, `picture`, `price` (default) | The bell, a load of salt, the ledger, a sail, honey, the medicine. |
| `Riddle` | `question`, `answers: Array[String]`, `correct: int`, `ducats` | Asked by a local; a wrong answer costs nothing. |
| `Offer` | `booster` (id), `price` | What a port's merchant sells (section 10). |
| `ClueTemplateSet` | `kind` (destination, trait, wrong port, greeting, goodbye), `templates: Array[String]` | "He asked the way to {fact}.", "She had {trait}.", "This is the wrong port, captain!" |
| `SeaConditions` | `winds: Array[WindChance]`, `change_seconds: Vector2` (min, max), `clouds: Vector2i` (min, max), `corsairs: Array[Zone]`, `patrols: Array[Zone]`, `barrels: int`, `speed_scale: float` | Each mission picks one (or overrides it). |
| `WindChance` | `name` (bura, jugo, maestral, ...), `direction` (degrees), `intensities: Vector3` (the weights of light, fresh, strong), `weight` | The winds of a region and how often they blow. |
| `Zone` | `center: Vector2` (longitude, latitude), `radius_km` | Where the corsairs or the patrols cruise. |

### A mission: the classes

| Class | Fields |
|---|---|
| `Mission` | `id`, `number`, `title`, `summary`, `start_port: Port`, `clock_days`, `sea: SeaConditions`, `steps: Array[MissionStep]`, `stars: Vector2` (the share of the clock left for three and for two stars), `fun_fact`, `music` (optional) |
| `MissionStep` | `id` (unique within the mission), `objective` (the line in the logbook) |

`MissionStep` is the base class of the steps; every step is one subclass, with exactly the fields its story needs:

| Step | Fields | What it means |
|---|---|---|
| `BriefingStep` | `speaker: Person`, `lines: Array[String]`, `by_pigeon: bool`, `first_clue: ClueSpec` | Baba Stana tells what happened, in person or by letter, and gives the first clue. |
| `TrailStep` | `target: Resource` (a `Person` or an `Item`), `ports: Array[Port]` (the pool), `length: int`, `fixed_route: bool`, `max_difficulty: int`, `clue_kinds: Array[String]`, `reveal_traits: Array[Trait]`, `rival: RivalSpec` (optional) | The target went from port to port; each right port gives the clue to the next one and maybe a trait. |
| `CollectStep` | `sources: Array[ItemSource]`, `needed: int` | Fetch `needed` items; each `ItemSource` names the item, the port, the seller and the price. |
| `DeliverStep` | `items: Array[Item]`, `people: Array[Person]`, `recipient: Person`, `port: Port` | Bring things or people to someone. |
| `LineupStep` | `target: Resource` (a `Person` or a boat), `decoys: Array[Resource]`, `shown: int`, `traits: Array[Trait]` | Pick the right one of `shown` by the traits gathered; the decoys share some traits, never all. |
| `TradeStep` | `links: Array[TradeLink]` | A chain of trades; each `TradeLink`: `port`, `person`, `gives: Item`, `wants: Item`. |
| `ReturnStep` | `port: Port` | Sail back, e.g., home to Pula. |
| `HearingStep` | `judge: Person`, `questions: Array[HearingQuestion]` | The judge asks; each `HearingQuestion` has the `question` and its `answer`, which refers to something of the voyage (a mission's item, port or person), and `decoys` for the wrong answers. |
| `CelebrationStep` | `lines: Array[String]`, `people: Array[Person]`, `picture` | The happy end; may unlock something (`unlocks`, e.g., "shipyard"). |

Two small helpers carry the specifications: `ClueSpec` (`kind`, `target port` or "the first port of the next trail") and `RivalSpec` (`speed`, `head_start_days`, `penalty_days`).

### Conversations: generated, and written by hand where they matter

* **Generated (most of them):** every step builds the conversations of its ports from the templates: a greeting by a local, two or three answers ("Have you seen…?", "Where did … go?", "What do you sell?", "Goodbye!"), and the clue from a template and a fact. So a mission needs no dialogue files for its ordinary ports.
* **Hand-written (the special moments):** a `Conversation` resource is a tree of `DialogueNode`s: `speaker: Person`, `line`, and up to three `Answer`s. An `Answer` has a `label`, `conditions: Array[Condition]` (shown only if all hold) and `effects: Array[Effect]` (what happens), and an optional `next: DialogueNode`. A step may refer to a conversation for a port to replace the generated one (e.g., the corsair captain of mission 10).
* **The effects** (subclasses of `Effect`): `GiveClue`, `RevealTrait`, `GiveItem`, `TakeItem`, `GiveDucats`, `TakeDucats`, `AskRiddle`, `OpenShop`, `SetFlag`, `CompleteStep`, `Goodbye`.
* **The conditions** (subclasses of `Condition`): `HasItem`, `HasDucats`, `StepActive`, `FlagSet`, `FirstVisit`.

A new kind of story moment means a new small effect or condition class, never a special case in the runner.

### Texts: what a translator sees

* **Every text field holds the English text, which is the message ID.** The extractor (`dev/translations/extract.py`) collects the text fields of all the resources in `data/` (it knows the fields per class) and of the scripts; every message gets a comment saying where it appears and how long it may be ("the line of a local, at most 2 lines").
* **Named placeholders:** `{fact}`, `{trait}`, `{item}`, `{person}`, `{port}`, `{captain}`, `{ducats}`. A template is translated as a whole, so every language orders its words its own way.
* **Grammatical gender:** the lines which mention a person or address the captains are looked up with a context: `m`, `f` or `pl` (two captains). The `Person.gender` and the captains' genders choose it; English gives the same text for all three.
* **Grammatical case (built, `Grammar`):** in Croatian and Russian, a name changes with its role in the sentence, and the preposition changes with the place ("в Пулу", but "на Хвар"; "u Zadar", but "na Hvar"). So a *translation* asks for the form it needs: `{port@to}` ("в Пулу", "na Hvar"), `{port@in}` ("в Пуле", "u Zadru"), `{fact@to}` and `{fact@about}` ("o gradu s okruglon crikvon svetog Donata"), `{item@acc}`, `{hallmark@acc}` and `{name@acc}` (a decoration). The forms of "to", "in" and "about" carry their preposition. `dev/translations/extract.py` collects a form for every port, fact, item, hallmark and decoration as a message with that context (`Grammar.CONTEXTS`); the translators fill them, and an empty form keeps the plain name. English needs none of them: `{port}` stays `{port}`.
* **Numbers (built):** a noun agrees with its number by the plural rule of the language: `{ducats|дукат|дуката|дукатов}` (one, few, many in Russian and Croatian; `{ducats|ducat|ducats}` in English). `dev/translations/check.py` checks that every placeholder of the English stays in the translation (with or without a form) and that every agreeing noun follows a number of the message. `tests/godot/test_grammar.gd` checks the plural rules and the forms.
* **The addressed captains (built, `Grammar.address`, `AddressedTranslation`):** `{crew|haiduk|haidukess|several|several haidukesses}` in a translation picks the form for the captains who are addressed (the `Crew` autoload knows their genders; `Grammar.addressed` narrows it to the captain of one boat). `check.py` checks that every choice has two to four forms and measures the longest form against the limits; `test_text_fit.gd` lays out the longest form.
* **The speaker's gender:** the clue templates are spoken by the locals, men and women, so their translations avoid the forms which show the speaker's gender ("Говорят, ...", "Čulo se da ...").
* **Checking:** the translation check (section 14) fails on a broken placeholder or a missing gender or case form; the mission validator checks that every text of a mission exists in every language.

### Running a mission: the plan and the state

* **`MissionPlanner`** (pure GDScript, no nodes) turns a `Mission` and a seed into a **`MissionPlan`**: for each step the concrete ports in order, the chosen fact and template of every clue, the traits in the order they are revealed, the decoys of the line-up, the prices. The same seed always gives the same plan.
* **`MissionState`** holds the progress: the plan, the index of the current step and its progress (a small dictionary per step type), the days used, the visited ports, the logbook (entries as message IDs with their arguments, so that they show in the current language), the items and the people on board, the ducats and the boosters of the mission, the flags, the boats (position, heading, speed), the wind, and the hazards.
* **`MissionRunner`** (a node) owns the state and is the only one to change it. The screens ask it and react to its signals: `step_started(step)`, `clue_found(entry)`, `item_changed(item)`, `clock_changed(days)`, `conversation_ready(port, conversation)`, `mission_won(stars)`, `mission_lost()`.
* **The steps contain their own rules**, as methods of their resource classes which take the state and never change themselves: `plan(rng, context) -> Dictionary`, `start(state)`, `conversation_at(port, state) -> ConversationInstance`, `on_arrival(port, state)`, `objective(state) -> LogbookEntry`, `is_done(state) -> bool`. A new step type is one new class with these methods.
* **The flow of a mission:** the runner starts the first step; the sailing screen reports the arrivals in ports; the step decides the conversation; the port screen plays it and reports the chosen answers; their effects change the state; when a step is done, the next one starts; after the last one, the stars are counted (section 4) and written into the voyage.

### Saving a mission in progress

The save of a voyage (section 7) gets a `mission` part while a mission runs: the mission `id`, the `plan` (as plain data: ids and indices, no resources), and the `state` (as plain data). We save the plan itself and not only the seed, so that a later change of the data (e.g., a new port in a pool) never changes a mission in the middle. The format version (section 7) grows with every change of these structures, and the loader converts older saves.

### The sailing world

* **One sailing scene for all the missions.** The chart comes from `adriatic_map.json` (generated from Natural Earth, section 9): the coastlines as polygons in kilometres of a projection around 43° N, the shoals, and the positions of the ports from their `Port.location`.
* **A mission configures the sea** with its `SeaConditions`: the winds and how often they change, the clouds, the corsair and the patrol zones, the barrels, and the `speed_scale` which keeps the legs between one and one and a half minutes.
* **Every port can be entered.** The detective work decides where to go; the sailing never marks the right port.

### Checking the missions

`MissionValidator` (GDScript, run by `tests/godot/test_missions.gd`) plans every mission with 50 seeds and checks:

* every `id` is unique, every reference points to an existing resource, and every port has a location on the chart,
* every destination clue fits exactly one port: no other port in the game has the same fact,
* every trail can be sailed within the clock, with at least one wrong port of slack,
* every item can be had before it must be delivered, and every trade chain can be completed,
* every line-up has exactly one candidate with all the traits revealed before it,
* every hearing question has its answer in the voyage so far,
* every text exists, with its gender and case forms, in every language.

`dev/missions/print_plan.gd` prints the plan of a mission for a seed as plain text, so that a mission can be read and reviewed like a story.

### Authoring a mission

1. Add the new ports, people, traits and items to `data/world/` (most are already there).
2. Create `data/missions/<nn>_<id>/mission.tres` in the Godot inspector: the header, the sea, and the steps, each chosen from the step types and filled in.
3. Write a `Conversation` only for the special moments.
4. Run the validator and `print_plan.gd`; read the story.
5. Extract the texts (`dev/translations/extract.py`); the translators fill in the new messages.
6. Play it in isolation: every mission has a test screen in `scenes/tests/missions/` which starts it at any step (`first_step`), with a fixed seed.

### Mission 1 as data

```
data/missions/01_bell_of_grebastica/mission.tres  (Mission)
  id = "bell_of_grebastica", number = 1, clock_days = 6, start_port = ports/pula.tres
  title = "The Bell of Grebaštica"
  sea = seas/calm_maestral.tres          (maestral only, no clouds, no corsairs, speed_scale 1.0)
  steps:
    BriefingStep    id = "briefing"   speaker = people/baba_stana.tres
                    lines = ["The children of Grebaštica wrote to me: the Aga's men took their bell and sailed south."]
                    first_clue = ClueSpec(kind = "destination", port = ports/zadar.tres)
    TrailStep       id = "trail"      target = items/bell.tres
                    ports = [ports/zadar.tres, ports/sibenik.tres], length = 2, fixed_route = true
                    max_difficulty = 1, clue_kinds = ["destination"]
                    reveal_traits = [traits/patched_red_sail.tres]
    LineupStep      id = "lineup"     target = boats/aga_boat.tres
                    decoys = [boats/fishing_boat_blue.tres, boats/trader_white.tres], shown = 3
                    traits = [traits/patched_red_sail.tres]
    DeliverStep     id = "deliver"    items = [items/bell.tres], recipient = people/grebastica_children.tres
                    port = ports/grebastica.tres
    CelebrationStep id = "celebration" lines = ["The bell rings again over the bay!"]
  fun_fact = "The cathedral of St. James in Šibenik was built only of stone, ..."
```

### Where we are

All fifteen missions play end to end, as data in `data/missions/<nn>_<id>/mission.tres`, with the world in `data/world/` (the chart, the powers, the ports with their views, the people with their portraits, the boats, the hallmarks, the items and the seas of the regions).

* **The steps** (`scenes/missions/steps/`): `BriefingStep` (in person, or `by_pigeon`), `TrailStep` (with `starts_at` for a fixed first port of a random route), `LineupStep` (of boats or of people, by their hallmarks; three or four candidates), `CollectStep` (any `needed` of several `ItemSource`s), `DeliverStep` (an item, or nobody; it is also the `Return` home, and may give something back), `TradeStep` (a chain of `TradeLink`s, learned link by link and traded back), `HearingStep` (a judge's questions, or a riddle; a wrong answer only asks again) and `CelebrationStep`.
* **Every step names its target ports** (`target_ports`), which the chart, the minimap, the arrow and the banner point to, and its `solution`, with which the tests play.
* **A step may continue where the crew is**: when a step starts and the crew is already in its port (e.g., the doctor is found in Dubrovnik, where the medicine is), the scene opens at once.
* **The mission clock** counts 100 km a day and 0.2 days per port. `tests/godot/test_missions.gd` plays every mission with 40 seeds as a good crew would (straight to the nearest target, 30% longer than the straight line, every answer right) and checks that such a crew can earn three stars; it also checks that the line-ups single out exactly one candidate, that every fact is unique, and that the wrong answers only cost time.
* **The screen at the end** (`MissionComplete`) is different for every mission: the view of a port of the story behind it, the happy person of the story in a golden frame (the medal of the Bird Dog in the finale), the mission's own headline and lines (`victory_title`, `victory_lines`), what the crew gets from now on (`reward`), the stars popping in one after the other, the days at sea, and "Did you know?" with the fun fact. `scenes/tests/mission_complete_test/` shows all eight (the arrow keys flip through them and change the stars).

**At sea** (`SeaHazards`, configured by the `SeaConditions` of every region): the storm clouds, the corsairs (they steal 20 ducats, or all on board if fewer, or take a toll of a day when there is nothing to steal; they flee from the patrols, don't dare to come close to two boats sailing together, and the figs buy them off), the Venetian patrols (a bribe of 10 ducats, or an inspection of half a day; they hunt the corsairs), the reefs, and the floating barrels and chests with ducats, a little off the way to the target. The ducats of a mission (barrels, errands, 10 for every task, and 20 from the yataks at the end) stay on board, and what is left at the end is saved with the voyage. Toasts in the middle of the screen tell what happened.

**The merchant** (built): every port scene has a second answer, "What do you sell?", which opens the merchant's stall: a card for every booster the power of the port sells (`Power.offers`, the boosters in `data/world/boosters/*.tres`), with its picture, what it does and its price; a booster the crew can't buy is greyed with the reason. The crew pays from the ducats on board of its boat; at the end, what is left on board is the crew's. The boosters work as in the table above (new sails +20% until the next port, the fisherman announces the wind 20 s ahead, the pilot keeps the reefs and the cliffs from hurting, the flag lets the patrols pass, the figs pay the next corsairs, bread and water give half a day back), at most two for a leg, shown as badges under the hull panel. The pigeon is not sold yet (there is no hint to give). **The purse** of the crew lies on the mission select, its coins piling up with the ducats.

**Master Ivan's shipyard** (built, `scenes/shipyard/`): after mission 2, the mission select has a button for it. Each captain decorates their own boat from the ducats of the crew (25 decorations in `data/world/decorations/`: sails with colours, stripes, a sun, a star, a seagull or the captain's initial; hull paints and a golden band; pennants; a dolphin, a lion, a seagull, a mermaid or a goat as a figurehead; streamers; lanterns; and a cat, a parrot, a dog or a goat on the deck, who leans into the turns). Every card shows a little boat wearing its decoration; buying asks first; what is bought stays bought (`Session.owned`), and every captain's choice is saved with the captain. The boats wear their decorations at sea and on the mission select, next to the purse.

**Saving a mission in progress** (built): every port and leaving the mission save its state into the voyage (`MissionRun.to_data`: the plan, the step, the clock, the hallmarks, the boosters, the errands and every boat's hold; and the boats' positions and the visited ports). Choosing the mission again asks "Continue the mission where you left off?"; finishing it clears the save.

**The rival** (built, `TrailStep.rival`, `Rival`): the Aga's recruiter in mission 2 sails the same trail at a bit more than half the crew's best speed, resting in every port, and shows on the minimap as a green dot. If he reaches the last port of the route while the crew is still on the trail, Master Ivan flees once more: the trail gets one more port of the pool, which costs the crew time, never the mission. He does it only once.

**Dolphins** (built): after a few seconds at full speed, two dolphins come to leap along the bow, and leave when the boat slows down.

**Tips** (built): the first time something happens in a voyage, a small sheet of paper, "A tip from Baba Stana", explains it in the half of the player and fades after a few seconds: the food running low, reefs and cliffs ahead, a damaged hull, a storm cloud, corsairs, a patrol, a floating barrel, a boat which tries to sail into the wind, a coming change of the wind, the first errand, and the merchants and the work of the ports. The voyage remembers the tips it showed (`Session.hints_seen`).

**Leaving a mission** asks first ("Leave the mission? It is saved, and you can continue later."), and the game waits meanwhile, so that Esc never ends a mission by accident. On the menus and in the instruction, Esc asks "Do you really want to quit the game?" before it quits (Enter answers yes, Esc no).

**The waters of the hazards:** the corsairs sail only in their waters (within 170 km of Ulcinj and 90 km of Vlorë), the Venetian patrols only in the waters of Venice (within 70 km of a Venetian port). On the open sea (`SeaConditions.storms`, missions 8, 9 and 12), half the clouds are storms: half again as big, darker, with more rain and lightning; a boat inside sails at a third of its speed, and the gusts push it twice as hard.

**Tacking:** the wind rose marks the directions into the wind, where no boat sails (35° on either side), as a red wedge, and the player's boat as a marker on its rim, red while it heads into the wind; the tip explains the zigzag. In mission 8, the maestral mostly blows against the crew on the way from Dubrovnik to Ancona.

**Sound effects** (`Sfx`), made by the code, so that there are no sound files to license: a crash on the reefs and the cliffs, coins for the ducats (barrels, payments, the merchant), thunder when lightning flashes near the crew, and the church bell at the celebrations of missions 1 and 15 (`CelebrationStep.sound`). They are quiet when the music is muted.

**Saves never mix one and two players:** a mission in progress of two boats does not continue with one player, and vice versa; the mission starts anew.

**The tests** (`tests/godot/`, on every commit): the world and the missions (`test_missions.gd`), every port reachable from the open sea (`test_reachability.gd`, a 1 km grid of the chart flooded from the middle of the Adriatic), every mission played through the real screen with one and two players (`test_all_missions_screen.gd`), the texts fitting their places in every language (`test_text_fit.gd`), the grammar (`test_grammar.gd`), the screen with the merchant, the errands, the towing, the meeting and the saves (`test_mission_screen.gd`), the voyages (`test_session.gd`) and the menus. The soak tests (`tests/soak/`: every mission sailed for minutes, and many random towings) run now and then.

**Not built yet** (the missions play without them): the logbook and the pigeon's hint (the chart already points to the target, so they matter less now).

### The chart and the pictures

* **The chart** (`data/world/adriatic_map.json`) is made by `dev/maps/make_adriatic_map.py` from the 1:10m land and minor islands of Natural Earth (public domain), projected to kilometres around 16° E, 43° N. The game draws it at 11.2 pixels per kilometre, so the screen shows about 171 × 96 km and the whole Adriatic (about 800 km long) is many screens large, like the sea of *Pirates!*, but small enough to cross: a boat sails up to 3 km a second, so crossing the Adriatic takes a bit more than a minute. The minimap in the lower right shows the whole chart with the boats, the target (a golden ring) and the ports of the errands (blue rings); the visited ports are not marked, so that only where to go next stands out.
* **Every port has an icon of its own** (`Port.icon`, drawn by `PortIcons` in the manner of the engraved charts): what the port is known for, from its facts. Pula the arena, Venice the campanile and a gondola, Trieste the salt pans and the yellow flag of the Habsburgs, Rijeka the clock tower, Senj the fortress of Nehaj, Pag the salt pans, Zadar the round church of St. Donatus, Grebaštica the chapel with its bell and a fig tree, Šibenik the domed cathedral, Split the palace of Diocletian, Hvar the theatre and the lavender, Korčula the walled town and a ship on the stocks, Ston the long walls, Dubrovnik the walls with Minčeta and the flag of Libertas, Herceg Novi the fortress and the mimosa, Kotor the walls up the mountain, Ulcinj the rock fortress, an olive tree and a corsair ship, Durrës the amphitheatre, Vlorë the castle of Kanina and the island of Sazan, Corfu the fortress on two peaks, Parga the castle and an orange tree, Preveza the fortress at the strait with a minaret, Rimini the Roman bridge of five arches, Ancona the arch of Trajan, Ortona the castle on the cliff and the dome of St. Thomas, Vieste the white rock of Pizzomunno, Bari the basilica of St. Nicholas, Brindisi the Roman column, and Otranto the cathedral with its rose window under the rising sun. The icon also stands on the name plate of a port's scenes and next to the arrow to the target.
* A port lies where its town is, except where the chart is too coarse for the harbour: Kotor sits at the end of its bay on the chart, about 4 km west of the real town.
* **The pictures** of the ports and the people are period prints (`assets/period/`, made by `dev/assets/fetch_period_art.py`): the town views of Camocio's *Isole famose* (1574) and the costumes of Vecellio's *Habiti antichi et moderni* (1590). A port without its own view shows the paper.


# Plan

## 16. Milestones

1. The pose test: the scene, the recordings and the classifier with its unit tests. **The code is done (see CONTRIBUTING.md). The first live try worked; the recordings with the kids are still to do.**
2. The instruction animation (section 6), with the 3D captain. **The first version is built (`scenes/instruction/`); next comes play-testing it with the kids.**
3. The sailing sandbox: the chart, the boat, the steering, the points of sail, the wheel panel and the wind, then the split screen with two players.
4. The port conversation with the hand cursor and fist clicks.
5. Mission 1 end to end in all three languages. Then play-testing with the kids, to tune the turn rate, the speeds, the leg duration and the wind.
6. The captains, the crews, saving and loading.
7. The ducats, the merchant, the boosters, and the shipyard with its decorations.
8. Missions 2 to 15 and the hazards.

## 17. Open questions

None at the moment. The design decisions so far:

* the time is around 1600,
* the captains live in Pula for now (nobody knows where Liso is from),
* the finale is in Preveza,
* the game is for ten-year-olds, in English, Russian and Dalmatian Croatian, with drafts in German, Spanish, French, Italian, Portuguese, Albanian and Turkish,
* two players play together, and the ducats carry over between missions.
