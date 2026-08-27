`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// RENDER_TB -- fotohokje voor de HELE renderer.
//
// Instantieert renderer.v zelf, dus wat je hier ziet is exact wat op het
// scherm komt.  Geen gedupliceerde paletten meer die uit de pas gaan lopen.
//
//   cd src
//   iverilog -g2012 -s render_tb -o ../sim ../test/render_tb.v *.v
//   vvp ../sim
//   python3 -c "from PIL import Image; Image.open('frame.ppm').save('frame.png')"
//
// De PPM wordt AL IN PORTRET weggeschreven (480 x 640), dus je hoeft niet
// meer te roteren in PIL.
//
// Er is een klok (title_egg hopt, dragon_draw heeft geregistreerde uitgangen)
// maar frame_tick blijft laag: alle tellers staan op hun resetwaarde, dus je
// krijgt een reproduceerbaar stilstaand beeld.  Animatie testen doe je met
// egg_tb.v.
// ---------------------------------------------------------------------------
module render_tb;

  // ======================= WAT WIL JE ZIEN ================================
  localparam [2:0] MODE = 3'd4;    // 0 TITLE  1 EGG  2 HOME  3 CHEST
                                   // 4 GAMEOVER  5 YOU_WIN
  localparam       STEP = 1;       // 1 = vol, 2 of 4 = snel itereren

  // stand van het spel (alleen relevant voor de gekozen mode)
  localparam [2:0] SET_HEARTS  = 3'd3;
  localparam [2:0] SET_SAT     = 3'd2;
  localparam [9:0] SET_COINS   = 10'd347;
  localparam [2:0] SET_LEVEL   = 3'd2;
  localparam       SET_OVERFL  = 1'b0;
  localparam       SET_EVOLVE  = 1'b1;   // evolve_now: knop mag oplichten

  // minigame
  localparam [1:0] SET_CSTATE  = 2'd0;   // 0 PICK  1 OPEN  2 RESULT  3 MENU
  localparam [1:0] SET_CSEL    = 2'd1;
  localparam [8:0] SET_CONTENT = 9'b010_001_100;   // {kist2, kist1, kist0}
  localparam [9:0] SET_POT     = 10'd160;
  localparam [3:0] SET_ROUND   = 4'd2;

  // ei / flits (alleen zichtbaar in mode EGG)
  localparam [2:0] SET_EGGFR   = 3'd3;   // 0 heel .. 4 wijd open
  localparam [9:0] SET_FLASHR  = 10'd0;  // 0 = flits uit

  localparam [7:0] SET_BTN_LEVEL = 8'b0010_0000;

  // ======================= aandrijving ====================================
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #20 clk = ~clk;               // 25 MHz

  reg [9:0] pix_x = 10'd0, pix_y = 10'd0;

  wire [1:0] R, G, B;

  renderer dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .pix_x          (pix_x),
    .pix_y          (pix_y),
    .video_active   (1'b1),

    .mode           (MODE),
    .menu_sel       (3'd0),
    .hearts         (SET_HEARTS),
    .satisfaction   (SET_SAT),
    .coins          (SET_COINS),
    .level          (SET_LEVEL),

    .evolve_now     (SET_EVOLVE),
    .combo_len      (2'd0),

    .chest_frame    (2'd0),
    .chest_state    (SET_CSTATE),
    .chest_sel      (SET_CSEL),
    .chest_outcome  (3'd0),

    .dragon_mood_anim (3'd0),
    .flash          (1'b0),
    .flame_frame    (1'b0),
    .evolve_blink   (1'b1),

    .frame_tick     (1'b0),           // geen animatie: stilstaand frame

    .overflow       (SET_OVERFL),
    .chest_contents (SET_CONTENT),
    .pot            (SET_POT),
    .round          (SET_ROUND),
    .egg_frame      (SET_EGGFR),
    .flash_r        (SET_FLASHR),
    .btn_level      (SET_BTN_LEVEL),

    .R(R), .G(G), .B(B)
  );

  // ======================= afvegen ========================================
  // Het scherm is fysiek 640x480 liggend, maar wij tekenen in portret.
  // De renderer rekent px = pix_y en py = 639 - pix_x, dus om portret-pixel
  // (px, py) te raken zetten we pix_y = px en pix_x = 639 - py.
  integer f, ppx, ppy;

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);

    f = $fopen("frame.ppm", "w");
    $fwrite(f, "P3\n%0d %0d\n255\n", 480/STEP, 640/STEP);

    for (ppy = 0; ppy < 640; ppy = ppy + STEP) begin
      for (ppx = 0; ppx < 480; ppx = ppx + STEP) begin
        pix_y = ppx[9:0];
        pix_x = 10'd639 - ppy[9:0];
        @(posedge clk);        // geregistreerde drawables (draak) bijwerken
        #1;
        $fwrite(f, "%0d %0d %0d\n", R*85, G*85, B*85);
      end
      if (ppy % 64 == 0) $display("rij %0d / 640", ppy);
    end

    $fclose(f);
    $display("klaar -> frame.ppm  (mode %0d)", MODE);
    $finish;
  end
endmodule