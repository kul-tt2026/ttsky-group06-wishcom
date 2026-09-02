`default_nettype none
// ---------------------------------------------------------------------------
// FEED_TB -- rendert lam + vlam over dragon_draw heen, voor 1 level per run.
// Level wordt gekozen via +LEVEL=<n> op de vvp-commandolijn (2, 4 of 7 om
// respectievelijk l2/l3/l4 te treffen, zie dragon_draw's mux-grenzen).
// ---------------------------------------------------------------------------
module feed_tb;
  reg clk = 0;
  always #5 clk = ~clk;

  reg  rst_n;
  reg  [2:0] level;
  reg  [9:0] px, py;
  reg  [6:0] fx_age;
  reg        active;

  // -- draak (gesynchroniseerd, 1 cyclus latency) --
  wire dragon_on;
  wire [2:0] dragon_code;
  dragon_draw u_draw (
    .clk(clk), .rst_n(rst_n), .x(px), .y(py), .level(level),
    .px_on(dragon_on), .px_code(dragon_code)
  );

  reg [5:0] sprite_rgb;
  always @(*) case (dragon_code)
    3'd1: sprite_rgb = 6'b00_00_00;
    3'd2: sprite_rgb = 6'b10_10_10;
    3'd3: sprite_rgb = 6'b00_11_00;
    3'd4: sprite_rgb = 6'b11_11_11;
    3'd5: sprite_rgb = 6'b00_10_00;
    3'd6: sprite_rgb = 6'b01_01_01;
    3'd7: sprite_rgb = 6'b10_11_01;
    default: sprite_rgb = 6'b00_00_00;
  endcase

  // -- feed effect (puur combinatorisch, geen clk nodig) --

  wire flame_on, lamb_on;
  wire [5:0] flame_rgb, lamb_rgb;
  feed_fx u_fx (
    .x(px), .y(py), .fx_age(fx_age), .active(active),
    .flame_on(flame_on), .flame_rgb(flame_rgb),
    .lamb_on(lamb_on), .lamb_rgb(lamb_rgb)
  );
  wire [5:0] rgb = flame_on           ? flame_rgb :
                    (dragon_on)       ? sprite_rgb   :
                    lamb_on           ? lamb_rgb     :
                                        6'b01_10_11;  // vlakke lucht

  integer fp, fx, fy, shot;
  reg [7:0] r8, g8, b8;

  task write_frame(input integer sh);
    reg [255:0] fname;
    begin
      $sformat(fname, "shot%03d.ppm", sh);
      fp = $fopen(fname, "wb");
      $fwrite(fp, "P6\n480 320\n255\n");
      for (fy = 0; fy < 320; fy = fy + 1) begin
        for (fx = 0; fx < 480; fx = fx + 1) begin
          px = fx[9:0];
          py = fy[9:0];
          @(posedge clk);
          #1;
          r8 = {rgb[5:4], rgb[5:4], rgb[5:4], rgb[5:4]};
          g8 = {rgb[3:2], rgb[3:2], rgb[3:2], rgb[3:2]};
          b8 = {rgb[1:0], rgb[1:0], rgb[1:0], rgb[1:0]};
          $fwrite(fp, "%c%c%c", r8, g8, b8);
        end
      end
      $fclose(fp);
    end
  endtask

  initial begin
    if (!$value$plusargs("LEVEL=%d", level))
      level = 3'd2;
    rst_n  = 1'b0;
    active = 1'b1;
    px = 10'd0; py = 10'd0; fx_age = 7'd0;
    @(posedge clk); @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    $display("feed_tb: level=%0d start", level);
    for (shot = 0; shot < 45; shot = shot + 1) begin
      fx_age = shot[6:0];
      write_frame(shot);
      if (shot % 10 == 0) $display("frame=%0d flame=%0d", shot, flame_on);
    end
    $display("feed_tb: klaar");
    $finish;
  end
endmodule