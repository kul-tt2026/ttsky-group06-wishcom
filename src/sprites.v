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
//     input  wire [2:0] level,
//     input  wire [1:0] mood_anim,
//     input  wire [1:0] bob,
//     output wire       px_on,
//     output wire [2:0] px_code
// );

//     //---------------------------------------------------------
//     // Middelpunt
//     //---------------------------------------------------------
//     wire signed [11:0] dx = $signed({2'b00, x}) - 12'sd320;
//     wire signed [11:0] dy = $signed({2'b00, y}) - 12'sd240;

//     //---------------------------------------------------------
//     // Hoogte en rand
//     //---------------------------------------------------------
//     localparam [11:0] B    = 12'd166;
//     localparam [11:0] RAND = 12'd6;

//     //---------------------------------------------------------
//     // 64-bit
//     //---------------------------------------------------------
//     wire signed [63:0] dx_ext = dx;
//     wire signed [63:0] dy_ext = dy;
//     wire signed [63:0] b_ext  = B;

//     //---------------------------------------------------------
//     // Kwadraten
//     //---------------------------------------------------------
//     wire signed [63:0] dx_sq = dx_ext * dx_ext;
//     wire signed [63:0] dy_sq = dy_ext * dy_ext;

//     wire signed [63:0] b_sq = b_ext * b_ext;

//     //---------------------------------------------------------
//     // Dynamische breedte
//     //
//     // boven ≈ 90 px
//     // midden ≈ 111 px
//     // onder ≈ 132 px
//     //---------------------------------------------------------
//     wire signed [63:0] a_dyn =
//         64'd90 + (dy_ext + 64'd166) / 8;

//     wire signed [63:0] a_dyn_out = a_dyn + RAND;

//     wire signed [63:0] a_dyn_sq     = a_dyn * a_dyn;
//     wire signed [63:0] a_dyn_out_sq = a_dyn_out * a_dyn_out;

//     //---------------------------------------------------------
//     // Binnenbox
//     //---------------------------------------------------------
//     wire binnen_in =
//         (dx_ext >= -a_dyn) &&
//         (dx_ext <=  a_dyn) &&
//         (dy_ext >= -b_ext) &&
//         (dy_ext <=  b_ext);

//     wire binnen_out =
//         (dx_ext >= -a_dyn_out) &&
//         (dx_ext <=  a_dyn_out) &&
//         (dy_ext >= -(b_ext+RAND)) &&
//         (dy_ext <=  (b_ext+RAND));

//     //---------------------------------------------------------
//     // Eivorm
//     //---------------------------------------------------------
//     wire in_ei =
//         binnen_in &&
//         ((dx_sq * b_sq + dy_sq * a_dyn_sq)
//             <= (a_dyn_sq * b_sq));

//     wire signed [63:0] b_out = b_ext + RAND;
//     wire signed [63:0] b_out_sq = b_out * b_out;

//     wire in_ei_out =
//         binnen_out &&
//         ((dx_sq * b_out_sq + dy_sq * a_dyn_out_sq)
//             <= (a_dyn_out_sq * b_out_sq));

//     //---------------------------------------------------------
//     // Output
//     //---------------------------------------------------------
//     assign px_on = 1'b1;

//     // 2 = groen
//     // 0 = zwart
//     // 1 = wit

//     assign px_code =
//         in_ei      ? 3'd2 :
//         in_ei_out  ? 3'd0 :
//                      3'd1;

//     wire _unused = &{level, mood_anim, bob, 1'b0};

// endmodule
`default_nettype none
`default_nettype none

module ei_generator (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] mood_anim,
    output wire       px_on,
    output wire [2:0] px_code
);

    // Ongebruikte signalen direct afvangen
    wire _unused = &{mood_anim, 1'b0};

    //---------------------------------------------------------
    // Middelpunt (12-bit signed)
    //---------------------------------------------------------
    wire signed [11:0] dx = $signed({2'b00, x}) - 12'sd320;
    wire signed [11:0] dy = $signed({2'b00, y}) - 12'sd240;

    //---------------------------------------------------------
    // Parameters (12-bit signed)
    //---------------------------------------------------------
    localparam signed [11:0] B    = 12'sd145;
    localparam signed [11:0] RAND = 12'sd8;

    // Dynamische breedte (kwadratische eivorm)
    wire signed [11:0] t        = dy + 12'sd166;
    wire signed [11:0] a_dyn    = 12'sd90 + $signed((t * t) / 12'sd2500);

    // Buitenste ei parameters
    wire signed [11:0] a_out    = a_dyn + RAND;
    wire signed [11:0] b_out    = B + RAND;

    // Kwadraten voor ovaalberekeningen
    wire signed [23:0] dx_sq    = dx * dx;
    wire signed [23:0] dy_sq    = dy * dy;

    wire signed [23:0] a_dyn_sq = a_dyn * a_dyn;
    wire signed [23:0] b_sq     = B * B;

    wire signed [23:0] a_out_sq = a_out * a_out;
    wire signed [23:0] b_out_sq = b_out * b_out;

    //---------------------------------------------------------
    // Binnenboxen
    //---------------------------------------------------------
    wire box_in =
        (dx >= -a_dyn) &&
        (dx <=  a_dyn) &&
        (dy >= -B)     &&
        (dy <=  B);

    wire box_out =
        (dx >= -a_out) &&
        (dx <=  a_out) &&
        (dy >= -b_out) &&
        (dy <=  b_out);

    //---------------------------------------------------------
    // Ovalen
    //---------------------------------------------------------
    wire in_ei =
        box_in &&
        ((dx_sq * b_sq + dy_sq * a_dyn_sq) <= (a_dyn_sq * b_sq));

    wire in_ei_out =
        box_out &&
        ((dx_sq * b_out_sq + dy_sq * a_out_sq) <= (a_out_sq * b_out_sq));

    //---------------------------------------------------------
    // Vlekjes binnen het ei (12-bit rekenkunde)
    //---------------------------------------------------------
    wire signed [11:0] vlek1_dx = dx - 12'sd25;
    wire signed [11:0] vlek1_dy = dy - (-12'sd60);
    wire vlek1 = (vlek1_dx * vlek1_dx + vlek1_dy * vlek1_dy) <= (12'sd27 * 12'sd27);

    wire signed [11:0] vlek2_dx = dx - 12'sd30;
    wire signed [11:0] vlek2_dy = dy - 12'sd70;
    wire vlek2 = (vlek2_dx * vlek2_dx + vlek2_dy * vlek2_dy) <= (12'sd35 * 12'sd35);

    wire signed [11:0] vlek3_dx = dx + 12'sd50;
    wire signed [11:0] vlek3_dy = dy - 12'sd20;
    wire vlek3 = (vlek3_dx * vlek3_dx + vlek3_dy * vlek3_dy) <= (12'sd30 * 12'sd30);

    //---------------------------------------------------------
    // Rand & Output
    //---------------------------------------------------------
    wire border = in_ei_out && !in_ei;

    assign px_on = in_ei_out;

    assign px_code =
        border                               ? 3'd1 : // Rand (Zwart)
        (in_ei && (vlek1 || vlek2 || vlek3)) ? 3'd2 : // Vlekken (Donkergroen)
        in_ei                                ? 3'd4 : // Ei vulling (Wit)
                                               3'd0;  // Transparant
endmodule

`default_nettype none

module dragon_l1_generator (
    input  wire [9:0] x,          // Scherm coördinaat X (0..639)
    input  wire [9:0] y,          // Scherm coördinaat Y (0..479)
    input  wire [2:0] mood_anim,  // Animatie status
    output wire       px_on,      // 1 = actieve pixel
    output wire [2:0] px_code     // Kleurcode
);

    wire _unused = &{mood_anim, 1'b0};

    // 8x Schaling (272x288 px op scherm)
    wire signed [11:0] raw_x = $signed({2'b00, x});
    wire signed [11:0] raw_y = $signed({2'b00, y});

    wire signed [11:0] rel_x = raw_x >>> 3;
    wire signed [11:0] rel_y = raw_y >>> 3;

    wire in_bounds = (raw_x >= 0 && raw_x < 272) && (raw_y >= 0 && raw_y < 288);

    wire [5:0] row = in_bounds ? rel_y[5:0] : 6'd0;
    wire [5:0] col = in_bounds ? rel_x[5:0] : 6'd0;

    // ROM Geheugen: 1224 entries van 3 bits (34 breed x 36 hoog)
    reg [2:0] rom [0:1223];

    initial begin
        $readmemh("dragon_l1.hex", rom);
    end

    // 1D Adres berekening: (row * 34) + col
    // Vermenigvuldiging met constante 34 = (row << 5) + (row << 1)
    wire [10:0] addr = (row * 6'd34) + col;

    wire [2:0] code = in_bounds ? rom[addr] : 3'd0;

    assign px_on   = in_bounds && (code != 3'd0);
    assign px_code = in_bounds ? code : 3'd0;

endmodule