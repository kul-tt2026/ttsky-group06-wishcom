`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// TITELSCHERM-ANIMATIE.  Maakt SHOTS PPM's van het VOLLEDIGE portretscherm
// (480 x 640), inclusief titelkaart, zodat je ziet wat de speler ziet.
//
//   cd src
//   iverilog -g2005 -o ../sim ../test/egg_tb.v title_egg.v title_card.v
//   vvp ../sim
//   python3 ../test/ppm2gif.py
//
// SHOTS * TICKS_PER_SHOT = 256 = precies EEN wiegcyclus, dus de gif loopt
// naadloos rond.  (wave is 9 bits en telt +2 per frame -> 512/2 = 256.)
// ---------------------------------------------------------------------------
module egg_tb;
  localparam SHOTS          = 32;
  localparam STEP           = 1;      // elke 2e pixel: 4x sneller, half zo groot
  localparam TICKS_PER_SHOT = 8;     // 16 * 16 = 256 = een volle cyclus
  localparam Y0 = 0, Y1 = 639;   // alleen de onderste helft: ei + gras        // hele portretscherm
  localparam X0 = 0, X1 = 479;

  reg clk = 0, rst_n = 0, frame_tick = 0;
  reg [9:0] x, y;

  always #20 clk = ~clk;              // 25 MHz -- ZONDER DIT GEBEURT ER NIETS

  wire       egg_on, ground_on, ground_shadow, press_on;
  wire [2:0] egg_code;
  title_egg u_egg (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .x(x), .y(y),
    .egg_on(egg_on), .egg_code(egg_code), .press_on(press_on),
    .ground_on(ground_on), .ground_shadow(ground_shadow)
  );

  wire       title_on;
  wire [2:0] title_code;
  title_card u_title (.x(x), .y(y), .px_on(title_on), .px_code(title_code));

  // palet: exact zoals in renderer.v
  reg [5:0] title_rgb;
  always @(*) case (title_code)
    3'd1: title_rgb = 6'b00_01_00;
    3'd2: title_rgb = 6'b01_11_01;
    3'd3: title_rgb = 6'b00_01_00;
    3'd4: title_rgb = 6'b01_11_01;
    3'd5: title_rgb = 6'b00_10_00;
    default: title_rgb = 6'b00_00_00;
  endcase

  reg [5:0] egg_rgb;
  always @(*) case (egg_code)
    3'd1: egg_rgb = 6'b00_00_00;
    3'd2: egg_rgb = 6'b10_10_10;
    3'd3: egg_rgb = 6'b00_11_00;
    3'd4: egg_rgb = 6'b11_11_11;
    3'd5: egg_rgb = 6'b00_10_00;
    3'd6: egg_rgb = 6'b01_01_01;
    3'd7: egg_rgb = 6'b10_11_01;
    default: egg_rgb = 6'b00_00_00;
  endcase

  reg [5:0] rgb;
  always @(*) begin
    if      (title_on)   rgb = title_rgb;
    else if (press_on)   rgb = 6'b00_00_00;     // PRESS ANY BUTTON, zwart
    else if (egg_on)     rgb = egg_rgb;
    else if (ground_on)  rgb = ground_shadow ? 6'b00_01_00 : 6'b00_10_00;
    else                 rgb = 6'b01_10_11;     // hemelsblauw
  end

  integer f, s, t, xi, yi;
  reg [8*32-1:0] fname;
  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1;

    for (s = 0; s < SHOTS; s = s + 1) begin
      // frame_tick op de NEGEDGE: de DUT sampelt op posedge, dus geen race
      for (t = 0; t < TICKS_PER_SHOT; t = t + 1) begin
        @(negedge clk); frame_tick = 1;
        @(negedge clk); frame_tick = 0;
      end

      $sformat(fname, "shot%02d.ppm", s);
      f = $fopen(fname, "w");
      $fwrite(f, "P3\n%0d %0d\n255\n", (X1-X0+1)/STEP, (Y1-Y0+1)/STEP);
      for (yi = Y0; yi <= Y1; yi = yi + STEP)
        for (xi = X0; xi <= X1; xi = xi + STEP) begin
          x = xi[9:0];
          y = yi[9:0];
          #1;
          $fwrite(f, "%0d %0d %0d\n", rgb[5:4]*85, rgb[3:2]*85, rgb[1:0]*85);
        end
      $fclose(f);
      $display("shot%02d.ppm klaar", s);
    end
    $finish;
  end
endmodule