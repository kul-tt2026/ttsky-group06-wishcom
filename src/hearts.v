
`default_nettype none
// ---------------------------------------------------------------------------
// HEARTS + OVERFLOW-LABEL.
//
// Links het woord "OVERFLOW" (alleen zichtbaar als overflow==1), rechts een
// rij hartjes.  Er worden alleen hartjes getekend die je ook HEBT: bij
// hearts==3 zie je er drie, geen lege omtrekken.  De rij staat op een VASTE
// plek, dus hij groeit naar rechts en springt niet heen en weer.
//
// Het hartje is wiskundig, net als coinbar/satisfactionbar: geen sprite-ROM.
// Twee cirkels bovenop een ruit (een 45 graden gedraaid vierkant).  De
// cirkels zitten precies op het midden van de twee bovenste ruitzijden, met
// straal = halve zijde, dus ze sluiten naadloos aan:
//
//        (o o)      <- twee cirkels, r^2 = 50
//         \ /       <- onderste helft van de ruit
//          v
//
// px_code: 1 = hartje  (rood in renderer.v)
//          2 = tekst   (wit in renderer.v)
// px_on is 0 buiten de vormen: dit is een transparante overlay, geen blok.
//
// LOKALE COORDINATEN.  Plaatsing hoort in renderer.v (HEARTS_X/HEARTS_Y),
// niet hier -- zo staat alle plaatsing na de portret-omzetting op een plek.
// ---------------------------------------------------------------------------
module hearts (
    input  wire [9:0] x,            // local (px - HEARTS_X)
    input  wire [9:0] y,            // local (py - HEARTS_Y)
    input  wire [2:0] hearts,       // 0..5, uit dragon_state
    input  wire       overflow,     // toont het label
    output wire       px_on,
    output wire [1:0] px_code
);
  // ======================= geometrie ======================================
  localparam [9:0] NHEART  = 10'd5;    // hoeveel er maximaal passen
  localparam [9:0] HPITCH  = 10'd32;   // stride per hartje -- MACHT VAN 2
  localparam [9:0] BLOCK_H = 10'd24;   // hoogte van de hele module

  localparam [9:0] NCHAR   = 10'd8;    // "OVERFLOW"
  localparam [9:0] CPITCH  = 10'd16;   // stride per letter -- MACHT VAN 2
  localparam [9:0] TEXT_W  = NCHAR * CPITCH;             // 128
  localparam [9:0] TEXT_Y  = 10'd4;    // tekst verticaal gecentreerd

  localparam [9:0] HEART_X0 = TEXT_W + 10'd16;           // 144: start rij

  // Boven/links van de origin wrapt de local coord naar ~1023, dus "< H"
  // test meteen ook de boven- en linkerrand.  Geen signed compare nodig.
  wire in_block = (y < BLOCK_H);

  // ======================= de tekst =======================================
  wire [9:0] ty  = y - TEXT_Y;
  wire       in_text_band = in_block && overflow && (x < TEXT_W) && (ty < 10'd16);

  wire [2:0] cidx = x[6:4];            // welke letter: x / CPITCH
  wire [3:0] cx   = x[3:0];            // positie binnen de letter-cel
  wire [3:0] cy   = ty[3:0];

  // 2x vergroot: een 6x8 glyph wordt 12x16.  De laatste 4 kolommen zijn gat.
  wire [2:0] gcol = cx[3:1];           // 0..5 (bij cx 0..11)
  wire [2:0] grow = cy[3:1];           // 0..7
  wire       in_glyph = (cx < 4'd12);

  wire [5:0] grow_bits;
  glyph_rom u_glyph (.chr(cidx), .row(grow), .bits(grow_bits));

  // bits[5] is de linkerkolom
  wire text_px = in_text_band && in_glyph && grow_bits[3'd5 - gcol];

  // ======================= de hartjes =====================================
  wire [9:0] hx    = x - HEART_X0;
  wire [2:0] hidx  = hx[7:5];          // welk hartje: hx / HPITCH
  wire [4:0] sx    = hx[4:0];          // positie binnen dit hartje

  wire in_row = in_block && (hx < NHEART * HPITCH);
  // alleen tekenen wat je HEBT (en nooit meer dan er passen)
  wire slot_on = in_row && ({1'b0, hidx} < ((hearts > NHEART[2:0]) ? NHEART[3:0]
                                                                  : {1'b0, hearts}));

  // ---- ruit: |sx-15| + |y-13| <= 10 ----
  wire [4:0] dxd = (sx >= 5'd15) ? (sx - 5'd15) : (5'd15 - sx);
  wire [4:0] dyd = (y[4:0] >= 5'd13) ? (y[4:0] - 5'd13) : (5'd13 - y[4:0]);
  wire       diamond = ((dxd + dyd) <= 5'd10);

  // ---- twee cirkels: middelpunten (10,8) en (20,8), r^2 = 50 ----
  wire [4:0] axl = (sx >= 5'd10) ? (sx - 5'd10) : (5'd10 - sx);
  wire [4:0] axr = (sx >= 5'd20) ? (sx - 5'd20) : (5'd20 - sx);
  wire [4:0] ay  = (y[4:0] >= 5'd8) ? (y[4:0] - 5'd8) : (5'd8 - y[4:0]);

  wire [9:0] ay_sq = ay * ay;
  wire       lobe_l = ((axl * axl) + ay_sq) <= 10'd50;
  wire       lobe_r = ((axr * axr) + ay_sq) <= 10'd50;

  wire heart_px = slot_on && (diamond || lobe_l || lobe_r);

  // ======================= output =========================================
  assign px_on   = heart_px | text_px;
  assign px_code = heart_px ? 2'd1 : 2'd2;
endmodule


// ---------------------------------------------------------------------------
// 6x8 letters, alleen wat "OVERFLOW" nodig heeft.  bits[5] = linkerkolom.
// chr is de POSITIE in het woord (0..7), niet een ASCII-code -- dit ROM'etje
// bestaat alleen voor dit ene label.
// ---------------------------------------------------------------------------
module glyph_rom (
    input  wire [2:0] chr,       // 0=O 1=V 2=E 3=R 4=F 5=L 6=O 7=W
    input  wire [2:0] row,       // 0..7
    output reg  [5:0] bits
);
  always @(*) begin
    case (chr)
      3'd0, 3'd6: case (row)             // O
        3'd0: bits = 6'b011110;  3'd1: bits = 6'b110011;
        3'd2: bits = 6'b110011;  3'd3: bits = 6'b110011;
        3'd4: bits = 6'b110011;  3'd5: bits = 6'b110011;
        3'd6: bits = 6'b110011;  3'd7: bits = 6'b011110;
      endcase
      3'd1: case (row)                   // V
        3'd0: bits = 6'b110011;  3'd1: bits = 6'b110011;
        3'd2: bits = 6'b110011;  3'd3: bits = 6'b110011;
        3'd4: bits = 6'b110011;  3'd5: bits = 6'b011110;
        3'd6: bits = 6'b011110;  3'd7: bits = 6'b001100;
      endcase
      3'd2: case (row)                   // E
        3'd0: bits = 6'b111111;  3'd1: bits = 6'b110000;
        3'd2: bits = 6'b110000;  3'd3: bits = 6'b111100;
        3'd4: bits = 6'b110000;  3'd5: bits = 6'b110000;
        3'd6: bits = 6'b110000;  3'd7: bits = 6'b111111;
      endcase
      3'd3: case (row)                   // R
        3'd0: bits = 6'b111110;  3'd1: bits = 6'b110011;
        3'd2: bits = 6'b110011;  3'd3: bits = 6'b111110;
        3'd4: bits = 6'b111100;  3'd5: bits = 6'b110110;
        3'd6: bits = 6'b110011;  3'd7: bits = 6'b110011;
      endcase
      3'd4: case (row)                   // F
        3'd0: bits = 6'b111111;  3'd1: bits = 6'b110000;
        3'd2: bits = 6'b110000;  3'd3: bits = 6'b111100;
        3'd4: bits = 6'b110000;  3'd5: bits = 6'b110000;
        3'd6: bits = 6'b110000;  3'd7: bits = 6'b110000;
      endcase
      3'd5: case (row)                   // L
        3'd0: bits = 6'b110000;  3'd1: bits = 6'b110000;
        3'd2: bits = 6'b110000;  3'd3: bits = 6'b110000;
        3'd4: bits = 6'b110000;  3'd5: bits = 6'b110000;
        3'd6: bits = 6'b110000;  3'd7: bits = 6'b111111;
      endcase
      default: case (row)                // W -- twee dunne V'en; met dikke
        3'd0: bits = 6'b101101;          // stammen leest hij als een U
        3'd1: bits = 6'b101101;  3'd2: bits = 6'b101101;
        3'd3: bits = 6'b101101;  3'd4: bits = 6'b101101;
        3'd5: bits = 6'b101101;  3'd6: bits = 6'b101101;
        3'd7: bits = 6'b010010;
      endcase
    endcase
  end
endmodule