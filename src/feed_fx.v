`default_nettype none
// feed_fx, kostengeoptimaliseerd.  Zelfde beeld, smallere rekenkunde.
module feed_fx (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [6:0] fx_age,
    input  wire       active,
    output wire [5:0] feed_rgb,
    output wire       feed_on
);
  localparam [9:0] MOUTH_X = 10'd185;
  localparam [9:0] MOUTH_Y = 10'd210;
  localparam [7:0] MAX_HH  = 8'd84;
  localparam [9:0] LAMB_X  = 10'd76;
  localparam [7:0] HH_RAMP = 8'd42;
  localparam [6:0] FLAME_START = 7'd44;
  localparam [3:0] FALL_SH = 4'd3;
  localparam [9:0] LAMB_YE = 10'd230;

  // ---- reach: alles op 4 bits ipv 7/10 ---------------------------------
  // fage wordt toch op 12 geklemd, dus vier bits volstaan en de shift werkt
  // op 4 bits in plaats van 10.
  wire [6:0] fage_raw = (fx_age > FLAME_START) ? (fx_age - FLAME_START) : 7'd0;
  wire [3:0] fage = (fage_raw > 7'd12) ? 4'd12 : fage_raw[3:0];
  wire [7:0] reach_raw = {fage, 4'b0};                 // fage * 16, max 192
  wire [7:0] reach = (reach_raw > 8'd185) ? 8'd185 : reach_raw;

  // ---- wig: fdx en hh op 8 bits ----------------------------------------
  wire       left_of_mouth = (x <= MOUTH_X);
  wire [7:0] fdx = MOUTH_X[7:0] - x[7:0];              // alleen geldig links
  wire [7:0] hh  = (fdx <= HH_RAMP) ? {fdx[6:0], 1'b0} : MAX_HH;

  // fdy heeft 9 bits nodig: py loopt tot 639, dus |y-210| kan 429 worden.
  wire [8:0] fdy = (y >= MOUTH_Y) ? (y[8:0] - MOUTH_Y[8:0])
                                  : (MOUTH_Y[8:0] - y[8:0]);
  wire       hh_zero = (hh == 8'd0);
  wire flame_on = active && left_of_mouth && (fdx < reach) &&
                    (fdy <= {1'b0, hh}) && !hh_zero;

  // ---- kleurzones ------------------------------------------------------
  // 4*fdy+wob <= 2*hh  is hetzelfde als  2*fdy+wob <= hh, dus de helft van
  // de bits.  De oranje grens houdt de oude vorm maar op 10 bits ipv 12.
  wire       wob = x[1] ^ y[0];
  wire [9:0] fdy2 = {fdy[8:0], 1'b0} | {9'd0, wob};    // 2*fdy + wob
  wire [9:0] fdy4 = {fdy[7:0], 2'b00} | {9'd0, wob};
  wire [9:0] three_hh = {2'd0, hh} + {1'd0, hh, 1'b0};

  wire flame_yellow = (fdy2 <= {2'd0, hh});
  wire flame_orange = !flame_yellow && (fdy4 <= three_hh);

  wire [5:0] flame_rgb = flame_yellow ? 6'b11_11_00 :
                     flame_orange ? 6'b11_10_00 :
                                    6'b11_00_00;

  // ---- val -------------------------------------------------------------
  // fall_t wordt op 63 geklemd en dan 3 geschoven: max 504, dus 9 bits.
  wire [5:0] fall_t = (fx_age > 7'd63) ? 6'd63 : fx_age[5:0];
  wire [8:0] fall_raw = {fall_t, 3'b0};
  wire [7:0] lamb_y0 = (fall_raw > {1'b0, LAMB_YE[7:0]}) ? LAMB_YE[7:0]
                                                        : fall_raw[7:0];

  // ---- het lam ---------------------------------------------------------
  // LET OP: y MOET hier tien bits blijven.  py loopt tot 639, en met negen
  // bits verschijnt het lam een tweede keer rond y=512.
  wire in_lamb = active && (x >= LAMB_X) && (x < LAMB_X + 10'd64) &&
                 (y >= {2'b0, lamb_y0}) && (y < {2'b0, lamb_y0} + 10'd64);
  wire [7:0] lox = x[7:0] - LAMB_X[7:0];
  wire [9:0] loy = y - {2'b0, lamb_y0};
  wire [3:0] lsx = in_lamb ? lox[5:2] : 4'd0;
  wire [3:0] lsy = in_lamb ? loy[5:2] : 4'd0;
  wire [7:0] laddr = {lsy, lsx};

  reg [1:0] rom [0:255];
  initial $readmemh("lamb_meat.hex", rom);
  wire [1:0] lcode = rom[laddr];

  wire lamb_on  = in_lamb && (lcode != 2'd0);
  wire [5:0] lamb_rgb = (lcode == 2'd1) ? 6'b00_00_00 : 6'b11_11_11;


 assign feed_on = lamb_on || flame_on;
 assign feed_rgb = flame_on ? flame_rgb : lamb_rgb;

 wire _unused = &{FALL_SH, lox[7:6], lox[1:0], loy[9:6], loy[1:0], 1'b0};
endmodule
