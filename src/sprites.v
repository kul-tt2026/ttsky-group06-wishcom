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

module flame_rom (
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

module heart_rom (
    input  wire [3:0] row,
    input  wire [3:0] col,
    output reg        on         // 1-bit: hearts are a single colour
);
  always @(*) begin
    on = 1'b0;
    if (col<4'd12) case (row)
      4'd1,4'd2 : on = (col>=1&&col<=4)||(col>=7&&col<=10);
      4'd3,4'd4,4'd5 : on = (col>=0&&col<=11);
      4'd6 : on = (col>=1&&col<=10);
      4'd7 : on = (col>=2&&col<=9);
      4'd8 : on = (col>=3&&col<=8);
      4'd9 : on = (col>=4&&col<=7);
      4'd10: on = (col==5||col==6);
      default: on = 1'b0;
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

`default_nettype none


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
    wire [4:0] rel_x = in_bounds ? (x - SPRITE_X) >> 3 : 5'd0;
    wire [4:0] rel_y = in_bounds ? (y - SPRITE_Y) >> 3 : 5'd0;

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

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? (x - SPRITE_X) >> 3 : 5'd0;
    wire [4:0] rel_y = in_bounds ? (y - SPRITE_Y) >> 3 : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
    wire [9:0] addr = {rel_y, rel_x};

    reg [2:0] rom_code;
      always @(*) begin
      case (addr)
          10'd75: rom_code = 3'd2;
          10'd106: rom_code = 3'd2;
          10'd107: rom_code = 3'd2;
          10'd113: rom_code = 3'd2;
          10'd136: rom_code = 3'd3;
          10'd137: rom_code = 3'd3;
          10'd138: rom_code = 3'd3;
          10'd139: rom_code = 3'd1;
          10'd140: rom_code = 3'd1;
          10'd141: rom_code = 3'd1;
          10'd143: rom_code = 3'd2;
          10'd144: rom_code = 3'd2;
          10'd167: rom_code = 3'd1;
          10'd168: rom_code = 3'd3;
          10'd169: rom_code = 3'd3;
          10'd170: rom_code = 3'd3;
          10'd171: rom_code = 3'd3;
          10'd172: rom_code = 3'd3;
          10'd173: rom_code = 3'd3;
          10'd175: rom_code = 3'd2;
          10'd177: rom_code = 3'd1;
          10'd198: rom_code = 3'd1;
          10'd199: rom_code = 3'd3;
          10'd200: rom_code = 3'd3;
          10'd201: rom_code = 3'd3;
          10'd202: rom_code = 3'd3;
          10'd203: rom_code = 3'd3;
          10'd204: rom_code = 3'd3;
          10'd205: rom_code = 3'd3;
          10'd206: rom_code = 3'd3;
          10'd209: rom_code = 3'd1;
          10'd229: rom_code = 3'd1;
          10'd230: rom_code = 3'd1;
          10'd231: rom_code = 3'd3;
          10'd232: rom_code = 3'd3;
          10'd233: rom_code = 3'd3;
          10'd234: rom_code = 3'd4;
          10'd235: rom_code = 3'd1;
          10'd236: rom_code = 3'd3;
          10'd237: rom_code = 3'd3;
          10'd238: rom_code = 3'd3;
          10'd239: rom_code = 3'd3;
          10'd240: rom_code = 3'd3;
          10'd241: rom_code = 3'd1;
          10'd260: rom_code = 3'd1;
          10'd261: rom_code = 3'd3;
          10'd262: rom_code = 3'd3;
          10'd263: rom_code = 3'd3;
          10'd264: rom_code = 3'd3;
          10'd265: rom_code = 3'd3;
          10'd266: rom_code = 3'd1;
          10'd267: rom_code = 3'd1;
          10'd268: rom_code = 3'd3;
          10'd269: rom_code = 3'd3;
          10'd270: rom_code = 3'd3;
          10'd271: rom_code = 3'd3;
          10'd272: rom_code = 3'd3;
          10'd273: rom_code = 3'd1;
          10'd291: rom_code = 3'd1;
          10'd292: rom_code = 3'd3;
          10'd293: rom_code = 3'd2;
          10'd294: rom_code = 3'd3;
          10'd295: rom_code = 3'd3;
          10'd296: rom_code = 3'd3;
          10'd297: rom_code = 3'd3;
          10'd298: rom_code = 3'd1;
          10'd299: rom_code = 3'd1;
          10'd300: rom_code = 3'd3;
          10'd301: rom_code = 3'd3;
          10'd302: rom_code = 3'd3;
          10'd303: rom_code = 3'd3;
          10'd304: rom_code = 3'd3;
          10'd305: rom_code = 3'd1;
          10'd323: rom_code = 3'd1;
          10'd324: rom_code = 3'd3;
          10'd325: rom_code = 3'd3;
          10'd326: rom_code = 3'd3;
          10'd327: rom_code = 3'd1;
          10'd328: rom_code = 3'd3;
          10'd329: rom_code = 3'd3;
          10'd330: rom_code = 3'd3;
          10'd331: rom_code = 3'd3;
          10'd332: rom_code = 3'd3;
          10'd333: rom_code = 3'd3;
          10'd334: rom_code = 3'd3;
          10'd335: rom_code = 3'd3;
          10'd336: rom_code = 3'd3;
          10'd337: rom_code = 3'd1;
          10'd355: rom_code = 3'd1;
          10'd356: rom_code = 3'd3;
          10'd357: rom_code = 3'd3;
          10'd358: rom_code = 3'd3;
          10'd359: rom_code = 3'd3;
          10'd360: rom_code = 3'd3;
          10'd361: rom_code = 3'd3;
          10'd362: rom_code = 3'd3;
          10'd363: rom_code = 3'd3;
          10'd364: rom_code = 3'd3;
          10'd365: rom_code = 3'd3;
          10'd366: rom_code = 3'd3;
          10'd367: rom_code = 3'd3;
          10'd368: rom_code = 3'd3;
          10'd369: rom_code = 3'd1;
          10'd388: rom_code = 3'd1;
          10'd389: rom_code = 3'd3;
          10'd390: rom_code = 3'd3;
          10'd391: rom_code = 3'd3;
          10'd392: rom_code = 3'd3;
          10'd393: rom_code = 3'd3;
          10'd394: rom_code = 3'd3;
          10'd395: rom_code = 3'd3;
          10'd396: rom_code = 3'd3;
          10'd397: rom_code = 3'd3;
          10'd398: rom_code = 3'd3;
          10'd399: rom_code = 3'd3;
          10'd400: rom_code = 3'd1;
          10'd421: rom_code = 3'd1;
          10'd422: rom_code = 3'd1;
          10'd423: rom_code = 3'd3;
          10'd424: rom_code = 3'd3;
          10'd425: rom_code = 3'd3;
          10'd426: rom_code = 3'd3;
          10'd427: rom_code = 3'd3;
          10'd428: rom_code = 3'd3;
          10'd429: rom_code = 3'd3;
          10'd430: rom_code = 3'd3;
          10'd431: rom_code = 3'd3;
          10'd432: rom_code = 3'd1;
          10'd439: rom_code = 3'd1;
          10'd440: rom_code = 3'd1;
          10'd455: rom_code = 3'd1;
          10'd456: rom_code = 3'd1;
          10'd457: rom_code = 3'd1;
          10'd458: rom_code = 3'd1;
          10'd459: rom_code = 3'd3;
          10'd460: rom_code = 3'd3;
          10'd461: rom_code = 3'd3;
          10'd462: rom_code = 3'd3;
          10'd463: rom_code = 3'd3;
          10'd464: rom_code = 3'd1;
          10'd470: rom_code = 3'd1;
          10'd471: rom_code = 3'd3;
          10'd472: rom_code = 3'd1;
          10'd491: rom_code = 3'd3;
          10'd492: rom_code = 3'd3;
          10'd493: rom_code = 3'd3;
          10'd494: rom_code = 3'd3;
          10'd495: rom_code = 3'd3;
          10'd496: rom_code = 3'd1;
          10'd501: rom_code = 3'd1;
          10'd502: rom_code = 3'd3;
          10'd503: rom_code = 3'd3;
          10'd504: rom_code = 3'd1;
          10'd522: rom_code = 3'd2;
          10'd523: rom_code = 3'd2;
          10'd524: rom_code = 3'd3;
          10'd525: rom_code = 3'd3;
          10'd526: rom_code = 3'd3;
          10'd527: rom_code = 3'd3;
          10'd528: rom_code = 3'd1;
          10'd529: rom_code = 3'd1;
          10'd533: rom_code = 3'd1;
          10'd534: rom_code = 3'd3;
          10'd535: rom_code = 3'd2;
          10'd536: rom_code = 3'd1;
          10'd551: rom_code = 3'd1;
          10'd552: rom_code = 3'd1;
          10'd553: rom_code = 3'd2;
          10'd554: rom_code = 3'd2;
          10'd555: rom_code = 3'd2;
          10'd556: rom_code = 3'd3;
          10'd557: rom_code = 3'd3;
          10'd558: rom_code = 3'd3;
          10'd559: rom_code = 3'd3;
          10'd560: rom_code = 3'd3;
          10'd561: rom_code = 3'd1;
          10'd562: rom_code = 3'd1;
          10'd564: rom_code = 3'd1;
          10'd565: rom_code = 3'd3;
          10'd566: rom_code = 3'd2;
          10'd567: rom_code = 3'd2;
          10'd568: rom_code = 3'd3;
          10'd569: rom_code = 3'd1;
          10'd582: rom_code = 3'd1;
          10'd585: rom_code = 3'd2;
          10'd586: rom_code = 3'd2;
          10'd587: rom_code = 3'd1;
          10'd588: rom_code = 3'd1;
          10'd589: rom_code = 3'd3;
          10'd590: rom_code = 3'd3;
          10'd591: rom_code = 3'd3;
          10'd592: rom_code = 3'd3;
          10'd593: rom_code = 3'd1;
          10'd594: rom_code = 3'd1;
          10'd595: rom_code = 3'd1;
          10'd596: rom_code = 3'd1;
          10'd597: rom_code = 3'd3;
          10'd598: rom_code = 3'd2;
          10'd599: rom_code = 3'd2;
          10'd600: rom_code = 3'd3;
          10'd601: rom_code = 3'd1;
          10'd602: rom_code = 3'd1;
          10'd613: rom_code = 3'd1;
          10'd615: rom_code = 3'd1;
          10'd616: rom_code = 3'd1;
          10'd617: rom_code = 3'd2;
          10'd618: rom_code = 3'd1;
          10'd619: rom_code = 3'd4;
          10'd620: rom_code = 3'd4;
          10'd621: rom_code = 3'd1;
          10'd622: rom_code = 3'd3;
          10'd623: rom_code = 3'd3;
          10'd624: rom_code = 3'd3;
          10'd625: rom_code = 3'd1;
          10'd626: rom_code = 3'd4;
          10'd627: rom_code = 3'd1;
          10'd628: rom_code = 3'd1;
          10'd629: rom_code = 3'd1;
          10'd630: rom_code = 3'd1;
          10'd631: rom_code = 3'd1;
          10'd632: rom_code = 3'd1;
          10'd633: rom_code = 3'd1;
          10'd634: rom_code = 3'd1;
          10'd643: rom_code = 3'd1;
          10'd644: rom_code = 3'd4;
          10'd645: rom_code = 3'd1;
          10'd646: rom_code = 3'd1;
          10'd647: rom_code = 3'd4;
          10'd648: rom_code = 3'd4;
          10'd649: rom_code = 3'd1;
          10'd650: rom_code = 3'd4;
          10'd651: rom_code = 3'd3;
          10'd652: rom_code = 3'd3;
          10'd653: rom_code = 3'd1;
          10'd654: rom_code = 3'd1;
          10'd655: rom_code = 3'd3;
          10'd656: rom_code = 3'd1;
          10'd657: rom_code = 3'd4;
          10'd658: rom_code = 3'd4;
          10'd659: rom_code = 3'd4;
          10'd660: rom_code = 3'd4;
          10'd661: rom_code = 3'd4;
          10'd662: rom_code = 3'd4;
          10'd663: rom_code = 3'd4;
          10'd664: rom_code = 3'd2;
          10'd665: rom_code = 3'd2;
          10'd666: rom_code = 3'd1;
          10'd675: rom_code = 3'd1;
          10'd676: rom_code = 3'd4;
          10'd677: rom_code = 3'd4;
          10'd678: rom_code = 3'd4;
          10'd679: rom_code = 3'd4;
          10'd680: rom_code = 3'd4;
          10'd681: rom_code = 3'd4;
          10'd682: rom_code = 3'd4;
          10'd683: rom_code = 3'd3;
          10'd684: rom_code = 3'd3;
          10'd685: rom_code = 3'd3;
          10'd686: rom_code = 3'd1;
          10'd687: rom_code = 3'd1;
          10'd688: rom_code = 3'd1;
          10'd689: rom_code = 3'd4;
          10'd690: rom_code = 3'd4;
          10'd691: rom_code = 3'd4;
          10'd692: rom_code = 3'd4;
          10'd693: rom_code = 3'd3;
          10'd694: rom_code = 3'd3;
          10'd695: rom_code = 3'd4;
          10'd696: rom_code = 3'd2;
          10'd697: rom_code = 3'd2;
          10'd698: rom_code = 3'd1;
          10'd707: rom_code = 3'd1;
          10'd708: rom_code = 3'd4;
          10'd709: rom_code = 3'd4;
          10'd710: rom_code = 3'd4;
          10'd711: rom_code = 3'd4;
          10'd712: rom_code = 3'd4;
          10'd713: rom_code = 3'd4;
          10'd714: rom_code = 3'd4;
          10'd715: rom_code = 3'd4;
          10'd716: rom_code = 3'd3;
          10'd717: rom_code = 3'd3;
          10'd718: rom_code = 3'd3;
          10'd719: rom_code = 3'd1;
          10'd720: rom_code = 3'd4;
          10'd721: rom_code = 3'd4;
          10'd722: rom_code = 3'd4;
          10'd723: rom_code = 3'd4;
          10'd724: rom_code = 3'd4;
          10'd725: rom_code = 3'd3;
          10'd726: rom_code = 3'd3;
          10'd727: rom_code = 3'd3;
          10'd728: rom_code = 3'd2;
          10'd729: rom_code = 3'd2;
          10'd730: rom_code = 3'd1;
          10'd739: rom_code = 3'd1;
          10'd740: rom_code = 3'd4;
          10'd741: rom_code = 3'd4;
          10'd742: rom_code = 3'd4;
          10'd743: rom_code = 3'd3;
          10'd744: rom_code = 3'd3;
          10'd745: rom_code = 3'd4;
          10'd746: rom_code = 3'd4;
          10'd747: rom_code = 3'd4;
          10'd748: rom_code = 3'd4;
          10'd749: rom_code = 3'd3;
          10'd750: rom_code = 3'd3;
          10'd751: rom_code = 3'd4;
          10'd752: rom_code = 3'd4;
          10'd753: rom_code = 3'd4;
          10'd754: rom_code = 3'd4;
          10'd755: rom_code = 3'd4;
          10'd756: rom_code = 3'd3;
          10'd757: rom_code = 3'd3;
          10'd758: rom_code = 3'd3;
          10'd759: rom_code = 3'd3;
          10'd760: rom_code = 3'd3;
          10'd761: rom_code = 3'd2;
          10'd762: rom_code = 3'd1;
          10'd771: rom_code = 3'd1;
          10'd772: rom_code = 3'd4;
          10'd773: rom_code = 3'd4;
          10'd774: rom_code = 3'd3;
          10'd775: rom_code = 3'd3;
          10'd776: rom_code = 3'd3;
          10'd777: rom_code = 3'd3;
          10'd778: rom_code = 3'd4;
          10'd779: rom_code = 3'd4;
          10'd780: rom_code = 3'd4;
          10'd781: rom_code = 3'd4;
          10'd782: rom_code = 3'd4;
          10'd783: rom_code = 3'd4;
          10'd784: rom_code = 3'd4;
          10'd785: rom_code = 3'd4;
          10'd786: rom_code = 3'd4;
          10'd787: rom_code = 3'd4;
          10'd788: rom_code = 3'd3;
          10'd789: rom_code = 3'd3;
          10'd790: rom_code = 3'd3;
          10'd791: rom_code = 3'd3;
          10'd792: rom_code = 3'd2;
          10'd793: rom_code = 3'd2;
          10'd794: rom_code = 3'd1;
          10'd803: rom_code = 3'd1;
          10'd804: rom_code = 3'd4;
          10'd805: rom_code = 3'd4;
          10'd806: rom_code = 3'd3;
          10'd807: rom_code = 3'd3;
          10'd808: rom_code = 3'd3;
          10'd809: rom_code = 3'd3;
          10'd810: rom_code = 3'd4;
          10'd811: rom_code = 3'd4;
          10'd812: rom_code = 3'd4;
          10'd813: rom_code = 3'd3;
          10'd814: rom_code = 3'd4;
          10'd815: rom_code = 3'd4;
          10'd816: rom_code = 3'd2;
          10'd817: rom_code = 3'd4;
          10'd818: rom_code = 3'd4;
          10'd819: rom_code = 3'd3;
          10'd820: rom_code = 3'd3;
          10'd821: rom_code = 3'd3;
          10'd822: rom_code = 3'd3;
          10'd823: rom_code = 3'd3;
          10'd824: rom_code = 3'd2;
          10'd825: rom_code = 3'd2;
          10'd826: rom_code = 3'd1;
          10'd835: rom_code = 3'd1;
          10'd836: rom_code = 3'd2;
          10'd837: rom_code = 3'd2;
          10'd838: rom_code = 3'd3;
          10'd839: rom_code = 3'd3;
          10'd840: rom_code = 3'd3;
          10'd841: rom_code = 3'd3;
          10'd842: rom_code = 3'd4;
          10'd843: rom_code = 3'd4;
          10'd844: rom_code = 3'd3;
          10'd845: rom_code = 3'd3;
          10'd846: rom_code = 3'd3;
          10'd847: rom_code = 3'd4;
          10'd848: rom_code = 3'd4;
          10'd849: rom_code = 3'd4;
          10'd850: rom_code = 3'd4;
          10'd851: rom_code = 3'd3;
          10'd852: rom_code = 3'd3;
          10'd853: rom_code = 3'd3;
          10'd854: rom_code = 3'd3;
          10'd855: rom_code = 3'd3;
          10'd856: rom_code = 3'd2;
          10'd857: rom_code = 3'd1;
          10'd868: rom_code = 3'd1;
          10'd869: rom_code = 3'd2;
          10'd870: rom_code = 3'd2;
          10'd871: rom_code = 3'd3;
          10'd872: rom_code = 3'd3;
          10'd873: rom_code = 3'd4;
          10'd874: rom_code = 3'd4;
          10'd875: rom_code = 3'd3;
          10'd876: rom_code = 3'd3;
          10'd877: rom_code = 3'd3;
          10'd878: rom_code = 3'd3;
          10'd879: rom_code = 3'd3;
          10'd880: rom_code = 3'd4;
          10'd881: rom_code = 3'd4;
          10'd882: rom_code = 3'd4;
          10'd883: rom_code = 3'd3;
          10'd884: rom_code = 3'd3;
          10'd885: rom_code = 3'd3;
          10'd886: rom_code = 3'd3;
          10'd887: rom_code = 3'd3;
          10'd888: rom_code = 3'd2;
          10'd889: rom_code = 3'd1;
          10'd901: rom_code = 3'd1;
          10'd902: rom_code = 3'd2;
          10'd903: rom_code = 3'd2;
          10'd904: rom_code = 3'd4;
          10'd905: rom_code = 3'd4;
          10'd906: rom_code = 3'd4;
          10'd907: rom_code = 3'd3;
          10'd908: rom_code = 3'd3;
          10'd909: rom_code = 3'd3;
          10'd910: rom_code = 3'd3;
          10'd911: rom_code = 3'd3;
          10'd912: rom_code = 3'd3;
          10'd913: rom_code = 3'd4;
          10'd914: rom_code = 3'd4;
          10'd915: rom_code = 3'd4;
          10'd916: rom_code = 3'd4;
          10'd917: rom_code = 3'd4;
          10'd918: rom_code = 3'd4;
          10'd919: rom_code = 3'd2;
          10'd920: rom_code = 3'd1;
          10'd934: rom_code = 3'd1;
          10'd935: rom_code = 3'd2;
          10'd936: rom_code = 3'd4;
          10'd937: rom_code = 3'd4;
          10'd938: rom_code = 3'd4;
          10'd939: rom_code = 3'd4;
          10'd940: rom_code = 3'd3;
          10'd941: rom_code = 3'd3;
          10'd942: rom_code = 3'd3;
          10'd943: rom_code = 3'd3;
          10'd944: rom_code = 3'd3;
          10'd945: rom_code = 3'd4;
          10'd946: rom_code = 3'd4;
          10'd947: rom_code = 3'd4;
          10'd948: rom_code = 3'd4;
          10'd949: rom_code = 3'd2;
          10'd950: rom_code = 3'd2;
          10'd951: rom_code = 3'd2;
          10'd967: rom_code = 3'd1;
          10'd968: rom_code = 3'd2;
          10'd969: rom_code = 3'd2;
          10'd970: rom_code = 3'd2;
          10'd971: rom_code = 3'd2;
          10'd972: rom_code = 3'd2;
          10'd973: rom_code = 3'd3;
          10'd974: rom_code = 3'd3;
          10'd975: rom_code = 3'd3;
          10'd976: rom_code = 3'd2;
          10'd977: rom_code = 3'd2;
          10'd978: rom_code = 3'd2;
          10'd979: rom_code = 3'd2;
          10'd980: rom_code = 3'd2;
          10'd981: rom_code = 3'd2;
          10'd982: rom_code = 3'd1;
          10'd983: rom_code = 3'd1;
          10'd999: rom_code = 3'd1;
          10'd1000: rom_code = 3'd1;
          10'd1001: rom_code = 3'd1;
          10'd1002: rom_code = 3'd1;
          10'd1003: rom_code = 3'd1;
          10'd1004: rom_code = 3'd1;
          10'd1005: rom_code = 3'd1;
          10'd1006: rom_code = 3'd1;
          10'd1007: rom_code = 3'd1;
          10'd1008: rom_code = 3'd1;
          10'd1009: rom_code = 3'd1;
          10'd1010: rom_code = 3'd1;
          10'd1011: rom_code = 3'd1;
          10'd1012: rom_code = 3'd1;
          10'd1013: rom_code = 3'd1;
          default: rom_code = 3'd0;
      endcase
    end

    // Geregistreerde (pipelined) output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px_on   <= 1'b0;
            px_code <= 3'd0;
        end else begin
            if (in_bounds && (rom_code != 3'd0)) begin
                px_on   <= 1'b1;
                px_code <= rom_code;
            end else begin
                px_on   <= 1'b0;
                px_code <= 3'd0;
            end
        end
    end

endmodule


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

    // Sprite startpositie op het scherm
    // Sprite blijft 256x256 op het scherm door 8x te schalen (ipv 4x)
    localparam [9:0] SPRITE_X = 10'd184;
    localparam [9:0] SPRITE_Y = 10'd96;
    localparam [9:0] SPRITE_W = 10'd256;
    localparam [9:0] SPRITE_H = 10'd256;

    wire in_bounds = (x >= SPRITE_X) && (x < (SPRITE_X + SPRITE_W)) &&
                     (y >= SPRITE_Y) && (y < (SPRITE_Y + SPRITE_H));

    // Delen door 8 (>> 3) i.p.v. door 4 -> 32x32 coördinaten
    wire [4:0] rel_x = in_bounds ? (x - SPRITE_X) >> 3 : 5'd0;
    wire [4:0] rel_y = in_bounds ? (y - SPRITE_Y) >> 3 : 5'd0;

    // 10-bit adres (1024 entries) i.p.v. 12-bit (4096 entries)
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