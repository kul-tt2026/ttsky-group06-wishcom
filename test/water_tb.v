`default_nettype none
// ---------------------------------------------------------------------------
// WATER_TB -- rendert de DRINK-animatie als PPM-reeks, over de draak heen,
// voor 1 level per run.  Level kies je met +LEVEL=<n> (2, 4 of 7 raken
// respectievelijk l2, l3 en l4, zie de mux in dragon_draw).
//
//   cd test
//   iverilog -g2012 -o /tmp/wtb water_tb.v ../src/*.v
//   cd ../src && vvp /tmp/wtb +LEVEL=2 && python3 ../test/ppm2gif.py
//   mv egg_anim.gif ../test/lvl2_water.gif && rm shot*.ppm
// ---------------------------------------------------------------------------
module water_tb;
  reg clk = 1'b0;
  always #5 clk = ~clk;

  reg rst_n;
  reg [2:0] level;
  reg [9:0] px, py;
  reg [6:0] fx_age;
  reg       active;

  // -- de draak (gesynchroniseerd, dus 1 klokflank per pixel) --
  wire dragon_on;
  wire [2:0] dragon_code;
  dragon_draw u_draw (
  .clk(clk), .rst_n(rst_n), .x(px), .y(py), .level(level),
  .dragon_bob(2'd0),                          // <-- erbij
  .px_on(dragon_on), .px_code(dragon_code)
);
  

  reg [5:0] sprite_rgb;
  always @(*) case (dragon_code)
    3'd1: sprite_rgb = 6'b00_00_00;   3'd2: sprite_rgb = 6'b10_10_10;
    3'd3: sprite_rgb = 6'b00_11_00;   3'd4: sprite_rgb = 6'b11_11_11;
    3'd5: sprite_rgb = 6'b00_10_00;   3'd6: sprite_rgb = 6'b01_01_01;
    3'd7: sprite_rgb = 6'b10_11_01;   default: sprite_rgb = 6'b00_00_00;
  endcase

  // -- het watereffect (puur combinatorisch) --
  wire water_on;
  wire [5:0] water_rgb;
  water_fx u_water (
    .x(px), .y(py), .fx_age(fx_age), .active(active),
    .water_on(water_on), .water_rgb(water_rgb)
  );

  // laagvolgorde zoals in renderer.v: water OVER de draak
  wire [5:0] bg  = (py >= 10'd294) ? 6'b00_10_00 : 6'b01_10_11;
  wire [5:0] rgb = water_on  ? water_rgb  :
                   dragon_on ? sprite_rgb : bg;

  integer fp, fx, fy, shot;
  reg [7:0] r8, g8, b8;
  reg [255:0] fname;

  initial begin
    if (!$value$plusargs("LEVEL=%d", level)) level = 3'd2;
    rst_n = 1'b0; active = 1'b1;
    px = 10'd0; py = 10'd0; fx_age = 7'd0;
    @(posedge clk); @(posedge clk); rst_n = 1'b1; @(posedge clk);

    $display("water_tb: level=%0d", level);
    for (shot = 0; shot < 30; shot = shot + 1) begin
      fx_age = shot[6:0];
      $sformat(fname, "shot%03d.ppm", shot);
      fp = $fopen(fname, "wb");
      $fwrite(fp, "P6\n480 320\n255\n");
      for (fy = 0; fy < 320; fy = fy + 1)
        for (fx = 0; fx < 480; fx = fx + 1) begin
          px = fx[9:0]; py = fy[9:0];
          @(posedge clk); #1;
          r8 = {rgb[5:4],rgb[5:4],rgb[5:4],rgb[5:4]};
          g8 = {rgb[3:2],rgb[3:2],rgb[3:2],rgb[3:2]};
          b8 = {rgb[1:0],rgb[1:0],rgb[1:0],rgb[1:0]};
          $fwrite(fp, "%c%c%c", r8, g8, b8);
        end
      $fclose(fp);
      if (shot % 5 == 0) $display("  frame %0d", shot);
    end
    $display("water_tb: klaar, 30 frames");
    $finish;
  end
endmodule