`default_nettype none
// ---------------------------------------------------------------------------
// TITLE_EGG  --  grasstrook, hoppend ei en "PRESS ANY BUTTON".
//
//   * GRAS   : strook van GRASS_H px onderaan.
//   * EI     : sprite uit egg_128s.hex (128x128), 2x geschaald -> 256 px.
//              Het ei HOPT: een verticale verschuiving uit een tabel.  Geen
//              shear meer -- die brak lijnen omdat een 2x vergrote sprite niet
//              per halve bronpixel kan verschuiven.  Verticaal schuiven is
//              artefactvrij zolang de stappen even zijn (= hele bronpixels).
//   * SCHADUW: blijft op dezelfde plek maar KRIMPT als het ei omhoog gaat.
//              Dat is de gangbare spelconventie: kleiner = verder van de grond.
//              Wil je het andersom (groter in de lucht), zet SHADOW_GROW op 1.
//   * TEKST  : "PRESS ANY BUTTON", knippert asymmetrisch (lang aan, kort uit).
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
    input  wire [2:0] egg_frame,     // 0 heel .. 4 wijd open, 5 weg
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

  // --- hop: tabel van verticale offsets ------------------------------------
  // 96 frames = 1.6 s.  Twaalf stappen van 8 frames: omhoog, even hangen,
  // omlaag, dan rust.  Alle waarden EVEN, dus hele bronpixels.
  reg [6:0] hop_cnt;
  always @(posedge clk) begin
    if (!rst_n)          hop_cnt <= 7'd0;
    else if (frame_tick) hop_cnt <= (hop_cnt == 7'd95) ? 7'd0 : hop_cnt + 7'd1;
  end

  reg [5:0] hop;                          // hoogte boven de grond, 0..20
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

  // zodra het barsten begint staat het ei stil
  wire cracking = (egg_frame != 3'd0);
  wire [9:0] foot_now = cracking ? EGG_FOOT : (EGG_FOOT - {4'b0, hop});
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

  // --- ei-sprite (128x128, 2x) ---------------------------------------------
  wire in_egg_box = (x >= EGG_X) && (x < EGG_X + EGG_W) &&
                    (y >= EGG_Y) && (y < EGG_Y + EGG_H);
  wire [9:0] offx = x - EGG_X;
  wire [9:0] offy = y - EGG_Y;
  wire [9:0] sclx = offx >> 1;
  wire [9:0] scly = offy >> 1;
  wire [6:0] rel_x = in_egg_box ? sclx[6:0] : 7'd0;
  wire [6:0] rel_y = in_egg_box ? scly[6:0] : 7'd0;
  wire [13:0] addr = {rel_y, rel_x};

  reg [2:0] rom [0:16383];
  initial $readmemh("egg_128s.hex", rom);

  wire [2:0] code = rom[addr];
  // Het ei blijft zichtbaar tot de flits het overneemt.  Zou je het bij
  // egg_frame 5 laten verdwijnen, dan zie je een frame lang leeg gras -- een
  // zichtbare "pop".  De flits groeit vanuit het midden van het ei naar buiten
  // en eet het als het ware van binnenuit op.
  assign egg_on   = in_egg_box && (code != 3'd0);
  assign egg_code = code;


  // ======================= BARST ==========================================
  // Geen extra sprites: alles wiskundig.
  //
  // DRIE hoofdstralen vanuit een punt midden in het ei, 120 graden uit elkaar
  // (een echte drieslag-breuk) en met een offset gedraaid, zodat geen enkele
  // recht omhoog of recht opzij wijst.  Daarna TWEE vertakkingen die halverwege
  // een hoofdstraal vertrekken onder een grote hoek (~90 graden), want een tak
  // die bijna evenwijdig loopt leest niet als een tak.
  //
  // Elke straal krijgt een driehoeksgolf-slingering.
  // REGEL: helling + slingering moet onder de lijndikte blijven, anders valt
  // de straal uiteen in losse stukjes.
  wire [9:0] lx = x - EGG_X;                     // lokaal 0..255
  wire [9:0] ly = y - EGG_Y;
  wire signed [11:0] slx = $signed({2'b0, lx});
  wire signed [11:0] sly = $signed({2'b0, ly});

  localparam signed [11:0] OX = 12'sd128;        // oorsprong midden in het ei
  localparam signed [11:0] OY = 12'sd112;

  reg [9:0] grow;
  reg [2:0] cw;
  always @(*) case (egg_frame)
    3'd0: begin grow = 10'd0;   cw = 3'd0; end
    3'd1: begin grow = 10'd45;  cw = 3'd2; end
    3'd2: begin grow = 10'd90;  cw = 3'd2; end
    3'd3: begin grow = 10'd140; cw = 3'd2; end
    3'd4: begin grow = 10'd200; cw = 3'd4; end
    default: begin grow = 10'd200; cw = 3'd4; end
  endcase

  // slingering: driehoeksgolf, periode 16, amplitude 6 (helling 0.375)
  function signed [11:0] wob;
    input [9:0] t;
    reg [2:0] hlf;
    reg [3:0] trw;
    begin
      hlf = t[2:0];
      trw = t[3] ? (4'd7 - {1'b0,hlf}) : {1'b0,hlf};
      wob = $signed({8'b0, trw[2:0], 1'b0}) - 12'sd7;
    end
  endfunction

  // Afstand tussen twee waarden.  BEIDE als argument meegeven: leest een
  // functie een modulesignaal van binnenuit, dan wordt de continue toewijzing
  // daar niet gevoelig voor en tekent de straal nooit.  Stille fout.
  function [9:0] dist;
    input signed [11:0] here;
    input signed [11:0] want;
    begin
      dist = (here >= want) ? (here - want) : (want - here);
    end
  endfunction

  // ---- hoofdstraal A: omhoog, licht naar rechts (offset: niet recht op) ---
  wire signed [11:0] tA = OY - sly;
  wire [9:0] lenA = (grow > 10'd104) ? 10'd104 : grow;
  wire hitA = (tA >= 0) && (tA < $signed({2'b0,lenA})) &&
              (dist(slx, OX + (tA >>> 2) + wob(tA[9:0])) <= {7'b0, cw});

  // ---- hoofdstraal B: naar links, licht omlaag (120 graden van A) --------
  //      langs x geparametriseerd, want deze is bijna horizontaal
  wire signed [11:0] tB = OX - slx;
  wire [9:0] lenB = (grow > 10'd112) ? 10'd112 : grow;
  wire hitB = (tB >= 0) && (tB < $signed({2'b0,lenB})) &&
              (dist(sly, OY + (tB >>> 2) + wob(tB[9:0])) <= {7'b0, cw});

  // ---- hoofdstraal C: omlaag naar rechts (120 graden van B) --------------
  wire signed [11:0] tC = sly - OY;
  wire [9:0] lenC = (grow > 10'd130) ? 10'd130 : grow;
  wire hitC = (tC >= 0) && (tC < $signed({2'b0,lenC})) &&
              (dist(slx, OX + tC + (tC >>> 2) + wob(tC[9:0])) <= {7'b0, cw});

  // ---- tak D: uit A op t=52, bijna HAAKS erop (naar rechts, licht omhoog) -
  localparam signed [11:0] DX0 = OX + 12'sd13;   // 52 >> 2
  localparam signed [11:0] DY0 = OY - 12'sd52;
  wire signed [11:0] tD = slx - DX0;
  wire [9:0] lenD = (grow > 10'd52) ?
                    ((grow - 10'd52 > 10'd70) ? 10'd70 : (grow - 10'd52)) : 10'd0;
  wire hitD = (egg_frame >= 3'd2) && (tD >= 0) && (tD < $signed({2'b0,lenD})) &&
              (dist(sly, DY0 - (tD >>> 2) + wob(tD[9:0])) <= 10'd2);

  // ---- tak E: uit C op t=60, steil naar linksonder (~95 graden van C) ----
  localparam signed [11:0] EX0 = OX + 12'sd75;   // 60 + 15
  localparam signed [11:0] EY0 = OY + 12'sd60;
  wire signed [11:0] tE = sly - EY0;
  wire [9:0] lenE = (grow > 10'd60) ?
                    ((grow - 10'd60 > 10'd60) ? 10'd60 : (grow - 10'd60)) : 10'd0;
  wire hitE = (egg_frame >= 3'd3) && (tE >= 0) && (tE < $signed({2'b0,lenE})) &&
              (dist(slx, EX0 - tE + wob(tE[9:0])) <= 10'd2);

  assign crack_on = in_egg_box && (code != 3'd0) &&
                    (hitA || hitB || hitC || hitD || hitE);

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
  wire in_press = blink &&
                  (x >= PRESS_X) && (x < PRESS_X + PRESS_W) &&
                  (y >= PRESS_Y) && (y < PRESS_Y + PRESS_H);
  wire [5:0] tx = (x - PRESS_X) >> 2;   // 0..62
  wire [2:0] ty = (y - PRESS_Y) >> 2;   // 0..4
  reg pon;
  always @(*) begin
    pon = 1'b0;
    case ({ty, tx})
      {3'd0,6'd0}: pon = 1'b1;
      {3'd0,6'd1}: pon = 1'b1;
      {3'd0,6'd4}: pon = 1'b1;
      {3'd0,6'd5}: pon = 1'b1;
      {3'd0,6'd8}: pon = 1'b1;
      {3'd0,6'd9}: pon = 1'b1;
      {3'd0,6'd10}: pon = 1'b1;
      {3'd0,6'd13}: pon = 1'b1;
      {3'd0,6'd14}: pon = 1'b1;
      {3'd0,6'd17}: pon = 1'b1;
      {3'd0,6'd18}: pon = 1'b1;
      {3'd0,6'd25}: pon = 1'b1;
      {3'd0,6'd28}: pon = 1'b1;
      {3'd0,6'd30}: pon = 1'b1;
      {3'd0,6'd32}: pon = 1'b1;
      {3'd0,6'd34}: pon = 1'b1;
      {3'd0,6'd40}: pon = 1'b1;
      {3'd0,6'd41}: pon = 1'b1;
      {3'd0,6'd44}: pon = 1'b1;
      {3'd0,6'd46}: pon = 1'b1;
      {3'd0,6'd48}: pon = 1'b1;
      {3'd0,6'd49}: pon = 1'b1;
      {3'd0,6'd50}: pon = 1'b1;
      {3'd0,6'd52}: pon = 1'b1;
      {3'd0,6'd53}: pon = 1'b1;
      {3'd0,6'd54}: pon = 1'b1;
      {3'd0,6'd56}: pon = 1'b1;
      {3'd0,6'd57}: pon = 1'b1;
      {3'd0,6'd58}: pon = 1'b1;
      {3'd0,6'd60}: pon = 1'b1;
      {3'd0,6'd62}: pon = 1'b1;
      {3'd1,6'd0}: pon = 1'b1;
      {3'd1,6'd2}: pon = 1'b1;
      {3'd1,6'd4}: pon = 1'b1;
      {3'd1,6'd6}: pon = 1'b1;
      {3'd1,6'd8}: pon = 1'b1;
      {3'd1,6'd12}: pon = 1'b1;
      {3'd1,6'd16}: pon = 1'b1;
      {3'd1,6'd24}: pon = 1'b1;
      {3'd1,6'd26}: pon = 1'b1;
      {3'd1,6'd28}: pon = 1'b1;
      {3'd1,6'd29}: pon = 1'b1;
      {3'd1,6'd30}: pon = 1'b1;
      {3'd1,6'd32}: pon = 1'b1;
      {3'd1,6'd34}: pon = 1'b1;
      {3'd1,6'd40}: pon = 1'b1;
      {3'd1,6'd42}: pon = 1'b1;
      {3'd1,6'd44}: pon = 1'b1;
      {3'd1,6'd46}: pon = 1'b1;
      {3'd1,6'd49}: pon = 1'b1;
      {3'd1,6'd53}: pon = 1'b1;
      {3'd1,6'd56}: pon = 1'b1;
      {3'd1,6'd58}: pon = 1'b1;
      {3'd1,6'd60}: pon = 1'b1;
      {3'd1,6'd61}: pon = 1'b1;
      {3'd1,6'd62}: pon = 1'b1;
      {3'd2,6'd0}: pon = 1'b1;
      {3'd2,6'd1}: pon = 1'b1;
      {3'd2,6'd4}: pon = 1'b1;
      {3'd2,6'd5}: pon = 1'b1;
      {3'd2,6'd8}: pon = 1'b1;
      {3'd2,6'd9}: pon = 1'b1;
      {3'd2,6'd13}: pon = 1'b1;
      {3'd2,6'd17}: pon = 1'b1;
      {3'd2,6'd24}: pon = 1'b1;
      {3'd2,6'd25}: pon = 1'b1;
      {3'd2,6'd26}: pon = 1'b1;
      {3'd2,6'd28}: pon = 1'b1;
      {3'd2,6'd30}: pon = 1'b1;
      {3'd2,6'd33}: pon = 1'b1;
      {3'd2,6'd40}: pon = 1'b1;
      {3'd2,6'd41}: pon = 1'b1;
      {3'd2,6'd44}: pon = 1'b1;
      {3'd2,6'd46}: pon = 1'b1;
      {3'd2,6'd49}: pon = 1'b1;
      {3'd2,6'd53}: pon = 1'b1;
      {3'd2,6'd56}: pon = 1'b1;
      {3'd2,6'd58}: pon = 1'b1;
      {3'd2,6'd60}: pon = 1'b1;
      {3'd2,6'd62}: pon = 1'b1;
      {3'd3,6'd0}: pon = 1'b1;
      {3'd3,6'd4}: pon = 1'b1;
      {3'd3,6'd6}: pon = 1'b1;
      {3'd3,6'd8}: pon = 1'b1;
      {3'd3,6'd14}: pon = 1'b1;
      {3'd3,6'd18}: pon = 1'b1;
      {3'd3,6'd24}: pon = 1'b1;
      {3'd3,6'd26}: pon = 1'b1;
      {3'd3,6'd28}: pon = 1'b1;
      {3'd3,6'd30}: pon = 1'b1;
      {3'd3,6'd33}: pon = 1'b1;
      {3'd3,6'd40}: pon = 1'b1;
      {3'd3,6'd42}: pon = 1'b1;
      {3'd3,6'd44}: pon = 1'b1;
      {3'd3,6'd46}: pon = 1'b1;
      {3'd3,6'd49}: pon = 1'b1;
      {3'd3,6'd53}: pon = 1'b1;
      {3'd3,6'd56}: pon = 1'b1;
      {3'd3,6'd58}: pon = 1'b1;
      {3'd3,6'd60}: pon = 1'b1;
      {3'd3,6'd62}: pon = 1'b1;
      {3'd4,6'd0}: pon = 1'b1;
      {3'd4,6'd4}: pon = 1'b1;
      {3'd4,6'd6}: pon = 1'b1;
      {3'd4,6'd8}: pon = 1'b1;
      {3'd4,6'd9}: pon = 1'b1;
      {3'd4,6'd10}: pon = 1'b1;
      {3'd4,6'd12}: pon = 1'b1;
      {3'd4,6'd13}: pon = 1'b1;
      {3'd4,6'd16}: pon = 1'b1;
      {3'd4,6'd17}: pon = 1'b1;
      {3'd4,6'd24}: pon = 1'b1;
      {3'd4,6'd26}: pon = 1'b1;
      {3'd4,6'd28}: pon = 1'b1;
      {3'd4,6'd30}: pon = 1'b1;
      {3'd4,6'd33}: pon = 1'b1;
      {3'd4,6'd40}: pon = 1'b1;
      {3'd4,6'd41}: pon = 1'b1;
      {3'd4,6'd44}: pon = 1'b1;
      {3'd4,6'd45}: pon = 1'b1;
      {3'd4,6'd46}: pon = 1'b1;
      {3'd4,6'd49}: pon = 1'b1;
      {3'd4,6'd53}: pon = 1'b1;
      {3'd4,6'd56}: pon = 1'b1;
      {3'd4,6'd57}: pon = 1'b1;
      {3'd4,6'd58}: pon = 1'b1;
      {3'd4,6'd60}: pon = 1'b1;
      {3'd4,6'd62}: pon = 1'b1;
      default: pon = 1'b0;
    endcase
  end
  assign press_on = in_press && pon;

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