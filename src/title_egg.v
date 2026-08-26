`default_nettype none
// ---------------------------------------------------------------------------
// TITLE_EGG  --  grasstrook, hoppend ei en "PRESS ANY BUTTON".
//
//   * GRAS   : strook van GRASS_H px onderaan.
//   * EI     : PROCEDUREEL uit twee kleine tabellen, 2x geschaald -> 256 px.
//              Het ei HOPT: een verticale verschuiving uit een tabel.  Geen
//              shear meer -- die brak lijnen omdat een 2x vergrote sprite niet
//              per halve bronpixel kan verschuiven.  Verticaal schuiven is
//              artefactvrij zolang de stappen even zijn (= hele bronpixels).
//   * SCHADUW: blijft op dezelfde plek maar KRIMPT als het ei omhoog gaat.
//              Dat is de gangbare spelconventie: kleiner = verder van de grond.
//              Wil je het andersom (groter in de lucht), zet SHADOW_GROW op 1.
//   * TEKST  : "PRESS ANY BUTTON", knippert asymmetrisch (lang aan, kort uit).
//
// HET EI IS GEEN BITMAP MEER.  egg_128s.hex was 128x128x3 = 49152 bits en
// kostte ~2400 cellen, terwijl er maar drie kleuren in zaten.  Je betaalde dus
// per pixel voor informatie die er niet was.  Nu staan vorm en textuur apart:
//
//   egg_shape.hex : 128 regels {hw_out[5:0], hw_in[5:0]}, 3 hexcijfers.
//                   Per BRONRIJ de halve breedte van de buitenrand en die van
//                   de witte schaal.  Alles daartussen is zwarte rand, dus de
//                   omtrek volgt de getekende vorm en sluit boven EN onder.
//                   hw_in == 0 betekent "deze rij is volledig rand" -- zo zijn
//                   de kapjes boven- en onderaan dicht.
//   egg_spots.hex :  32 regels van 32 bits.  Elke bit = een blok van 4x4
//                   bronpixels (8x8 op het scherm).  Bewust grof; de stippen
//                   zijn textuur, geen lijnwerk, en blijven asymmetrisch.
//
// Samen ~2500 bits.  Beide worden gegenereerd door tools/egg_decompose.py uit
// egg_128s.hex; die hex blijft in de repo als bron-art, maar wordt door de
// hardware niet meer gelezen.  Wil je het ei wijzigen: pas de art aan en draai
// het script opnieuw -- niet dit bestand.
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
  localparam [9:0] EGG_W    = 10'd256;   // 128 * 2
  localparam [9:0] EGG_H    = 10'd256;
  localparam [9:0] EGG_FOOT = 10'd590;   // voet in rust: midden van het gras
  localparam [9:0] EGG_X    = EGG_CX - (EGG_W >> 1);

  localparam SHADOW_GROW = 1'b0;         // 0 = krimpen (normaal), 1 = groeien

  // --- kleurcodes van het ei (zelfde palet als dragon_rgb) ----------------
  localparam [2:0] EGG_EDGE  = 3'd1;     // zwarte omtrek
  localparam [2:0] EGG_SHELL = 3'd4;     // witte schaal
  localparam [2:0] EGG_SPOT  = 3'd5;     // donkergroene vlek

  // --- hop: tabel van verticale offsets ------------------------------------
  // 96 frames = 1.6 s.  Twaalf stappen van 8 frames: omhoog, even hangen,
  // omlaag, dan rust.  Alle waarden EVEN, dus hele bronpixels.
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

  // --- ei: procedureel uit vorm- en stippentabel (128x128 bron, 2x) -------
  wire in_egg_box = (x >= EGG_X) && (x < EGG_X + EGG_W) &&
                    (y >= EGG_Y) && (y < EGG_Y + EGG_H);
  wire [9:0] offx = x - EGG_X;
  wire [9:0] offy = y - EGG_Y;
  wire [9:0] sclx = offx >> 1;
  wire [9:0] scly = offy >> 1;
  wire [6:0] rel_x = in_egg_box ? sclx[6:0] : 7'd0;
  wire [6:0] rel_y = in_egg_box ? scly[6:0] : 7'd0;

  // Afstand tot de middenas.  De as ligt tussen kolom 63 en 64, dus de rechter
  // helft krijgt er 1 bij -- exact dezelfde formule als egg_decompose.py, want
  // anders staat de rand aan een kant een pixel scheef.
  wire [6:0] dax = (rel_x > 7'd63) ? (rel_x - 7'd62) : (7'd63 - rel_x);

  reg [11:0] shape [0:127];
  initial $readmemh("egg_shape.hex", shape);
  wire [11:0] srow   = shape[rel_y];
  wire [5:0]  hw_out = srow[11:6];       // buitenrand van de schaal
  wire [5:0]  hw_in  = srow[5:0];        // waar de witte schaal begint

  // hw_out == 0 (lege rij) valt hier vanzelf af: dax < 0 is nooit waar.
  wire in_shell = in_egg_box && (dax < {1'b0, hw_out});
  wire on_edge  = in_shell && ((hw_in == 6'd0) || (dax >= {1'b0, hw_in}));

  // stippen: 32x32 blokken van 4x4 bronpixels, NIET gespiegeld
  reg [31:0] spots [0:31];
  initial $readmemh("egg_spots.hex", spots);
  wire [31:0] spot_row = spots[rel_y[6:2]];
  wire        spot     = spot_row[rel_x[6:2]];

  wire [2:0] code = !in_shell ? 3'd0      :
                    on_edge   ? EGG_EDGE  :
                    spot      ? EGG_SPOT  :
                                EGG_SHELL;

  // Het ei blijft zichtbaar tot de flits het overneemt.  Zou je het bij
  // egg_frame 5 laten verdwijnen, dan zie je een frame lang leeg gras -- een
  // zichtbare "pop".  De flits groeit vanuit het midden van het ei naar buiten
  // en eet het als het ware van binnenuit op.
  assign egg_on   = in_shell;
  assign egg_code = code;

  // ======================= BARST ==========================================
  // DRIE hoofdstralen vanuit een punt midden in het ei, 120 graden uit elkaar
  // (een echte drieslag-breuk) en met een offset gedraaid, zodat geen enkele
  // recht omhoog of recht opzij wijst.  Er zaten ooit twee vertakkingen bij;
  // die kostten samen ~400 cellen en zijn eruit gehaald -- git bewaart ze.
  //
  // In ruil komen de drie stralen nu NA ELKAAR: eerst A, dan B erbij, dan C.
  // Dat leest als een ei dat stap voor stap openbreekt, in plaats van drie
  // lijnen die synchroon uitzetten.  Het is bovendien goedkoper -- elke straal
  // leest zijn lengte uit de tabel, zonder gedeelde `grow` met drie
  // afkapvergelijkingen erachter.
  //
  // Elke straal krijgt een driehoeksgolf-slingering.
  // REGEL: helling + slingering moet onder de lijndikte blijven, anders valt
  // de straal uiteen in losse stukjes.
  //
  // Alles rekent in 10-bit signed: de grootste tussenwaarde is
  // OX + tC + (tC>>>2) + wob = 313, ruim binnen -512..511.
  wire [9:0] lx = x - EGG_X;                     // lokaal 0..255
  wire [9:0] ly = y - EGG_Y;
  wire signed [9:0] slx = $signed({2'b0, lx[7:0]});
  wire signed [9:0] sly = $signed({2'b0, ly[7:0]});

  localparam signed [9:0] OX = 10'sd128;         // oorsprong midden in het ei
  localparam signed [9:0] OY = 10'sd112;

  // Lengte per straal per frame; 0 = deze straal bestaat nog niet.
  // De lijn wordt dikker naarmate het ei verder openbreekt.
   // Lengte per straal per frame; 0 = deze straal bestaat nog niet.
  // Twee stralen, 120 graden uit elkaar: A omhoog, B naar links.  Er was ooit
  // een derde (C, naar rechtsonder) plus twee vertakkingen; die zijn eruit
  // gehaald toen de plaats op moest -- git bewaart ze.
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
    begin
      hlf = t[2:0];
      trw = t[3] ? (4'd7 - {1'b0,hlf}) : {1'b0,hlf};
      wob = $signed({6'b0, trw[2:0], 1'b0}) - 10'sd7;
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
  wire [9:0] fdx = (x >= EGG_CX) ? (x - EGG_CX) : (EGG_CX - x);
  wire [9:0] fcy = EGG_FOOT - 10'd128;                  // midden van het ei
  wire [9:0] fdy = (y >= fcy) ? (y - fcy) : (fcy - y);
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
endmodule