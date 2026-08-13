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

module ei_generator (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] mood_anim,
    output wire       px_on,
    output wire [2:0] px_code
);

    // Ongebruikte signalen direct afvangen
    wire _unused = &{ mood_anim, 1'b0};

    //---------------------------------------------------------
    // Middelpunt
    //---------------------------------------------------------
    wire signed [11:0] dx = $signed({2'b00,x}) - 12'sd320;
    wire signed [11:0] dy = $signed({2'b00,y}) - 12'sd240;

    //---------------------------------------------------------
    // Parameters
    //---------------------------------------------------------
    localparam signed [63:0] B = 64'd145;
    localparam signed [63:0] RAND = 64'd8;

    //---------------------------------------------------------
    // 64-bit & Kwadraten
    //---------------------------------------------------------
    wire signed [63:0] dx64 = dx;
    wire signed [63:0] dy64 = dy;
    wire signed [63:0] dx_sq = dx64 * dx64;
    wire signed [63:0] dy_sq = dy64 * dy64;
    wire signed [63:0] b_sq = B * B;

    // Dynamische breedte (kwadratische eivorm)
    wire signed [63:0] t = dy64 + 64'd166;
    wire signed [63:0] a_dyn = 64'd90 + (t * t) / 2500;
    wire signed [63:0] a_dyn_sq = a_dyn * a_dyn;

    //---------------------------------------------------------
    // Buitenste ei
    //---------------------------------------------------------
    wire signed [63:0] a_out = a_dyn + RAND;
    wire signed [63:0] b_out = B + RAND;

    wire signed [63:0] a_out_sq = a_out * a_out;
    wire signed [63:0] b_out_sq = b_out * b_out;

    //---------------------------------------------------------
    // Binnenboxen
    //---------------------------------------------------------
    wire box_in =
        (dx64 >= -a_dyn) &&
        (dx64 <=  a_dyn) &&
        (dy64 >= -B) &&
        (dy64 <=  B);

    wire box_out =
        (dx64 >= -a_out) &&
        (dx64 <=  a_out) &&
        (dy64 >= -b_out) &&
        (dy64 <=  b_out);

    //---------------------------------------------------------
    // Ovalen
    //---------------------------------------------------------
    wire in_ei =
        box_in &&
        ((dx_sq * b_sq + dy_sq * a_dyn_sq)
            <= (a_dyn_sq * b_sq));

    wire in_ei_out =
        box_out &&
        ((dx_sq * b_out_sq + dy_sq * a_out_sq)
            <= (a_out_sq * b_out_sq));

    //---------------------------------------------------------
    // Vlekjes binnen het ei
    //---------------------------------------------------------
    wire signed [63:0] vlek1_dx = dx64 - 64'sd25;
    wire signed [63:0] vlek1_dy = dy64 - (-64'sd60);
    wire vlek1 = (vlek1_dx * vlek1_dx + vlek1_dy * vlek1_dy) <= (64'sd27 * 64'sd27);

    wire signed [63:0] vlek2_dx = dx64 - 64'sd30;
    wire signed [63:0] vlek2_dy = dy64 - 64'sd70;
    wire vlek2 = (vlek2_dx * vlek2_dx + vlek2_dy * vlek2_dy) <= (64'sd35 * 64'sd35);

    wire signed [63:0] vlek3_dx = dx64 + 64'sd50;
    wire signed [63:0] vlek3_dy = dy64 - 64'sd20;
    wire vlek3 = (vlek3_dx * vlek3_dx + vlek3_dy * vlek3_dy) <= (64'sd30 * 64'sd30);

    //---------------------------------------------------------
    // Rand & Output
    //---------------------------------------------------------
    wire border = in_ei_out && !in_ei;

    assign px_on = 1'b1;

    assign px_code =
        border                       ? 3'd0 : 
        (in_ei && (vlek1 || vlek2 || vlek3)) ? 3'd2 : 
        in_ei                        ? 3'd4 : 
                                       3'd4;  

endmodule

`default_nettype none

module dragon_l1_generator (
    input  wire [9:0] x,          // Scherm coördinaat X (0..639)
    input  wire [9:0] y,          // Scherm coördinaat Y (0..479)
    input  wire [2:0] mood_anim,  // Animatie status (optioneel te gebruiken)
    output wire       px_on,      // 1 = er is een draak-pixel op deze coördinaat
    output wire [2:0] px_code     // Kleurcode (0=transparant, 1=outline, 2=groen, etc.)
);

    // Ongebruikte signalen netjes afvangen
    wire _unused = &{mood_anim, 1'b0};
    // ---------------------------------------------------------
    // Kleuren-placeholders (pas de waarden HIER aan)
    // ---------------------------------------------------------
    // ---------------------------------------------------------
    // Kleuren-placeholders (Gecorrigeerd!)
    // ---------------------------------------------------------
    localparam [2:0] color0 = 3'd0; // TRANSPARANT (Achtergrond, geen pixel)
    localparam [2:0] color1 = 3'd1; // ZWART (Omtrek / Oogjes)
    localparam [2:0] color2 = 3'd2; // Medium groen (Lijfje & Eivlekken)
    localparam [2:0] color3 = 3'd3; // Fel groen (Buikje & Staart)
    localparam [2:0] color4 = 3'd4; // WIT (Eierschaal & Oogglim)
    localparam [2:0] color5 = 3'd5; // Medium grijs (Horentjes)
    localparam [2:0] color6 = 3'd6; // Donkergrijs (Schaduw horentjes)
    //---------------------------------------------------------
    // Positionering (Middelpunt van de sprite op 320, 240)
    // Draak is 34 px breed en 36 px hoog.
    // X-bereik: 320 - 17 = 303
    // Y-bereik: 240 - 18 = 222
    //---------------------------------------------------------
    // 1. Oorspronkelijke relatieve positie berekenen (t.o.v. het midden 320, 240)
    // Bij 2x vergroting is de draak op het scherm 68x72 pixels.
    // Middelpunt-offset: 320 - 34 = 286, 240 - 36 = 204
   //---------------------------------------------------------
    // 16x Schaling (Draak wordt 544 x 576 pixels op het scherm)
    // 
    // Midden van scherm = (320, 240)
    // Halve breedte = 544 / 2 = 272 -> Offset X = 320 - 272 = 48
    // Halve hoogte  = 576 / 2 = 288 -> Offset Y = 240 - 288 = -48
    //---------------------------------------------------------
    // 8x Schaling (272x288 px)
    // Offset X = 320 - (272/2) = 184
    // Offset Y = 240 - (288/2) = 96
    // Vorm de lokale scherm-X en Y om naar de 8x geschaalde sprite
    // (Gebruik x en y direct zonder de dubbele offset van 184/96!)
    wire signed [11:0] raw_x = $signed({2'b00, x});
    wire signed [11:0] raw_y = $signed({2'b00, y});

    // Deel door 8 (>>> 3)
    wire signed [11:0] rel_x = raw_x >>> 3;
    wire signed [11:0] rel_y = raw_y >>> 3;

    // Binnen de grenzen van de geschaalde sprite (34*8 = 272, 36*8 = 288)
    wire in_bounds = (raw_x >= 0 && raw_x < 272) && (raw_y >= 0 && raw_y < 288);

    wire [5:0] row = in_bounds ? rel_y[5:0] : 6'd0;
    wire [5:0] col = in_bounds ? rel_x[5:0] : 6'd0;
    

    reg [2:0] code;

    //---------------------------------------------------------
    // ROM Logica (gegenereerd uit je afbeelding)
    //---------------------------------------------------------


    always @(*) begin
        code = color0;
        if (in_bounds) begin
            case (row[5:0])
               
                // Generated from lvl1.png (34x36)
// Module / block name: dragon_l1
    6'd0: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color0;
    6'd12: code = color0;
    6'd13: code = color0;
    6'd14: code = color0;
    6'd15: code = color0;
    6'd16: code = color0;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd1: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color6;
    6'd12: code = color6;
    6'd13: code = color6;
    6'd14: code = color0;
    6'd15: code = color0;
    6'd16: code = color0;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd2: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color6;
    6'd12: code = color5;
    6'd13: code = color6;
    6'd14: code = color0;
    6'd15: code = color0;
    6'd16: code = color0;
    6'd17: code = color6;
    6'd18: code = color6;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd3: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color6;
    6'd11: code = color5;
    6'd12: code = color5;
    6'd13: code = color6;
    6'd14: code = color0;
    6'd15: code = color0;
    6'd16: code = color6;
    6'd17: code = color6;
    6'd18: code = color5;
    6'd19: code = color6;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd4: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color0;
    6'd12: code = color5;
    6'd13: code = color6;
    6'd14: code = color0;
    6'd15: code = color6;
    6'd16: code = color6;
    6'd17: code = color5;
    6'd18: code = color5;
    6'd19: code = color6;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd5: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color0;
    6'd13: code = color0;
    6'd14: code = color0;
    6'd15: code = color6;
    6'd16: code = color5;
    6'd17: code = color5;
    6'd18: code = color6;
    6'd19: code = color6;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd6: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color6;
    6'd16: code = color5;
    6'd17: code = color6;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd7: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color6;
    6'd17: code = color6;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd8: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color2;
    6'd12: code = color0;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd9: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color3;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color0;
    6'd12: code = color0;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd10: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color3;
    6'd5: code = color2;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color0;
    6'd12: code = color0;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd11: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color3;
    6'd5: code = color3;
    6'd6: code = color3;
    6'd7: code = color0;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd12: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color3;
    6'd5: code = color3;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd13: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color3;
    6'd5: code = color3;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd14: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color3;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd15: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color3;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color3;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd16: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color0;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color3;
    6'd25: code = color3;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd17: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color3;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd18: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color3;
    6'd24: code = color2;
    6'd25: code = color3;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd19: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color3;
    6'd23: code = color2;
    6'd24: code = color2;
    6'd25: code = color3;
    6'd26: code = color3;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd20: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color6;
    6'd8: code = color6;
    6'd9: code = color6;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color0;
    6'd13: code = color0;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color3;
    6'd23: code = color2;
    6'd24: code = color2;
    6'd25: code = color2;
    6'd26: code = color3;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd21: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color6;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color2;
    6'd11: code = color0;
    6'd12: code = color2;
    6'd13: code = color2;
    6'd14: code = color0;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color0;
    6'd19: code = color2;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd22: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color6;
    6'd7: code = color0;
    6'd8: code = color2;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color0;
    6'd12: code = color2;
    6'd13: code = color3;
    6'd14: code = color0;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color2;
    6'd20: code = color0;
    6'd21: code = color2;
    6'd22: code = color2;
    6'd23: code = color2;
    6'd24: code = color2;
    6'd25: code = color0;
    6'd26: code = color5;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd23: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color2;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color2;
    6'd8: code = color2;
    6'd9: code = color2;
    6'd10: code = color0;
    6'd11: code = color2;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color0;
    6'd15: code = color0;
    6'd16: code = color3;
    6'd17: code = color0;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color2;
    6'd22: code = color2;
    6'd23: code = color2;
    6'd24: code = color2;
    6'd25: code = color2;
    6'd26: code = color5;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd24: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color2;
    6'd5: code = color2;
    6'd6: code = color2;
    6'd7: code = color2;
    6'd8: code = color2;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color0;
    6'd16: code = color0;
    6'd17: code = color0;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color2;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color2;
    6'd25: code = color2;
    6'd26: code = color5;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd25: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color2;
    6'd5: code = color2;
    6'd6: code = color2;
    6'd7: code = color2;
    6'd8: code = color2;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color0;
    6'd17: code = color2;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color2;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color3;
    6'd26: code = color5;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd26: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color2;
    6'd5: code = color2;
    6'd6: code = color2;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color2;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color2;
    6'd17: code = color2;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color3;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color3;
    6'd26: code = color3;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd27: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color2;
    6'd5: code = color2;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color2;
    6'd14: code = color2;
    6'd15: code = color2;
    6'd16: code = color2;
    6'd17: code = color2;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color3;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color3;
    6'd26: code = color5;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd28: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color2;
    6'd5: code = color2;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color2;
    6'd14: code = color3;
    6'd15: code = color2;
    6'd16: code = color2;
    6'd17: code = color5;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color3;
    6'd21: code = color3;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color3;
    6'd26: code = color5;
    6'd27: code = color5;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd29: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color5;
    6'd5: code = color5;
    6'd6: code = color3;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color3;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color2;
    6'd17: code = color2;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color3;
    6'd21: code = color3;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color2;
    6'd26: code = color5;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd30: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color5;
    6'd6: code = color5;
    6'd7: code = color3;
    6'd8: code = color3;
    6'd9: code = color3;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color2;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color3;
    6'd21: code = color3;
    6'd22: code = color3;
    6'd23: code = color3;
    6'd24: code = color3;
    6'd25: code = color5;
    6'd26: code = color5;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd31: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color5;
    6'd7: code = color2;
    6'd8: code = color2;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color3;
    6'd21: code = color3;
    6'd22: code = color3;
    6'd23: code = color2;
    6'd24: code = color2;
    6'd25: code = color5;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd32: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color5;
    6'd7: code = color5;
    6'd8: code = color2;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color3;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color2;
    6'd22: code = color2;
    6'd23: code = color2;
    6'd24: code = color5;
    6'd25: code = color5;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd33: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color5;
    6'd8: code = color5;
    6'd9: code = color2;
    6'd10: code = color2;
    6'd11: code = color2;
    6'd12: code = color2;
    6'd13: code = color3;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color3;
    6'd18: code = color2;
    6'd19: code = color2;
    6'd20: code = color2;
    6'd21: code = color2;
    6'd22: code = color5;
    6'd23: code = color5;
    6'd24: code = color5;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd34: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color5;
    6'd9: code = color5;
    6'd10: code = color5;
    6'd11: code = color5;
    6'd12: code = color5;
    6'd13: code = color5;
    6'd14: code = color3;
    6'd15: code = color3;
    6'd16: code = color3;
    6'd17: code = color5;
    6'd18: code = color5;
    6'd19: code = color5;
    6'd20: code = color5;
    6'd21: code = color5;
    6'd22: code = color5;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  6'd35: case (col[5:0])
    6'd0: code = color0;
    6'd1: code = color0;
    6'd2: code = color0;
    6'd3: code = color0;
    6'd4: code = color0;
    6'd5: code = color0;
    6'd6: code = color0;
    6'd7: code = color0;
    6'd8: code = color0;
    6'd9: code = color0;
    6'd10: code = color0;
    6'd11: code = color0;
    6'd12: code = color0;
    6'd13: code = color0;
    6'd14: code = color0;
    6'd15: code = color0;
    6'd16: code = color0;
    6'd17: code = color0;
    6'd18: code = color0;
    6'd19: code = color0;
    6'd20: code = color0;
    6'd21: code = color0;
    6'd22: code = color0;
    6'd23: code = color0;
    6'd24: code = color0;
    6'd25: code = color0;
    6'd26: code = color0;
    6'd27: code = color0;
    6'd28: code = color0;
    6'd29: code = color0;
    6'd30: code = color0;
    6'd31: code = color0;
    6'd32: code = color0;
    6'd33: code = color0;
    default: code = color4;
  endcase
  default: code = color4;
  endcase
end
    end

    //---------------------------------------------------------
    // Output Toewijzing
    //---------------------------------------------------------
    // px_on is 1 als we binnen het vakje zitten én de pixel niet transparant (0) is
    assign px_on   = in_bounds && (code != 3'd0);
    assign px_code = in_bounds ? code : 3'd0;

endmodule