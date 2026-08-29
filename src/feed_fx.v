`default_nettype none
// ---------------------------------------------------------------------------
// FEED_FX -- het lam valt uit de lucht en de draak blaast er vuur naar.
//
// De draak staat op px 186..314, dus zijn bek op x = 185 is zijn LINKERrand:
// de vlam gaat naar links, richting het lam en de schermrand.
//
// De doorsnede (hh) groeit vanaf de bek en blijft daarna constant -- geen
// verval meer, de vlam versmalt dus niet opnieuw voorbij het lam:
//   fdx <= HH_RAMP    : groeit met 2 px straal per px afstand
//   fdx >  HH_RAMP    : blijft constant op MAX_HH tot de rand van het scherm
//
// Kleur: 3 concentrische zones (geel kern / oranje / rood) o.b.v. fdy t.o.v.
// de lokale halve breedte hh, met vergelijkingen i.p.v. een deling:
//   4*fdy <= 2*hh  -> geel   (kern, 0-50% van hh)
//   4*fdy <= 3*hh  -> oranje (50-75%)
//   anders          -> rood   (75-100%)
// Een 1-bit wobble (x[1]^y[0]) op 4*fdy geeft de randen een klein pixel-art
// kartelrandje, zonder LFSR/random generator.
//
// fx_age komt uit anim.v en loopt op vanaf act_feed.
// ---------------------------------------------------------------------------
module feed_fx (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [6:0] fx_age,
    input  wire       active,       // fx_on && fx_kind == FX_FEED
    output wire       flame_on,
    output wire [5:0] flame_rgb,
    output wire       lamb_on,
    output wire [5:0] lamb_rgb
);
  localparam [9:0] MOUTH_X = 10'd185;
  localparam [9:0] MOUTH_Y = 10'd210;                // 84 boven de graslijn
  localparam [9:0] GRASS_Y = 10'd294;
  localparam [9:0] MAX_HH  = GRASS_Y - MOUTH_Y;      // 84
  localparam [9:0] LAMB_X  = 10'd76;                 // linkerrand van het lam
  localparam [9:0] LAMB_YE = 10'd230;                // onderkant op het gras

  localparam [9:0] HH_RAMP  = MAX_HH >> 1;            // 42: einde groeifase

  // De vlam start pas een tijd NA de landing (frame ~32), i.p.v. er middenin
  // -- dat geeft de opbouw/anticipatie.  FLAME_START opschuiven = langere
  // pauze; kleiner = korter.
  // -- vlam: sneller vooruit (x16 i.p.v. x6 per frame) --
localparam [6:0] FLAME_START = 7'd30;

wire [6:0] fage_raw = (fx_age > FLAME_START) ? (fx_age - FLAME_START) : 7'd0;
wire [6:0] fage = (fage_raw > 7'd12) ? 7'd12 : fage_raw;   // klem: geen wrap
wire [9:0] reach_raw = {3'd0, fage} << 5;                  // fage * 16
wire [9:0] reach = (reach_raw > MOUTH_X) ? MOUTH_X : reach_raw;

wire [9:0] fdx = MOUTH_X - x;

  // -- groei tot HH_RAMP, daarna vlak op MAX_HH tot de schermrand --
  wire [9:0] hh = (fdx <= HH_RAMP) ? (fdx << 1) : MAX_HH;

  wire [9:0] fdy = (y >= MOUTH_Y) ? (y - MOUTH_Y) : (MOUTH_Y - y);
  wire       hh_zero = (hh == 10'd0);   // sluit de punt netjes af i.p.v. een dun sliertje
  assign flame_on = active && (x <= MOUTH_X) && (fdx < reach) && (fdy <= hh) && !hh_zero;

  // -- kleurzones: 4*fdy vs 2*hh / 3*hh, allemaal shift+add, geen deling --
  wire        wob   = x[1] ^ y[0];
  wire [9:0]  fdy4  = {fdy[7:0], 2'b00} | {9'd0, wob};   // 4*fdy, +0/+1 wiggle
  wire [9:0]  two_hh   = hh << 1;
  wire [9:0]  three_hh = hh + (hh << 1);

  wire flame_yellow = (fdy4 <= two_hh);
  wire flame_orange = !flame_yellow && (fdy4 <= three_hh);

  assign flame_rgb = flame_yellow ? 6'b11_11_00 :
                      flame_orange ? 6'b11_10_00 :
                                      6'b11_00_00;

  // -- val: constante snelheid, instelbaar --------------------------------
  // FALL_SH is een bit-shift, dus de snelheid is een macht van twee:
  //   1 -> 2 px/frame  (landt frame 115, veel te traag)
  //   2 -> 4 px/frame  (landt frame  58)
  //   3 -> 8 px/frame  (landt frame  29)   <-- huidige keuze
  //   4 -> 16 px/frame (landt frame  15)
  // Een shift is gratis; een tussenwaarde kost een optelling (zie onderaan).
  localparam [3:0] FALL_SH   = 4'd4;
  // De klem op de tijd is niet cosmetisch: zonder hem loopt fall_raw over de
  // 10-bits grens en begint er een tweede schaap te vallen.  63<<4 = 1008,
  // dus dit is veilig tot en met FALL_SH = 4.
  localparam [9:0] FALL_TMAX = 10'd63;

  wire [9:0] fx_age10 = {3'd0, fx_age};
  wire [9:0] fall_t   = (fx_age10 > FALL_TMAX) ? FALL_TMAX : fx_age10;
  wire [9:0] fall_raw = fall_t << FALL_SH;
  wire [9:0] lamb_y0 = (fall_raw > LAMB_YE) ? LAMB_YE : fall_raw;
    wire in_lamb = active && (x >= LAMB_X) && (x < LAMB_X + 10'd64) &&
                 (y >= lamb_y0) && (y < lamb_y0 + 10'd64);
  wire [9:0] lox = x - LAMB_X;
  wire [9:0] loy = y - lamb_y0;
  wire [3:0] lsx = in_lamb ? lox[5:2] : 4'd0;
  wire [3:0] lsy = in_lamb ? loy[5:2] : 4'd0;
  wire [7:0] laddr = {lsy, lsx};

  reg [1:0] rom [0:255];
  initial $readmemh("lamb.hex", rom);
  wire [1:0] lcode = rom[laddr];

  assign lamb_on  = in_lamb && (lcode != 2'd0);
  assign lamb_rgb = (lcode == 2'd1) ? 6'b00_00_00 : 6'b11_11_11;
endmodule  