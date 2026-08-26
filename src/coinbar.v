`default_nettype none
// ---------------------------------------------------------------------------
// COINBAR -- VERTICAAL.  8 vakjes, vult van ONDER naar BOVEN, met het
// muntbedrag als drie cijfers eronder.
//
// GEEN DELINGEN.  Alles gaat via vermenigvuldigen met een constante en
// shiften; yosys maakt daar shift-adds van.
//     n / 3   ==  (n * 683) >> 11     exact voor n < 2048
//     n / 10  ==  (n * 205) >> 11     exact voor n < 1024
//     n / 100 ==  (n *  41) >> 12     exact voor n < 1024
//
// SCHAAL VAN DE BALK: coins[9:7] is het aantal volle vakjes.  Dat is een
// bus-slice, dus gratis -- maar het betekent wel dat er op 1024 geschaald
// wordt en niet op COINS_MAX.  Het bovenste vakje gaat aan bij 896; bij
// coins >= COINS_MAX zetten we alles aan zodat de balk echt vol staat.
//
// px_code: 0 = frame + schotjes   1 = leeg vakje   2 = vol vakje + cijfers
// ---------------------------------------------------------------------------
module coinbar (
    input  wire [9:0] x,            // lokaal (pix_x - COINBAR_X)
    input  wire [9:0] y,            // lokaal (pix_y - COINBAR_Y)
    input  wire [9:0] coins,        // 0..1000, uit dragon_state
    output wire       px_on,
    output wire [1:0] px_code
);
  localparam [9:0] COINS_MAX = 10'd1000;

  // ======================= geometrie balk =================================
  localparam [9:0] NSEG  = 10'd8;
  localparam [9:0] FRAME = 10'd4;
  localparam [9:0] PITCH = 10'd24;     // 24 = 8*3, dus /24 == (n>>3)/3
  localparam [9:0] SEG_H = 10'd20;     // 24-20 = 4 px schotje
  localparam [9:0] SEG_W = 10'd32;

  localparam [9:0] BAR_W = FRAME + SEG_W + FRAME;                            // 40
  localparam [9:0] BAR_H = FRAME + (NSEG * PITCH) - (PITCH - SEG_H) + FRAME; // 196

  // ======================= geometrie cijfers ==============================
  // 3x5 font, schaal 3: drie cijfers van 9 px met 3 px ertussen = 33 breed.
  localparam [9:0] TXT_Y_START = BAR_H + 10'd6;      // 202
  localparam [9:0] TXT_Y_END   = TXT_Y_START + 10'd15;
  localparam [9:0] TXT_X_START = 10'd3;
  localparam [9:0] TXT_X_END   = TXT_X_START + 10'd33;

  // ======================= waar zijn we (balk) ============================
  // Boven/links van de origin wrapt de lokale coordinaat naar ~1023, dus
  // "< BAR_W" vangt meteen de linker- en bovenrand af.  Geen signed compare.
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);

  wire [9:0] diff_y = y - FRAME;        // 0..187 binnen in_inner

  // idx = diff_y / 24 = (diff_y / 8) / 3
  wire [7:0]  dy8   = diff_y[7:0];
  wire [4:0]  dq    = dy8[7:3];                       // /8, 0..23
  wire [15:0] m3    = {11'd0, dq} * 16'd683;
  wire [2:0]  idx   = m3[13:11];                      // /3, 0..7

  // sy = diff_y - idx*24, met idx*24 = (idx<<4) + (idx<<3)
  wire [9:0] idx24 = ({7'd0, idx} << 4) + ({7'd0, idx} << 3);
  wire [9:0] sy    = diff_y - idx24;

  wire in_seg = in_inner && (sy < SEG_H);

  // ======================= vulling balk ===================================
  wire [2:0] nfull = coins[9:7];
  wire       maxed = (coins >= COINS_MAX);
  // 8 past niet in 3 bits, dus deze vergelijking MOET 4 bits breed zijn --
  // anders is first_lit bij nfull==0 gelijk aan 0 en licht alles op.
  wire [3:0] first_lit = 4'd8 - {1'b0, nfull};
  wire       lit       = in_seg && (maxed || ({1'b0, idx} >= first_lit));

  // ======================= BCD, zonder deler ==============================
  wire [9:0]  c_val  = (coins > 10'd999) ? 10'd999 : coins;

  wire [15:0] m100   = {6'd0, c_val} * 16'd41;        // /100
  wire [3:0]  d_hond = m100[15:12];
  wire [9:0]  h100   = ({6'd0, d_hond} << 6) +        // d_hond * 100
                       ({6'd0, d_hond} << 5) +
                       ({6'd0, d_hond} << 2);
  wire [9:0]  r100   = c_val - h100;                  // 0..99

  wire [15:0] m10    = {6'd0, r100} * 16'd205;        // /10
  wire [3:0]  d_tien = m10[14:11];
  wire [9:0]  t10    = ({6'd0, d_tien} << 3) +        // d_tien * 10
                       ({6'd0, d_tien} << 1);
  wire [9:0]  r10    = r100 - t10;
  wire [3:0]  d_een  = r10[3:0];

  wire show_hond = (d_hond != 4'd0);
  wire show_tien = show_hond || (d_tien != 4'd0);

  // ======================= cijfers tekenen ================================
  wire in_txt_box = (y >= TXT_Y_START) && (y < TXT_Y_END) &&
                    (x >= TXT_X_START) && (x < TXT_X_END);

  wire [9:0] dy_txt = y - TXT_Y_START;   // 0..14
  wire [9:0] dx_txt = x - TXT_X_START;   // 0..32
  wire [5:0] txt_x  = in_txt_box ? dx_txt[5:0] : 6'd0;

  // font_y = dy_txt / 3.  Bereik is 0..14, dus vergelijken is goedkoper
  // dan vermenigvuldigen.
  wire [2:0] font_y = !in_txt_box     ? 3'd0 :
                      (dy_txt < 10'd3)  ? 3'd0 :
                      (dy_txt < 10'd6)  ? 3'd1 :
                      (dy_txt < 10'd9)  ? 3'd2 :
                      (dy_txt < 10'd12) ? 3'd3 : 3'd4;

  // Welk cijfer, en welke kolom daarbinnen.  Slots: 0..8, 12..20, 24..32.
  reg [3:0] cur_digit;
  reg [5:0] col_in_digit;
  reg       valid_col;

  always @(*) begin
    if (txt_x <= 6'd8) begin
      cur_digit = d_hond;  col_in_digit = txt_x;             valid_col = show_hond;
    end else if (txt_x >= 6'd12 && txt_x <= 6'd20) begin
      cur_digit = d_tien;  col_in_digit = txt_x - 6'd12;     valid_col = show_tien;
    end else if (txt_x >= 6'd24 && txt_x <= 6'd32) begin
      cur_digit = d_een;   col_in_digit = txt_x - 6'd24;     valid_col = 1'b1;
    end else begin
      cur_digit = 4'd0;    col_in_digit = 6'd0;              valid_col = 1'b0;
    end
  end

  // font_x = col_in_digit / 3, bereik 0..8
  wire [1:0] font_x = (col_in_digit < 6'd3) ? 2'd0 :
                      (col_in_digit < 6'd6) ? 2'd1 : 2'd2;

  // 3x5 bitmap, bit 14 is linksboven
  reg [14:0] glyph;
  always @(*) case (cur_digit)
    4'd0:    glyph = 15'b111_101_101_101_111;
    4'd1:    glyph = 15'b010_110_010_010_111;
    4'd2:    glyph = 15'b111_001_111_100_111;
    4'd3:    glyph = 15'b111_001_111_001_111;
    4'd4:    glyph = 15'b101_101_111_001_001;
    4'd5:    glyph = 15'b111_100_111_001_111;
    4'd6:    glyph = 15'b111_100_111_101_111;
    4'd7:    glyph = 15'b111_001_001_010_010;
    4'd8:    glyph = 15'b111_101_111_101_111;
    4'd9:    glyph = 15'b111_101_111_001_111;
    default: glyph = 15'b000_000_000_000_000;
  endcase

  // Eerst de rij kiezen, dan de kolom.  Twee kleine muxen in plaats van
  // een variabele bit-index met een vermenigvuldiging erin.
  reg [2:0] row_bits;
  always @(*) case (font_y)
    3'd0:    row_bits = glyph[14:12];
    3'd1:    row_bits = glyph[11:9];
    3'd2:    row_bits = glyph[8:6];
    3'd3:    row_bits = glyph[5:3];
    default: row_bits = glyph[2:0];
  endcase

  wire pix_lit = (font_x == 2'd0) ? row_bits[2] :
                 (font_x == 2'd1) ? row_bits[1] : row_bits[0];

  wire font_px = in_txt_box && valid_col && pix_lit;

  // ======================= output =========================================
  assign px_on   = in_bar || font_px;
  assign px_code = font_px ? 2'd2 :
                   !in_seg ? 2'd0 :
                   lit     ? 2'd2 : 2'd1;
endmodule