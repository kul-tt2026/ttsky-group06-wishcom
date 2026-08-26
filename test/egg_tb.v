`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// TITELSCHERM-ANIMATIE, met de ECHTE home.v erin.
//
// Tijdlijn: PRESS_AT frames titelscherm, dan een knopdruk van een frame, dan
// het barsten en de flits -- allemaal aangestuurd door home.v zelf, niet door
// met de hand verzonnen waarden.  Zo test je meteen het contract tussen home
// en title_egg.
//
//   cd src
//   rm -f shot*.ppm
//   iverilog -g2012 -s egg_tb -o ../sim ../test/egg_tb.v title_egg.v title_card.v home.v
//   vvp ../sim
//   python3 ../test/ppm2gif.py 50
//
// SNELHEID: TICKS_PER_SHOT = 3 videoframes = 50 ms, dus `ppm2gif.py 50` loopt
// op ware snelheid.  Wil je 100 ms per beeld, zet TICKS_PER_SHOT op 6 en geef
// ppm2gif geen argument.
//
// PRESS_AT = 192 is precies twee hopcycli (2 x 96), dus de druk valt op het
// moment dat het ei op de grond staat.  Zet hem op 228 om te zien of het ei
// zijn boog afmaakt als je midden in de lucht drukt.
// ---------------------------------------------------------------------------
module egg_tb;
  localparam SHOTS          = 132;   // 132 * 3 = 396 frames: dekt de hele reeks
  localparam TICKS_PER_SHOT = 3;     // 3 frames = 50 ms
  localparam STEP           = 2;     // 240x320; 1 voor de eindversie
  localparam PRESS_AT       = 192;   // na twee volle hopcycli

  localparam Y0 = 0, Y1 = 639;       // hele portretscherm
  localparam X0 = 0, X1 = 479;

  reg clk = 1'b0, rst_n = 1'b0, frame_tick = 1'b0;
  reg [7:0] btn_pressed = 8'd0;
  reg [9:0] x, y;

  always #20 clk = ~clk;             // 25 MHz -- ZONDER DIT GEBEURT ER NIETS

  // ---- de echte mode-machine ----------------------------------------------
  wire [2:0] mode, egg_frame;
  wire [9:0] flash_r;
  home u_home (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .btn_pressed(btn_pressed),
    .game_over(1'b0), .you_win(1'b0), .minigame_done(1'b0), .coins(10'd0),
    .mode(mode), .egg_frame(egg_frame), .flash_r(flash_r)
  );

  // ---- de drawables --------------------------------------------------------
  wire       egg_on, crack_on, flash_on, flash_rim, press_on;
  wire       ground_on, ground_shadow;
  wire [2:0] egg_code;
  title_egg u_egg (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .x(x), .y(y),
    .egg_frame(egg_frame), .flash_r(flash_r),
    .egg_on(egg_on), .egg_code(egg_code),
    .crack_on(crack_on),
    .flash_on(flash_on), .flash_rim(flash_rim),
    .press_on(press_on),
    .ground_on(ground_on), .ground_shadow(ground_shadow)
  );

  wire       title_on;
  wire [2:0] title_code;
  title_card u_title (.x(x), .y(y), .px_on(title_on), .px_code(title_code));

  // ---- paletten: exact zoals renderer.v ------------------------------------
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

  // ---- STACK: exact de cascade uit renderer.v ------------------------------
  reg [5:0] rgb;
  always @(*) begin
    if      (mode > 3'd1) rgb = 6'b00_00_00;   // HOME bereikt: einde animatie
    else if (flash_on)    rgb = flash_rim ? 6'b11_00_00 : 6'b11_10_00;
    else if (title_on)    rgb = title_rgb;
    else if (crack_on)    rgb = 6'b00_00_00;   // barst BOVEN het ei
    else if (egg_on)      rgb = egg_rgb;
    else if (press_on && (mode == 3'd0)) rgb = 6'b00_00_00;
    else if (ground_on)   rgb = ground_shadow ? 6'b00_01_00 : 6'b00_10_00;
    else                  rgb = 6'b01_10_11;   // hemelsblauw
  end

  // ---- aandrijving ---------------------------------------------------------
  integer f, s, t, xi, yi, frame_no;
  reg [8*32-1:0] fname;

  task tick;                          // een videoframe, met de knop indien nodig
    begin
      if (frame_no == PRESS_AT) btn_pressed = 8'b1000_0000;   // knop 7 = PLAY
      // frame_tick op de NEGEDGE: de DUT sampelt op posedge, dus geen race
      @(negedge clk); frame_tick = 1'b1;
      @(negedge clk); frame_tick = 1'b0;
      btn_pressed = 8'd0;
      frame_no = frame_no + 1;
    end
  endtask

  initial begin
    frame_no = 0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);

    for (s = 0; s < SHOTS; s = s + 1) begin
      for (t = 0; t < TICKS_PER_SHOT; t = t + 1) tick;

      $sformat(fname, "shot%03d.ppm", s);      // %03d: er zijn er meer dan 100
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
      $display("shot%03d  frame=%0d  mode=%0d  egg_frame=%0d  flash_r=%0d",
               s, frame_no, mode, egg_frame, flash_r);
    end

    $display("klaar -- %0d beelden", SHOTS);
    $finish;
  end
endmodule