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
// EEN GEDEELDE LABEL-INSTANTIE.  Dit stond hier ooit als drie losse `label`
// instanties, een per woord.  Elke instantie sleept zijn eigen font_rom (196
// cellen) en word_rom (66) mee, en de drie woorden staan op volstrekt
// disjuncte y-banden -- er kan er dus nooit meer dan een tegelijk tekenen.
// Twee van de drie kopieen deden op elk moment niets.  Nu muxen we eerst de
// INVOER en gebruiken we een instantie: ~700 cellen goedkoper, zelfde beeld.
// Zelfde reden waarom renderer.v maar EEN title_egg instantieert voor twee
// modes, en waarom draw_buttons zijn font maar een keer opzoekt.
//
// ABSOLUTE portret-coordinaten (px, py), net als draw_buttons.
//
// px_code (3 bits) -- gedeeld met de sprite in pot.hex:
//   1 = zwart / outline      5 = dof goud
//   2 = bruin (de pot)       6 = fel geel (de munten)
//   3 = oranje highlight     7 = groen (CONTINUE)
//   4 = wit (tekst)
// ---------------------------------------------------------------------------
module chest_menu (
    input  wire [9:0] x,            // absolute portret-x, 0..479
    input  wire [9:0] y,            // absolute portret-y, 0..639
    input  wire [9:0] pot,          // 0..999, uit chest_game
    input  wire [3:0] round,        // 0..15, wordt als round+1 getoond
    output wire       px_on,
    output wire [2:0] px_code
);

  // ======================= 1. de drie woorden =============================
  // ROUND    op y  80..111
  // CONTINUE op y 469..500
  // CASH OUT op y 559..590
  //
  // De keuze hangt ALLEEN van y af, dus we hoeven de uitkomst niet extra te
  // gaten: valt y buiten alle drie de banden, dan blijft de mux op CASH OUT
  // staan en zorgt de eigen bandtest van `label` (ly < 32) ervoor dat er
  // niets verschijnt.  Voor y in 559..590 IS dat ook precies het juiste woord.
  wire in_lbl_r  = (y >= 10'd80)  && (y < 10'd112);   // ROUND
  wire in_lbl_c1 = (y >= 10'd469) && (y < 10'd501);   // CONTINUE

  wire [9:0] lbl_X0 = in_lbl_r ? 10'd120 : 10'd112;
  wire [9:0] lbl_Y0 = in_lbl_r ? 10'd80  : in_lbl_c1 ? 10'd469 : 10'd559;
  wire [3:0] lbl_n  = in_lbl_r ? 4'd5    : 4'd8;
  wire [1:0] lbl_w  = in_lbl_r ? 2'd0    : in_lbl_c1 ? 2'd1    : 2'd2;

  wire lbl_on;
  label u_lbl (
    .x(x), .y(y), .X0(lbl_X0), .Y0(lbl_Y0),
    .nchar(lbl_n), .word(lbl_w),
    .on(lbl_on)
  );

  // ======================= 2. het rondenummer =============================
  // round telt vanaf 0, de speler telt vanaf 1
  wire [4:0] round_disp = {1'b0, round} + 5'd1;
  wire       num_round;
  number2 u_num_round (
    .x(x), .y(y), .X0(10'd300), .Y0(10'd80),
    .val(round_disp),
    .on(num_round)
  );

  // ======================= 3. de geldpot ==================================
  // Sprite uit pot.hex (32x32, 6x geschaald -> 192x192 op het scherm).
  wire       pot_on;
  wire [2:0] pot_code;
  pot_sprite u_pot (.x(x), .y(y), .px_on(pot_on), .px_code(pot_code));

  // ======================= 4. het bedrag ==================================
  // Groot, direct onder de pot.  Voorloopnullen worden weggelaten.
  wire num_pot;
  number3 u_num_pot (
    .x(x), .y(y), .X0(10'd144), .Y0(10'd400),
    .val(pot),
    .on(num_pot)
  );
  // Kan nog: number2 en number3 hebben elk hun eigen digit_rom (74 cellen) en
  // staan ook op disjuncte plekken, dus dezelfde truc werkt daar.  Dat vraagt
  // wel dat beide modules hun digit + rij naar buiten brengen en de bits weer
  // binnen -- minder zelfstandige modules voor 74 cellen.  Nu niet gedaan.

  // ======================= 5. de twee knoppen =============================
  localparam [9:0] BTN_X0 = 10'd60,  BTN_X1 = 10'd420;
  localparam [9:0] B1_Y0  = 10'd450, B1_Y1  = 10'd520;   // CONTINUE
  localparam [9:0] B2_Y0  = 10'd540, B2_Y1  = 10'd610;   // CASH OUT

  wire in_b1 = (x >= BTN_X0) && (x < BTN_X1) && (y >= B1_Y0) && (y < B1_Y1);
  wire in_b2 = (x >= BTN_X0) && (x < BTN_X1) && (y >= B2_Y0) && (y < B2_Y1);

  wire b1_edge = in_b1 && ((x < BTN_X0 + 10'd4) || (x >= BTN_X1 - 10'd4) ||
                           (y < B1_Y0 + 10'd4)  || (y >= B1_Y1 - 10'd4));
  wire b2_edge = in_b2 && ((x < BTN_X0 + 10'd4) || (x >= BTN_X1 - 10'd4) ||
                           (y < B2_Y0 + 10'd4)  || (y >= B2_Y1 - 10'd4));

  // ======================= 6. stapelen ====================================
  wire text_on = lbl_on | num_round | num_pot;

  assign px_on = text_on || pot_on || in_b1 || in_b2;

  assign px_code = text_on              ? 3'd4     :   // wit
                   pot_on               ? pot_code :   // sprite eigen kleuren
                   (b1_edge || b2_edge) ? 3'd1     :   // zwarte outlines
                   in_b1                ? 3'd7     :   // CONTINUE = groen
                                          3'd5;        // CASH OUT = dof goud
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
  // {6'd0, nchar} is tien bits, net als wlen zelf -- met vijf nullen ervoor
  // was de linkerkant van de shift er negen en klaagde verilator (WIDTHEXPAND).
  wire [9:0] wlen = {6'd0, nchar} << 5;        // nchar * 32

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

  // bits is vijf breed, dus hier is een index van drie bits wel correct
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

  // bits telt vier posities, dus twee indexbits.  Met drie klaagde verilator
  // (WIDTHTRUNC); de bovenste bit was toch altijd nul.
  wire [1:0] gcol = cx[4:3];                   // 0..3
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

  assign on = in_band && in_g && visible && bits[2'd3 - gcol];
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

  wire [1:0] gcol = cx[3:2];                   // 0..3, twee bits volstaan
  wire [2:0] grow = cy[4:2];                   // 0..5

  wire [3:0] digit   = pos ? ones : tens;
  wire       visible = pos || (tens != 4'd0);

  wire [3:0] bits;
  digit_rom u_dig (.digit(digit), .row(grow), .bits(bits));

  assign on = in_band && in_g && visible && bits[2'd3 - gcol];
endmodule


// ---------------------------------------------------------------------------
// BIN2BCD -- double dabble, 10 bits -> drie decimale cijfers.
// Puur combinatorisch: een keten van "als een nibble >= 5, tel er 3 bij op,
// dan alles een plaats opschuiven".  Tien keer, want tien inputbits.
//
// coinbar.v doet zijn eigen BCD met multiply-shifts; die kan deze module
// gewoon instantieren en zo een paar honderd cellen schrappen.
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