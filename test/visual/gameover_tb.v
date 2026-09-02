`default_nettype none
`timescale 1ns/1ps

module home_tb;

  reg        clk;
  reg        rst_n;
  reg  [9:0] pix_x, pix_y;
  reg        video_active;

  // Signalen tussen home.v en renderer.v
  wire [2:0] mode;
  wire [2:0] menu_sel;
  wire       act_feed, act_drink, act_sleep, act_minigame, req_evolve, restart;

  // Interne signalen voor home.v
  reg        frame_tick;
  reg  [7:0] btn_pressed;
  reg        game_over;
  reg        you_win;
  reg        minigame_done;

  // Signalen specifiek voor jouw renderer.v interface
  reg  [2:0] hearts;
  reg  [2:0] satisfaction;
  reg  [9:0] coins;
  reg  [2:0] level;
  reg        evolve_now;
  reg  [1:0] combo_len;
  reg  [1:0] chest_frame;
  reg  [1:0] chest_state;
  reg  [1:0] chest_sel;
  reg  [2:0] chest_outcome;
  reg  [2:0] dragon_mood_anim;
  reg        flash;
  reg        flame_frame;
  reg        overflow;

  // Output RGB van de renderer (2-bit per kleur)
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  // 25 MHz klokgeneratie (periode 40 ns)
  always #20 clk = ~clk;

  // 1. Instantieer home.v
  home u_home (
    .clk           (clk),
    .rst_n         (rst_n),
    .frame_tick    (frame_tick),
    .btn_pressed   (btn_pressed),
    .game_over     (game_over),
    .you_win       (you_win),
    .minigame_done (minigame_done),
    .coins         (coins),
    .mode          (mode),
    .menu_sel      (menu_sel),
    .act_feed      (act_feed),
    .act_drink     (act_drink),
    .act_sleep     (act_sleep),
    .act_minigame  (act_minigame),
    .req_evolve    (req_evolve),
    .restart       (restart)
  );

  // 2. Instantieer jouw renderer.v
  renderer u_renderer (
    .clk              (clk),
    .rst_n            (rst_n),
    .pix_x            (pix_x),
    .pix_y            (pix_y),
    .video_active     (video_active),
    .mode             (mode),
    .menu_sel         (menu_sel),
    .hearts           (hearts),
    .satisfaction     (satisfaction),
    .coins            (coins),
    .level            (level),
    .evolve_now       (evolve_now),
    .combo_len        (combo_len),
    .chest_frame      (chest_frame),
    .chest_state      (chest_state),
    .chest_sel        (chest_sel),
    .chest_outcome    (chest_outcome),
    .dragon_mood_anim (dragon_mood_anim),
    .flash            (flash),
    .flame_frame      (flame_frame),
    .overflow         (overflow),
    .R                (R),
    .G                (G),
    .B                (B)
  );

  integer f, xi, yi;

  initial begin
    // Signalen initialiseren
    clk              = 0;
    rst_n            = 0;
    pix_x            = 0;
    pix_y            = 0;
    video_active     = 1'b1;
    frame_tick       = 0;
    btn_pressed      = 8'd0;
    game_over        = 1;
    you_win          = 0;
    minigame_done    = 0;

    // Dummy waarden voor HUD/status
    coins            = 10'd40;
    level            = 3'd1;        // Level 4 (voor je nieuwe 48x48 sprite)
    hearts           = 3'd1;
    satisfaction     = 3'd1;
    evolve_now       = 1'b0;
    combo_len        = 2'd0;
    chest_frame      = 2'd0;
    chest_state      = 2'd0;
    chest_sel        = 2'd0;
    chest_outcome    = 3'd0;
    dragon_mood_anim = 3'd0;
    flash            = 1'b0;
    flame_frame      = 1'b0;
    overflow         = 1'b0;

    #100;
    rst_n = 1; // Reset loslaten (begint in M_TITLE)
    #40;

    // 1. Druk op een knop om van M_TITLE naar M_HOME te gaan
    @(posedge clk);
    frame_tick  = 1'b1;
    btn_pressed = 8'b0001_0000;
    @(posedge clk);
    frame_tick  = 1'b0;
    btn_pressed = 8'd0;

    #40;

    // 2. Extra tick zodat home.v de 'game_over = 1' registreert en naar M_GAMEOVER springt
    @(posedge clk);
    frame_tick  = 1'b1;
    @(posedge clk);
    frame_tick  = 1'b0;

    force mode = 3'd4;
    if (mode !== 3'd4) $fatal(1, "Verkeerde mode voor game-over-render: %0d", mode);
    $display("Mode gezet op: %0d (4 = M_GAMEOVER)", mode);
    
    f = $fopen("frame.ppm", "w");
    $fwrite(f, "P3\n640 480\n255\n");

    // Loop door alle pixels
    for (yi = 0; yi < 480; yi = yi + 1) begin
      for (xi = 0; xi < 640; xi = xi + 1) begin
        pix_x = xi[9:0];
        pix_y = yi[9:0];

        @(posedge clk);
        @(negedge clk);

        // 2-bit R, G, B converteren naar 0-255 schaal (0, 85, 170, 255)
        $fwrite(f, "%0d %0d %0d\n", R * 85, G * 85, B * 85);
      end
    end

    $fclose(f);
    $display("Render klaar! frame.ppm gegenereerd.");
    $finish;
  end

endmodule