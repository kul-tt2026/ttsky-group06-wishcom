`default_nettype none
// ---------------------------------------------------------------------------
// TITLE_EGG  --  grasstrook onderaan het titelscherm met een wiegend ei.
//
//   * GRAS   : een strook van GRASS_H px onderaan.
//   * SCHADUW: ellips onder het ei, schuift mee met de kanteling.
//   * EI     : de echte sprite uit dragon_l1.hex (32x32), EGG_SC x geschaald,
//              met SHEAR: elke rij schuift horizontaal met (dy * tilt) >>> 6.
//              Het draaipunt is de VOET van het ei, dus het wiegt op de grond
//              in plaats van zijwaarts weg te glijden.
//
// Uitgangen (de renderer kiest de kleuren):
//   egg_on / egg_code : gebruik hetzelfde palet als dragon_rgb (codes 1..7)
//   ground_on         : gras of schaduw
//   ground_shadow     : 1 = schaduw, 0 = gras
//
// Laagvolgorde in de renderer:  ei > grond > lucht
// ---------------------------------------------------------------------------
module title_egg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire [9:0] x,             // portret-x  0..479
    input  wire [9:0] y,             // portret-y  0..639

    output wire       egg_on,
    output wire [2:0] egg_code,
    output wire       ground_on,
    output wire       ground_shadow
);
  // --- plaatsing -----------------------------------------------------------
  localparam [9:0] GRASS_Y = 10'd540;   // bovenkant van de grasstrook
  localparam [9:0] GRASS_H = 10'd100;   // hoogte van de strook
  localparam [9:0] EGG_CX  = 10'd240;   // midden van het scherm
  localparam [9:0] EGG_SC  = 10'd4;     // schaal: 32 * 4 = 128 px
  localparam [9:0] EGG_W   = 10'd128;
  localparam [9:0] EGG_H   = 10'd128;
  localparam [9:0] EGG_FOOT= 10'd556;   // waar de onderkant van het ei staat
  localparam [9:0] EGG_X   = EGG_CX - (EGG_W >> 1);
  localparam [9:0] EGG_Y   = EGG_FOOT - EGG_H;

  // --- wiegen: driehoeksgolf -> tilt -8..+7 --------------------------------
  reg [8:0] wave;
  always @(posedge clk) begin
    if (!rst_n)          wave <= 9'd0;
    else if (frame_tick) wave <= wave + 9'd2;
  end
  wire [7:0] tri_wave = wave[8] ? (8'd255 - wave[7:0]) : wave[7:0];
  wire signed [5:0] tilt = $signed({1'b0, tri_wave[7:3]}) - 6'sd16;

  // --- SHEAR: draaipunt is de voet ----------------------------------------
  wire signed [10:0] dyp   = $signed({1'b0, y}) - $signed({1'b0, EGG_FOOT});
  wire signed [16:0] smul  = dyp * tilt;
  wire signed [10:0] shear = smul[16:6];        // ~ (dy*tilt)/64
  wire signed [11:0] xs    = $signed({2'b0, x}) - shear;
  wire xs_ok = (xs >= 0) && (xs < 12'sd480);
  wire [9:0] ex = xs[9:0];

  // --- ei-sprite ------------------------------------------------------------
  wire in_egg_box = xs_ok && (ex >= EGG_X) && (ex < EGG_X + EGG_W) &&
                    (y  >= EGG_Y) && (y  < EGG_Y + EGG_H);
  wire [9:0] offx = ex - EGG_X;
  wire [9:0] offy = y  - EGG_Y;
  wire [9:0] sclx = offx >> 2;                  // /4
  wire [9:0] scly = offy >> 2;
  wire [4:0] rel_x = in_egg_box ? sclx[4:0] : 5'd0;
  wire [4:0] rel_y = in_egg_box ? scly[4:0] : 5'd0;
  wire [9:0] addr  = {rel_y, rel_x};

  reg [2:0] rom [0:1023];
  initial $readmemh("dragon_l1.hex", rom);

  wire [2:0] code = rom[addr];
  assign egg_on   = in_egg_box && (code != 3'd0);
  assign egg_code = code;

  // --- schaduw: ellips onder de voet, schuift mee -------------------------
  localparam [9:0] SH_Y = 10'd560;
  wire signed [10:0] sh_off = {{5{tilt[5]}}, tilt};          // = tilt
  wire signed [11:0] sh_cx  = $signed({2'b0, EGG_CX}) - sh_off;
  wire [9:0] shy  = (y >= SH_Y) ? (y - SH_Y) : (SH_Y - y);
  reg  [6:0] shw;
  always @(*) case (shy[3:0])
    4'd0: shw = 7'd60; 4'd1: shw = 7'd59; 4'd2: shw = 7'd57;
    4'd3: shw = 7'd53; 4'd4: shw = 7'd47; 4'd5: shw = 7'd38;
    4'd6: shw = 7'd24; default: shw = 7'd0;
  endcase
  wire [9:0] shdx = (x >= sh_cx[9:0]) ? (x - sh_cx[9:0]) : (sh_cx[9:0] - x);
  wire shadow = (shy <= 10'd6) && (shdx < {3'b0, shw});

  // --- gras ----------------------------------------------------------------
  wire grass = (y >= GRASS_Y) && (y < GRASS_Y + GRASS_H);

  assign ground_on     = grass || shadow;
  assign ground_shadow = shadow;
endmodule