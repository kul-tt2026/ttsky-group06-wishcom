`default_nettype none
// ---------------------------------------------------------------------------
// HEARTS -- een rij van vijf hartjes.
//
// Altijd vijf zwarte omtrekken, rood gevuld tot aan `hearts`.  De rij staat
// op een VASTE plek en springt dus niet heen en weer als je er een verliest.
//
// GEEN TEKST MEER.  Hier stond ooit het woord "OVERFLOW" links van de rij,
// met een eigen alfabet (glyph_rom) dat verder nergens voor diende.  Vijf
// rode hartjes zeggen al dat je vol zit; nu worden ze bij overflow wit in
// plaats van rood en is het alfabet verdwenen.  Scheelt ~200 cellen.
// Zie de git-historie als je de tekst terug wilt.
//
// Het hartje is wiskundig, net als coinbar/satisfactionbar: geen sprite-ROM.
// Twee bollen bovenop een ruit (een 45 graden gedraaid vierkant):
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
// px_code: 0 = zwarte omtrek | 1 = rood gevuld | 2 = gevuld bij overflow
// px_on is 0 buiten de vormen: dit is een transparante overlay, geen blok.
//
// LOKALE COORDINATEN.  Plaatsing hoort in renderer.v (HEARTS_X/HEARTS_Y).
// ---------------------------------------------------------------------------
module hearts (
    input  wire [9:0] x,            // local (px - HEARTS_X)
    input  wire [9:0] y,            // local (py - HEARTS_Y)
    input  wire [2:0] u_hearts,       // 0..5, uit dragon_state
    input  wire       overflow,     // vol: kleurt de gevulde hartjes anders
    output wire       px_on,
    output wire [1:0] px_code
);
  // ======================= geometrie ======================================
  localparam [9:0] NHEART  = 10'd5;    // aantal slots
  localparam [9:0] HPITCH  = 10'd40;   // stride per hartje
  localparam [9:0] ROW_W   = 10'd200;  // NHEART * HPITCH -- houd deze in sync
  localparam [9:0] BLOCK_H = 10'd32;

  // Boven/links van de origin wrapt de local coord naar ~1023, dus "< H"
  // test meteen ook de boven- en linkerrand.  Geen signed compare nodig.
  wire in_block = (y < BLOCK_H);
  wire in_row   = in_block && (x < ROW_W);

  // ======================= welk hartjesslot ===============================
  // Vijf vaste grenzen in plaats van x/40 en x%40.  hbase is het begin van
  // het slot; sx = x - hbase is de positie binnen dit hartje (0..39).
  reg [2:0] hidx;
  reg [9:0] hbase;
  always @(*) begin
    if      (x < 10'd40)  begin hidx = 3'd0; hbase = 10'd0;   end
    else if (x < 10'd80)  begin hidx = 3'd1; hbase = 10'd40;  end
    else if (x < 10'd120) begin hidx = 3'd2; hbase = 10'd80;  end
    else if (x < 10'd160) begin hidx = 3'd3; hbase = 10'd120; end
    else                  begin hidx = 3'd4; hbase = 10'd160; end
  end
  wire [9:0] sxw = x - hbase;
  wire [5:0] sx  = sxw[5:0];           // 0..39

  wire [2:0] hearts_c   = (u_hearts > 3'd5) ? 3'd5 : u_hearts;  // nooit meer dan er passen
  wire       heart_full = in_row && (hidx < hearts_c);

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
  wire heart_outer = in_row && (diamond_o || lobe_l_o || lobe_r_o);
  wire heart_inner = in_row && (diamond_i || lobe_l_i || lobe_r_i);

  wire heart_edge = heart_outer && !heart_inner;   // zwarte contour
  wire heart_core = heart_inner && heart_full;     // gevulde kern

  assign px_on   = heart_edge || heart_core;
  assign px_code = heart_core ? (overflow ? 2'd2 : 2'd1) : 2'd0;

  wire _unused = &{NHEART, HPITCH, sxw[9:6], 1'b0};
endmodule