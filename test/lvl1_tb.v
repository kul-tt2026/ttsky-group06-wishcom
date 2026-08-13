`default_nettype none
`timescale 1ns/1ps

module egg_tb;

  reg  [9:0] pix_x, pix_y;
  wire [9:0] px = pix_y;
  wire [9:0] py = 10'd639 - pix_x;
  reg  [2:0] level;
  reg  [2:0] mood_anim;

  wire       px_on;
  wire [2:0] px_code;    // Zorg dat dit [2:0] is

  // Instantiateer de ei_generator module
  dragon_draw u_dragon_lvl1 (
    .x(px),
    .y(py),
    .level(level),
    .mood_anim(mood_anim),
    .px_on(px_on),
    .px_code(px_code)
  );

  // Kleurenpalet voor px_code (3-bit)

  // b01_11_01
  reg [5:0] rgb;
  always @(*) begin
    case (px_code)
      3'd0: rgb = 6'b00_00_00; // Uit / Zwart
      3'd1: rgb = 6'b00_00_00; // Zwart
      3'd2: rgb = 6'b11_11_11; // Medium groen
      3'd3: rgb = 6'b00_10_00; // Fel groen met een tikje rood/blauw
      3'd4: rgb = 6'b11_11_11; // Maximaal R, G en B
      3'd5: rgb = 6'b10_10_10; // Medium grijs
      3'd6: rgb = 6'b01_01_01; // Donkergrijs
      default: rgb = 6'b01_01_01; // Donkergrijs
    endcase
  end

  integer f, xi, yi;

  initial begin
    level     = 3'd3; 
    mood_anim = 2'd0; 

    $display("Starten van 640x480 ei_generator render test...");

    f = $fopen("frame.ppm", "w");
    $fwrite(f, "P3\n640 480\n255\n");

    for (yi = 0; yi < 480; yi = yi + 1) begin
      for (xi = 0; xi < 640; xi = xi + 1) begin
        pix_x = xi[9:0];
        pix_y = yi[9:0];

        #1;

        // Print ALLEEN als de kleurcode 4 (WIT) is!
        if (px_on && px_code == 3'd4) begin
            $display("HOERA! Wit pixel gevonden op (%0d,%0d) -> px_code = %0d", xi, yi, px_code);
        end
        // ----------------------------------

        $fwrite(f, "%0d %0d %0d\n", rgb[5:4]*85, rgb[3:2]*85, rgb[1:0]*85);
      end
    end

    $fclose(f);
    $display("Test afgerond!");
    $finish;
  end

endmodule