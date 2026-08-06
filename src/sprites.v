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
module dragon_rom (
    input  wire [2:0] level,
    input  wire [5:0] row,
    input  wire [5:0] col,
    output reg  [2:0] code       // 0=transparent 1=outline 2=body 3=belly ...
);
  always @(*) begin
    code = 3'd0;
    // placeholder: 16x16 egg shown for every level.
    // codes: 1=outline, 2=body
    if (row<6'd16 && col<6'd16) begin
      case (row[3:0])
        4'd0 : code = (col>=6 && col<=9)  ? 3'd1 : 3'd0;
        4'd1 : code = (col>=5 && col<=10) ? ((col==5||col==10)?3'd1:3'd2) : 3'd0;
        4'd2 : code = (col>=4 && col<=11) ? ((col==4||col==11)?3'd1:3'd2) : 3'd0;
        4'd3 : code = (col>=3 && col<=12) ? ((col==3||col==12)?3'd1:3'd2) : 3'd0;
        4'd4,4'd5 : code = (col>=2 && col<=13) ? ((col==2||col==13)?3'd1:3'd2) : 3'd0;
        4'd6,4'd7,4'd8,4'd9,4'd10 :
               code = (col>=1 && col<=14) ? ((col==1||col==14)?3'd1:3'd2) : 3'd0;
        4'd11,4'd12 : code = (col>=2 && col<=13) ? ((col==2||col==13)?3'd1:3'd2) : 3'd0;
        4'd13: code = (col>=3 && col<=12) ? ((col==3||col==12)?3'd1:3'd2) : 3'd0;
        4'd14: code = (col>=4 && col<=11) ? ((col==4||col==11)?3'd1:3'd2) : 3'd0;
        4'd15: code = (col>=6 && col<=9)  ? 3'd1 : 3'd0;
        default: code = 3'd0;
      endcase
    end
  end
  wire _unused = &{level, row[5:4], col[5:4], 1'b0};
endmodule

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


// `default_nettype none

// module ei_generator (
//     input  wire [9:0] x,
//     input  wire [9:0] y,
//     input  wire [2:0] level,
//     input  wire [1:0] mood_anim,
//     input  wire [1:0] bob,
//     output wire       px_on,
//     output wire [2:0] px_code
// );

//   wire signed [11:0] dx = $signed({2'b00, x}) - 12'sd320;
//   wire signed [11:0] dy = $signed({2'b00, y}) - 12'sd240;

//   // Jouw gewenste maten
//   localparam [11:0] A = 12'd100;
//   localparam [11:0] B = 12'd166;

//   // Schakel direct over naar 64-bits (signed [63:0]). 
//   // Hiermee kan de chip astronomisch grote getallen berekenen zonder overflow!
//   wire signed [63:0] dx_ext = dx;
//   wire signed [63:0] dy_ext = dy;
//   wire signed [63:0] a_ext  = A;
//   wire signed [63:0] b_ext  = B;

//   wire signed [63:0] dx_sq  = dx_ext * dx_ext;
//   wire signed [63:0] dy_sq  = dy_ext * dy_ext;
//   wire signed [63:0] a_sq   = a_ext  * a_ext;
//   wire signed [63:0] b_sq   = b_ext  * b_ext;

//   // De ovaal-vergelijking in 64-bit formaat
//   wire binnen_box = (dx_ext >= -a_ext) && (dx_ext <= a_ext) && 
//                     (dy_ext >= -b_ext) && (dy_ext <= b_ext);

//   wire in_ovaal = binnen_box && ((dx_sq * b_sq + dy_sq * a_sq) <= (a_sq * b_sq));

//   assign px_on = 1'b1;
//   assign px_code = in_ovaal ? 3'd3 : 3'd1; // 3 = Rood, 1 = Wit

//   wire _unused = &{level, mood_anim, bob, 1'b0};

// endmodule

`default_nettype none

module ei_generator (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] level,
    input  wire [1:0] mood_anim,
    input  wire [1:0] bob,
    output wire       px_on,
    output wire [2:0] px_code
);

  wire signed [11:0] dx = $signed({2'b00, x}) - 12'sd320;
  wire signed [11:0] dy = $signed({2'b00, y}) - 12'sd240;

  // Maten van de ovaal en de randdikte
  localparam [11:0] A = 12'd100;
  localparam [11:0] B = 12'd166;
  localparam [11:0] RAND_DIKTE = 12'd4;
  
  localparam [11:0] A_OUT = A + RAND_DIKTE;
  localparam [11:0] B_OUT = B + RAND_DIKTE;

  wire signed [63:0] dx_ext = dx;
  wire signed [63:0] dy_ext = dy;
  
  wire signed [63:0] a_in   = A;
  wire signed [63:0] b_in   = B;
  wire signed [63:0] a_out  = A_OUT;
  wire signed [63:0] b_out  = B_OUT;

  wire signed [63:0] dx_sq  = dx_ext * dx_ext;
  wire signed [63:0] dy_sq  = dy_ext * dy_ext;

  wire signed [63:0] a_in_sq  = a_in  * a_in;
  wire signed [63:0] b_in_sq  = b_in  * b_in;
  wire signed [63:0] a_out_sq = a_out * a_out;
  wire signed [63:0] b_out_sq = b_out * b_out;

  // Omdat dx_sq en dy_sq altijd positief zijn, controleren we de box 
  // door te kijken of het kwadraat kleiner is dan de straal in het kwadraat!
  wire binnen_box_in  = (dx_sq <= a_in_sq)  && (dy_sq <= b_in_sq);
  wire binnen_box_out = (dx_sq <= a_out_sq) && (dy_sq <= b_out_sq);

  wire in_binnen_ovaal = binnen_box_in  && ((dx_sq * b_in_sq  + dy_sq * a_in_sq)  <= (a_in_sq  * b_in_sq));
  wire in_buiten_ovaal = binnen_box_out && ((dx_sq * b_out_sq + dy_sq * a_out_sq) <= (a_out_sq * b_out_sq));

  assign px_on = 1'b1;
  
  assign px_code = in_binnen_ovaal ? 3'd3 :          // Binnenkant = Rood
                   in_buiten_ovaal ? 3'd0 :          // De rand = Zwart
                   3'd1;                             // Achtergrond = Wit

  wire _unused = &{level, mood_anim, bob, 1'b0};

endmodule