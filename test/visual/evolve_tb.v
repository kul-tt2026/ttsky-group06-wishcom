`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// EVOLVE_TB -- gif van de evolutie: de oude vorm knippert, de flits groeit
// vanuit het midden van de draak, en de nieuwe vorm komt eruit.
//
//   cd src
//   rm -f shot*.ppm
//   iverilog -g2012 -s evolve_tb -o /tmp/et ../test/evolve_tb.v *.v
//   vvp /tmp/et +FROM=2 +TO=4
//   python3 ../test/ppm2gif.py 33
//   mv egg_anim.gif ../test/evolve_2_4.gif && rm shot*.ppm
//
//   +FROM  het level VOOR de evolutie   (1..2 = l2, 3..6 = l3, 7 = l4)
//   +TO    het level ERNA
//
// TICKS_PER_SHOT = 2 videoframes = 33 ms, dus `ppm2gif.py 33` is ware
// snelheid.  De hele reeks duurt EVO_LEN = 60 frames = 1 s.
//
// LET OP -- DEZE TESTBENCH GEBRUIKT renderer.v NIET.
// Hij instantieert alleen anim en dragon_draw, en tekent de achthoek zelf.
// Wijzigingen in renderer.v (fl_cx / fl_cy / fl_r) hebben hier dus GEEN
// effect; die zie je pas op het echte scherm.  Stem het middelpunt hier met
// +CX= en +CY=, en zet de waarde die je mooi vindt daarna over naar
// renderer.v.
// ---------------------------------------------------------------------------
module evolve_tb;
  localparam SHOTS          = 40;     // 40 * 2 = 80 frames, ruim de 60 van EVO_LEN
  localparam TICKS_PER_SHOT = 2;
  localparam STEP           = 2;

  localparam [9:0] RIM = 10'd12;
  // middelpunt van de flits -- instelbaar met +CX= en +CY=
  //   CX loopt over de 480 px brede kant (240 = midden)
  //   CY loopt over de 640 px hoge kant  (236 = midden van de draak)
  reg [9:0] EVO_CX, EVO_CY;

  reg clk = 1'b0;
  always #20 clk = ~clk;

  reg rst_n, frame_tick, evolved;
  reg [2:0] lvl_from, lvl_to, level;
  reg [9:0] px, py;

  wire night, flash, evolve_blink, fx_on, evo_on;
  wire [1:0] dragon_bob, fx_kind;
  wire [6:0] fx_age;
  wire [9:0] evo_r;
  wire [2:0] level_shown;
  anim u_anim (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick), .restart(1'b0),
    .satisfaction(3'd4),
    .act_feed(1'b0), .act_drink(1'b0), .act_sleep(1'b0), .wake(1'b0),
    .evolved(evolved), .level(level),
    .night(night), .dragon_bob(dragon_bob), .flash(flash),
    .evolve_blink(evolve_blink), .level_shown(level_shown),
    .fx_kind(fx_kind), .fx_on(fx_on), .fx_age(fx_age),
    .evo_on(evo_on), .evo_r(evo_r)
  );

  wire       dragon_on;
  wire [2:0] dragon_code;
  dragon_draw u_draw (
    .clk(clk), .rst_n(rst_n), .x(px), .y(py),
    .dragon_bob(dragon_bob), .level(level_shown),
    .px_on(dragon_on), .px_code(dragon_code)
  );

  reg [5:0] sprite_rgb;
  always @(*) case (dragon_code)
    3'd1: sprite_rgb = 6'b00_00_00;   3'd2: sprite_rgb = 6'b10_10_10;
    3'd3: sprite_rgb = 6'b00_11_00;   3'd4: sprite_rgb = 6'b11_11_11;
    3'd5: sprite_rgb = 6'b00_10_00;   3'd6: sprite_rgb = 6'b01_01_01;
    3'd7: sprite_rgb = 6'b10_11_01;   default: sprite_rgb = 6'b00_00_00;
  endcase

  // ---- de achthoek, zoals renderer.v hem moet tekenen -------------------
  wire [9:0] fdx = (px >= EVO_CX) ? (px - EVO_CX) : (EVO_CX - px);
  wire [9:0] fdy = (py >= EVO_CY) ? (py - EVO_CY) : (EVO_CY - py);
  wire [9:0] fmx = (fdx > fdy) ? fdx : fdy;
  wire [9:0] fmn = (fdx > fdy) ? fdy : fdx;
  wire [9:0] fd  = fmx + (fmn >> 1);
  wire flash_on  = (evo_r != 10'd0) && (fd <= evo_r);
  wire flash_rim = flash_on && (fd + RIM > evo_r);

  // ---- STACK: flits boven de draak; `flash` knippert de oude vorm weg ----
  wire [5:0] bg = (py >= 10'd294) ? 6'b00_10_00 : 6'b01_10_11;
  reg  [5:0] rgb;
  always @(*) begin
    if      (flash_on)            rgb = flash_rim ? 6'b11_00_00 : 6'b11_10_00;
    else if (dragon_on && !flash) rgb = sprite_rgb;   // flash=1 -> draak weg
    else                          rgb = bg;
  end

  integer fp, fx, fy, s, t, frame_no;
  reg [8*32-1:0] fname;
  reg [7:0] r8, g8, b8;

  task tick;
    begin
      // op frame 4 evolueren: dragon_state zet level om en pulst `evolved`
      if (frame_no == 4) begin evolved = 1'b1; level = lvl_to; end
      @(negedge clk); frame_tick = 1'b1;
      @(negedge clk); frame_tick = 1'b0;
      evolved = 1'b0;
      frame_no = frame_no + 1;
    end
  endtask

  initial begin
    if (!$value$plusargs("FROM=%d", lvl_from)) lvl_from = 3'd2;
    if (!$value$plusargs("TO=%d",   lvl_to))   lvl_to   = 3'd3;
    if (!$value$plusargs("CX=%d",   EVO_CX))   EVO_CX   = 10'd240;
    if (!$value$plusargs("CY=%d",   EVO_CY))   EVO_CY   = 10'd236;
    rst_n = 1'b0; frame_tick = 1'b0; evolved = 1'b0;
    level = lvl_from; px = 10'd0; py = 10'd0; frame_no = 0;
    repeat (4) @(posedge clk); rst_n = 1'b1; repeat (4) @(posedge clk);
    $display("evolve_tb: van level %0d naar %0d, flits op (%0d,%0d)",
             lvl_from, lvl_to, EVO_CX, EVO_CY);
    $display("           (deze testbench gebruikt renderer.v NIET)");

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
      $display("  shot%03d frame=%0d evo_on=%b r=%0d flash=%b toont level %0d",
               s, frame_no, evo_on, evo_r, flash, level_shown);
    end
    $display("evolve_tb: klaar");
    $finish;
  end
endmodule
