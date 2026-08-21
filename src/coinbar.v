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
module coinbar (
    input  wire [9:0] x,            // local (pix_x - COINBAR_X)
    input  wire [9:0] y,            // local (pix_y - COINBAR_Y)
    input  wire [9:0] coins,        // 0..1000, uit dragon_state
    output wire       px_on,
    output wire [1:0] px_code
);
  // ======================= schaal =========================================
  localparam [9:0] COINS_MAX = 10'd1000;   // waar de balk vol staat
 
  // ======================= geometrie ======================================
  localparam [9:0] NSEG  = 10'd8;      // 8 vakjes onder elkaar
  localparam [9:0] FRAME = 10'd3;      // randdikte
  localparam [9:0] PITCH = 10'd16;     // stride per vakje -- MOET macht van 2
  localparam [9:0] SEG_H = 10'd14;     // vakjehoogte; 16-14 = 2px schotje
  localparam [9:0] SEG_W = 10'd18;     // vakjebreedte
 
  // Onder het laatste vakje komt geen schotje meer: -(PITCH-SEG_H).
  localparam [9:0] BAR_W = FRAME + SEG_W + FRAME;                            // 24
  localparam [9:0] BAR_H = FRAME + (NSEG * PITCH) - (PITCH - SEG_H) + FRAME; // 132
 
  // ======================= waar zijn we ===================================
  // Boven/links van de origin wrapt de local coord naar ~1023, dus "< BAR_H"
  // test meteen ook de boven- en linkerrand.  Geen signed compare nodig.
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
 
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);


// In coinbar.v regel 49:
  wire [9:0] diff_y = y - FRAME;
  wire [6:0] ry     = diff_y[6:0];   // Lost zowel WIDTHTRUNC als UNUSEDSIGNAL op
  wire [2:0] idx = ry[6:4];            // ry / PITCH -> vakje 0 (boven) .. 7 (onder)
  wire [3:0] sy  = ry[3:0];            // positie binnen dit vakje
 
  wire in_seg = in_inner && (sy < SEG_H[3:0]);
 
  // ======================= hoeveel vakjes vol =============================
  // coins[9:7] = coins / 128 = aantal volle vakjes (0..7).  Gratis: dit is
  // gewoon een stuk van de bus, geen deler.
  wire [2:0] nfull = coins[9:7];
  wire       maxed = (coins >= COINS_MAX);
 
  // Let op: 8 past niet in 3 bits, dus deze vergelijking MOET 4 bits breed
  // zijn -- anders is first_lit bij nfull==0 gelijk aan 0 en licht alles op.
  wire [3:0] first_lit = 4'd8 - {1'b0, nfull};
 
  wire lit = in_seg && (maxed || ({1'b0, idx} >= first_lit));
 
  // ======================= output =========================================
  assign px_on   = in_bar;
  assign px_code = !in_seg ? 2'd0 :    // frame + schotjes
                   lit     ? 2'd2 :    // vol -> geel
                             2'd1;     // leeg vakje
endmodule


