`default_nettype none

// ---------------------------------------------------------------------------
// COINBAR -- VERTICAAL.  8 vakjes, vult van ONDER naar BOVEN.
//
// SCHAAL: coins is 10 bits en loopt tot COINS_MAX (1000).  Om de deling
// "hoeveel vakjes zijn vol" gratis te houden delen we op 1024 in plaats van
// op 1000: 8 vakjes x 128 coins, dus coins[9:7] IS de vakjesteller.
// Gevolg: het bovenste vakje begint bij 896; bij coins >= COINS_MAX zetten
// we alles aan zodat de balk bij het maximum echt vol staat.
//

// GEOMETRIE: FRAME / SEG_W / SEG_H / NSEG mag je vrij aanpassen.
// PITCH MOET een macht van 2 blijven -- daarop rust idx = ry[6:4].
//
// px_code: 0 = frame + schotjes   (donker)
//          1 = leeg vakje         (donkergrijs)
//          2 = vol vakje          (geel)
// ---------------------------------------------------------------------------
// module coinbar (
//     input  wire [9:0] x,            // local (pix_x - COINBAR_X)
//     input  wire [9:0] y,            // local (pix_y - COINBAR_Y)
//     input  wire [9:0] coins,        // 0..1000, uit dragon_state
//     output wire       px_on,
//     output wire [1:0] px_code
// );
//   // ======================= schaal =========================================
//   localparam [9:0] COINS_MAX = 10'd1000;   // waar de balk vol staat
 
//   // ======================= geometrie ======================================
//   localparam [9:0] NSEG  = 10'd8;      // 8 vakjes onder elkaar
//   localparam [9:0] FRAME = 10'd3;      // randdikte
//   localparam [9:0] PITCH = 10'd16;     // stride per vakje -- MOET macht van 2
//   localparam [9:0] SEG_H = 10'd14;     // vakjehoogte; 16-14 = 2px schotje
//   localparam [9:0] SEG_W = 10'd18;     // vakjebreedte
 
//   // Onder het laatste vakje komt geen schotje meer: -(PITCH-SEG_H).
//   localparam [9:0] BAR_W = FRAME + SEG_W + FRAME;                            // 24
//   localparam [9:0] BAR_H = FRAME + (NSEG * PITCH) - (PITCH - SEG_H) + FRAME; // 132
 
//   // ======================= waar zijn we ===================================
//   // Boven/links van de origin wrapt de local coord naar ~1023, dus "< BAR_H"
//   // test meteen ook de boven- en linkerrand.  Geen signed compare nodig.
//   wire in_bar   = (x < BAR_W) && (y < BAR_H);
 
//   wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
//                   (y >= FRAME) && (y < BAR_H - FRAME);


// // In coinbar.v regel 49:
//   wire [9:0] diff_y = y - FRAME;
//   wire [6:0] ry     = diff_y[6:0];   // Lost zowel WIDTHTRUNC als UNUSEDSIGNAL op
//   wire [2:0] idx = ry[6:4];            // ry / PITCH -> vakje 0 (boven) .. 7 (onder)
//   wire [3:0] sy  = ry[3:0];            // positie binnen dit vakje
 
//   wire in_seg = in_inner && (sy < SEG_H[3:0]);
 
//   // ======================= hoeveel vakjes vol =============================
//   // coins[9:7] = coins / 128 = aantal volle vakjes (0..7).  Gratis: dit is
//   // gewoon een stuk van de bus, geen deler.
//   wire [2:0] nfull = coins[9:7];
//   wire       maxed = (coins >= COINS_MAX);
 
//   // Let op: 8 past niet in 3 bits, dus deze vergelijking MOET 4 bits breed
//   // zijn -- anders is first_lit bij nfull==0 gelijk aan 0 en licht alles op.
//   wire [3:0] first_lit = 4'd8 - {1'b0, nfull};
 
//   wire lit = in_seg && (maxed || ({1'b0, idx} >= first_lit));
 
//   // ======================= output =========================================
//   assign px_on   = in_bar;
//   assign px_code = !in_seg ? 2'd0 :    // frame + schotjes
//                    lit     ? 2'd2 :    // vol -> geel
//                              2'd1;     // leeg vakje
// endmodule


`default_nettype none

module coinbar (
    input  wire [9:0] x,            // local (pix_x - COINBAR_X)
    input  wire [9:0] y,            // local (pix_y - COINBAR_Y)
    input  wire [9:0] coins,        // 0..1000, uit dragon_state
    output wire       px_on,
    output wire [1:0] px_code       // 0: frame/outline, 1: leeg/achtergrond, 2: vol/geel/tekst
);

  // ======================= schaal =========================================
  localparam [9:0] COINS_MAX = 10'd1000;

  // ======================= geometrie balk (vergroot) ======================
  localparam [9:0] NSEG  = 10'd8;      // 8 segmenten
  localparam [9:0] FRAME = 10'd4;      // Randdikte 4 px
  localparam [9:0] PITCH = 10'd24;     // Afstand per segment
  localparam [9:0] SEG_H = 10'd20;     // Hoogte segment (24 - 20 = 4 px tussenschotje)
  localparam [9:0] SEG_W = 10'd32;     // Breedte binnenvakje

  localparam [9:0] BAR_W = FRAME + SEG_W + FRAME;                               // 40 px breed
  localparam [9:0] BAR_H = FRAME + (NSEG * PITCH) - (PITCH - SEG_H) + FRAME;    // 196 px hoog

  // ======================= geometrie cijfers (3x font, gecentreerd) =======
  // 3 cijfers: 3*(3*3) + 2*(3) = 33 px breed, 15 px hoog
  // Gecentreerd op 40 px balk: start op x = (40 - 33)/2 = 3
  localparam [9:0] TXT_Y_START = BAR_H + 10'd6;
  localparam [9:0] TXT_Y_END   = TXT_Y_START + 10'd15;
  localparam [9:0] TXT_X_START = 10'd3;
  localparam [9:0] TXT_X_END   = TXT_X_START + 10'd33;

  // ======================= waar zijn we (balk) ============================
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);

  wire [9:0] diff_y = y - FRAME;
  wire [2:0] idx    = diff_y / PITCH;           // Vakje 0 (boven) .. 7 (onder)
  wire [9:0] sy     = diff_y % PITCH;           // Positie binnen segment

  wire in_seg = in_inner && (sy < SEG_H);

  // ======================= vulling balk ===================================
  wire [2:0] nfull     = coins[9:7];
  wire       maxed     = (coins >= COINS_MAX);
  wire [3:0] first_lit = 4'd8 - {1'b0, nfull};
  wire       lit       = in_seg && (maxed || ({1'b0, idx} >= first_lit));

  // ======================= BCD decodering (0..999) ========================
  wire [9:0] c_val  = (coins > 10'd999) ? 10'd999 : coins;
  wire [3:0] d_hond = c_val / 10'd100;
  wire [3:0] d_tien = (c_val % 10'd100) / 10'd10;
  wire [3:0] d_een  = c_val % 10'd10;

  wire show_hond = (d_hond != 4'd0);
  wire show_tien = (d_hond != 4'd0) || (d_tien != 4'd0);

  // ======================= 3x5 font rendering (3x geschaald) =============
  wire in_txt_box = (y >= TXT_Y_START) && (y < TXT_Y_END) &&
                    (x >= TXT_X_START) && (x < TXT_X_END);

  wire [9:0] dy_txt = y - TXT_Y_START;
  wire [9:0] dx_txt = x - TXT_X_START;

  wire [3:0] font_y = in_txt_box ? (dy_txt / 10'd3) : 4'd0;
  wire [5:0] txt_x  = in_txt_box ? dx_txt[5:0] : 6'd0;

  reg [3:0] cur_digit;
  reg [3:0] font_x;
  reg       valid_col;

  always @(*) begin
    // Cijfer 1: x = 0..8 (font_x = 0..2)
    if (txt_x <= 6'd8) begin
      cur_digit = d_hond;
      font_x    = txt_x / 6'd3;
      valid_col = show_hond;
    // Cijfer 2: x = 12..20 (font_x = 0..2)
    end else if (txt_x >= 6'd12 && txt_x <= 6'd20) begin
      cur_digit = d_tien;
      font_x    = (txt_x - 6'd12) / 6'd3;
      valid_col = show_tien;
    // Cijfer 3: x = 24..32 (font_x = 0..2)
    end else if (txt_x >= 6'd24 && txt_x <= 6'd32) begin
      cur_digit = d_een;
      font_x    = (txt_x - 6'd24) / 6'd3;
      valid_col = 1'b1;
    end else begin
      cur_digit = 4'd0;
      font_x    = 4'd0;
      valid_col = 1'b0;
    end
  end

  // 3x5 bitmap per cijfer (15 bits)
  reg [14:0] glyph;
  always @(*) begin
    case (cur_digit)
      4'd0: glyph = 15'b111_101_101_101_111;
      4'd1: glyph = 15'b010_110_010_010_111;
      4'd2: glyph = 15'b111_001_111_100_111;
      4'd3: glyph = 15'b111_001_111_001_111;
      4'd4: glyph = 15'b101_101_111_001_001;
      4'd5: glyph = 15'b111_100_111_001_111;
      4'd6: glyph = 15'b111_100_111_101_111;
      4'd7: glyph = 15'b111_001_001_010_010;
      4'd8: glyph = 15'b111_101_111_101_111;
      4'd9: glyph = 15'b111_101_111_001_111;
      default: glyph = 15'b000_000_000_000_000;
    endcase
  end

  // Selecteer actieve pixel
  wire [3:0] bit_idx = (4'd4 - font_y) * 4'd3 + (4'd2 - font_x);
  wire font_px = in_txt_box && valid_col && glyph[bit_idx];

  // ======================= output =========================================
  assign px_on   = in_bar || font_px;
  assign px_code = font_px ? 2'd2 :               // Cijfers in geel/wit
                   !in_seg ? 2'd0 :               // Frame / schotjes
                   lit     ? 2'd2 :               // Volle balk
                             2'd1;                // Lege balk
endmodule