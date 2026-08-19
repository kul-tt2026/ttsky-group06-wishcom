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

  // Instantie van dragon_draw (of direct dragon_l1_generator)
  // Instantieer direct de l1 generator
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
      3'd0: rgb = 6'b00_00_00; // Transparant / Zwart
      3'd1: rgb = 6'b00_00_00; // Zwart (Outline)
      3'd2: rgb = 6'b00_10_00; // Donkergroen (Vlekken)
      3'd3: rgb = 6'b01_11_01; // Felgroen (Lijfje)
      3'd4: rgb = 6'b11_11_11; // Wit (Eierschaal)
      3'd5: rgb = 6'b10_10_10; // Grijs
      3'd6: rgb = 6'b01_01_01; // Donkergrijs
      3'd7: rgb = 6'b01_11_01; // Lichtgroen (Buikje)
      default: rgb = 6'b00_00_00;
    endcase
  end

  integer f, xi, yi;

  initial begin
    // 1. Initialiseer signalen en voer reset uit
    clk       = 0;
    rst_n     = 0;
    pix_x     = 0;
    pix_y     = 0;
    level     = 3'd3; 
    mood_anim = 3'd0; 

    #100;
    rst_n = 1; // Reset loslaten
    #40;

    $display("Starten van 640x480 dragon render test...");

    f = $fopen("frame.ppm", "w");
    $fwrite(f, "P3\n640 480\n255\n");

    // 2. Render pixel voor pixel gesynchroniseerd met de klok
    for (yi = 0; yi < 480; yi = yi + 1) begin
      for (xi = 0; xi < 640; xi = xi + 1) begin
        pix_x = xi[9:0];
        pix_y = yi[9:0];

        // Wacht op de opgaande en neergaande flank zodat de geregistreerde pixel stabiel is
        @(posedge clk);
        @(negedge clk);

        $fwrite(f, "%0d %0d %0d\n", rgb[5:4]*85, rgb[3:2]*85, rgb[1:0]*85);
      end
    end

    $fclose(f);
    $display("Test afgerond!");
    $finish;
  end

endmodule