`default_nettype none
// ---------------------------------------------------------------------------
// ICON_DRAW -- tekent het pictogram dat IN een kist zit.
//
// EEN GEDEELDE ROM voor alle iconen: 16x16 per stuk, x8 geschaald -> 128x128,
// precies het vakje van chest_draw.  x8 is een bitselectie, dus gratis.
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
// Alles onder y = 64 valt vanzelf achter de bak; geen clipping nodig.
//
// px_code (zie icon_color in renderer.v):
//   1 = zwart            5 = wit (glans)
//   2 = bruin / donkeroranje   6 = rood (drank, vonken, rode bom)
//   3 = oranje           7 = grijsblauw (glas)
//   4 = creme / geel
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

  // Boven/links van de origin wrapt de lokale coordinaat naar ~1023, dus een
  // enkele "< 128" test vangt meteen ook de linker- en bovenrand af.
  wire in_box = (x < 10'd128) && (y < 10'd128);

  reg [1:0] sel;
  always @(*) case (icon)
    I_COIN:   sel = 2'd0;
    I_CURSED: sel = 2'd1;
    I_BOMB:   sel = 2'd2;
    I_BOMB2:  sel = 2'd2;      // zelfde bitmap, zwart wordt rood
    default:  sel = 2'd3;      // I_2X
  endcase

  wire [3:0] sx = x[6:3];      // x8 schaal, gewoon drie bits eraf
  wire [3:0] sy = y[6:3];

  wire [9:0] addr = in_box ? {sel, sy, sx} : 10'd0;

  reg [2:0] rom [0:1023];
  initial $readmemh("icons.hex", rom);
  wire [2:0] raw = rom[addr];

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

  assign px_on   = in_box && (raw != 3'd0);
  assign px_code = code;
endmodule