`default_nettype none
// ---------------------------------------------------------------------------
// CHEST_MENU -- het tussenscherm van de minigame (chest_state == C_MENU).
//
// Toont:  ROUND <n>            welke ronde je nu speelt (round + 1)
//         een geldpot          met daaronder het bedrag in de pot
//         CONTINUE  (knop 6)   doorspelen, nieuwe ronde
//         CASH OUT  (knop 7)   bank de pot en verlaat de minigame
//
// Er is GEEN cursor: de twee knoppen zijn vaste toetsen, precies zoals
// chest_game.v ze al afhandelt.  De knoppen op het scherm zijn dus puur
// een label, geen selecteerbaar element.
//
// ABSOLUTE portret-coordinaten (px, py), net als draw_buttons.
//
// px_code (3 bits):
//   1 = zwart / outline      4 = wit (tekst)
//   2 = hout (pot)           5 = rood
//   3 = goud                 6 = donker
//                            7 = groen
// ---------------------------------------------------------------------------
module chest_menu (
    input  wire [9:0] x,            // absolute portret-x, 0..479
    input  wire [9:0] y,            // absolute portret-y, 0..639
    input  wire [9:0] pot,          // 0..999, uit chest_game
    input  wire [3:0] round,        // 0..15, wordt als round+1 getoond
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam [9:0] CX = 10'd240;               // midden van het scherm

  // ======================= 1. "ROUND n" ===================================
  wire lbl_round;
  label u_lbl_round (
    .x(x), .y(y), .X0(10'd120), .Y0(10'd48),
    .nchar(4'd5), .word(2'd0),                 // "ROUND"
    .on(lbl_round)
  );

  // round telt vanaf 0, de speler telt vanaf 1
  wire [4:0] round_disp = {1'b0, round} + 5'd1;
  wire       num_round;
  number2 u_num_round (
    .x(x), .y(y), .X0(10'd300), .Y0(10'd48),
    .val(round_disp),
    .on(num_round)
  );

  // ======================= 2. de geldpot ==================================
  // Rand bovenaan, daaronder een naar onderen breder wordende bak.
  localparam [9:0] RIM_Y0  = 10'd140, RIM_Y1  = 10'd164;
  localparam [9:0] BODY_Y0 = 10'd164, BODY_Y1 = 10'd330;

  wire [9:0] adx = (x >= CX) ? (x - CX) : (CX - x);      // |x - midden|

  // rim: vaste breedte
  wire in_rim  = (y >= RIM_Y0) && (y < RIM_Y1) && (adx < 10'd72);
  wire rim_edge = in_rim && ((adx >= 10'd68) ||
                             (y < RIM_Y0 + 10'd4) || (y >= RIM_Y1 - 10'd4));

  // body: halve breedte groeit van 56 naar ~76
  wire [9:0] bhw = 10'd56 + ((y - BODY_Y0) >> 3);
  wire in_body   = (y >= BODY_Y0) && (y < BODY_Y1) && (adx < bhw);
  wire body_edge = in_body && ((adx + 10'd4 >= bhw) || (y >= BODY_Y1 - 10'd4));

  // gouden munt op de buik van de pot
  wire [9:0] cdy = (y >= 10'd250) ? (y - 10'd250) : (10'd250 - y);
  wire [11:0] cr2 = (adx[5:0] * adx[5:0]) + (cdy[5:0] * cdy[5:0]);
  wire in_coin   = in_body && (adx < 10'd40) && (cdy < 10'd40) && (cr2 <= 12'd900);
  wire coin_ring = in_coin && (cr2 >= 12'd676);

  wire pot_on = in_rim || in_body;

  // ======================= 3. het bedrag ==================================
  // Groot, direct onder de pot.  Voorloopnullen worden weggelaten.
  wire num_pot;
  number3 u_num_pot (
    .x(x), .y(y), .X0(10'd144), .Y0(10'd350),
    .val(pot),
    .on(num_pot)
  );

  // ======================= 4. de twee knoppen =============================
  localparam [9:0] BTN_X0 = 10'd60,  BTN_X1 = 10'd420;
  localparam [9:0] B1_Y0  = 10'd450, B1_Y1  = 10'd520;   // CONTINUE
  localparam [9:0] B2_Y0  = 10'd540, B2_Y1  = 10'd610;   // CASH OUT

  wire in_b1 = (x >= BTN_X0) && (x < BTN_X1) && (y >= B1_Y0) && (y < B1_Y1);
  wire in_b2 = (x >= BTN_X0) && (x < BTN_X1) && (y >= B2_Y0) && (y < B2_Y1);

  wire b1_edge = in_b1 && ((x < BTN_X0 + 10'd4) || (x >= BTN_X1 - 10'd4) ||
                           (y < B1_Y0 + 10'd4)  || (y >= B1_Y1 - 10'd4));
  wire b2_edge = in_b2 && ((x < BTN_X0 + 10'd4) || (x >= BTN_X1 - 10'd4) ||
                           (y < B2_Y0 + 10'd4)  || (y >= B2_Y1 - 10'd4));

  // labels: 8 tekens x 32 px = 256 breed, gecentreerd in een knop van 360
  wire lbl_cont, lbl_cash;
  label u_lbl_cont (
    .x(x), .y(y), .X0(10'd112), .Y0(10'd469),
    .nchar(4'd8), .word(2'd1),                 // "CONTINUE"
    .on(lbl_cont)
  );
  label u_lbl_cash (
    .x(x), .y(y), .X0(10'd112), .Y0(10'd559),
    .nchar(4'd8), .word(2'd2),                 // "CASH OUT"
    .on(lbl_cash)
  );

  // ======================= 5. stapelen ====================================
  wire text_on = lbl_round | num_round | num_pot | lbl_cont | lbl_cash;

  assign px_on = text_on || pot_on || in_b1 || in_b2;

  assign px_code = text_on            ? 3'd4 :   // wit
                   coin_ring          ? 3'd1 :   // zwarte rand om de munt
                   in_coin            ? 3'd3 :   // gouden munt
                   (rim_edge || body_edge ||
                    b1_edge || b2_edge) ? 3'd1 : // zwarte outlines
                   in_rim             ? 3'd3 :   // gouden rand van de pot
                   in_body            ? 3'd2 :   // houten pot
                   in_b1              ? 3'd7 :   // CONTINUE = groen
                                        3'd3;    // CASH OUT = goud
endmodule


// ---------------------------------------------------------------------------
// LABEL -- tekent een woord uit word_rom op (X0, Y0).
// Schaal 4: een 5x8 glyph wordt 20x32, met een pitch van 32 (12 px gat).
// Pitch is een macht van 2, dus "welke letter" is gewoon een bus-slice.
// ---------------------------------------------------------------------------
module label (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] X0,
    input  wire [9:0] Y0,
    input  wire [3:0] nchar,
    input  wire [1:0] word,
    output wire       on
);
  wire [9:0] lx = x - X0;
  wire [9:0] ly = y - Y0;
  wire [9:0] wlen = {5'd0, nchar} << 5;        // nchar * 32

  wire in_band = (ly < 10'd32) && (lx < wlen);

  wire [2:0] pos  = lx[7:5];                   // welke letter
  wire [4:0] cx   = lx[4:0];                   // kolom binnen de cel
  wire [4:0] cy   = ly[4:0];
  wire       in_g = (cx < 5'd20);              // 20 px glyph, 12 px gat

  wire [2:0] gcol = cx[4:2];                   // 0..4
  wire [2:0] grow = cy[4:2];                   // 0..7

  wire [3:0] chr;
  word_rom u_word (.word(word), .pos(pos), .chr(chr));

  wire [4:0] bits;
  font_rom u_font (.chr(chr), .row(grow), .bits(bits));

  assign on = in_band && in_g && bits[3'd4 - gcol];
endmodule


// ---------------------------------------------------------------------------
// NUMBER3 -- drie cijfers, schaal 8 (32x48 per cijfer, pitch 64).
// Voorloopnullen worden weggelaten: 40 leest als "40", niet als "040".
// ---------------------------------------------------------------------------
module number3 (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] X0,
    input  wire [9:0] Y0,
    input  wire [9:0] val,
    output wire       on
);
  wire [3:0] d100, d10, d1;
  bin2bcd u_bcd (.bin(val), .d100(d100), .d10(d10), .d1(d1));

  wire [9:0] lx = x - X0;
  wire [9:0] ly = y - Y0;
  wire in_band = (ly < 10'd48) && (lx < 10'd192);

  wire [1:0] pos  = lx[7:6];                   // 0, 1 of 2
  wire [5:0] cx   = lx[5:0];
  wire [5:0] cy   = ly[5:0];
  wire       in_g = (cx < 6'd32) && (cy < 6'd48);

  wire [2:0] gcol = {1'b0, cx[4:3]};           // 0..3
  wire [2:0] grow = cy[5:3];                   // 0..5

  reg  [3:0] digit;
  reg        visible;
  always @(*) case (pos)
    2'd0:    begin digit = d100; visible = (d100 != 4'd0); end
    2'd1:    begin digit = d10;  visible = (d100 != 4'd0) || (d10 != 4'd0); end
    default: begin digit = d1;   visible = 1'b1; end
  endcase

  wire [3:0] bits;
  digit_rom u_dig (.digit(digit), .row(grow), .bits(bits));

  assign on = in_band && in_g && visible && bits[3'd3 - gcol];
endmodule


// ---------------------------------------------------------------------------
// NUMBER2 -- twee cijfers, schaal 4 (16x24 per cijfer, pitch 32).
// Alleen voor het rondenummer, dus 0..31 volstaat.
// ---------------------------------------------------------------------------
module number2 (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] X0,
    input  wire [9:0] Y0,
    input  wire [4:0] val,
    output wire       on
);
  wire [3:0] tens = (val >= 5'd30) ? 4'd3 : (val >= 5'd20) ? 4'd2 :
                    (val >= 5'd10) ? 4'd1 : 4'd0;
  // tens * 10 = (tens << 3) + (tens << 1)
  wire [4:0] tens10 = {tens[1:0], 3'd0} + {1'b0, tens[2:0], 1'b0};
  wire [4:0] rest   = val - tens10;
  wire [3:0] ones   = rest[3:0];

  wire [9:0] lx = x - X0;
  wire [9:0] ly = y - Y0;
  wire in_band = (ly < 10'd24) && (lx < 10'd64);

  wire       pos  = lx[5];
  wire [4:0] cx   = lx[4:0];
  wire [4:0] cy   = ly[4:0];
  wire       in_g = (cx < 5'd16) && (cy < 5'd24);

  wire [2:0] gcol = {1'b0, cx[3:2]};           // 0..3
  wire [2:0] grow = cy[4:2];                   // 0..5

  wire [3:0] digit   = pos ? ones : tens;
  wire       visible = pos || (tens != 4'd0);

  wire [3:0] bits;
  digit_rom u_dig (.digit(digit), .row(grow), .bits(bits));

  assign on = in_band && in_g && visible && bits[3'd3 - gcol];
endmodule


// ---------------------------------------------------------------------------
// BIN2BCD -- double dabble, 10 bits -> drie decimale cijfers.
// Puur combinatorisch: een keten van "als een nibble >= 5, tel er 3 bij op,
// dan alles een plaats opschuiven".  Tien keer, want tien inputbits.
// ---------------------------------------------------------------------------
module bin2bcd (
    input  wire [9:0] bin,
    output reg  [3:0] d100,
    output reg  [3:0] d10,
    output reg  [3:0] d1
);
  integer i;
  reg [21:0] s;
  always @(*) begin
    s = {12'd0, bin};
    for (i = 0; i < 10; i = i + 1) begin
      if (s[13:10] >= 4'd5) s[13:10] = s[13:10] + 4'd3;
      if (s[17:14] >= 4'd5) s[17:14] = s[17:14] + 4'd3;
      if (s[21:18] >= 4'd5) s[21:18] = s[21:18] + 4'd3;
      s = s << 1;
    end
    d1   = s[13:10];
    d10  = s[17:14];
    d100 = s[21:18];
  end
endmodule


// ---------------------------------------------------------------------------
// WORD_ROM -- welke letter staat op welke plek in welk woord.
// 0 = "ROUND", 1 = "CONTINUE", 2 = "CASH OUT".
// ---------------------------------------------------------------------------
module word_rom (
    input  wire [1:0] word,
    input  wire [2:0] pos,
    output reg  [3:0] chr
);
  localparam BLANK=4'd0, L_A=4'd1, L_C=4'd2, L_D=4'd3, L_E=4'd4, L_H=4'd5,
             L_I=4'd6, L_N=4'd7, L_O=4'd8, L_R=4'd9, L_S=4'd10, L_T=4'd11,
             L_U=4'd12;
  always @(*) case (word)
    2'd0: case (pos)                           // ROUND
      3'd0: chr = L_R;  3'd1: chr = L_O;  3'd2: chr = L_U;
      3'd3: chr = L_N;  3'd4: chr = L_D;  default: chr = BLANK;
    endcase
    2'd1: case (pos)                           // CONTINUE
      3'd0: chr = L_C;  3'd1: chr = L_O;  3'd2: chr = L_N;  3'd3: chr = L_T;
      3'd4: chr = L_I;  3'd5: chr = L_N;  3'd6: chr = L_U;  default: chr = L_E;
    endcase
    default: case (pos)                        // CASH OUT
      3'd0: chr = L_C;  3'd1: chr = L_A;  3'd2: chr = L_S;  3'd3: chr = L_H;
      3'd4: chr = BLANK; 3'd5: chr = L_O; 3'd6: chr = L_U;  default: chr = L_T;
    endcase
  endcase
endmodule


// ---------------------------------------------------------------------------
// FONT_ROM -- 5x8, alleen de twaalf letters die deze drie woorden nodig
// hebben.  bits[4] is de linkerkolom.  Groeit het aantal woorden, dan groeit
// alleen deze case mee.
// ---------------------------------------------------------------------------
module font_rom (
    input  wire [3:0] chr,
    input  wire [2:0] row,
    output reg  [4:0] bits
);
  always @(*) begin
    case (chr)
      4'd1: case (row)                         // A
        3'd0: bits = 5'b01110;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10001;  3'd3: bits = 5'b11111;
        3'd4: bits = 5'b10001;  3'd5: bits = 5'b10001;
        3'd6: bits = 5'b10001;  default: bits = 5'b00000;
      endcase
      4'd2: case (row)                         // C
        3'd0: bits = 5'b01110;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10000;  3'd3: bits = 5'b10000;
        3'd4: bits = 5'b10000;  3'd5: bits = 5'b10001;
        3'd6: bits = 5'b01110;  default: bits = 5'b00000;
      endcase
      4'd3: case (row)                         // D
        3'd0: bits = 5'b11110;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10001;  3'd3: bits = 5'b10001;
        3'd4: bits = 5'b10001;  3'd5: bits = 5'b10001;
        3'd6: bits = 5'b11110;  default: bits = 5'b00000;
      endcase
      4'd4: case (row)                         // E
        3'd0: bits = 5'b11111;  3'd1: bits = 5'b10000;
        3'd2: bits = 5'b10000;  3'd3: bits = 5'b11110;
        3'd4: bits = 5'b10000;  3'd5: bits = 5'b10000;
        3'd6: bits = 5'b11111;  default: bits = 5'b00000;
      endcase
      4'd5: case (row)                         // H
        3'd0: bits = 5'b10001;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10001;  3'd3: bits = 5'b11111;
        3'd4: bits = 5'b10001;  3'd5: bits = 5'b10001;
        3'd6: bits = 5'b10001;  default: bits = 5'b00000;
      endcase
      4'd6: case (row)                         // I
        3'd0: bits = 5'b11111;  3'd1: bits = 5'b00100;
        3'd2: bits = 5'b00100;  3'd3: bits = 5'b00100;
        3'd4: bits = 5'b00100;  3'd5: bits = 5'b00100;
        3'd6: bits = 5'b11111;  default: bits = 5'b00000;
      endcase
      4'd7: case (row)                         // N
        3'd0: bits = 5'b10001;  3'd1: bits = 5'b11001;
        3'd2: bits = 5'b11001;  3'd3: bits = 5'b10101;
        3'd4: bits = 5'b10011;  3'd5: bits = 5'b10011;
        3'd6: bits = 5'b10001;  default: bits = 5'b00000;
      endcase
      4'd8: case (row)                         // O
        3'd0: bits = 5'b01110;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10001;  3'd3: bits = 5'b10001;
        3'd4: bits = 5'b10001;  3'd5: bits = 5'b10001;
        3'd6: bits = 5'b01110;  default: bits = 5'b00000;
      endcase
      4'd9: case (row)                         // R
        3'd0: bits = 5'b11110;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10001;  3'd3: bits = 5'b11110;
        3'd4: bits = 5'b10100;  3'd5: bits = 5'b10010;
        3'd6: bits = 5'b10001;  default: bits = 5'b00000;
      endcase
      4'd10: case (row)                        // S
        3'd0: bits = 5'b01111;  3'd1: bits = 5'b10000;
        3'd2: bits = 5'b10000;  3'd3: bits = 5'b01110;
        3'd4: bits = 5'b00001;  3'd5: bits = 5'b00001;
        3'd6: bits = 5'b11110;  default: bits = 5'b00000;
      endcase
      4'd11: case (row)                        // T
        3'd0: bits = 5'b11111;  3'd1: bits = 5'b00100;
        3'd2: bits = 5'b00100;  3'd3: bits = 5'b00100;
        3'd4: bits = 5'b00100;  3'd5: bits = 5'b00100;
        3'd6: bits = 5'b00100;  default: bits = 5'b00000;
      endcase
      4'd12: case (row)                        // U
        3'd0: bits = 5'b10001;  3'd1: bits = 5'b10001;
        3'd2: bits = 5'b10001;  3'd3: bits = 5'b10001;
        3'd4: bits = 5'b10001;  3'd5: bits = 5'b10001;
        3'd6: bits = 5'b01110;  default: bits = 5'b00000;
      endcase
      default: bits = 5'b00000;                // spatie
    endcase
  end
endmodule