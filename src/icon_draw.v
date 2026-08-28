`default_nettype none
// ---------------------------------------------------------------------------
// ICON_DRAW -- tekent het pictogram dat IN een kist zit.
//
// EEN GEDEELDE ROM voor alle iconen: 16x16 per stuk, x4 geschaald -> 64x64,
// gecentreerd in het kistvakje van 128 en zo geplaatst dat het boven de rand
// van de bak uitkomt.  x4 is een bitselectie, dus gratis.
//
// Hier stonden ooit procedurele cirkels met `dx*dx + dy*dy` -- variabele maal
// variabele, de dure soort, ~450 cellen voor twee iconen.  De tabel doet er
// vier voor minder.
//
//   blok 0 = munt        blok 2 = bom
//   blok 1 = gifdrankje  blok 3 = X2
//
// De RODE bom is dezelfde bitmap als de zwarte, met een kleuromzetting: zwart
// wordt rood en de rode vonken worden geel, anders vallen die weg tegen de
// romp.  Dat scheelt 256 ROM-ingangen.
//
// icons.hex komt uit tools/png2icons.py (de bron-PNG's staan in docs/).
//
// LAAG: dit hoort in de cascade van renderer.v TUSSEN bak en deksel:
//        bak (wint) > icoon > deksel
// chest_draw tekent de bak vanaf y = 64, dus alles onder die lijn valt vanzelf
// achter de kist.  Het icoon loopt van 24 tot 87: de bovenste 40 px zie je,
// de onderste 24 verdwijnen achter de bak.  Geen clipping nodig.
//
// px_code (zie icon_color in renderer.v):
//   1 = zwart                  5 = wit (glans)
//   2 = bruin / donkeroranje   6 = rood (drank, vonken, rode bom)
//   3 = oranje                 7 = grijsblauw (glas)
//   4 = ook blauw 
// ---------------------------------------------------------------------------
module icon_draw (
    input  wire [9:0] x,          // lokaal, 0..127
    input  wire [9:0] y,          // lokaal, 0..127
    input  wire [2:0] icon,       // zelfde codering als chest_game.v

    output wire       px_on,
    output wire [2:0] px_code
);
  // Zelfde nummers als de O_* localparams in chest_game.v.  Hernummer je die
  // daar, dan moet deze case mee.
  localparam [2:0] I_COIN   = 3'd0,
                   I_2X     = 3'd1,
                   I_CURSED = 3'd2,
                   I_BOMB   = 3'd3,
                   I_BOMB2  = 3'd4;

  // ---- welk blok in de ROM -----------------------------------------------
  reg [1:0] sel;
  always @(*) case (icon)
    I_COIN:   sel = 2'd0;
    I_CURSED: sel = 2'd1;
    I_BOMB:   sel = 2'd2;
    I_BOMB2:  sel = 2'd2;      // zelfde bitmap, zwart wordt rood
    default:  sel = 2'd3;      // I_2X
  endcase

  // ---- waar in het vakje -------------------------------------------------
  // IC_Y lager zet duwt het icoon dieper de kist in, hoger laat er meer van
  // zien.  Andere maten dan 64 of 128 kunnen niet: het moet een macht van twee
  // blijven, anders heb je een deler nodig.
  localparam [9:0] IC_X = 10'd32;   // (128 - 64) / 2
  localparam [9:0] IC_Y = 10'd8;
  localparam [9:0] IC_W = 10'd64;   // 16 * 4

  wire in_box = (x >= IC_X) && (x < IC_X + IC_W) &&
                (y >= IC_Y) && (y < IC_Y + IC_W);

  wire [9:0] ox = x - IC_X;
  wire [9:0] oy = y - IC_Y;
  wire [3:0] sx = in_box ? ox[5:2] : 4'd0;   // x4 schaal
  wire [3:0] sy = in_box ? oy[5:2] : 4'd0;

  wire [9:0] addr = in_box ? {sel, sy, sx} : 10'd0;

  // ---- de tabel ----------------------------------------------------------
  reg [2:0] rom [0:1023];
  initial $readmemh("icons.hex", rom);
  wire [2:0] raw = rom[addr];

  // ---- kleuromzetting voor de rode bom -----------------------------------
  reg [2:0] code;
  always @(*) begin
    if (icon == I_BOMB2) begin
      case (raw)
        3'd1:    code = 3'd6;   // zwarte romp wordt rood
        3'd6:    code = 3'd4;   // rode vonken worden geel, anders vallen ze weg
        default: code = raw;
      endcase
    end else begin
      code = raw;
    end
  end

  // ---- uitgangen ---------------------------------------------------------
  assign px_on   = in_box && (raw != 3'd0);
  assign px_code = code;
endmodule