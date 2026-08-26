`default_nettype none
// ---------------------------------------------------------------------------
// HEARTS + OVERFLOW-LABEL.
//
// Links het woord "OVERFLOW" (alleen zichtbaar als overflow==1), rechts een
// rij van vijf hartjes: altijd vijf zwarte omtrekken, rood gevuld tot aan
// `hearts`.  De rij staat op een VASTE plek en springt dus niet heen en weer.
//
// Het hartje is wiskundig, net als coinbar/satisfactionbar: geen sprite-ROM.
// Twee cirkels bovenop een ruit (een 45 graden gedraaid vierkant):
//
//        (o o)      <- twee bollen
//         \ /       <- onderste helft van de ruit
//          v
//
// GEEN DELER, GEEN MODULO, GEEN ECHTE VERMENIGVULDIGING.
//   * HPITCH is 40 en dus geen macht van twee -- hx/40 en hx%40 kostten samen
//     honderden cellen.  Met vijf slots is een vergelijkingsketen goedkoper
//     dan welke deeltruc ook: vier comparatoren en klaar.
//   * De bollen testten axl*axl + ay*ay <= r2.  Twee variabelen vermenigvuldigd
//     is de DURE soort (een constante maal iets wordt shift-adds, dit niet).
//     Vervangen door een tabel met de halve breedte van de bol per rij --
//     exact dezelfde aanpak als de ellips in draw_buttons.  De tabel bevat
//     halfbreedte+1, zodat 0 netjes "niets op deze rij" betekent en we met
//     "<" kunnen testen in plaats van "<=".
//
// px_code: 0 = zwarte rand | 1 = rood gevuld | 2 = witte tekst
// px_on is 0 buiten de vormen: dit is een transparante overlay, geen blok.
//
// LOKALE COORDINATEN.  Plaatsing hoort in renderer.v (HEARTS_X/HEARTS_Y).
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
  localparam [9:0] NHEART  = 10'd5;    // aantal slots
  localparam [9:0] HPITCH  = 10'd40;   // stride per hartje
  localparam [9:0] ROW_W   = 10'd200;  // NHEART * HPITCH -- houd deze in sync
  localparam [9:0] BLOCK_H = 10'd32;

  localparam [9:0] TEXT_W  = 10'd128;  // 8 letters * 16
  localparam [9:0] TEXT_Y  = 10'd8;
  localparam [9:0] HEART_X0 = TEXT_W + 10'd16;   // 144: start van de rij

  // Boven/links van de origin wrapt de local coord naar ~1023, dus "< H"
  // test meteen ook de boven- en linkerrand.  Geen signed compare nodig.
  wire in_block = (y < BLOCK_H);

  // ======================= de tekst =======================================
  wire [9:0] ty = y - TEXT_Y;
  wire       in_text_band = in_block && overflow && (x < TEXT_W) && (ty < 10'd16);

  wire [2:0] cidx = x[6:4];            // welke letter (CPITCH = 16)
  wire [3:0] cx   = x[3:0];
  wire [3:0] cy   = ty[3:0];

  wire [2:0] gcol = cx[3:1];           // 2x vergroot: 6x8 glyph -> 12x16
  wire [2:0] grow = cy[3:1];
  wire       in_glyph = (cx < 4'd12);

  wire [5:0] grow_bits;
  glyph_rom u_glyph (.chr(cidx), .row(grow), .bits(grow_bits));

  wire text_px = in_text_band && in_glyph && grow_bits[3'd5 - gcol];

  // ======================= welk hartjesslot ===============================
  // Vijf vaste grenzen in plaats van hx/40 en hx%40.  hbase is het begin van
  // het slot; sx = hx - hbase is de positie binnen dit hartje (0..39).
  wire [9:0] hx     = x - HEART_X0;
  wire       in_row = in_block && (hx < ROW_W);

  reg [2:0] hidx;
  reg [9:0] hbase;
  always @(*) begin
    if      (hx < 10'd40)  begin hidx = 3'd0; hbase = 10'd0;   end
    else if (hx < 10'd80)  begin hidx = 3'd1; hbase = 10'd40;  end
    else if (hx < 10'd120) begin hidx = 3'd2; hbase = 10'd80;  end
    else if (hx < 10'd160) begin hidx = 3'd3; hbase = 10'd120; end
    else                   begin hidx = 3'd4; hbase = 10'd160; end
  end
  wire [9:0] sxw = hx - hbase;
  wire [5:0] sx  = sxw[5:0];           // 0..39

  wire [2:0] hearts_c = (hearts > 3'd5) ? 3'd5 : hearts;   // nooit meer dan er passen
  wire slot_exists = in_row;
  wire heart_filled = slot_exists && (hidx < hearts_c);

  // ======================= de ruit ========================================
  // Hartje gecentreerd op sx = 20.  Buitenruit |sx-20| + |y-17| <= 14,
  // binnenruit een pixel hoger en vier smaller -- het verschil is de rand.
  wire [5:0] dxd = (sx >= 6'd20) ? (sx - 6'd20) : (6'd20 - sx);

  wire [5:0] dy_o = (y[5:0] >= 6'd17) ? (y[5:0] - 6'd17) : (6'd17 - y[5:0]);
  wire [5:0] dy_i = (y[5:0] >= 6'd16) ? (y[5:0] - 6'd16) : (6'd16 - y[5:0]);

  wire diamond_o = ((dxd + dy_o) <= 6'd14);
  wire diamond_i = ((dxd + dy_i) <= 6'd10);

  // ======================= de twee bollen =================================
  // Centra op (13, 11) en (27, 11).  De tabel geeft per rij de halve breedte
  // PLUS EEN, afgeleid uit floor(sqrt(r2 - ay^2)) + 1 met r2 = 85 (buiten) en
  // r2 = 48 (binnen).  Nul = deze rij raakt de bol niet.
  wire [5:0] ay  = (y[5:0] >= 6'd11) ? (y[5:0] - 6'd11) : (6'd11 - y[5:0]);
  wire [5:0] axl = (sx >= 6'd13) ? (sx - 6'd13) : (6'd13 - sx);
  wire [5:0] axr = (sx >= 6'd27) ? (sx - 6'd27) : (6'd27 - sx);

  reg [3:0] lw_o, lw_i;
  always @(*) case (ay)
    6'd0:    begin lw_o = 4'd10; lw_i = 4'd7; end
    6'd1:    begin lw_o = 4'd10; lw_i = 4'd7; end
    6'd2:    begin lw_o = 4'd10; lw_i = 4'd7; end
    6'd3:    begin lw_o = 4'd9;  lw_i = 4'd7; end
    6'd4:    begin lw_o = 4'd9;  lw_i = 4'd6; end
    6'd5:    begin lw_o = 4'd8;  lw_i = 4'd5; end
    6'd6:    begin lw_o = 4'd8;  lw_i = 4'd4; end
    6'd7:    begin lw_o = 4'd7;  lw_i = 4'd0; end
    6'd8:    begin lw_o = 4'd5;  lw_i = 4'd0; end
    6'd9:    begin lw_o = 4'd3;  lw_i = 4'd0; end
    default: begin lw_o = 4'd0;  lw_i = 4'd0; end
  endcase

  wire lobe_l_o = (axl < {2'b0, lw_o});
  wire lobe_r_o = (axr < {2'b0, lw_o});
  wire lobe_l_i = (axl < {2'b0, lw_i});
  wire lobe_r_i = (axr < {2'b0, lw_i});

  // ======================= samenstellen ===================================
  wire heart_outer = slot_exists && (diamond_o || lobe_l_o || lobe_r_o);
  wire heart_inner = slot_exists && (diamond_i || lobe_l_i || lobe_r_i);

  wire heart_edge = heart_outer && !heart_inner;   // zwarte contour
  wire heart_core = heart_inner && heart_filled;   // rode kern

  assign px_on   = text_px || heart_edge || heart_core;
  assign px_code = text_px    ? 2'd2 :
                   heart_core ? 2'd1 : 2'd0;
endmodule


// ---------------------------------------------------------------------------
// 6x8 letters, alleen wat "OVERFLOW" nodig heeft.  bits[5] = linkerkolom.
// chr is de POSITIE in het woord (0..7), niet een ASCII-code -- dit ROM'etje
// bestaat alleen voor dit ene label.
// ---------------------------------------------------------------------------
module glyph_rom (
    input  wire [2:0] chr,
    input  wire [2:0] row,
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