`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// Zuiver-Verilog render test: sweep over 640x480, schrijf een PPM.
// Geen cocotb nodig -> loopt in een seconde.
// commandos: dos2unix render_tb.v ../src/*.v
//cd /mnt/c/Users/annab/tinytapeout/ttsky-group06-wishcom/test
//iverilog -g2012 -o sim render_tb.v ../src/satisfactionbar.v ../src/coinbar.v ../src/hearts.v
//vvp sim
//python3 -c "from PIL import Image; Image.open('frame.ppm').save('frame.png')"
// python3 -c "
// from PIL import Image
// Image.open('frame.ppm').transpose(Image.ROTATE_90).save('frame.png')"
// ---------------------------------------------------------------------------
module render_tb;

  // ---- zet hier wat je wil testen -----------------------------------------
  localparam [9:0] HEARTS_X  = 10'd168, HEARTS_Y  = 10'd16;  // 304 x 24
  localparam [9:0] SATBAR_X  = 10'd294, SATBAR_Y  = 10'd48;  // 162 x 24
  localparam [9:0] COINBAR_X = 10'd24,  COINBAR_Y = 10'd80;  //  24 x 132

  reg  [9:0] pix_x, pix_y;
  wire [9:0] px = pix_y;
  wire [9:0] py = 10'd639 - pix_x;
  reg  [2:0] sat;
  reg  [9:0] coins;

  // ---- satisfaction bar ----------------------------------------------------
  wire       sat_on;
  wire [2:0] sat_code;
  satisfactionbar u_sat (
    .x(px - SATBAR_X), .y(py - SATBAR_Y),
    .sat(sat), .px_on(sat_on), .px_code(sat_code)
  );

  // --- coin bar ------------------------------
  wire       coin_on;
  wire [1:0] coin_code;

  coinbar u_coin (
    .x(px - COINBAR_X), .y(py - COINBAR_Y),
    .coins(coins),
    .px_on(coin_on), .px_code(coin_code)
  );

  // --- hearts------------------------------
  reg  [2:0] hcount;
  reg        ovf;
  wire       h_on;
  wire [1:0] h_code;

  hearts u_hearts (
    .x(px - HEARTS_X), .y(py - HEARTS_Y),
    .hearts(hcount), .overflow(ovf),
    .px_on(h_on), .px_code(h_code)
  );

  

  // ---- palet: exact zoals in renderer.v ------------------------------------
  reg [5:0] sat_rgb;
  always @(*) case (sat_code)
    3'd1: sat_rgb = 6'b11_00_00;
    3'd2: sat_rgb = 6'b11_01_00;
    3'd3: sat_rgb = 6'b11_11_00;
    3'd4: sat_rgb = 6'b10_11_00;
    3'd5: sat_rgb = 6'b00_11_00;
    3'd6: sat_rgb = 6'b11_11_11;
    3'd7: sat_rgb = 6'b01_01_01;
    default: sat_rgb = 6'b00_00_00;
  endcase

  reg [5:0] coin_rgb;
  always @(*) case (coin_code)
    2'd0: coin_rgb = 6'b00_00_00;   // frame + schotjes, donker
    2'd1: coin_rgb = 6'b01_01_01;   // leeg vakje, donkergrijs
    2'd2: coin_rgb = 6'b11_11_00;   // vol vakje, geel
    default: coin_rgb = 6'b00_00_00;
  endcase

  wire [5:0] hearts_rgb = (h_code == 2'd1) ? 6'b11_00_00 : 6'b11_11_11;


  localparam [5:0] BG_HOME = 6'b01_10_11;

  reg [5:0] rgb;
  always @(*) begin
    if      (h_on) rgb = hearts_rgb;
    else if      (sat_on)  rgb = sat_rgb;
    else if (coin_on) rgb = coin_rgb;
    else              rgb = BG_HOME;
  end

  integer f, xi, yi;
  initial begin
    sat  = 3'd0;      // 0-5
    coins = 10'd700; // 0-1000
    hcount = 3'd2;      // 0..5
    ovf    = 1'b1;      // label aan
    f = $fopen("frame.ppm", "w");
    $fwrite(f, "P3\n640 480\n255\n");
    for (yi = 0; yi < 480; yi = yi + 1) begin
      for (xi = 0; xi < 640; xi = xi + 1) begin
        pix_x = xi[9:0];
        pix_y = yi[9:0];
        #1;
        $fwrite(f, "%0d %0d %0d\n", rgb[5:4]*85, rgb[3:2]*85, rgb[1:0]*85);
      end
    end
    $fclose(f);
    $display("klaar -> frame.ppm");
    $finish;
  end
endmodule