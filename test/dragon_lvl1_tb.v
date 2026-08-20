`default_nettype none
`timescale 1ns/1ps

module dragon_lvl1_tb;

  reg        clk;
  reg        rst_n;
  reg  [9:0] pix_x, pix_y;
  wire [9:0] px = pix_y;
  wire [9:0] py = 10'd639 - pix_x;
  reg  [2:0] level;
  reg  [2:0] mood_anim;

  wire       px_on;
  wire [2:0] px_code;

  // Klokgeneratie: 25 MHz (periode 40 ns)
  always #20 clk = ~clk;

  // Instantieer de level 1 generator
  dragon_l1_generator u_dragon_lvl1 (
    .clk       (clk),
    .rst_n     (rst_n),
    .x         (px),
    .y         (py),
    .mood_anim (mood_anim),
    .px_on     (px_on),
    .px_code   (px_code)
  );

  // Kleurenpalet voor px_code (3-bit)
  reg [5:0] rgb;
  always @(*) begin
    case (px_code)
      3'd0: rgb = 6'b00_00_00; // Transparant / Achtergrond
      3'd1: rgb = 6'b00_00_00; // Zwart (Outlines)
      3'd2: rgb = 6'b10_10_10; // Grijs (Hoorns licht)
      3'd3: rgb = 6'b00_11_00; // Fel groen (Lichaam draak)
      3'd4: rgb = 6'b11_11_11; // Wit (Eierschaal / Oogreflectie)
      3'd5: rgb = 6'b00_10_00; // Donkergroen (Eivlekken / Schaduw)
      3'd6: rgb = 6'b01_01_01; // Donkergrijs (Hoorns schaduw)
      3'd7: rgb = 6'b10_11_01; // Lichtgroen / Geelgroen (Nekje & Buikje)
      default: rgb = 6'b00_00_00;
    endcase
  end

  integer f, xi, yi;
  integer count[0:7];
  integer k;

  initial begin
    // 1. Initialisatie en reset
    clk       = 0;
    rst_n     = 0;
    pix_x     = 0;
    pix_y     = 0;
    level     = 3'd1; 
    mood_anim = 3'd0; 

    for (k = 0; k < 8; k = k + 1) begin
      count[k] = 0;
    end

    #100;
    rst_n = 1;
    #40;

    $display("Starten van 640x480 dragon render test...");

    f = $fopen("frame.ppm", "w");
    $fwrite(f, "P3\n640 480\n255\n");

    // 2. Pixel voor pixel scannen
    for (yi = 0; yi < 480; yi = yi + 1) begin
      for (xi = 0; xi < 640; xi = xi + 1) begin
        @(negedge clk);
        pix_x = xi[9:0];
        pix_y = yi[9:0];

        @(posedge clk);
        #1; // Settling delay voor combinatorische paden

        // Houd telling bij van getekende pixels
        if (px_on) begin
          count[px_code] = count[px_code] + 1;
        end

        $fwrite(f, "%0d %0d %0d\n", rgb[5:4]*85, rgb[3:2]*85, rgb[1:0]*85);
      end
    end

    $fclose(f);
    $display("Test afgerond!");
    $display("Overzicht actieve pixels per kleurcode:");
    $display("  Code 0 (Transparant): %0d", count[0]);
    $display("  Code 1 (Zwart/Rand): %0d", count[1]);
    $display("  Code 2 (Grijs/Hoorn): %0d", count[2]);
    $display("  Code 3 (Felgroen):    %0d", count[3]);
    $display("  Code 4 (Wit):         %0d", count[4]);
    $display("  Code 5 (Donkergroen): %0d", count[5]);
    $display("  Code 6 (Donkergrijs): %0d", count[6]);
    $display("  Code 7 (Lichtgroen):  %0d", count[7]);
    $finish;
  end

endmodule