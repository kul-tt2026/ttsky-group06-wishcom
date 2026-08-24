# Dragonchi - Render-gids

Alles wat de render group moet weten: welk signaal je binnenkrijgt, wat je ermee
tekent, en welke logica daarvoor bij jullie hoort. Jullie krijgen antwoorden
binnen en tekenen die - hoe de game-kant rekent staat hier bewust niet in.

Laatst bijgewerkt: 10 aug 2026. (Dit bestand is bewust ASCII-only zodat het in
elke editor goed leest.)

---

## 1. De VGA-basis

- **640x480 @ 60 Hz, "race the beam".** Er is geen framebuffer: voor elke pixel
  die de straal passeert beslis je op dat moment welke kleur hij krijgt.
  `pix_x`/`pix_y` (10 bits) zeggen waar de straal is, en jullie combinatoriek
  levert `R`,`G`,`B` af.
- **`video_active` laag betekent: RGB MOET zwart.** Buiten het zichtbare gebied
  iets anders dan 000000 sturen breekt de sync op echte monitoren.
- **64 kleuren:** 2 bits per kanaal (niveaus 00/55/AA/FF). Palet-swatch:
  `vga64_swatch.png` in de repo.
- **`uo_out = {hsync, B0, G0, R0, vsync, B1, G1, R1}`** - vastgelegd door de
  TinyVGA-Pmod, nooit herschikken. Dit zit in `project.v`; jullie leveren alleen
  R/G/B.
- **Schalen alleen x2/x4/x8** (bit-shift, gratis). Andere factoren kosten
  vermenigvuldigers die er niet zijn.
- **Sprites via `png2rom.py`**: PNG -> Verilog-ROM, kleurt automatisch af op het
  64-palet en waarschuwt bij afwijkingen.

### De drawable-afspraak
`renderer.v` is de baas en de enige die `mode` ziet. Elke drawable beantwoordt
een vraag: "is deze pixel van jou, en welke kleurcode?" via `px_on`/`px_code`,
in **lokale** coordinaten - de baas trekt de origin af (`.x(pix_x - DRAGON_X)`).
Alle posities zijn localparams in `renderer.v`; iets verplaatsen is een regel.

**Laagvolgorde, voor naar achter: hud > bars > dragon > chests > achtergrond.**
De eerste zichtbare laag wint.

---

## 2. `mode [2:0]` - welke compositie

| Waarde | Scherm | Wat je tekent |
|---|---|---|
| 0 | TITLE | logo / "PRESS ANY BUTTON". Mag simpel: effen kleur + tekst-sprite |
| 1 | EGG | breek ei open door knopklik  
| 2 | HOME | dragon + satisfaction-balk + menu-iconen + hud |
| 3 | CHEST | drie kisten + pot + hud (dragon niet) |
| 4 | GAMEOVER | apart scherm; de gewone dragon verdwijnt |
| 5 | YOU_WIN | apart scherm, feestelijk |

`game_over` en `you_win` bestaan als signalen maar **komen niet bij jullie** -
ze bereiken jullie uitsluitend als mode 3 of 4. Nooit apart op testen.

De hud is zichtbaar in HOME en CHEST (en desgewenst YOU_WIN) - dat regel je met
de `show_*` enable-wires; dat is de volledige kost van meerdere composities.

---

## 3. De stats, een voor een

### `hearts [2:0]` - 0 t/m 5
**Vijf** hart-iconen op een rij (hud). `hearts` is het aantal gevulde; de rest
teken je leeg (omtrek) zodat de speler ziet wat hij mist. Logica: per icoon
`i < hearts ? vol : leeg` - een vergelijking per positie, geen teller.

### `satisfaction [2:0]` - 0 t/m 4
Horizontale balk met **vijf** segmenten; spelstart staat op 2 (midden).
Per segment: `i < fill ? gevuld : leeg`. Kleursuggestie: groen gevuld,
donkergrijs leeg. Dezelfde waarde stuurt ook de gezichtsuitdrukking van de
dragon (zie paragraaf 4).

### `coins [9:0]` - 0 t/m 999
**Drie decimale cijfers** in de hud. Binair -> decimaal gaat via double-dabble;
let op dat die **10 bits** aankan (een 8-bit versie stopt bij 255).
Cijfer-sprites komen uit `digit_rom` in `sprites.v`. Voorloopnullen mogen
("047") - dat is zelfs makkelijker en leesbaarder in pixelstijl.

### `level [2:0]` - 0 t/m 7, en de vorm-mapping
Dit is het enige stuk spel-logica dat bij jullie hoort, in `dragon_draw.v`:

```verilog
wire [1:0] form = (level >= 3'd7) ? 2'd2 :
                  (level >= 3'd3) ? 2'd1 : 2'd0;
```

| Level | Tekening |
|---|---|
| 0-2 | vorm 1 (baby) |
| 3-6 | vorm 2 |
| 7 | vorm 3 (eindvorm) |

De mapping staat bewust bij jullie, naast de artwork: komt er ooit een vierde
tekening, dan verandert er buiten `dragon_draw.v` niets. Toon daarnaast het
level-cijfer zelf in de hud (een digit, zelfde digit_rom).

**Level-up is geen event voor jullie.** Jullie lezen elk frame de huidige
waarde; het frame na een evolve staat er gewoon een hoger getal. Willen jullie
een fanfare (flits bij de vormwissel), onthoud dan zelf de vorige waarde:

```verilog
reg [2:0] level_d;
always @(posedge clk) if (frame_tick) level_d <= level;
wire level_changed = (level != level_d);   // start een flits-timer
```

### `evolve_now` - 1 bit
Betekent: de speler kan de volgende evolutie betalen. Kant-en-klaar berekend;
**jullie rekenen nooit met prijzen of munten.** Implementatie: het
EVOLVE-icoon krijgt twee gedaantes - opgelicht/fel bij 1, gedimd/grijs bij 0.
Een `if` op de kleurkeuze van dat icoon. Niet knipperen: het is een toestand
die minutenlang hoog kan staan, knipperen wordt irritant.

### `overflow` - 1 bit
Flitst als de speler iets deed dat al op max zat (hartjes vol, munten op 999,
humeur op max). Het signaal is **al getimed**: het blijft precies 2 seconden
hoog en gaat vanzelf uit. Jullie kiezen alleen wat er anders uitziet zolang
het hoog is - simpelste goede optie: de hud laten knipperen op het bestaande
`flash`-signaal (`overflow && flash ? ~rgb : rgb`). Welke stat het was krijg
je niet te horen; de hele hud flitsen is prima.

### `combo_len [1:0]` - **NIET TEKENEN**
Bestaat als signaal, maar er komt **geen combo-balk** op het scherm. Sluit hem
aan op de `_unused`-truc en verder niets. De tweede bar-instantie die hiervoor
bedoeld was kan eruit.

### `menu_sel [2:0]` - **NIET TEKENEN**
Met de nieuwe knoppenmap (zie paragraaf 7) heeft elke actie een eigen knop,
dus er is geen cursor meer op het home-menu. Teken de vijf iconen met hun
knop-hint erbij (het cijfer of het knopsymbool); een highlight-kader is niet
nodig. `menu_sel` gaat in `_unused`.

---

## 4. Dragon-signalen (HOME-scherm)

De dragon wordt bepaald door **drie onafhankelijke assen** - er is bewust geen
gecombineerde "dragon-staat"-variabele:

| As | Signaal | Wat het kiest |
|---|---|---|
| Vorm | `level` | welke sprite-ROM (paragraaf 3) |
| Uitdrukking | `satisfaction` | het gezicht: 0-1 sip, 2-3 neutraal, 4 blij |
| Beweging | `dragon_bob [1:0]`, `dragon_mood_anim [1:0]` | animatieframe / y-offset |

Teken de uitdrukking als **kleine losse sprite** (ogen/mond) boven op het
lichaam, niet als complete dragon per stemming - anders heb je 3 vormen x 3
stemmingen = 9 volledige ROMs en dat past niet in het budget.

`dragon_bob` is het goedkoopst als y-offset: `.y(pix_y - DRAGON_Y - bob_offset)`.

LET OP, breedte-conflict om te fixen: `renderer.v` declareert
`dragon_mood_anim [2:0]`, maar het signaal is **2 bits**. Gelijktrekken.

---

## 5. Minigame-signalen (CHEST-scherm)

### `chest_state [1:0]` - welke fase je tekent
| Waarde | Fase | Wat je tekent |
|---|---|---|
| 0 | PICK | drie dichte kisten, highlight op `chest_sel` |
| 1 | OPEN | open-animatie op de gekozen kist (`chest_frame` is het frame) |
| 2 | RESULT | **alle drie de kisten open** - toon ook wat niet gekozen is |
| 3 | MENU | het doorgaan-of-cashen-scherm (zie onder) |

Fase 2 is het belangrijkste gevoelsmoment van het spel: de bom die je ontweek
laten zien kost niets (de inhoud ligt toch al vast) en doet meer dan welke
beloning ook.

### `chest_sel [1:0]` - 0 t/m 2
Welke kist de speler nu aanwijst (knoppen 1/3, zie paragraaf 7). Highlight =
omranding of lichtere tint; de `highlighted`-input van `chest_draw` bestaat
hiervoor al.

### `chest_outcome [2:0]` - wat er in de geopende kist zat
| Code | Inhoud | Sprite-eis |
|---|---|---|
| 0 | munt | |
| 1 | x2 | |
| 2 | cursed potion | |
| 3 | bom | |
| 4 | **bom-2** | **moet zichtbaar verschillen van code 3** - tint of vonkje. Een speler die een hartje verliest aan iets dat er identiek uitzag als wat hij net overleefde, voelt zich bedrogen in plaats van gewaarschuwd |

Vijf inhoud-sprites, maar een kist-lichaam: teken de inhoud als klein los
sprite'je in/boven de open kist, net als de dragon-uitdrukking.

### Het MENU-scherm (`chest_state == 3`)
Hier kiest de speler: doorgaan of cashen. Te tonen:
- de **pot**, groot en duidelijk gescheiden van de portemonnee in de hud -
  dat verschil IS de spanning van het spel
- het **rondenummer** (intern 0-gebaseerd: teken `round + 1`)
- de twee opties met hun knop: **6 = doorgaan, 7 = cashen en stoppen**

LET OP: `pot [9:0]` en `round [3:0]` worden nog niet geexporteerd door de
game-kant; dat is aangevraagd. Bouw het scherm alvast tegen die twee poorten.

### `chest_frame [1:0]`, `flash`, `flame_frame`
Animatieframes. `flash` is een generieke knipper-klok - ook bruikbaar voor de
overflow-flits (paragraaf 3) en de kist-highlight.

---

## 6. Knop-hints op het scherm

Omdat elke functie een vaste knop heeft, zijn hints belangrijker dan cursors.
Per scherm horen deze hints in beeld (klein, hud-stijl):

- HOME: bij elk menu-icoon zijn knopnummer (4 FEED, 5 DRINK, 6 SLEEP, 7 PLAY,
  1 EVOLVE)
- CHEST/PICK: "1/3 = kies kist, 6 = open, 7 = stop"
- CHEST/MENU: "6 = doorgaan, 7 = cashen"
- TITLE / GAMEOVER / YOU_WIN: "druk op een knop"

---

## 7. De controller

Acht knoppen, elk als een-frame puls in `btn_pressed`. De nummers in de
afbeelding zijn de bitnummers:

![Knoppenmap](controller_layout.png)

D-pad: 0 = links, 1 = boven, 2 = rechts, 3 = onder.
Diamant rechts: 4 = links, 5 = boven, 6 = rechts, 7 = onder.

| Bit | Op HOME | Op CHEST |
|---|---|---|
| 0 | - | - |
| 1 | **EVOLVE** | **kist-cursor omhoog/vorige** |
| 2 | - | - |
| 3 | - | **kist-cursor omlaag/volgende** |
| 4 | FEED | - |
| 5 | DRINK | - |
| 6 | SLEEP | **SELECT: kist openen / doorgaan (MENU-fase)** |
| 7 | PLAY (minigame in) | **BACK: cashen en stoppen** |

Bits 1, 3, 6 en 7 betekenen dus iets anders in de minigame dan op HOME. Voor
jullie relevant omdat de knop-hints per compositie moeten kloppen - en dit
hoort straks ook op het bedieningskaartje bij de demo.

LET OP: dit is de NIEUWE map. `home.v` implementeert op dit moment nog de oude
(0-3 = acties, 6 = select-menu); die wordt aangepast. De hints die jullie
tekenen moeten deze tabel volgen, niet de oude code.

---

## 8. Wat jullie bewust NIET krijgen

| Signaal | Waarom niet |
|---|---|
| `game_over`, `you_win` | bereiken jullie als `mode` 3/4 - een bron van waarheid |
| `req_evolve` en alle `req_*` | spel-verzoeken; jullie zien alleen het gevolg (de stats veranderen) |
| evolve-prijzen, ronde-regels | `evolve_now` en `chest_state` zijn de kant-en-klare antwoorden |
| `coins` voor betaalbaarheid | dat is `evolve_now`; `coins` gebruiken jullie alleen om cijfers te tekenen |

De regel achter dit alles: **de render group rekent nooit spelregels uit, de
game group bepaalt nooit waar iets op het scherm staat.**

---

## 9. Checklist per drawable

| Module | Krijgt | Levert | Kern-logica |
|---|---|---|---|
| `renderer.v` | alles hierboven | R,G,B | PLACE / SHOW / STACK / COLOUR; enige `mode`-lezer |
| `dragon_draw.v` | lokale x/y, level, satisfaction*, bob, mood_anim | px_on, px_code | vorm-mapping (par. 3), lichaam-ROM + uitdrukking-sprite |
| `chest_draw.v` x3 | lokale x/y, frame, highlighted, inhoud-code | px_on, px_code | een module, drie origins; inhoud als los sprite'je |
| satisfaction-bar | lokale x/y, fill | px_on, px_code | segmenten: `i < fill` |
| `hud.v` | absolute x/y, hearts, coins, level | px_on, px_code | 5 hartjes, double-dabble **10-bit**, 3+1 digits |

*satisfaction gaat nu nog niet naar dragon_draw - toevoegen zodra de
uitdrukkings-sprites bestaan.

Na elke merge: `yosys -p "read_verilog src/*.v; synth -top <topnaam>; stat"` en
het celgetal in de groepschat. Sprites zijn de grootste onbekende in het
budget - meet ze vroeg met echte artwork, niet met placeholders.
