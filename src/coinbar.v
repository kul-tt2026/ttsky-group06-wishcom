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
// DE CIJFERS KOMEN UIT digit_rom (sprites.v), hetzelfde 4x6 font dat
// chest_menu voor de pot en het rondenummer gebruikt.  Er stond hier ooit
// een eigen 3x5 bitmap; die is weg zodat elk getal op het scherm er
// hetzelfde uitziet.  Zie de git-historie als je hem terug wilt.
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
  // 4x6 font op schaal 3: elk cijfer 12x18, pitch 14 (12 glyph + 2 gat).
  // Drie cijfers = 12+2+12+2+12 = 40, precies de breedte van de balk.
  localparam [9:0] TXT_Y_START = BAR_H + 10'd6;        // 202
  localparam [9:0] TXT_Y_END   = TXT_Y_START + 10'd18; // 220
  localparam [9:0] TXT_W       = 10'd40;

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
  wire in_txt_box = (y >= TXT_Y_START) && (y < TXT_Y_END) && (x < TXT_W);

  wire [9:0] dy_txt = y - TXT_Y_START;   // 0..17
  wire [5:0] txt_x  = in_txt_box ? x[5:0] : 6'd0;   // 0..39

  // font_y = dy_txt / 3.  Bereik is 0..17, dus vergelijken is goedkoper
  // dan vermenigvuldigen.
  wire [2:0] font_y = !in_txt_box       ? 3'd0 :
                      (dy_txt < 10'd3)  ? 3'd0 :
                      (dy_txt < 10'd6)  ? 3'd1 :
                      (dy_txt < 10'd9)  ? 3'd2 :
                      (dy_txt < 10'd12) ? 3'd3 :
                      (dy_txt < 10'd15) ? 3'd4 : 3'd5;

  // Welk cijfer, en welke kolom daarbinnen.  Slots: 0..11, 14..25, 28..39.
  reg [3:0] cur_digit;
  reg [5:0] col_in_digit;
  reg       valid_col;

  always @(*) begin
    if (txt_x <= 6'd11) begin
      cur_digit = d_hond;  col_in_digit = txt_x;          valid_col = show_hond;
    end else if (txt_x >= 6'd14 && txt_x <= 6'd25) begin
      cur_digit = d_tien;  col_in_digit = txt_x - 6'd14;  valid_col = show_tien;
    end else if (txt_x >= 6'd28) begin
      cur_digit = d_een;   col_in_digit = txt_x - 6'd28;  valid_col = 1'b1;
    end else begin
      cur_digit = 4'd0;    col_in_digit = 6'd0;           valid_col = 1'b0;
    end
  end

  // font_x = col_in_digit / 3, bereik 0..11 -> 0..3
  wire [1:0] font_x = (col_in_digit < 6'd3) ? 2'd0 :
                      (col_in_digit < 6'd6) ? 2'd1 :
                      (col_in_digit < 6'd9) ? 2'd2 : 2'd3;

  // Het gedeelde 4x6 font; bits[3] is de linkerkolom.
  wire [3:0] bits;
  digit_rom u_dig (.digit(cur_digit), .row(font_y), .bits(bits));

  wire font_px = in_txt_box && valid_col && bits[2'd3 - font_x];

  // ======================= output =========================================
  assign px_on   = in_bar || font_px;
  assign px_code = font_px ? 2'd2 :
                   !in_seg ? 2'd0 :
                   lit     ? 2'd2 : 2'd1;
endmodule