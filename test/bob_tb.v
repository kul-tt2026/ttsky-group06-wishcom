`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// BOB_TB -- gif van de idle-wip van de draak, per level en per humeur.
//
//   cd src
//   rm -f shot*.ppm
//   iverilog -g2012 -s bob_tb -o /tmp/bt ../test/bob_tb.v *.v
//   vvp /tmp/bt +LEVEL=2 +SAT=4
//   python3 ../test/ppm2gif.py 50
//   mv egg_anim.gif ../test/bob_l2_s4.gif && rm shot*.ppm
//
//   +LEVEL   1..2 -> l2,  3..6 -> l3,  7 -> l4   (zie de mux in dragon_draw)
//   +SAT     0 stilstand, 1 traag .. 4 snel      (zie total_cycle in anim.v)
//   +FEED=n  druk op frame n op voeren; zo zie je of de draak eerst LANDT
//            voordat de vlam vertrekt.  Weglaten = alleen wippen.
//
// TICKS_PER_SHOT = 3 videoframes = 50 ms, dus `ppm2gif.py 50` loopt op ware
// snelheid.  SHOTS * 3 frames moet lang genoeg zijn voor een hele wipcyclus:
// bij SAT=1 duurt die 150 frames, dus 60 shots dekt hem net.
// ---------------------------------------------------------------------------
module bob_tb;
  localparam SHOTS          = 60;
  localparam TICKS_PER_SHOT = 3;
  localparam STEP           = 2;      // 240x320 preview; 1 voor volle resolutie

  reg clk = 1'b0;
  always #20 clk = ~clk;              // 25 MHz

  reg rst_n, frame_tick;
  reg [2:0] level, sat;
  reg [9:0] px, py;
  reg act_feed;
  integer feed_at;

  // ---- anim levert dragon_bob ------------------------------------------
  wire night, flash, evolve_blink, fx_on, evo_on;
  wire [1:0] fx_kind;
  wire [6:0] fx_age;
  wire [9:0] evo_r;
  wire [2:0] level_shown;
  wire [2:0] dragon_bob;
  anim u_anim (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick), .restart(1'b0),
    .satisfaction(sat),
    .act_feed(act_feed), .act_drink(1'b0), .act_sleep(1'b0), .wake(1'b0),
    .evolved(1'b0), .level(level),
    .night(night), .dragon_bob(dragon_bob), .flash(flash),
    .evolve_blink(evolve_blink), .level_shown(level_shown),
    .fx_kind(fx_kind), .fx_on(fx_on), .fx_age(fx_age),
    .evo_on(evo_on), .evo_r(evo_r)
  );

  // ---- de draak --------------------------------------------------------
  wire       dragon_on;
  wire [2:0] dragon_code;
  dragon_draw u_draw (
    .clk(clk), .rst_n(rst_n), .x(px), .y(py),
    .dragon_bob(dragon_bob), .level(level_shown),
    .px_on(dragon_on), .px_code(dragon_code)
  );

  // palet exact zoals renderer.v
  reg [5:0] sprite_rgb;
  always @(*) case (dragon_code)
    3'd1: sprite_rgb = 6'b00_00_00;   3'd2: sprite_rgb = 6'b10_10_10;
    3'd3: sprite_rgb = 6'b00_11_00;   3'd4: sprite_rgb = 6'b11_11_11;
    3'd5: sprite_rgb = 6'b00_10_00;   3'd6: sprite_rgb = 6'b01_01_01;
    3'd7: sprite_rgb = 6'b10_11_01;   default: sprite_rgb = 6'b00_00_00;
  endcase

  // ---- het voer-effect, zodat je de landing kan zien -------------------
  wire       feed_on;
  wire [5:0] feed_rgb;
  feed_fx u_feed (
    .x(px), .y(py), .fx_age(fx_age),
    .active(fx_on && (fx_kind == 2'd1)),
    .feed_on(feed_on), .feed_rgb(feed_rgb)
  );

  wire [5:0] bg  = (py >= 10'd294) ? 6'b00_10_00 : 6'b01_10_11;
  wire [5:0] rgb = feed_on   ? feed_rgb   :
                   dragon_on ? sprite_rgb : bg;

  integer fp, fx, fy, s, t, frame_no;
  reg [8*32-1:0] fname;
  reg [7:0] r8, g8, b8;

  task tick;
    begin
      act_feed = (feed_at >= 0) && (frame_no == feed_at);
      @(negedge clk); frame_tick = 1'b1;
      @(negedge clk); frame_tick = 1'b0;
      act_feed = 1'b0;
      frame_no = frame_no + 1;
    end
  endtask

  initial begin
    if (!$value$plusargs("LEVEL=%d", level)) level = 3'd2;
    if (!$value$plusargs("SAT=%d",   sat))   sat   = 3'd4;
    if (!$value$plusargs("FEED=%d",  feed_at)) feed_at = -1;
    rst_n = 1'b0; frame_tick = 1'b0; act_feed = 1'b0;
    px = 10'd0; py = 10'd0; frame_no = 0;
    repeat (4) @(posedge clk); rst_n = 1'b1; repeat (4) @(posedge clk);
    $display("bob_tb: level=%0d satisfaction=%0d feed_at=%0d", level, sat, feed_at);

    for (s = 0; s < SHOTS; s = s + 1) begin
      for (t = 0; t < TICKS_PER_SHOT; t = t + 1) tick;

      $sformat(fname, "shot%03d.ppm", s);
      fp = $fopen(fname, "w");
      $fwrite(fp, "P3\n%0d %0d\n255\n", 480/STEP, 640/STEP);
      for (fy = 0; fy < 640; fy = fy + STEP)
        for (fx = 0; fx < 480; fx = fx + STEP) begin
          px = fx[9:0]; py = fy[9:0];
          @(posedge clk); #1;
          r8 = {rgb[5:4],rgb[5:4],rgb[5:4],rgb[5:4]};
          g8 = {rgb[3:2],rgb[3:2],rgb[3:2],rgb[3:2]};
          b8 = {rgb[1:0],rgb[1:0],rgb[1:0],rgb[1:0]};
          $fwrite(fp, "%0d %0d %0d\n", r8, g8, b8);
        end
      $fclose(fp);
      $display("  shot%03d  frame=%0d  bob=%0d  fx_on=%b fx_kind=%0d",
               s, frame_no, dragon_bob, fx_on, fx_kind);
    end
    $display("bob_tb: klaar, %0d beelden", SHOTS);
    $finish;
  end
endmodule