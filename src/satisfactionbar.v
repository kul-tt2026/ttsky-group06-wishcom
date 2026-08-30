`default_nettype none
// ---------------------------------------------------------------------------
// SATISFACTIONBAR -- vijf vakjes met een gezichtje, van boos naar heel blij.
//
// Het actieve vakje krijgt een witte rand.  Alle vijf houden hun kleur, zodat
// je de hele schaal blijft zien (CURSOR_MODE).  Zet CURSOR_MODE op 0 en de
// vakjes boven `sat` gaan uit.
//
// GEEN DELER, GEEN MODULO.  PITCH is 62 en dus geen macht van twee; diff_x/62
// en diff_x%62 kostten samen honderden cellen.  Met vijf vakjes is een
// vergelijkingsketen goedkoper dan welke deeltruc ook -- zelfde aanpak als in
// hearts.v en coinbar.v.
//
// DE GEZICHTJES zijn getekende 15x15 bitmaps, x2 geschaald naar 30x30 en
// gecentreerd in het vakje van 56 x 40.  Ze staan als CASE van 15-bit
// constanten en niet als $readmemh-tabel: de flow liep eerder vast op het
// platslaan van geheugens, en een case op de RIJ (niet per pixel) geeft
// precies dezelfde logica zonder dat memory_map eraan te pas komt.
// Gegenereerd uit de PNG's in docs/ door tools/png2smiley.py.
//
// px_code: 0 = zwart (frame, schotjes, en de lijnen van het gezichtje)
//          1..5 = kleur van vakje 0..4
//          6 = witte selectierand
//          7 = onverlicht (alleen in FILL-modus)
// ---------------------------------------------------------------------------
module satisfactionbar (
    input  wire [9:0] x,             // local (px - SATBAR_X)
    input  wire [9:0] y,             // local (py - SATBAR_Y)
    input  wire [2:0] sat,           // 0..4: actieve segment
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam CURSOR_MODE = 1'b1;
  localparam SMILEY      = 1'b1;

  // ======================= geometrie =======================================
  localparam [9:0] NSEG  = 10'd5;
  localparam [9:0] FRAME = 10'd4;       // zwarte buitenrand, was 2
  localparam [9:0] PITCH = 10'd62;      // afstand per segment
  localparam [9:0] SEG_W = 10'd56;      // vakje langs x; 62-56 = 6 px schotje
  localparam [9:0] SEG_H = 10'd40;      // vakje langs y

  localparam [9:0] BAR_W = FRAME + (NSEG * PITCH) - (PITCH - SEG_W) + FRAME; // 312
  localparam [9:0] BAR_H = FRAME + SEG_H + FRAME;                            //  48

  // ======================= coordinaten =====================================
  // Links/boven van de origin wrapt de lokale coordinaat naar ~1023, dus
  // "< BAR_W" vangt meteen de linker- en bovenrand af.  Geen signed compare.
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);

  wire [9:0] diff_x = x - FRAME;
  wire [9:0] diff_y = y - FRAME;        // 0..39
  wire [5:0] sy     = diff_y[5:0];

  // Vijf vaste grenzen in plaats van diff_x/62 en diff_x%62.
  reg [2:0] idx;
  reg [9:0] sbase;
  always @(*) begin
    if      (diff_x < 10'd62)  begin idx = 3'd0; sbase = 10'd0;   end
    else if (diff_x < 10'd124) begin idx = 3'd1; sbase = 10'd62;  end
    else if (diff_x < 10'd186) begin idx = 3'd2; sbase = 10'd124; end
    else if (diff_x < 10'd248) begin idx = 3'd3; sbase = 10'd186; end
    else                       begin idx = 3'd4; sbase = 10'd248; end
  end
  wire [9:0] sxw = diff_x - sbase;
  wire [5:0] sx  = sxw[5:0];            // 0..61

  // idx is door de keten hierboven altijd 0..4, dus een "idx < NSEG" test
  // zou niets meer doen -- die is eruit.
  wire in_seg = in_inner && (sx < 6'd56);

  // ======================= selectie =======================================
  wire selected = (idx == sat);

  wire ring = CURSOR_MODE && in_seg && selected &&
              ((sx < 6'd2) || (sx >= 6'd54) ||
               (sy < 6'd2) || (sy >= 6'd38));

  wire coloured = CURSOR_MODE ? 1'b1 : (idx <= sat);

  // ======================= het gezichtje ==================================
  // 15x15 op x2 = 30x30, gecentreerd: sx 13..42, sy 5..34.
  wire in_face = (sx >= 6'd13) && (sx < 6'd43) &&
                 (sy >= 6'd5)  && (sy < 6'd35);

  wire [5:0] fdx = sx - 6'd13;          // 0..29
  wire [5:0] fdy = sy - 6'd5;
  wire [3:0] fx  = fdx[4:1];            // /2, 0..14
  wire [3:0] fy  = fdy[4:1];

  reg [14:0] frow;
  always @(*) case ({idx, fy})
    // --- 0: boos ---
    {3'd0,4'd0 }: frow = 15'b000001111100000;
    {3'd0,4'd1 }: frow = 15'b000110000011000;
    {3'd0,4'd2 }: frow = 15'b001000000000100;
    {3'd0,4'd3 }: frow = 15'b010000000000010;
    {3'd0,4'd4 }: frow = 15'b010000000000010;
    {3'd0,4'd5 }: frow = 15'b100010000010001;
    {3'd0,4'd6 }: frow = 15'b100011000110001;
    {3'd0,4'd7 }: frow = 15'b100000000000001;
    {3'd0,4'd8 }: frow = 15'b100000000000001;
    {3'd0,4'd9 }: frow = 15'b100001111100001;
    {3'd0,4'd10}: frow = 15'b010000000000010;
    {3'd0,4'd11}: frow = 15'b010000000000010;
    {3'd0,4'd12}: frow = 15'b001000000000100;
    {3'd0,4'd13}: frow = 15'b000110000011000;
    {3'd0,4'd14}: frow = 15'b000001111100000;
    // --- 1: ontevreden ---
    {3'd1,4'd0 }: frow = 15'b000001111100000;
    {3'd1,4'd1 }: frow = 15'b000110000011000;
    {3'd1,4'd2 }: frow = 15'b001000000000100;
    {3'd1,4'd3 }: frow = 15'b010000000000010;
    {3'd1,4'd4 }: frow = 15'b010011000110010;
    {3'd1,4'd5 }: frow = 15'b100011000110001;
    {3'd1,4'd6 }: frow = 15'b100011000110001;
    {3'd1,4'd7 }: frow = 15'b100000000000001;
    {3'd1,4'd8 }: frow = 15'b100000000000001;
    {3'd1,4'd9 }: frow = 15'b100001111100001;
    {3'd1,4'd10}: frow = 15'b010010000010010;
    {3'd1,4'd11}: frow = 15'b010000000000010;
    {3'd1,4'd12}: frow = 15'b001000000000100;
    {3'd1,4'd13}: frow = 15'b000110000011000;
    {3'd1,4'd14}: frow = 15'b000001111100000;
    // --- 2: neutraal ---
    {3'd2,4'd0 }: frow = 15'b000001111100000;
    {3'd2,4'd1 }: frow = 15'b000110000011000;
    {3'd2,4'd2 }: frow = 15'b001000000000100;
    {3'd2,4'd3 }: frow = 15'b010000000000010;
    {3'd2,4'd4 }: frow = 15'b010011000110010;
    {3'd2,4'd5 }: frow = 15'b100011000110001;
    {3'd2,4'd6 }: frow = 15'b100011000110001;
    {3'd2,4'd7 }: frow = 15'b100000000000001;
    {3'd2,4'd8 }: frow = 15'b100000000000001;
    {3'd2,4'd9 }: frow = 15'b100001111100001;
    {3'd2,4'd10}: frow = 15'b010000000000010;
    {3'd2,4'd11}: frow = 15'b010000000000010;
    {3'd2,4'd12}: frow = 15'b001000000000100;
    {3'd2,4'd13}: frow = 15'b000110000011000;
    {3'd2,4'd14}: frow = 15'b000001111100000;
    // --- 3: blij ---
    {3'd3,4'd0 }: frow = 15'b000001111100000;
    {3'd3,4'd1 }: frow = 15'b000110000011000;
    {3'd3,4'd2 }: frow = 15'b001000000000100;
    {3'd3,4'd3 }: frow = 15'b010000000000010;
    {3'd3,4'd4 }: frow = 15'b010011000110010;
    {3'd3,4'd5 }: frow = 15'b100011000110001;
    {3'd3,4'd6 }: frow = 15'b100011000110001;
    {3'd3,4'd7 }: frow = 15'b100000000000001;
    {3'd3,4'd8 }: frow = 15'b100000000000001;
    {3'd3,4'd9 }: frow = 15'b100100000001001;
    {3'd3,4'd10}: frow = 15'b010010000010010;
    {3'd3,4'd11}: frow = 15'b010001111100010;
    {3'd3,4'd12}: frow = 15'b001000000000100;
    {3'd3,4'd13}: frow = 15'b000110000011000;
    {3'd3,4'd14}: frow = 15'b000001111100000;
    // --- 4: heel blij ---
    {3'd4,4'd0 }: frow = 15'b000001111100000;
    {3'd4,4'd1 }: frow = 15'b000110000011000;
    {3'd4,4'd2 }: frow = 15'b001000000000100;
    {3'd4,4'd3 }: frow = 15'b010000000000010;
    {3'd4,4'd4 }: frow = 15'b010011000110010;
    {3'd4,4'd5 }: frow = 15'b100011000110001;
    {3'd4,4'd6 }: frow = 15'b100011000110001;
    {3'd4,4'd7 }: frow = 15'b100000000000001;
    {3'd4,4'd8 }: frow = 15'b100000000000001;
    {3'd4,4'd9 }: frow = 15'b100111111111001;
    {3'd4,4'd10}: frow = 15'b010011111110010;
    {3'd4,4'd11}: frow = 15'b010001111100010;
    {3'd4,4'd12}: frow = 15'b001000000000100;
    {3'd4,4'd13}: frow = 15'b000110000011000;
    {3'd4,4'd14}: frow = 15'b000001111100000;
    default: frow = 15'd0;
  endcase

  // bit 14 is de linkerkolom
  wire smiley = SMILEY && in_seg && in_face && frow[4'd14 - fx];

  // ======================= output =========================================
  // Het hele blok is dekkend: frame en schotjes delen code 0, zodat de balk
  // als een object leest in plaats van de achtergrond door te laten schijnen.
  assign px_on   = in_bar;
  assign px_code = !in_seg  ? 3'd0         :   // frame + schotjes
                   ring     ? 3'd6         :   // witte selectierand
                   smiley   ? 3'd0         :   // de lijnen van het gezichtje
                   coloured ? (idx + 3'd1) :   // kleur 1..5
                              3'd7;            // onverlicht


  wire _unused = &{diff_y[9:6], sxw[9:6], fdx[5:0], fdy[5:0], 1'b0};
endmodule