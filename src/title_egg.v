`default_nettype none
// ---------------------------------------------------------------------------
// TITLE_EGG  --  grasstrook, hoppend ei en "PRESS ANY BUTTON".
//
//   * GRAS   : strook van GRASS_H px onderaan.
//   * EI     : één 32x32 sprite, 8x geschaald -> 256 px.  Het ei HOPT: een
//              verticale verschuiving uit een tabel.  Geen shear -- die brak
//              lijnen omdat een vergrote sprite niet per halve bronpixel kan
//              verschuiven.  Verticaal schuiven is artefactvrij zolang de
//              stappen een veelvoud van de schaal zijn (hier: even is genoeg,
//              8 zou perfect zijn -- zie de opmerking bij de hop-tabel).
//   * SCHADUW: blijft op dezelfde plek maar KRIMPT als het ei omhoog gaat.
//              Dat is de gangbare spelconventie: kleiner = verder van de grond.
//              Wil je het andersom (groter in de lucht), zet SHADOW_GROW op 1.
//   * TEKST  : "PRESS ANY BUTTON", knippert asymmetrisch (lang aan, kort uit).
//
// HET EI IS WEER EEN GEWONE BITMAP, maar nu op 32x32 in plaats van 128x128.
// De geschiedenis in het kort:
//
//   egg_128s.hex   128x128x3 = 49152 bits, ~2400 cellen.  Veel te duur.
//   shape + spots  procedureel, ~2500 bits.  Goedkoper, maar de vorm moest
//                  gespiegeld zijn (halve breedte per rij) en de stippen
//                  zaten in een aparte tabel met een 32:1 mux erachter.
//   egg_32.hex     1024 pixels x 3 bits = 3072 bits.  <-- NU
//
// De 32x32-versie is niet alleen goedkoper dan de procedurele (gemeten in een
// losse testbank: 416 tegen 550 cellen), ze is ook eerlijker: de sprite is
// precies wat je tekent, inclusief asymmetrie, zonder dat vorm en textuur in
// twee tabellen uit elkaar getrokken worden.  tools/egg_decompose.py is
// daarmee overbodig geworden; egg_shape.hex en egg_spots.hex mogen weg.
//
// Wil je het ei wijzigen: teken een nieuwe 32x32 en schrijf hem als egg_32.hex,
// één hexcijfer per pixel, 32 per regel.  De codes zijn die van dragon_rgb:
//   0 = transparant   1 = zwarte rand   2 = grijze schaduw
//   4 = witte schaal  5 = donkergroene vlek
//
// Uitgangen (de renderer kiest de kleuren):
//   egg_on / egg_code : gebruik hetzelfde palet als dragon_rgb (codes 1..7)
//   press_on          : tekstpixel, teken hem zwart
//   ground_on         : gras of schaduw
//   ground_shadow     : 1 = schaduw, 0 = gras
//
// Laagvolgorde in de renderer:  tekst > ei > grond > lucht
// ---------------------------------------------------------------------------
module title_egg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire [9:0] x,             // portret-x  0..479
    input  wire [9:0] y,             // portret-y  0..639
    input  wire [2:0] egg_frame,     // 0 heel .. 4 wijd open, 5 same
    input  wire [9:0] flash_r,       // straal van de flits; 0 = uit
    input  wire [9:0] flash_cx, 
    input  wire [9:0] flash_cy, 

    output wire       egg_on,
    output wire [2:0] egg_code,
    output wire       crack_on,      // teken deze donker, BOVEN het ei
    output wire       flash_on,      // schijf, BOVEN alles
    output wire       flash_rim,     // 1 = buitenste bies (rood), 0 = kern (oranje)
    output wire       press_on,
    output wire       ground_on,
    output wire       ground_shadow
);
  // --- plaatsing (titelkaart eindigt op y = 249 bij T_Y = 155) -------------
  localparam [9:0] PRESS_X  = 10'd114;   // (480 - 252) / 2
  localparam [9:0] PRESS_Y  = 10'd286;
  localparam [9:0] PRESS_W  = 10'd252;   // 63 native * 4
  localparam [9:0] PRESS_H  = 10'd20;    //  5 native * 4

  localparam [9:0] GRASS_Y  = 10'd540;
  localparam [9:0] GRASS_H  = 10'd100;

  localparam [9:0] EGG_CX   = 10'd240;
  localparam [9:0] EGG_W    = 10'd256;   // 32 * 8
  localparam [9:0] EGG_H    = 10'd256;
  localparam [9:0] EGG_FOOT = 10'd590;   // voet in rust: midden van het gras
  localparam [9:0] EGG_X    = EGG_CX - (EGG_W >> 1);

  localparam SHADOW_GROW = 1'b0;         // 0 = krimpen (normaal), 1 = groeien

  // --- kleurcodes van het ei (zelfde palet als dragon_rgb) ----------------
  // Ze staan nu IN egg_32.hex; deze namen blijven staan als legenda.
  //   1 = EGG_EDGE (zwart)   2 = grijs   4 = EGG_SHELL (wit)   5 = EGG_SPOT

  // --- hop: tabel van verticale offsets ------------------------------------
  // 96 frames = 1.6 s.  Twaalf stappen van 8 frames: omhoog, even hangen,
  // omlaag, dan rust.
  //
  // LET OP: de sprite is nu 8x geschaald, dus een offset die geen veelvoud van
  // 8 is verschuift het ei met een fractie van een bronpixel.  Dat is niet
  // fout -- het ei blijft heel, want de hele bitmap schuift mee -- maar de
  // blokjes "trillen" een pixel op hun rasterlijn.  Wil je dat weg, gebruik
  // dan alleen veelvouden van 8 (0, 8, 16, 24); de tabel hieronder houdt de
  // oude, fijnere beweging aan omdat die vloeiender oogt.
  //
  // Zodra het barsten begint MAAKT het ei zijn hop af en blijft dan liggen.
  // Meteen stilzetten zou het ei mid-lucht naar de grond laten springen.
  wire cracking = (egg_frame != 3'd0);

  reg  [6:0] hop_cnt;
  reg  [5:0] hop;                         // hoogte boven de grond, 0..20
  reg        landed;
  wire       hold = cracking && landed;

  always @(posedge clk) begin
    if (!rst_n)                   hop_cnt <= 7'd0;
    else if (frame_tick && !hold) hop_cnt <= (hop_cnt == 7'd95) ? 7'd0
                                                                : hop_cnt + 7'd1;
  end

  always @(*) case (hop_cnt[6:3])
    4'd0:  hop = 6'd0;
    4'd1:  hop = 6'd8;
    4'd2:  hop = 6'd14;
    4'd3:  hop = 6'd18;
    4'd4:  hop = 6'd20;                   // hangen
    4'd5:  hop = 6'd20;
    4'd6:  hop = 6'd18;
    4'd7:  hop = 6'd14;
    4'd8:  hop = 6'd8;
    default: hop = 6'd0;                  // 9,10,11 = rust op de grond
  endcase

  always @(posedge clk) begin
    if (!rst_n)            landed <= 1'b0;
    else if (frame_tick) begin
      if      (!cracking)   landed <= 1'b0;   // terug op TITLE
      else if (hop == 6'd0) landed <= 1'b1;   // hij staat op de grond
    end
  end

  wire [9:0] foot_now = EGG_FOOT - {4'b0, hop};
  wire [9:0] EGG_Y    = foot_now - EGG_H;

  // --- knipperen: 3 s cyclus, lang aan / kort uit --------------------------
  reg [7:0] blink_cnt;
  reg       blink;
  always @(posedge clk) begin
    if (!rst_n) begin
      blink_cnt <= 8'd0; blink <= 1'b1;
    end else if (frame_tick) begin
      if (blink_cnt == 8'd179) blink_cnt <= 8'd0;
      else                     blink_cnt <= blink_cnt + 8'd1;
      blink <= (blink_cnt < 8'd150);      // 2.5 s aan, 0.5 s uit
    end
  end

  // --- ei: één 32x32 bitmap, 8x geschaald ---------------------------------
  // De deling door 8 is een bitselectie, dus gratis: offx[7:3] is exact
  // offx >> 3 voor de 0..255 die binnen het vak voorkomen.  Buiten het vak
  // klemmen we het adres op 0 zodat de ROM niet op een willekeurig adres
  // geadresseerd wordt (scheelt logica en houdt de simulatie deterministisch).
  wire in_egg_box = (x >= EGG_X) && (x < EGG_X + EGG_W) &&
                    (y >= EGG_Y) && (y < EGG_Y + EGG_H);
  wire [9:0] offx = x - EGG_X;
  wire [9:0] offy = y - EGG_Y;
  wire [4:0] rel_x = in_egg_box ? offx[7:3] : 5'd0;
  wire [4:0] rel_y = in_egg_box ? offy[7:3] : 5'd0;
  wire [9:0] eaddr = {rel_y, rel_x};

  reg [2:0] egg_rom [0:1023];
  initial $readmemh("egg_32.hex", egg_rom);
  wire [2:0] code = egg_rom[eaddr];

  // in_shell = "hier zit ei".  De barst hangt hiervan af, dus de naam blijft.
  wire in_shell = in_egg_box && (code != 3'd0);

  // Het ei blijft zichtbaar tot de flits het overneemt.  Zou je het bij
  // egg_frame 5 laten verdwijnen, dan zie je een frame lang leeg gras -- een
  // zichtbare "pop".  De flits groeit vanuit het midden van het ei naar buiten
  // en eet het als het ware van binnenuit op.
  assign egg_on   = in_shell;
  assign egg_code = code;

  // ======================= BARST ==========================================
  // Twee stralen vanuit een punt midden in het ei, 120 graden uit elkaar, met
  // een offset gedraaid zodat geen enkele recht omhoog of recht opzij wijst.
  // Er zaten ooit een derde straal en twee vertakkingen bij; die kostten samen
  // ~400 cellen en zijn eruit gehaald -- git bewaart ze.
  //
  // De stralen komen NA ELKAAR: eerst A, dan B erbij.  Dat leest als een ei
  // dat stap voor stap openbreekt, in plaats van lijnen die synchroon uitzetten.
  //
  // Elke straal krijgt een driehoeksgolf-slingering.
  // REGEL: helling + slingering moet onder de lijndikte blijven, anders valt
  // de straal uiteen in losse stukjes.
  //
  // Alles rekent in 10-bit signed: de grootste tussenwaarde is
  // OX + tC + (tC>>>2) + wob = 313, ruim binnen -512..511.
  //
  // De barst rekent in SCHERMpixels (0..255 binnen het ei), niet in bronpixels,
  // dus hij is niet meegeschaald naar 32x32 en blijft even fijn als voorheen.
  wire [9:0] lx = x - EGG_X;                     // lokaal 0..255
  wire [9:0] ly = y - EGG_Y;
  wire signed [9:0] slx = $signed({2'b0, lx[7:0]});
  wire signed [9:0] sly = $signed({2'b0, ly[7:0]});

  localparam signed [9:0] OX = 10'sd128;         // oorsprong midden in het ei
  localparam signed [9:0] OY = 10'sd112;

  // Lengte per straal per frame; 0 = deze straal bestaat nog niet.
  // De lijn wordt dikker naarmate het ei verder openbreekt.
  reg [7:0] lenA, lenB;
  reg [2:0] cw;
  always @(*) case (egg_frame)
    3'd0:    begin lenA=8'd0;   lenB=8'd0;   cw=3'd0; end
    3'd1:    begin lenA=8'd45;  lenB=8'd0;   cw=3'd2; end
    3'd2:    begin lenA=8'd80;  lenB=8'd40;  cw=3'd2; end
    3'd3:    begin lenA=8'd104; lenB=8'd80;  cw=3'd3; end
    default: begin lenA=8'd104; lenB=8'd112; cw=3'd4; end
  endcase

  // slingering: driehoeksgolf, periode 16, amplitude 7.
  // Alleen de onderste vier bits doen mee, dus die geven we ook maar door.
  function signed [9:0] wob;
    input [3:0] t;
    reg [2:0] hlf;
    reg [3:0] trw;
    reg _unused_trw;
    begin
      hlf = t[2:0];
      trw = t[3] ? (4'd7 - {1'b0,hlf}) : {1'b0,hlf};
      wob = $signed({6'b0, trw[2:0], 1'b0}) - 10'sd7;

      _unused_trw = trw[3];
    end
  endfunction

  // |here - want| <= w, zonder de dubbele aftrekking van absdiff.
  // (here - want + w) ligt in 0..2w precies als het verschil binnen w valt:
  // te negatief en de som wordt negatief (unsigned: enorm), te positief en hij
  // wordt groter dan 2w.  Een aftrekking, een optelling, EEN vergelijking.
  // BEIDE waarden als argument meegeven -- leest een functie een modulesignaal
  // van binnenuit, dan wordt de continue toewijzing daar niet gevoelig voor en
  // tekent de straal nooit.  Stille fout.
  function ok;
    input signed [9:0] here;
    input signed [9:0] want;
    input        [2:0] w;
    reg   signed [9:0] d;
    begin
      d  = here - want + $signed({7'b0, w});
      ok = ($unsigned(d) <= {6'b0, w, 1'b0});     // {w,1'b0} = 2*w
    end
  endfunction

  // ---- straal A: omhoog, licht naar rechts -- verschijnt als eerste -------
  wire signed [9:0] tA = OY - sly;
  wire hitA = (tA >= 0) && (tA < $signed({2'b0, lenA})) &&
              ok(slx, OX + (tA >>> 2) + wob(tA[3:0]), cw);

  // ---- straal B: naar links, licht omlaag -- komt er in frame 2 bij -------
  //      langs x geparametriseerd, want deze is bijna horizontaal
  wire signed [9:0] tB = OX - slx;
  wire hitB = (tB >= 0) && (tB < $signed({2'b0, lenB})) &&
              ok(sly, OY + (tB >>> 2) + wob(tB[3:0]), cw);

  assign crack_on = in_shell && (hitA || hitB);


  // ======================= FLITS ==========================================
  // Een groeiende schijf die het scherm overneemt.  Een echte cirkel kost twee
  // vermenigvuldigingen per pixel (duur!); een ACHTHOEK benadert hem met
  // alleen vergelijkingen en shifts:  max + min/2 <= r.
  // flash_r komt van buiten (home.v telt hem op), zodat de groei vloeiend is.
  wire [9:0] fdx = (x >= flash_cx) ? (x - flash_cx) : (flash_cx - x);
  wire [9:0] fdy = (y >= flash_cy) ? (y - flash_cy) : (flash_cy - y);

  wire [9:0] fmx = (fdx > fdy) ? fdx : fdy;
  wire [9:0] fmn = (fdx > fdy) ? fdy : fdx;
  localparam [9:0] RIM = 10'd10;        // dikte van de rode bies
  wire [9:0] fd   = fmx + (fmn >> 1);   // achthoek-"afstand"
  assign flash_on  = (flash_r != 10'd0) && (fd <= flash_r);
  // de buitenste RIM pixels van de schijf krijgen een andere kleur
  assign flash_rim = flash_on && (fd + RIM > flash_r);

  // --- PRESS ANY BUTTON (3x5 font, 4x geschaald) --------------------------
  localparam PRESS = 1'b0;
  wire in_press = PRESS && blink &&
                  (x >= PRESS_X) && (x < PRESS_X + PRESS_W) &&
                  (y >= PRESS_Y) && (y < PRESS_Y + PRESS_H);
  wire [9:0] pdx = x - PRESS_X;
  wire [9:0] pdy = y - PRESS_Y;
  wire [5:0] tx  = pdx[7:2];   // 0..62, was (x - PRESS_X) >> 2
  wire [2:0] ty  = pdy[4:2];   // 0..4,  was (y - PRESS_Y) >> 2

  reg [63:0] press_rows [0:4];
  initial $readmemh("title_press.hex", press_rows);

  wire [2:0]  ty_c = in_press ? ty : 3'd0;
  wire [63:0] prow = press_rows[ty_c];

  assign press_on = in_press && prow[tx];

  // --- schaduw: vaste plek, krimpt als het ei omhoog gaat -----------------
  localparam [9:0] SH_Y = 10'd588;      // net onder de voet in rust

  // halve breedte van de ellips per rij
  wire [9:0] shy = (y >= SH_Y) ? (y - SH_Y) : (SH_Y - y);
  reg [6:0] shw_base;
  always @(*) case (shy[3:0])
    4'd0: shw_base = 7'd66; 4'd1: shw_base = 7'd64; 4'd2: shw_base = 7'd60;
    4'd3: shw_base = 7'd52; 4'd4: shw_base = 7'd40; default: shw_base = 7'd0;
  endcase

  // krimp evenredig met de hoogte: bij hop 20 gaat er 20 af (of erbij)
  wire [6:0] shrink = {1'b0, hop};
  wire [6:0] shw = SHADOW_GROW ? (shw_base + shrink)
                 : ((shw_base > shrink) ? (shw_base - shrink) : 7'd0);

  wire [9:0] shdx = (x >= EGG_CX) ? (x - EGG_CX) : (EGG_CX - x);
  wire shadow = (shy <= 10'd4) && (shdx < {3'b0, shw});

  // --- gras ----------------------------------------------------------------
  wire grass = (y >= GRASS_Y) && (y < GRASS_Y + GRASS_H);

  assign ground_on     = grass || shadow;
  assign ground_shadow = shadow;

  wire _unused = &{1'b0, offx[9:8], offx[2:0], offy[9:8], offy[2:0], lx[9:8], ly[9:8], pdx[9:8], pdx[1:0], pdy[9:5], pdy[1:0]};
endmodule