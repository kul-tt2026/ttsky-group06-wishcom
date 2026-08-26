`default_nettype none
// ---------------------------------------------------------------------------
// Sprite storage.  OWNER: RENDER GROUP.
//
// Bevat: chest_rom, flame_rom, digit_rom (placeholders / font),
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
// En: dode code WEGGOOIEN, niet uitcommentariëren.  Een `/*` zonder `*/`
// heeft hier ooit de halve file onzichtbaar gemaakt; git bewaart de rest.
// ---------------------------------------------------------------------------


// ===========================================================================
// PLACEHOLDERS -- nergens geïnstantieerd voor zover ik kan zien.  Controleer
// met `grep -n "chest_rom\|flame_rom" *.v` en gooi ze weg als dat klopt.
// ===========================================================================
module chest_rom (
    input  wire [1:0] frame,     // 0 closed, 1 opening, 2 open
    input  wire [4:0] row,
    input  wire [4:0] col,
    output reg  [1:0] code       // 0=transparent 1=outline 2=wood 3=gold
);
  always @(*) begin
    code = 2'd0;
    if (row>=5'd4 && row<5'd20 && col<5'd24) begin
      if (row==5'd4 || row==5'd19 || col==5'd0 || col==5'd23) code = 2'd1;
      else if (row==5'd11 || row==5'd12)                      code = 2'd3;
      else                                                    code = 2'd2;
    end
  end
  wire _unused = &{frame, 1'b0};
endmodule


module flame_rom (
    input  wire       frame,
    input  wire [3:0] row,
    input  wire [3:0] col,
    output reg  [1:0] code       // 0=transparent 1=bright 2=pale
);
  always @(*) begin
    code = 2'd0;
    if (col<4'd8) case (row)
      4'd0 : code = (col==3||col==4) && frame ? 2'd1 : 2'd0;
      4'd1 : code = (col==3||col==4) ? 2'd1 : 2'd0;
      4'd2,4'd3 : code = (col>=2&&col<=5) ? 2'd1 : 2'd0;
      4'd4,4'd5,4'd6 : code = (col>=1&&col<=6) ? ((col>=3&&col<=4)?2'd2:2'd1) : 2'd0;
      4'd7,4'd8 : code = (col>=1&&col<=6) ? ((col>=2&&col<=5)?2'd2:2'd1) : 2'd0;
      4'd9,4'd10: code = (col>=2&&col<=5) ? 2'd2 : 2'd0;
      4'd11: code = (col==3||col==4) ? 2'd2 : 2'd0;
      default: code = 2'd0;
    endcase
  end
endmodule


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
// DRAGON L2 -- 32x32 sprite, 5x geschaald -> 160x160.
// De schaling /5 gaat via (n * 205) >> 10, niet via een deler.
// ===========================================================================
module dragon_l2_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);
    wire _unused = &{mood_anim, 1'b0};

    localparam [9:0] SPRITE_X = 10'd170;
    localparam [9:0] SPRITE_Y = 10'd180;
    localparam [9:0] SPRITE_W = 10'd160;
    localparam [9:0] SPRITE_H = 10'd160;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    wire [9:0]  ox = x - SPRITE_X;
    wire [9:0]  oy = y - SPRITE_Y;
    wire [19:0] mx = {10'd0, ox} * 20'd205;      // /5
    wire [19:0] my = {10'd0, oy} * 20'd205;
    wire [4:0]  rel_x = in_bounds ? mx[14:10] : 5'd0;
    wire [4:0]  rel_y = in_bounds ? my[14:10] : 5'd0;

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
// DRAGON L3 -- 32x32 sprite, 6x geschaald -> 192x192.
// /6 via (n * 683) >> 12.
// ===========================================================================
module dragon_l3_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);
    wire _unused = &{mood_anim, 1'b0};

    localparam [9:0] SPRITE_X = 10'd190;
    localparam [9:0] SPRITE_Y = 10'd144;
    localparam [9:0] SPRITE_W = 10'd192;
    localparam [9:0] SPRITE_H = 10'd192;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    wire [9:0]  ox = x - SPRITE_X;
    wire [9:0]  oy = y - SPRITE_Y;
    wire [19:0] mx = {10'd0, ox} * 20'd683;      // /6
    wire [19:0] my = {10'd0, oy} * 20'd683;
    wire [4:0]  rel_x = in_bounds ? mx[16:12] : 5'd0;
    wire [4:0]  rel_y = in_bounds ? my[16:12] : 5'd0;

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
// DRAGON L4 -- 48x48 sprite, 5x geschaald -> 240x240.
// /5 via (n * 205) >> 10.  Adres = rel_y*48 + rel_x = (y<<5)+(y<<4)+x.
// ===========================================================================
module dragon_l4_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);
    wire _unused = &{mood_anim, 1'b0};

    localparam [9:0] SPRITE_X = 10'd165;
    localparam [9:0] SPRITE_Y = 10'd120;
    localparam [9:0] SPRITE_W = 10'd240;
    localparam [9:0] SPRITE_H = 10'd240;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    wire [9:0]  ox = x - SPRITE_X;
    wire [9:0]  oy = y - SPRITE_Y;
    wire [19:0] mx = {10'd0, ox} * 20'd205;      // /5
    wire [19:0] my = {10'd0, oy} * 20'd205;
    wire [5:0]  rel_x = in_bounds ? mx[15:10] : 6'd0;
    wire [5:0]  rel_y = in_bounds ? my[15:10] : 6'd0;

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
// BACKGROUND -- het thuisscherm: lucht, zon, twee wolkjes, gras en aarde.
//
// PORTRET-coordinaten (px, py), net als alle andere drawables.
//
//   y <  GRASS_Y            lucht, met zon en wolkjes
//   y in [GRASS_Y, +50)     grasstrook -- zelfde groen als het titelscherm
//   y in [SOIL_Y,  +4)      donkere aardrand, scheidt gras van grond
//   y >= SOIL_Y + 4         aarde
//
// GRASS_Y AFSTELLEN: de draak moet er met zijn onderkant op rusten.  De drie
// sprite-vakken eindigen op y = 340 (l2), 336 (l3) en 360 (l4), dus 344 laat
// de kleine draken erop staan en de grote er net iets in zakken.  Zie je na
// een render dat het niet klopt, dan is dit de enige regel die je aanraakt.
//
// GEEN VERMENIGVULDIGINGEN: de zon is een tabel van halfbreedtes per rij
// (zoals draw_buttons), de wolkjes en de horizon zijn vergelijkingen.
// ===========================================================================
module background (
    input  wire [9:0] x,          // portret-x  0..479
    input  wire [9:0] y,          // portret-y  0..639
    output reg  [5:0] bg_rgb
);
  // ---- horizon -----------------------------------------------------------
  localparam [9:0] GRASS_Y = 10'd344;            // bovenkant gras
  localparam [9:0] GRASS_H = 10'd50;             // dikte grasstrook
  localparam [9:0] SOIL_Y  = GRASS_Y + GRASS_H;  // 394
  localparam [9:0] EDGE_H  = 10'd4;              // donkere scheidingslijn

  // ---- zon: rechtsboven, onder de hartjes --------------------------------
  localparam [9:0] SUN_CX = 10'd404;
  localparam [9:0] SUN_CY = 10'd104;
  localparam [9:0] SUN_R  = 10'd36;

  // ---- kleuren -----------------------------------------------------------
  localparam [5:0] C_SKY   = 6'b01_10_11;   // hemelsblauw, zoals het titelscherm
  localparam [5:0] C_SUN   = 6'b11_11_00;   // geel
  localparam [5:0] C_CLOUD = 6'b11_11_11;   // wit
  localparam [5:0] C_GRASS = 6'b00_10_00;   // ZELFDE groen als title_egg's gras
  localparam [5:0] C_EDGE  = 6'b01_00_00;   // donkerbruine rand
  localparam [5:0] C_SOIL  = 6'b10_01_00;   // aarde

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
  // Elk twee rechthoeken: een smalle bovenop een brede.  Links naast de draak
  // en rechts eronder, zodat ze niet achter de sprite verdwijnen.
  wire cloud1 = (y >= 10'd205 && y < 10'd215 && x >= 10'd91  && x < 10'd139) ||
                (y >= 10'd215 && y < 10'd227 && x >= 10'd75  && x < 10'd155);

  wire cloud2 = (y >= 10'd265 && y < 10'd275 && x >= 10'd406 && x < 10'd454) ||
                (y >= 10'd275 && y < 10'd287 && x >= 10'd390 && x < 10'd470);

  // ---- stapelen ----------------------------------------------------------
  always @(*) begin
    if      (y >= SOIL_Y + EDGE_H) bg_rgb = C_SOIL;
    else if (y >= SOIL_Y)          bg_rgb = C_EDGE;
    else if (y >= GRASS_Y)         bg_rgb = C_GRASS;
    else if (sun)                  bg_rgb = C_SUN;
    else if (cloud1 || cloud2)     bg_rgb = C_CLOUD;
    else                           bg_rgb = C_SKY;
  end
endmodule


// ===========================================================================
// GAMEOVER_TEXT -- "GAME" / "OVER" in een 6x8 font, 6x geschaald.
// Vier delingen eruit: /48 wordt een vergelijkingsketen, /6 wordt *683 >> 12.
// ===========================================================================
module gameover_text (
    input  wire [9:0] px,        // 0..479 (portret X)
    input  wire [9:0] py,        // 0..639 (portret Y)
    output wire       text_on
);
  localparam [9:0] START_X = 10'd144;
  localparam [9:0] LINE1_Y = 10'd250;   // GAME
  localparam [9:0] LINE2_Y = 10'd320;   // OVER
  localparam [9:0] CHAR_H  = 10'd48;

  wire in_line1 = (px >= START_X) && (px < START_X + 10'd192) &&
                  (py >= LINE1_Y) && (py < LINE1_Y + CHAR_H);
  wire in_line2 = (px >= START_X) && (px < START_X + 10'd192) &&
                  (py >= LINE2_Y) && (py < LINE2_Y + CHAR_H);

  wire [9:0] lx = px - START_X;         // 0..191

  // welke letter: vier vergelijkingen i.p.v. lx / 48
  wire [1:0] char_pos = (lx < 10'd48)  ? 2'd0 :
                        (lx < 10'd96)  ? 2'd1 :
                        (lx < 10'd144) ? 2'd2 : 2'd3;
  wire [9:0] char_x0  = ({8'd0, char_pos} << 5) + ({8'd0, char_pos} << 4);  // *48
  wire [9:0] cx10     = lx - char_x0;
  wire [5:0] cx       = cx10[5:0];      // 0..47 binnen de lettercel

  wire [9:0] ly10 = in_line1 ? (py - LINE1_Y) : (py - LINE2_Y);
  wire [5:0] ly   = ly10[5:0];          // 0..47

  // /6 == (n * 683) >> 12
  wire [15:0] mcol = {10'd0, cx} * 16'd683;
  wire [15:0] mrow = {10'd0, ly} * 16'd683;
  wire [2:0]  gcol = mcol[14:12];       // 0..5
  wire [2:0]  grow = mrow[14:12];       // 0..7

  wire in_glyph = (cx < 6'd36);         // laatste 12 px is tussenruimte

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
// POT_SPRITE -- 32x32, 8x geschaald.  Schaal is een macht van twee: shift.
// ===========================================================================
module pot_sprite (
    input  wire [9:0] x,
    input  wire [9:0] y,
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam [9:0] SPRITE_X = 10'd112;
  localparam [9:0] SPRITE_Y = 10'd140;
  localparam [9:0] SPRITE_W = 10'd256;
  localparam [9:0] SPRITE_H = 10'd256;

  wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                   (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

  wire [9:0] div_x = (x - SPRITE_X) >> 3;
  wire [9:0] div_y = (y - SPRITE_Y) >> 3;
  wire [4:0] rel_x = in_bounds ? div_x[4:0] : 5'd0;
  wire [4:0] rel_y = in_bounds ? div_y[4:0] : 5'd0;
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