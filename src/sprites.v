`default_nettype none
// ---------------------------------------------------------------------------
// Sprite storage.  OWNER: RENDER GROUP.
//
// THIS FILE IS GENERATED.  Do not hand-edit the case blocks -- run:
//     python3 tools/png2rom.py art/egg.png      --name dragon_l0 --bits 3
//     python3 tools/png2rom.py art/adult.png    --name dragon_l3 --bits 3
//     python3 tools/png2rom.py art/chest_c.png  --name chest_f0  --bits 2
//     ...then paste / redirect the output here.
//
// Code 0 always means TRANSPARENT (background shows through).
// The placeholder egg below exists so the pipeline can be tested end-to-end
// before any real art is converted.
//
// LET OP: geen SystemVerilog-casts (5'(...) / 6'(...)) gebruiken.  Yosys
// draait in Verilog-2005 en weigert die; iverilog slikt ze wel door -g2012,
// dus de fout duikt pas op bij de gds-flow.  Gebruik een tussen-wire + slice.
// ---------------------------------------------------------------------------
// module dragon_rom (
//     input  wire [2:0] level,
//     input  wire [5:0] row,
//     input  wire [5:0] col,
//     output reg  [2:0] code       // 0=transparent 1=outline 2=body 3=belly ...
// );
//   always @(*) begin
//     code = color0;
//     // placeholder: 16x16 egg shown for every level.
//     // codes: 1=outline, 2=body
//     if (row<6'd16 && col<6'd16) begin
//       case (row[3:0])
//         4'd0 : code = (col>=6 && col<=9)  ? 3'd1 : 3'd0;
//         4'd1 : code = (col>=5 && col<=10) ? ((col==5||col==10)?3'd1:3'd2) : 3'd0;
//         4'd2 : code = (col>=4 && col<=11) ? ((col==4||col==11)?3'd1:3'd2) : 3'd0;
//         4'd3 : code = (col>=3 && col<=12) ? ((col==3||col==12)?3'd1:3'd2) : 3'd0;
//         4'd4,4'd5 : code = (col>=2 && col<=13) ? ((col==2||col==13)?3'd1:3'd2) : 3'd0;
//         4'd6,4'd7,4'd8,4'd9,4'd10 :
//                code = (col>=1 && col<=14) ? ((col==1||col==14)?3'd1:3'd2) : 3'd0;
//         4'd11,4'd12 : code = (col>=2 && col<=13) ? ((col==2||col==13)?3'd1:3'd2) : 3'd0;
//         4'd13: code = (col>=3 && col<=12) ? ((col==3||col==12)?3'd1:3'd2) : 3'd0;
//         4'd14: code = (col>=4 && col<=11) ? ((col==4||col==11)?3'd1:3'd2) : 3'd0;
//         4'd15: code = (col>=6 && col<=9)  ? 3'd1 : 3'd0;
//         default: code = color0;
//       endcase
//     end
//   end
//   wire _unused = &{level, row[5:4], col[5:4], 1'b0};
// endmodule

module chest_rom (
    input  wire [1:0] frame,     // 0 closed, 1 opening, 2 open
    input  wire [4:0] row,
    input  wire [4:0] col,
    output reg  [1:0] code       // 0=transparent 1=outline 2=wood 3=gold
);
  // placeholder: simple 24x16 box with a gold band
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

module flame_rom ( // mag dit weg? 
    input  wire       frame,
    input  wire [3:0] row,
    input  wire [3:0] col,
    output reg  [1:0] code       // 0=transparent 1=bright 2=pale
);
  // placeholder: 8x12 teardrop, two frames differ by one row
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


module digit_rom (
    input  wire [3:0] digit,     // 0..9
    input  wire [2:0] row,       // 0..5
    output reg  [3:0] bits       // 4 wide; bits[3] = leftmost
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

// module ei_generator (
//     input  wire [9:0] x,
//     input  wire [9:0] y,
//     input  wire [2:0] mood_anim,
//     output wire       px_on,
//     output wire [2:0] px_code
// );

//     // Ongebruikte signalen direct afvangen
//     wire _unused = &{mood_anim, 1'b0};

//     //---------------------------------------------------------
//     // Middelpunt (12-bit signed)
//     //---------------------------------------------------------
//     wire signed [11:0] dx = $signed({2'b00, x}) - 12'sd320;
//     wire signed [11:0] dy = $signed({2'b00, y}) - 12'sd240;

//     //---------------------------------------------------------
//     // Parameters (12-bit signed)
//     //---------------------------------------------------------
//     localparam signed [11:0] B    = 12'sd145;
//     localparam signed [11:0] RAND = 12'sd8;

//     // Dynamische breedte (kwadratische eivorm)
//     wire signed [11:0] t        = dy + 12'sd166;
//     wire signed [11:0] a_dyn    = 12'sd90 + $signed((t * t) / 12'sd2500);

//     // Buitenste ei parameters
//     wire signed [11:0] a_out    = a_dyn + RAND;
//     wire signed [11:0] b_out    = B + RAND;

//     // Kwadraten voor ovaalberekeningen
//     wire signed [23:0] dx_sq    = dx * dx;
//     wire signed [23:0] dy_sq    = dy * dy;

//     wire signed [23:0] a_dyn_sq = a_dyn * a_dyn;
//     wire signed [23:0] b_sq     = B * B;

//     wire signed [23:0] a_out_sq = a_out * a_out;
//     wire signed [23:0] b_out_sq = b_out * b_out;

//     //---------------------------------------------------------
//     // Binnenboxen
//     //---------------------------------------------------------
//     wire box_in =
//         (dx >= -a_dyn) &&
//         (dx <=  a_dyn) &&
//         (dy >= -B)     &&
//         (dy <=  B);

//     wire box_out =
//         (dx >= -a_out) &&
//         (dx <=  a_out) &&
//         (dy >= -b_out) &&
//         (dy <=  b_out);

//     //---------------------------------------------------------
//     // Ovalen
//     //---------------------------------------------------------
//     wire in_ei =
//         box_in &&
//         ((dx_sq * b_sq + dy_sq * a_dyn_sq) <= (a_dyn_sq * b_sq));

//     wire in_ei_out =
//         box_out &&
//         ((dx_sq * b_out_sq + dy_sq * a_out_sq) <= (a_out_sq * b_out_sq));

//     //---------------------------------------------------------
//     // Vlekjes binnen het ei (12-bit rekenkunde)
//     //---------------------------------------------------------
//     wire signed [11:0] vlek1_dx = dx - 12'sd25;
//     wire signed [11:0] vlek1_dy = dy - (-12'sd60);
//     wire vlek1 = (vlek1_dx * vlek1_dx + vlek1_dy * vlek1_dy) <= (12'sd27 * 12'sd27);

//     wire signed [11:0] vlek2_dx = dx - 12'sd30;
//     wire signed [11:0] vlek2_dy = dy - 12'sd70;
//     wire vlek2 = (vlek2_dx * vlek2_dx + vlek2_dy * vlek2_dy) <= (12'sd35 * 12'sd35);

//     wire signed [11:0] vlek3_dx = dx + 12'sd50;
//     wire signed [11:0] vlek3_dy = dy - 12'sd20;
//     wire vlek3 = (vlek3_dx * vlek3_dx + vlek3_dy * vlek3_dy) <= (12'sd30 * 12'sd30);

//     //---------------------------------------------------------
//     // Rand & Output
//     //---------------------------------------------------------
//     wire border = in_ei_out && !in_ei;

//     assign px_on = in_ei_out;

//     assign px_code =
//         border                               ? 3'd1 : // Rand (Zwart)
//         (in_ei && (vlek1 || vlek2 || vlek3)) ? 3'd2 : // Vlekken (Donkergroen)
//         in_ei                                ? 3'd4 : // Ei vulling (Wit)
//                                                3'd0;  // Transparant
// endmodule


module egg1_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    wire _unused = &{mood_anim, 1'b0};

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) >> 3) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) >> 3) : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("egg1.hex", rom);
    end
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule


module egg2_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    wire _unused = &{mood_anim, 1'b0};

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) >> 3) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) >> 3) : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("egg2.hex", rom);
    end
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule


module egg3_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    wire _unused = &{mood_anim, 1'b0};

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) >> 3) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) >> 3) : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("egg3.hex", rom);
    end
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule


module egg4_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    wire _unused = &{mood_anim, 1'b0};

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) >> 3) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) >> 3) : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("egg4.hex", rom);
    end
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule


module egg5_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    wire _unused = &{mood_anim, 1'b0};

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) >> 3) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) >> 3) : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("egg5.hex", rom);
    end
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule

module dragon_l1_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [2:0]  mood_anim,
    output reg         px_on,
    output reg  [2:0]  px_code
);

    wire _unused = &{mood_anim, 1'b0};

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) >> 3) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) >> 3) : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("dragon_l1.hex", rom);
    end
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule


`default_nettype none

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

    // 32 * 5 = 160x160 pixels op het scherm (gecentreerd op 480x640)
    localparam [9:0] SPRITE_X = 10'd170;  // (480 - 160) / 2 = 160
    localparam [9:0] SPRITE_Y = 10'd180;
    localparam [9:0] SPRITE_W = 10'd160;
    localparam [9:0] SPRITE_H = 10'd160;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 5 -> 32x32 ROM-coördinaten (bereik 0..31)
    wire [4:0] rel_x = in_bounds ? ((x - SPRITE_X) / 10'd5) : 5'd0;
    wire [4:0] rel_y = in_bounds ? ((y - SPRITE_Y) / 10'd5) : 5'd0;

    // 10-bit adres voor de 1024 entries: {rel_y, rel_x}
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("dragon_l2.hex", rom);
    end
    
    // Geregistreerde output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule

`default_nettype none

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

    // 32 * 6 = 192x192 pixels op het scherm
    localparam [9:0] SPRITE_X = 10'd190;
    localparam [9:0] SPRITE_Y = 10'd144;
    localparam [9:0] SPRITE_W = 10'd192;
    localparam [9:0] SPRITE_H = 10'd192;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 6 -> 32x32 ROM-coördinaten (bereik 0..31)
    wire [4:0] rel_x = in_bounds ? 5'((x - SPRITE_X) / 6) : 5'd0;
    wire [4:0] rel_y = in_bounds ? 5'((y - SPRITE_Y) / 6) : 5'd0;

    // 10-bit adres voor 1024 entries: {rel_y, rel_x}
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom [0:1023];
    initial begin
        $readmemh("dragon_l3.hex", rom);
    end
    
    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule



`default_nettype none

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

    // 48 pixels * 8x schaling = 384x384 pixels op het scherm
    // Gecentreerd op 640x480: X = 128, Y = 48
   // 48 * 3.5 = 168x168 pixels op het scherm
    // Gecentreerd op 640x480: X = (640-168)/2 = 236, Y = (480-168)/2 = 156
    // 48 * 4 = 192 pixels breed en hoog
    // Gecentreerd op 640x480: X = (640-192)/2 = 224, Y = (480-192)/2 = 144
    localparam [9:0] SPRITE_X = 10'd165;
    localparam [9:0] SPRITE_Y = 10'd120;
    localparam [9:0] SPRITE_W = 10'd240;
    localparam [9:0] SPRITE_H = 10'd240;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 5 i.p.v. 6
    wire [5:0] rel_x = in_bounds ? 6'((x - SPRITE_X) / 5) : 6'd0;
    wire [5:0] rel_y = in_bounds ? 6'((y - SPRITE_Y) / 5) : 6'd0;

    // 12-bit adres: rel_y * 48 + rel_x = (rel_y << 5) + (rel_y << 4) + rel_x
    wire [11:0] addr = ({6'd0, rel_y} << 5) + ({6'd0, rel_y} << 4) + {6'd0, rel_x};

    // 2.304 entries (48 * 48)
    reg [2:0] rom [0:2303];
    initial begin
        $readmemh("dragon_l4.hex", rom);
    end

    // Geregistreerde output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom[addr] != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom[addr];
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule

module background (
    input  wire [9:0] pix_x,    // 0..639 (horizontaal)
    input  wire [9:0] pix_y,    // 0..479 (verticaal)
    output reg  [5:0] bg_rgb
);

  // ======================= 1. WOLKJES =====================================
  // Wolk 1: Bovenaan (pix_x: 480..540, pix_y: 110..140)
  wire wolk1 = ((pix_x >= 10'd490 && pix_x < 10'd530 && pix_y >= 10'd110 && pix_y < 10'd120) ||
                (pix_x >= 10'd480 && pix_x < 10'd540 && pix_y >= 10'd120 && pix_y < 10'd140));

  // Wolk 2: Onderaan (pix_x: 460..520, pix_y: 340..370)
  wire wolk2 = ((pix_x >= 10'd470 && pix_x < 10'd510 && pix_y >= 10'd340 && pix_y < 10'd350) ||
                (pix_x >= 10'd460 && pix_x < 10'd520 && pix_y >= 10'd350 && pix_y < 10'd370));

  wire is_cloud = wolk1 || wolk2;

  // ======================= 2. ZACHTE GLOOIENDE BERGEN =====================
  // We maken 2 mooie heuveltoppen: één op y=140 en één op y=340
  // Heuvel 1 (top rond y = 140, raakt x = 285)
  wire [8:0] dy1 = (pix_y > 10'd140) ? (pix_y[8:0] - 9'd140) : (9'd140 - pix_y[8:0]);
  wire [9:0] curve1 = (dy1 * dy1) >> 7; // Zachte parabool
  wire [9:0] hill1_x = (10'd285 > curve1) ? (10'd285 - curve1) : 10'd0;

  // Heuvel 2 (top rond y = 340, raakt x = 270)
  wire [8:0] dy2 = (pix_y > 10'd340) ? (pix_y[8:0] - 9'd340) : (9'd340 - pix_y[8:0]);
  wire [9:0] curve2 = (dy2 * dy2) >> 7;
  wire [9:0] hill2_x = (10'd270 > curve2) ? (10'd270 - curve2) : 10'd0;

  // Gecombineerde heuvelranden (achterste heuvels pieken net wat verder naar links)
  wire in_front_hill = (pix_x <= hill1_x);
  wire in_back_hill  = (pix_x <= hill2_x);

  // ======================= 3. KLEUREN =====================================
  always @(*) begin
    // Voorste zachte heuvel (fris groen)
    if (in_front_hill) begin
      if (pix_x >= (hill1_x - 10'd8))
        bg_rgb = 6'b10_11_01; // Limoen/lichtgroene rand highlight
      else
        bg_rgb = 6'b00_11_00; // Grasgroen vlak
    // Achterste heuvel (donkerder dieptegroen)
    end else if (in_back_hill) begin
      if (pix_x >= (hill2_x - 10'd8))
        bg_rgb = 6'b00_11_00; // Grasgroene rand
      else
        bg_rgb = 6'b00_10_00; // Donkerder bosgroen
    // Wolkjes
    end else if (is_cloud) begin
      bg_rgb = 6'b11_11_11;   // Wit
    // Egale hemelsblauwe lucht
    end else begin
      bg_rgb = 6'b01_10_11;   // 1 vaste kleur blauw
    end
  end

endmodule

`default_nettype none

module gameover_text (
    input  wire [9:0] px,        // 0..479 (portrait X)
    input  wire [9:0] py,        // 0..639 (portrait Y)
    output wire       text_on
);

  // ======================= Geometrie & Positie =============================
  // Scherm: 480 x 640
  // Woordbreedte: 4 letters * 48px stride = 192 px -> X start op (480 - 192) / 2 = 144
  localparam [9:0] START_X = 10'd144;
  localparam [9:0] LINE1_Y = 10'd250; // GAME
  localparam [9:0] LINE2_Y = 10'd320; // OVER
  localparam [9:0] CHAR_W  = 10'd48;  // Stride per letter
  localparam [9:0] CHAR_H  = 10'd48;  // Hoogte per letter (6x geschaald: 8 * 6 = 48)

  wire in_line1 = (px >= START_X) && (px < START_X + 10'd192) &&
                  (py >= LINE1_Y) && (py < LINE1_Y + CHAR_H);

  wire in_line2 = (px >= START_X) && (px < START_X + 10'd192) &&
                  (py >= LINE2_Y) && (py < LINE2_Y + CHAR_H);

  wire [9:0] lx = px - START_X;       // 0..191
  wire [1:0] char_pos = lx / CHAR_W;  // Welke letter in het woord: 0..3
  wire [5:0] cx = lx % CHAR_W;        // 0..47 binnen de lettercel

  wire [9:0] ly = in_line1 ? (py - LINE1_Y) : (py - LINE2_Y);

  // 6x Schaling naar het 6x8 font (deling door 6)
  wire [2:0] gcol = cx / 6'd6;        // 0..5 (bij cx 0..35)
  wire [2:0] grow = ly / 6'd6;        // 0..7 (bij ly 0..47)
  wire       in_glyph = (cx < 6'd36); // Laatste 12 pixels zijn tussenruimte

  // ======================= Karakter Selectie ===============================
  // IDs: 0:G, 1:A, 2:M, 3:E, 4:O, 5:V, 6:R
  reg [2:0] glyph_id;
  always @(*) begin
    if (in_line1) begin
      // "GAME"
      case (char_pos)
        2'd0: glyph_id = 3'd0; // G
        2'd1: glyph_id = 3'd1; // A
        2'd2: glyph_id = 3'd2; // M
        2'd3: glyph_id = 3'd3; // E
      endcase
    end else begin
      // "OVER"
      case (char_pos)
        2'd0: glyph_id = 3'd4; // O
        2'd1: glyph_id = 3'd5; // V
        2'd2: glyph_id = 3'd3; // E
        2'd3: glyph_id = 3'd6; // R
      endcase
    end
  end

  // ======================= Glyph ROM ======================================
  reg [5:0] glyph_bits;
  always @(*) begin
    case (glyph_id)
      3'd0: case (grow) // G
        3'd0: glyph_bits = 6'b011110; 3'd1: glyph_bits = 6'b110011;
        3'd2: bits_g();               3'd3: glyph_bits = 6'b110111;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; 3'd7: glyph_bits = 6'b011110;
      endcase
      3'd1: case (grow) // A
        3'd0: glyph_bits = 6'b011110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b111111;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; 3'd7: glyph_bits = 6'b110011;
      endcase
      3'd2: case (grow) // M
        3'd0: glyph_bits = 6'b110011; 3'd1: glyph_bits = 6'b111111;
        3'd2: glyph_bits = 6'b101101; 3'd3: glyph_bits = 6'b100001;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; 3'd7: glyph_bits = 6'b110011;
      endcase
      3'd3: case (grow) // E
        3'd0: glyph_bits = 6'b111111; 3'd1: glyph_bits = 6'b110000;
        3'd2: glyph_bits = 6'b110000; 3'd3: glyph_bits = 6'b111100;
        3'd4: glyph_bits = 6'b110000; 3'd5: glyph_bits = 6'b110000;
        3'd6: glyph_bits = 6'b110000; 3'd7: glyph_bits = 6'b111111;
      endcase
      3'd4: case (grow) // O
        3'd0: glyph_bits = 6'b011110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b110011;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b110011;
        3'd6: glyph_bits = 6'b110011; 3'd7: glyph_bits = 6'b011110;
      endcase
      3'd5: case (grow) // V
        3'd0: glyph_bits = 6'b110011; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b110011;
        3'd4: glyph_bits = 6'b110011; 3'd5: glyph_bits = 6'b011110;
        3'd6: glyph_bits = 6'b011110; 3'd7: glyph_bits = 6'b001100;
      endcase
      default: case (grow) // R
        3'd0: glyph_bits = 6'b111110; 3'd1: glyph_bits = 6'b110011;
        3'd2: glyph_bits = 6'b110011; 3'd3: glyph_bits = 6'b111110;
        3'd4: glyph_bits = 6'b111100; 3'd5: glyph_bits = 6'b110110;
        3'd6: glyph_bits = 6'b110011; 3'd7: glyph_bits = 6'b110011;
      endcase
    endcase
  end

  task bits_g;
    glyph_bits = 6'b110000;
  endtask

  // ======================= Output ==========================================
  assign text_on = (in_line1 || in_line2) && in_glyph && glyph_bits[3'd5 - gcol];

endmodule


module pot_sprite (
    input  wire [9:0] x,
    input  wire [9:0] y,
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam [9:0] SPRITE_X = 10'd112;   // 240 - 192/2, gecentreerd
  localparam [9:0] SPRITE_Y = 10'd140;
  localparam [9:0] SPRITE_W = 10'd256;   // 32 * 8
  localparam [9:0] SPRITE_H = 10'd256;
 
  wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                   (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));
 
  wire [9:0] div_x = (x - SPRITE_X) >> 3;
  wire [9:0] div_y = (y - SPRITE_Y) >> 3;
  wire [4:0] rel_x = in_bounds ? div_x[4:0] : 5'd0;
  wire [4:0] rel_y = in_bounds ? div_y[4:0] : 5'd0;
  wire [9:0] addr  = {rel_y, rel_x};
 
  reg [2:0] rom [0:1023];
  initial begin
    $readmemh("pot.hex", rom);
  end
 
  assign px_code = in_bounds ? rom[addr] : 3'd0;
  assign px_on   = (px_code != 3'd0);        // code 0 = transparant
endmodule
