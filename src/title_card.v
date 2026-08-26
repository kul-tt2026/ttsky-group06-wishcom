`default_nettype none
// ---------------------------------------------------------------------------
// TITLE_CARD  --  "Dragonochi" (blackletter) in een gevleugelde banier.
//
// Opbouw (achter -> voor):
//   1. vleugels : 33x19 native, 8x geschaald -> 264 x 152 px, gecentreerd
//   2. kader    : boven/onderbalk EEN kleur en uitstekend; zijkanten dubbel
//                 met een dip halverwege
//   3. letters  : 200x37 native, 2x geschaald -> 400 x 74 px
//
// De vleugels zitten ACHTER het kader en worden er onderaan door afgesneden.
// Die overlap is wat het een logo maakt in plaats van een ornament erbovenop.
// Meer of minder vleugel laten zien = W_SINK aanpassen.
//
// DE BITMAPS ZITTEN IN HEX-ROM'S, niet in een case.  Twee losse `case`-blokken
// met duizend {rij, kolom}-ingangen kostten ~6000 cellen; als geheugen kan
// yosys er logica-minimalisatie op loslaten en scheelt dat een factor.  Het
// maakt bovendien de render-benches tientallen seconden sneller, want iverilog
// hoeft niet langer per pixel duizenden regels combinatoriek te evalueren.
//
//   title_letters.hex : 37 rijen x 200 bits (1 bit per pixel)
//   title_wings.hex   : 19 rijen x 33 pixels van 2 bits, gepad tot 72 bits
//
// Beide worden gegenereerd door tools/case2hex.py uit de oorspronkelijke
// case-blokken; die staan in de git-historie van dit bestand.  Wil je de art
// wijzigen, pas dan de hex aan (of de bron waar hij uit komt) -- niet dit
// bestand.
//
// px_code (de renderer kiest de kleuren):
//     0 transparant
//     1 letters + vleugel-omtrek        -> donkergroen 6'b00_01_00
//     2 kadervulling + vleugel-vlak     -> lichtgroen  6'b01_11_01
//     3 donkere rand (balken + zijkant) -> donkergroen 6'b00_01_00
//     4 lichte rand  (alleen zijkanten) -> lichtgroen  6'b01_11_01
//     5 vleugel-aders                   -> tussentint  6'b00_10_00
// ---------------------------------------------------------------------------
module title_card (
    input  wire [9:0] x,
    input  wire [9:0] y,
    output wire       px_on,
    output wire [2:0] px_code
);
  // --- tekst ---------------------------------------------------------------
  localparam [9:0] T_X    = 10'd40;
  localparam [9:0] T_Y    = 10'd155;    // lager: de vleugels zijn nu hoog
  localparam [9:0] T_W    = 10'd400;    // 200 native * 2
  localparam [9:0] T_H    = 10'd74;     //  37 native * 2
  localparam [9:0] PAD    = 10'd12;
  localparam [9:0] BORDER = 10'd4;      // 1 native per randlaag

  // --- kadervorm -----------------------------------------------------------
  localparam [9:0] EXT     = 10'd12;    // uitstek van de balken
  localparam [9:0] NOTCH_H = 10'd24;    // halve hoogte van de dip
  localparam [9:0] NOTCH_D = 10'd12;    // diepte van de dip

  // --- vleugels ------------------------------------------------------------
  localparam [9:0] W_W    = 10'd264;    // 33 native * 8
  localparam [9:0] W_H    = 10'd152;    // 19 native * 8
  localparam [9:0] W_SINK = 10'd40;     // hoeveel vleugel achter het kader zakt

  // --- basis-rechthoek van het kader --------------------------------------
  wire [9:0] O_X = T_X - PAD - 2*BORDER;
  wire [9:0] O_Y = T_Y - PAD - 2*BORDER;
  wire [9:0] O_W = T_W + 2*PAD + 4*BORDER;
  wire [9:0] O_H = T_H + 2*PAD + 4*BORDER;

  wire in_rows = (y >= O_Y) && (y < O_Y + O_H);
  wire [9:0] ly = y - O_Y;

  wire bar = (ly < 2*BORDER) || (ly >= O_H - 2*BORDER);

  wire [9:0] cy  = O_H >> 1;
  wire [9:0] dy  = (ly >= cy) ? (ly - cy) : (cy - ly);
  wire [9:0] ins = (dy <= NOTCH_H)           ? NOTCH_D :
                   (dy <= NOTCH_H + NOTCH_D) ? (NOTCH_H + NOTCH_D - dy) :
                                               10'd0;

  wire [9:0] L = bar ? (O_X - EXT)           : (O_X + ins);
  wire [9:0] R = bar ? (O_X + O_W + EXT - 1) : (O_X + O_W - 1 - ins);

  wire in_outer = in_rows && (x >= L) && (x <= R);
  wire in_inner = in_outer && (x >= L + BORDER) && (x <= R - BORDER) &&
                  (ly >= BORDER) && (ly < O_H - BORDER);
  wire in_fill  = in_outer && (x >= L + 2*BORDER) && (x <= R - 2*BORDER) &&
                  (ly >= 2*BORDER) && (ly < O_H - 2*BORDER);

  // alleen de zijkanten zijn tweekleurig; de balken zijn uniform donker
  wire side_outer = in_outer && !in_inner && !bar;
  wire side_inner = in_inner && !in_fill  && !bar;

  wire in_text = (x >= T_X) && (x < T_X + T_W) &&
                 (y >= T_Y) && (y < T_Y + T_H);

  // --- vleugels: gecentreerd, onderkant W_SINK diep achter het kader -------
  wire [9:0] W_X = O_X + (O_W >> 1) - (W_W >> 1);
  wire [9:0] W_Y = O_Y - W_H + W_SINK;
  wire in_wing = (x >= W_X) && (x < W_X + W_W) &&
                 (y >= W_Y) && (y < W_Y + W_H);

  // --- letter-ROM: 37 rijen van 200 bits, 2x geschaald (>>1) --------------
  wire [7:0] rx = (x - T_X) >> 1;       // 0..199
  wire [5:0] ry = (y - T_Y) >> 1;       // 0..36

  reg [199:0] letter_rows [0:36];
  initial $readmemh("title_letters.hex", letter_rows);

  // buiten het tekstvak wrapt de coordinaat; nooit buiten de array indexeren
  wire [5:0]   ry_c = in_text ? ry : 6'd0;
  wire [199:0] lrow = letter_rows[ry_c];

  wire letter = in_text && lrow[rx];

  // --- vleugel-ROM: 19 rijen, 33 pixels van 2 bits, 8x geschaald (>>3) ----
  wire [5:0] wx = (x - W_X) >> 3;       // 0..32
  wire [4:0] wy = (y - W_Y) >> 3;       // 0..18

  reg [71:0] wing_rows [0:18];
  initial $readmemh("title_wings.hex", wing_rows);

  wire [4:0]  wy_c = in_wing ? wy : 5'd0;
  wire [71:0] wrow = wing_rows[wy_c];

  // {wx, 1'b0} is wx*2; +: 2 pakt daar twee bits vanaf (Verilog-2001, geen SV)
  wire [1:0] wcode = in_wing ? wrow[{wx, 1'b0} +: 2] : 2'd0;

  wire wing = in_wing && (wcode != 2'd0);

  // --- samenstellen: letters > kader > vleugels ---------------------------
  //  De vleugels staan ACHTERAAN, dus het kader snijdt ze af.
  assign px_code = letter     ? 3'd1 :
                   in_fill    ? 3'd2 :
                   side_inner ? 3'd4 :
                   side_outer ? 3'd3 :
                   in_outer   ? 3'd3 :          // balken: uniform donker
                   wing       ? ((wcode == 2'd1) ? 3'd1 :
                                 (wcode == 2'd2) ? 3'd5 : 3'd2) : 3'd0;
  assign px_on   = in_outer || wing;
endmodule