`default_nettype none
// ---------------------------------------------------------------------------
// Sprite storage.  OWNER: RENDER GROUP.
//
// Bevat: digit_rom (placeholders / font),
//        dragon_l2/l3/l4_generator, background, gameover_text,
//        pot_sprite, chest_lid_rom, chest_body_rom.
//
// Code 0 betekent altijd TRANSPARANT (achtergrond komt erdoor).
//
// TWEE REGELS die dit bestand al eens gebroken hebben:
//   1. Geen SystemVerilog-casts (5'(...) / 6'(...)).  Gebruik een tussen-wire
//      plus een slice.
//   2. Geen delingen.  Een deler door een niet-macht-van-twee kost honderden
//      tot duizenden cellen.  Vervang door vermenigvuldigen met een constante
//      en shiften -- yosys maakt daar shift-adds van:
//          n / 3   ==  (n * 683) >> 11    exact voor n < 2048
//          n / 5   ==  (n * 205) >> 10    exact voor n < 1024
//          n / 6   ==  (n * 683) >> 12    exact voor n < 2048
//          n / 10  ==  (n * 205) >> 11    exact voor n < 1024
//          n / 100 ==  (n *  41) >> 12    exact voor n < 1024
//
// 


// ===========================================================================
// DIGIT_ROM -- 4x6 cijferfont.  bits[3] is de linkerkolom.
// ===========================================================================
module digit_rom (
    input  wire [3:0] digit,     // 0..9
    input  wire [2:0] row,       // 0..5
    output reg  [3:0] bits
);
  always @(*) begin
    case ({digit, row})
      {4'd0,3'd0}: bits=4'b0110; {4'd0,3'd1}: bits=4'b1001; {4'd0,3'd2}: bits=4'b1001;
      {4'd0,3'd3}: bits=4'b1001; {4'd0,3'd4}: bits=4'b1001; {4'd0,3'd5}: bits=4'b0110;
      {4'd1,3'd0}: bits=4'b0010; {4'd1,3'd1}: bits=4'b0110; {4'd1,3'd2}: bits=4'b0010;
      {4'd1,3'd3}: bits=4'b0010; {4'd1,3'd4}: bits=4'b0010; {4'd1,3'd5}: bits=4'b0111;
      {4'd2,3'd0}: bits=4'b0110; {4'd2,3'd1}: bits=4'b1001; {4'd2,3'd2}: bits=4'b0001;
      {4'd2,3'd3}: bits=4'b0010; {4'd2,3'd4}: bits=4'b0100; {4'd2,3'd5}: bits=4'b1111;
      {4'd3,3'd0}: bits=4'b1110; {4'd3,3'd1}: bits=4'b0001; {4'd3,3'd2}: bits=4'b0110;
      {4'd3,3'd3}: bits=4'b0001; {4'd3,3'd4}: bits=4'b0001; {4'd3,3'd5}: bits=4'b1110;
      {4'd4,3'd0}: bits=4'b1001; {4'd4,3'd1}: bits=4'b1001; {4'd4,3'd2}: bits=4'b1111;
      {4'd4,3'd3}: bits=4'b0001; {4'd4,3'd4}: bits=4'b0001; {4'd4,3'd5}: bits=4'b0001;
      {4'd5,3'd0}: bits=4'b1111; {4'd5,3'd1}: bits=4'b1000; {4'd5,3'd2}: bits=4'b1110;
      {4'd5,3'd3}: bits=4'b0001; {4'd5,3'd4}: bits=4'b0001; {4'd5,3'd5}: bits=4'b1110;
      {4'd6,3'd0}: bits=4'b0110; {4'd6,3'd1}: bits=4'b1000; {4'd6,3'd2}: bits=4'b1110;
      {4'd6,3'd3}: bits=4'b1001; {4'd6,3'd4}: bits=4'b1001; {4'd6,3'd5}: bits=4'b0110;
      {4'd7,3'd0}: bits=4'b1111; {4'd7,3'd1}: bits=4'b0001; {4'd7,3'd2}: bits=4'b0010;
      {4'd7,3'd3}: bits=4'b0100; {4'd7,3'd4}: bits=4'b0100; {4'd7,3'd5}: bits=4'b0100;
      {4'd8,3'd0}: bits=4'b0110; {4'd8,3'd1}: bits=4'b1001; {4'd8,3'd2}: bits=4'b0110;
      {4'd8,3'd3}: bits=4'b1001; {4'd8,3'd4}: bits=4'b1001; {4'd8,3'd5}: bits=4'b0110;
      {4'd9,3'd0}: bits=4'b0110; {4'd9,3'd1}: bits=4'b1001; {4'd9,3'd2}: bits=4'b0111;
      {4'd9,3'd3}: bits=4'b0001; {4'd9,3'd4}: bits=4'b0001; {4'd9,3'd5}: bits=4'b0110;
      default: bits=4'b0000;
    endcase
  end
endmodule

// ===========================================================================
// DRAGON L2 -- 32x32 sprite, 4x geschaald -> 128x128.
//
// Schaal 4 en niet 5: /4 is een bitselectie en kost nul cellen, terwijl /5
// via (n * 205) >> 10 twee optelbomen van vijf termen kostte -- samen zo'n
// 280 cellen voor deze module alleen.  De draak wordt daardoor 160 -> 128 px.
// De ONDERKANT staat nog op y = 340, zodat hij op het gras blijft staan
// (background.v zet GRASS_Y op 344); alleen de bovenkant zakt mee.
// ===========================================================================
module dragon_l2_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    localparam [9:0] SPRITE_X = 10'd186;   // midden blijft 250
    localparam [9:0] SPRITE_Y = 10'd166;   // onderkant blijft 340
    localparam [9:0] SPRITE_W = 10'd128;   // 32 * 4
    localparam [9:0] SPRITE_H = 10'd128;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    wire [9:0] ox = x - SPRITE_X;          // 0..127 binnen in_bounds
    wire [9:0] oy = y - SPRITE_Y;

    // /4 als bitselectie.  Buiten het vak wrapt ox naar ~1023, dus de
    // in_bounds-gate blijft nodig om nooit buiten de ROM te indexeren.
    wire [4:0] rel_x = in_bounds ? ox[6:2] : 5'd0;   // 0..31
    wire [4:0] rel_y = in_bounds ? oy[6:2] : 5'd0;

    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial $readmemh("dragon_l2.hex", rom);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else if (in_bounds && (rom[addr] != 3'd0)) begin
            px_on   <= 1'b1;
            px_code <= rom[addr];
        end else begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end
    end
endmodule


// ===========================================================================
// DRAGON L3 -- 32x32 sprite, 4x geschaald -> 128x128.
//
// Was 6x (192 px) via (n * 683) >> 12; dat waren twee optelbomen.  Nu 4x,
// dus een bitselectie.  Dit is de grootste stap in formaat van de drie:
// 192 -> 128.  Onderkant blijft op y = 336.
// ===========================================================================
module dragon_l3_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    localparam [9:0] SPRITE_X = 10'd222;   // midden blijft 286
    localparam [9:0] SPRITE_Y = 10'd162;   // onderkant blijft 336
    localparam [9:0] SPRITE_W = 10'd128;   // 32 * 4
    localparam [9:0] SPRITE_H = 10'd128;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    wire [9:0] ox = x - SPRITE_X;
    wire [9:0] oy = y - SPRITE_Y;

    wire [4:0] rel_x = in_bounds ? ox[6:2] : 5'd0;   // 0..31
    wire [4:0] rel_y = in_bounds ? oy[6:2] : 5'd0;

    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial $readmemh("dragon_l3.hex", rom);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else if (in_bounds && (rom[addr] != 3'd0)) begin
            px_on   <= 1'b1;
            px_code <= rom[addr];
        end else begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end
    end
endmodule


// ===========================================================================
// DRAGON L4 -- 48x48 sprite, 4x geschaald -> 192x192.
//
// Was 5x (240 px).  Adres = rel_y*48 + rel_x = (rel_y<<5) + (rel_y<<4) + rel_x;
// dat is een constante maal een variabele en blijft dus gewoon twee shifts en
// een optelling -- daar zat het probleem niet.  Onderkant blijft op y = 360.
// ===========================================================================
module dragon_l4_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    localparam [9:0] SPRITE_X = 10'd189;   // midden blijft 285
    localparam [9:0] SPRITE_Y = 10'd122;   // onderkant blijft 360
    localparam [9:0] SPRITE_W = 10'd192;   // 48 * 4
    localparam [9:0] SPRITE_H = 10'd192;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    wire [9:0] ox = x - SPRITE_X;          // 0..191 binnen in_bounds
    wire [9:0] oy = y - SPRITE_Y;

    wire [5:0] rel_x = in_bounds ? ox[7:2] : 6'd0;   // 0..47
    wire [5:0] rel_y = in_bounds ? oy[7:2] : 6'd0;

    wire [11:0] addr = ({6'd0, rel_y} << 5) + ({6'd0, rel_y} << 4) + {6'd0, rel_x};

    reg [2:0] rom [0:2303];
    initial $readmemh("dragon_l4.hex", rom);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else if (in_bounds && (rom[addr] != 3'd0)) begin
            px_on   <= 1'b1;
            px_code <= rom[addr];
        end else begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end
    end
endmodule

// ===========================================================================
// BACKGROUND -- lucht met zon en twee wolkjes, een grasstrook, en daaronder
// aarde.  De zon gaat via een halfbreedte-tabel per rij (zoals draw_buttons),
// de wolkjes en de horizon zijn vergelijkingen.
// ===========================================================================
module background (
    input  wire [9:0] x,          // portret-x  0..479
    input  wire [9:0] y,          // portret-y  0..639
    output reg  [5:0] bg_rgb
);
  // ---- horizon -----------------------------------------------------------
  localparam [9:0] GRASS_Y = 10'd294;            // bovenkant gras
  localparam [9:0] GRASS_H = 10'd100;            // dikte grasstrook
  localparam [9:0] SOIL_Y  = GRASS_Y + GRASS_H;  // 394
  localparam [9:0] EDGE_H  = 10'd4;              // donkere scheidingslijn

  // ---- zon: rechtsboven, onder de hartjes --------------------------------
  localparam [9:0] SUN_CX = 10'd404;
  localparam [9:0] SUN_CY = 10'd104;
  localparam [9:0] SUN_R  = 10'd36;

  // ---- kleuren -----------------------------------------------------------
  localparam [5:0] C_SKY     = 6'b01_10_11;   // hemelsblauw, zoals het titelscherm
  localparam [5:0] C_SUN     = 6'b11_11_00;   // geel
  localparam [5:0] C_CLOUD   = 6'b11_11_11;   // wit
  localparam [5:0] C_GRASS   = 6'b00_10_00;   // ZELFDE groen als title_egg's gras
  localparam [5:0] C_EDGE    = 6'b01_00_00;   // donkerbruine rand
  localparam [5:0] C_SOIL    = 6'b10_01_00;   // aarde
  localparam [5:0] C_SOIL_DK = 6'b01_00_00;   // donkerder, voor de spikkels

  // ---- zon ---------------------------------------------------------------
  // Halfbreedte per rij uit een tabel: sqrt(R^2 - dy^2) zou twee
  // vermenigvuldigingen per pixel kosten.  Index in stappen van 2 px; bij een
  // straal van 36 is dat niet te zien.
  wire [9:0] sdx = (x >= SUN_CX) ? (x - SUN_CX) : (SUN_CX - x);
  wire [9:0] sdy = (y >= SUN_CY) ? (y - SUN_CY) : (SUN_CY - y);

  reg [5:0] sun_hw;
  always @(*) case (sdy[5:1])              // sdy >> 1, geldig zolang sdy <= 36
    5'd0:  sun_hw = 6'd36;  5'd1:  sun_hw = 6'd36;
    5'd2:  sun_hw = 6'd36;  5'd3:  sun_hw = 6'd35;
    5'd4:  sun_hw = 6'd35;  5'd5:  sun_hw = 6'd35;
    5'd6:  sun_hw = 6'd34;  5'd7:  sun_hw = 6'd33;
    5'd8:  sun_hw = 6'd32;  5'd9:  sun_hw = 6'd31;
    5'd10: sun_hw = 6'd30;  5'd11: sun_hw = 6'd28;
    5'd12: sun_hw = 6'd27;  5'd13: sun_hw = 6'd25;
    5'd14: sun_hw = 6'd23;  5'd15: sun_hw = 6'd20;
    5'd16: sun_hw = 6'd16;  5'd17: sun_hw = 6'd12;
    default: sun_hw = 6'd0;
  endcase

  wire sun = (sdy <= SUN_R) && (sdx < {4'd0, sun_hw});

  // ---- twee wolkjes ------------------------------------------------------
  // Elk twee rechthoeken: een smalle bovenop een brede.  Ze zijn 50 px mee
  // omhoog gegaan met de graslijn.  De onderste blijft daarmee ruim onder de
  // zon: die eindigt op y = 140, deze begint op 215.
  wire cloud1 = (y >= 10'd95 && y < 10'd105 && x >= 10'd121  && x < 10'd169) ||
                (y >= 10'd105 && y < 10'd117 && x >= 10'd105  && x < 10'd185);

  wire cloud2 = (y >= 10'd165 && y < 10'd175 && x >= 10'd376 && x < 10'd424) ||
                (y >= 10'd175 && y < 10'd187 && x >= 10'd360 && x < 10'd440);

   // ---- spikkels in de grond ---------------------------------------------
  // Een gewone x^y geeft ZIGZAG: bit i hangt dan alleen van x[i] en y[i] af,
  // en dat leest als diagonale strepen.  Hier gaat y er OMGEKEERD in -- bit i
  // van h komt uit x[i] en y[5-i] -- waardoor er geen diagonaal meer in zit.
  // Omdraaien is alleen bedrading, dus dat is gratis.
  //
  // De laagste gebruikte bit is bit 1, dus de korrels zijn 2 px groot.
  // Grovere korrels: neem x[7:2] en y[7:2].
  // Meer korrels: laat de tweede voorwaarde weg (gaat van ~9% naar ~12%).
  wire [5:0] hx = x[6:1];
  wire [5:0] hy = {y[1], y[2], y[3], y[4], y[5], y[6]};   // omgekeerd
  wire [5:0] h  = hx ^ hy;

  wire speck = (h[2:0] == 3'd3) && (h[5:4] != 2'b00);
  // ---- stapelen ----------------------------------------------------------
  always @(*) begin
    if      (y >= SOIL_Y + EDGE_H) bg_rgb = speck ? C_SOIL_DK : C_SOIL;
    else if (y >= SOIL_Y)          bg_rgb = C_EDGE;
    else if (y >= GRASS_Y)         bg_rgb = C_GRASS;
    else if (sun)                  bg_rgb = C_SUN;
    else if (cloud1 || cloud2)     bg_rgb = C_CLOUD;
    else                           bg_rgb = C_SKY;
  end
endmodule


// ===========================================================================
// GAMEOVER_TEXT -- "GAME" / "OVER" in een 6x8 font, 8x geschaald.
// Schaal 8 en niet 6: /8 is een bitselectie, terwijl /6 via (n*683)>>12 twee
// optelbomen van zes termen kostte.  Ook de lettercel is nu 64 breed, een
// macht van twee, waardoor "welke letter" een bus-slice is in plaats van een
// vergelijkingsketen plus een vermenigvuldiging met 48.
// ===========================================================================
module gameover_text (
    input  wire [9:0] px,        // 0..479 (portret X)
    input  wire [9:0] py,        // 0..639 (portret Y)
    output wire       text_on
);
  localparam [9:0] START_X = 10'd112;   // (480 - 256) / 2
  localparam [9:0] LINE_W  = 10'd256;   // 4 letters * 64
  localparam [9:0] LINE1_Y = 10'd240;   // GAME
  localparam [9:0] LINE2_Y = 10'd330;   // OVER
  localparam [9:0] CHAR_H  = 10'd64;    // 8 rijen * 8

  wire in_line1 = (px >= START_X) && (px < START_X + LINE_W) &&
                  (py >= LINE1_Y) && (py < LINE1_Y + CHAR_H);
  wire in_line2 = (px >= START_X) && (px < START_X + LINE_W) &&
                  (py >= LINE2_Y) && (py < LINE2_Y + CHAR_H);

  wire [9:0] lx = px - START_X;         // 0..255

  wire [1:0] char_pos = lx[7:6];        // welke letter: /64, gewoon een slice
  wire [5:0] cx       = lx[5:0];        // 0..63 binnen de lettercel

  wire [9:0] ly10 = in_line1 ? (py - LINE1_Y) : (py - LINE2_Y);
  wire [5:0] ly   = ly10[5:0];          // 0..63

  wire [2:0] gcol = cx[5:3];            // /8
  wire [2:0] grow = ly[5:3];            // /8

  wire in_glyph = (cx < 6'd48);         // laatste 16 px is tussenruimte

  // ---- welk karakter -----------------------------------------------------
  // IDs: 0:G 1:A 2:M 3:E 4:O 5:V 6:R
  reg [2:0] glyph_id;
  always @(*) begin
    if (in_line1) case (char_pos)       // GAME
      2'd0: glyph_id = 3'd0;
      2'd1: glyph_id = 3'd1;
      2'd2: glyph_id = 3'd2;
      default: glyph_id = 3'd3;
    endcase
    else case (char_pos)                // OVER
      2'd0: glyph_id = 3'd4;
      2'd1: glyph_id = 3'd5;
      2'd2: glyph_id = 3'd3;
      default: glyph_id = 3'd6;
    endcase
  end

  // ---- glyph-tabel -------------------------------------------------------
  reg [5:0] glyph_bits;
  always @(*) begin
    case (glyph_id)
      3'd0: case (grow)                 // G
        3'd0: glyph_bits = 6'b011110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110000; 3'd3: glyph_bits = 6'b110111;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; default: glyph_bits = 6'b011110;
      endcase
      3'd1: case (grow)                 // A
        3'd0: glyph_bits = 6'b011110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b111111;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; default: glyph_bits = 6'b110011;
      endcase
      3'd2: case (grow)                 // M
        3'd0: glyph_bits = 6'b110011; 3'd1: glyph_bits = 6'b111111;
        3'd2: glyph_bits = 6'b101101; 3'd3: glyph_bits = 6'b100001;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; default: glyph_bits = 6'b110011;
      endcase
      3'd3: case (grow)                 // E
        3'd0: glyph_bits = 6'b111111; 3'd1: glyph_bits = 6'b110000;
        3'd2: glyph_bits = 6'b110000; 3'd3: glyph_bits = 6'b111100;
        3'd4: glyph_bits = 6'b110000; 3'd5: glyph_bits = 6'b110000;
        3'd6: glyph_bits = 6'b110000; default: glyph_bits = 6'b111111;
      endcase
      3'd4: case (grow)                 // O
        3'd0: glyph_bits = 6'b011110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b110011;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; default: glyph_bits = 6'b011110;
      endcase
      3'd5: case (grow)                 // V
        3'd0: glyph_bits = 6'b110011; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b110011;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b011110;
        3'd6: glyph_bits = 6'b011110; default: glyph_bits = 6'b001100;
      endcase
      default: case (grow)              // R
        3'd0: glyph_bits = 6'b111110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b111110;
        3'd4: glyph_bits = 6'b111100; 3'd5: glyph_bits = 6'b110110;
        3'd6: glyph_bits = 6'b110011; default: glyph_bits = 6'b110011;
      endcase
    endcase
  end

  assign text_on = (in_line1 || in_line2) && in_glyph && glyph_bits[3'd5 - gcol];
endmodule

// ===========================================================================
// POT_SPRITE -- 32x32, 4x geschaald -> 128x128.  Schaal is een macht van twee.
// De aanroeper plaatst hem: op het kiesscherm staat hij linksboven in de
// boord, in het menu gecentreerd.  Dezelfde instantie, alleen een andere
// oorsprong -- twee instanties zouden de ROM twee keer op de chip zetten.
// ===========================================================================
module pot_sprite (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] X0,
    input  wire [9:0] Y0,
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam [9:0] SPRITE_W = 10'd128;   // 32 * 4
  localparam [9:0] SPRITE_H = 10'd128;

  wire in_bounds = (x >= X0) && (x < X0 + SPRITE_W) &&
                   (y >= Y0) && (y < Y0 + SPRITE_H);

  wire [9:0] ox = x - X0;
  wire [9:0] oy = y - Y0;
  wire [4:0] rel_x = in_bounds ? ox[6:2] : 5'd0;   // /4
  wire [4:0] rel_y = in_bounds ? oy[6:2] : 5'd0;
  wire [9:0] addr  = {rel_y, rel_x};

  reg [2:0] rom [0:1023];
  initial $readmemh("pot.hex", rom);

  assign px_code = in_bounds ? rom[addr] : 3'd0;
  assign px_on   = (px_code != 3'd0);
endmodule

// ===========================================================================
// CHEST ROM'S -- deksel (twee frames) en bak.
// ===========================================================================
module chest_lid_rom (
    input  wire       frame,      // 0 dicht, 1 open
    input  wire [3:0] row,        // 0..15
    input  wire [4:0] col,        // 0..31
    output wire [1:0] code
);
  reg [1:0] rom [0:1023];
  initial $readmemh("chest_lid.hex", rom);

  wire [9:0] addr = {frame, row, col};
  assign code = rom[addr];
endmodule


module chest_body_rom (
    input  wire [3:0] row,        // 0..15
    input  wire [4:0] col,        // 0..31
    output wire [1:0] code
);
  reg [1:0] rom [0:511];
  initial $readmemh("chest_body.hex", rom);

  wire [8:0] addr = {row, col};
  assign code = rom[addr];
endmodule
// ---------------------------------------------------------------------------
// LEVEL_BOX -- "LVL n" linksboven op het homescherm.
//
// De drie letters zijn een vaste minibitmap van 3x5, geen font.  LVL verandert
// nooit, dus een opzoektabel plus woordindex zou meer logica kosten dan de
// twee case-blokjes hieronder -- L en V zijn zo simpel dat er bijna niets van
// overblijft.  Zelfde afweging als PRESS ANY BUTTON in title_egg.v.
//
// Het CIJFER komt wel uit de gedeelde digit_rom, via de renderer: dit vakje
// zegt met q_digit/q_row wat het wil opzoeken en krijgt het antwoord in
// q_bits terug.  Zo staat die tabel maar een keer op de chip in plaats van
// vier keer (menu, pot, munten, level).
//
// Alles op schaal 3: letters 9x15, cijfer 12x18.  Vak is 48 x 18.
// ---------------------------------------------------------------------------
module level_box (
    input  wire [9:0] x,            // lokaal (px - LEVEL_X)
    input  wire [9:0] y,            // lokaal (py - LEVEL_Y)
    input  wire [2:0] level,        // 0..7, wordt als level+1 getoond
    output wire [3:0] q_digit,
    output wire [2:0] q_row,
    input  wire [3:0] q_bits,
    output wire       q_on,
    output wire       on
);
  // ======================= "LVL" ==========================================
  // Letterslots: 0..8, 11..19, 22..30.  Twee px lager dan het cijfer, zodat
  // de 15 hoge letters tegen het 18 hoge cijfer gecentreerd staan.
  localparam [9:0] TXT_Y0 = 10'd2;

  wire in_txt = (x < 10'd31) && (y >= TXT_Y0) && (y < TXT_Y0 + 10'd15);
  wire [9:0] tdy = y - TXT_Y0;                 // 0..14

  reg [1:0] lslot;                             // 0 = L, 1 = V, 2 = L
  reg [9:0] lbase;
  reg       lvalid;
  always @(*) begin
    if      (x <= 10'd8)                 begin lslot=2'd0; lbase=10'd0;  lvalid=1'b1; end
    else if (x >= 10'd11 && x <= 10'd19) begin lslot=2'd1; lbase=10'd11; lvalid=1'b1; end
    else if (x >= 10'd22 && x <= 10'd30) begin lslot=2'd2; lbase=10'd22; lvalid=1'b1; end
    else                                 begin lslot=2'd0; lbase=10'd0;  lvalid=1'b0; end
  end
  wire [9:0] lcx = x - lbase;                  // 0..8

  // /3 met vergelijkingen: de bereiken zijn te klein voor een deeltruc.
  wire [1:0] lgx = (lcx < 10'd3) ? 2'd0 : (lcx < 10'd6) ? 2'd1 : 2'd2;
  wire [2:0] lgy = (tdy < 10'd3)  ? 3'd0 : (tdy < 10'd6)  ? 3'd1 :
                   (tdy < 10'd9)  ? 3'd2 : (tdy < 10'd12) ? 3'd3 : 3'd4;

  // L = 100 100 100 100 111 ,  V = 101 101 101 101 010
  reg [2:0] lrow;
  always @(*) begin
    if (lslot == 2'd1)
      case (lgy)                               // V
        3'd4:    lrow = 3'b010;
        default: lrow = 3'b101;
      endcase
    else
      case (lgy)                               // L
        3'd4:    lrow = 3'b111;
        default: lrow = 3'b100;
      endcase
  end

  wire txt_px = in_txt && lvalid &&
                ((lgx == 2'd0) ? lrow[2] : (lgx == 2'd1) ? lrow[1] : lrow[0]);

  // ======================= het cijfer =====================================
  wire in_dig = (x >= 10'd36) && (x < 10'd48) && (y < 10'd18);
  wire [9:0] ddx = x - 10'd36;                 // 0..11

  wire [1:0] dgx = (ddx < 10'd3) ? 2'd0 : (ddx < 10'd6) ? 2'd1 :
                   (ddx < 10'd9) ? 2'd2 : 2'd3;
  wire [2:0] dgy = (y < 10'd3)  ? 3'd0 : (y < 10'd6)  ? 3'd1 :
                   (y < 10'd9)  ? 3'd2 : (y < 10'd12) ? 3'd3 :
                   (y < 10'd15) ? 3'd4 : 3'd5;

  assign q_digit = {1'b0, level} + 4'd1;       // level telt vanaf 0, de speler vanaf 1
  assign q_row   = dgy;
  assign q_on    = in_dig;

  wire dig_px = in_dig && q_bits[2'd3 - dgx];

  assign on = txt_px || dig_px;
endmodule

// ---------------------------------------------------------------------------
// WIN_SCREEN -- "YOU WIN" in twee regels, gouden letters op zwart.
//
// Dezelfde 5x8 glyphs als font_rom in chest_menu.v: O, U, I en N zijn er
// letterlijk uit overgenomen, Y en W zijn in dezelfde stijl bijgetekend.
// Maar het is een VASTE bitmap, geen fontopzoeking: "YOU WIN" verandert
// nooit, en een label-instantie zou font_rom en word_rom een tweede keer op
// de chip zetten voor 415 cellen.  Zelfde afweging als bij PRESS ANY BUTTON
// en LVL.
//
// Schaal 16 (een bitselectie, dus gratis): elke letter wordt 80 x 112, elke
// regel 272 x 112.  Twee regels onder elkaar, gecentreerd op een scherm van
// 480 breed.
// ---------------------------------------------------------------------------
module win_screen (
    input  wire [9:0] x,          // absolute portret-x, 0..479
    input  wire [9:0] y,          // absolute portret-y, 0..639
    output wire       on
);
  localparam [9:0] W_X  = 10'd104;   // (480 - 272) / 2
  localparam [9:0] W_W  = 10'd272;   // 17 kolommen * 16
  localparam [9:0] W_H  = 10'd112;   //  7 rijen    * 16
  localparam [9:0] L1_Y = 10'd200;   // "YOU"
  localparam [9:0] L2_Y = 10'd344;   // "WIN"

  wire in_x  = (x >= W_X) && (x < W_X + W_W);
  wire in_l1 = in_x && (y >= L1_Y) && (y < L1_Y + W_H);
  wire in_l2 = in_x && (y >= L2_Y) && (y < L2_Y + W_H);

  wire [9:0] gx = x - W_X;
  wire [9:0] gy = in_l1 ? (y - L1_Y) : (y - L2_Y);

  wire [4:0] col = gx[8:4];          // /16, 0..16
  wire [2:0] row = gy[6:4];          // /16, 0..6

  // Zeventien kolommen per regel: drie letters van 5 met 1 px ertussen.
  // Bit 16 is de linkerkolom.
  reg [16:0] bits;
  always @(*) case ({in_l2, row})
    // ---- regel 1: Y O U ----
    {1'b0,3'd0}: bits = 17'b10001_0_01110_0_10001;
    {1'b0,3'd1}: bits = 17'b10001_0_10001_0_10001;
    {1'b0,3'd2}: bits = 17'b01010_0_10001_0_10001;
    {1'b0,3'd3}: bits = 17'b00100_0_10001_0_10001;
    {1'b0,3'd4}: bits = 17'b00100_0_10001_0_10001;
    {1'b0,3'd5}: bits = 17'b00100_0_10001_0_10001;
    {1'b0,3'd6}: bits = 17'b00100_0_01110_0_01110;
    // ---- regel 2: W I N ----
    {1'b1,3'd0}: bits = 17'b10001_0_11111_0_10001;
    {1'b1,3'd1}: bits = 17'b10001_0_00100_0_11001;
    {1'b1,3'd2}: bits = 17'b10001_0_00100_0_11001;
    {1'b1,3'd3}: bits = 17'b10101_0_00100_0_10101;
    {1'b1,3'd4}: bits = 17'b10101_0_00100_0_10011;
    {1'b1,3'd5}: bits = 17'b11011_0_00100_0_10011;
    {1'b1,3'd6}: bits = 17'b10001_0_11111_0_10001;
    default:     bits = 17'd0;
  endcase

  assign on = (in_l1 || in_l2) && bits[5'd16 - col];
endmodule

// ===========================================================================
// SCALES_BG -- drakenschubben als achtergrond voor de minigame, met een
// bruine boord en een gouden bies bovenaan.
//
// Tegel van 64 x 32, waarbij elke tweede rij een halve tegel opschuift -- dat
// verspringen is wat de schubben laat nestelen.  Beide maten zijn machten van
// twee, dus "waar zit ik in de tegel" is puur bitselectie, en een halve tegel
// opschuiven is bit 5 omklappen in plaats van een opteller.
//
// Elke schub is de BOVENRAND van een cirkel met straal 36 waarvan het
// middelpunt op ty = 34 ligt, dus net onder de tegel.  Daardoor waaiert hij
// uit van smal bovenaan naar de volle tegelbreedte onderaan.  De halve breedte
// per rij komt uit een tabel: geen sqrt, geen vermenigvuldiging.
//
// De schubben rekenen vanaf SCALES_Y en niet vanaf y = 0, zodat de eerste rij
// onder de bies netjes bij het begin van een tegel start in plaats van er
// halverwege doorheen gesneden te worden.
// ===========================================================================
/*module scales_bg (
    input  wire [9:0] x,          // portret-x  0..479
    input  wire [9:0] y,          // portret-y  0..639
    input  wire       plain,      // 1 = effen bruin onder de bies (menuscherm)
    output wire [5:0] bg_rgb
);
  // ---- kleuren -----------------------------------------------------------
  localparam [5:0] C_LINE  = 6'b00_00_00;   // zwart
  localparam [5:0] C_LIGHT = 6'b00_10_00;   // schub
  localparam [5:0] C_DARK  = 6'b00_01_00;   // naad en schaduw
  localparam [5:0] C_BROWN = 6'b01_00_00;   // hout, zoals de kisten
  localparam [5:0] C_GOLD  = 6'b11_10_00;   // goud, zoals de kisten

  // ---- boord bovenaan ----------------------------------------------------
  localparam [9:0] BORDER_H = 10'd176;                  // bruine boord
  localparam [9:0] TRIM_H   = 10'd10;                    // gouden bies
  localparam [9:0] SCALES_Y = BORDER_H + TRIM_H;        // 208

  // ---- vorm van de schub -------------------------------------------------
  localparam [5:0] LINE_W = 6'd6;           // dikte van de omtrek
  localparam [4:0] SHADE  = 5'd10;          // hoogte van de schaduwband

  wire [9:0] ys = y - SCALES_Y;             // wrapt boven de bies; niet erg,
                                            // de cascade tekent daar de boord
  wire [5:0] tx = {x[5] ^ ys[5], x[4:0]};   // 0..63 binnen de tegel
  wire [4:0] ty = ys[4:0];                  // 0..31

  wire [5:0] dx = (tx >= 6'd32) ? (tx - 6'd32) : (6'd32 - tx);   // 0..32

  reg [5:0] hw;
  always @(*) case (ty)
    5'd0:  hw = 6'd11;   5'd1:  hw = 6'd14;   5'd2:  hw = 6'd16;
    5'd3:  hw = 6'd18;   5'd4:  hw = 6'd19;   5'd5:  hw = 6'd21;
    5'd6:  hw = 6'd22;   5'd7:  hw = 6'd23;   5'd8:  hw = 6'd24;
    5'd9:  hw = 6'd25;   5'd10: hw = 6'd26;   5'd11: hw = 6'd27;
    5'd12: hw = 6'd28;   5'd13: hw = 6'd29;   5'd14: hw = 6'd29;
    5'd15: hw = 6'd30;   5'd16: hw = 6'd31;   5'd17: hw = 6'd31;
    default: hw = 6'd32;                      // vanaf rij 18 vult hij de tegel
  endcase

  wire outside = (dx > hw);
  wire outline = !outside && (dx + LINE_W > hw);
  wire shadow  = !outside && !outline && (ty < SHADE);

  wire [5:0] scale_rgb = outline             ? C_LINE :
                         (outside || shadow) ? C_DARK : C_LIGHT;

  // Op het menuscherm is alles effen bruin: geen schubben en ook geen bies.
  // Daar staan twee grote knoppen en de pot op, en dat leest rustiger zonder
  // enige structuur eronder.
  assign bg_rgb = (plain || (y < BORDER_H)) ? C_BROWN :
                  (y < SCALES_Y)            ? C_GOLD  : scale_rgb;
endmodule */

`default_nettype none
// ===========================================================================
// VELVET_BG -- gecapitonneerd rood fluweel als achtergrond voor de minigame,
// met een bruine boord en een gouden bies bovenaan.
//
// Ruiten zijn goedkoop: |dx| + |dy| binnen een tegel geeft de afstand tot het
// tegelmidden in ruitvorm, en dat is puur optellen.  Tegel 64 x 64, dus alle
// tegelposities zijn bitselecties.
//
// De ruiten liggen op TWEE roosters tegelijk: eentje rond het tegelmidden en
// eentje rond de tegelhoek.  Dat volgt vanzelf uit dd -- is de ruitafstand
// groter dan een halve tegel, dan hoor je bij de buurruit en is de afstand
// 64 min die waarde.  Zo sluit het vlak zonder gaten.
//
// HET VELD IS GEDITHERD tussen twee roodtinten.  Op twee bits per kanaal is er
// niets tussen (85,0,0) en (170,0,0), en allebei apart zijn ze te donker of te
// fel; om en om per pixel leest als (128,0,0) en dat is precies de kleur die
// fluweel nodig heeft.  Kost een XOR.  Ziet het er op de echte monitor
// onrustig uit, zet DITHER op 0 -- dan wordt het veld effen donkerrood.
// ===========================================================================
module velvet_bg (
    input  wire [9:0] x,          // portret-x  0..479
    input  wire [9:0] y,          // portret-y  0..639
    output wire [5:0] bg_rgb
);
  localparam DITHER = 1'b1;

  // ---- kleuren -----------------------------------------------------------
  localparam [5:0] C_TUFT  = 6'b00_00_00;   // zwart knoopje op de kruising
  localparam [5:0] C_SEAM  = 6'b01_00_00;   // donkerrode naad
  localparam [5:0] C_FLD1  = 6'b01_00_00;   // veld, donkere helft
  localparam [5:0] C_FLD2  = 6'b10_00_00;   // veld, lichte helft
  localparam [5:0] C_BROWN = 6'b01_00_00;   // boord
  localparam [5:0] C_GOLD  = 6'b11_10_00;   // bies

  // ---- boord bovenaan ----------------------------------------------------
  localparam [9:0] BORDER_H = 10'd176;
  localparam [9:0] TRIM_H   = 10'd10;
  localparam [9:0] SCALES_Y = BORDER_H + TRIM_H;   // 186

  // ---- het patroon -------------------------------------------------------
  localparam [6:0] SEAM_W = 7'd1;           // dikte van de naad
  localparam [5:0] TUFT_W = 6'd3;           // grootte van het knoopje

  wire [5:0] tx = x[5:0];
  wire [5:0] ty = y[5:0];

  wire [5:0] dx = (tx >= 6'd32) ? (tx - 6'd32) : (6'd32 - tx);   // 0..32
  wire [5:0] dy = (ty >= 6'd32) ? (ty - 6'd32) : (6'd32 - ty);

  wire [6:0] d  = {1'b0, dx} + {1'b0, dy};                       // 0..64
  wire [6:0] dd = (d <= 7'd32) ? d : (7'd64 - d);                // 0..32

  // De vier ruiten raken elkaar op de tegelranden; daar zit het knoopje.
  wire tuft = ((dx >= 6'd32 - TUFT_W) && (dy <= TUFT_W)) ||
              ((dx <= TUFT_W)         && (dy >= 6'd32 - TUFT_W));

  wire seam = (dd >= 7'd32 - SEAM_W);
  wire dith = DITHER && (x[0] ^ y[0]);

  wire [5:0] velvet = tuft ? C_TUFT :
                      seam ? C_SEAM :
                      dith ? C_FLD2 : C_FLD1;
  localparam [5:0] C_LINE = 6'b00_00_00;   // zwarte scheiding
  localparam [9:0] LINE_W = 10'd4;         // dikte

  // ---- stapelen ----------------------------------------------------------
  // Een zwart lijntje aan weerskanten van de bies: goud direct tegen rood
  // vloeit visueel in elkaar over, met zwart ertussen springt het los.
  assign bg_rgb =
      (y <  BORDER_H )     ? C_BROWN :   // boord
      (y <  SCALES_Y)              ? C_GOLD  :   // gouden bies
      (y <  SCALES_Y + LINE_W)     ? C_LINE  :   // lijntje onder de bies
                                     velvet;
endmodule