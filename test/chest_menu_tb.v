`default_nettype none
`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// CHEST MENU RENDER-TESTBENCH
//
// Zelfde opzet als home_lvl1_tb.v: home.v + renderer.v instantieren, in de
// juiste toestand zetten en daarna 1 volledig 640x480 frame naar frame.ppm
// schrijven.  Verschil: hier renderen we het KISTEN-scherm in de MENU-fase
// (chest_state == 3), dus na een geopende kist met een pot in de wacht.
//
// De chest_* signalen worden hier -- net als in de home_*_tb's -- met de hand
// gezet i.p.v. door chest_game.v gedreven, zodat je exact de frame kan kiezen
// die je wil zien.
// ---------------------------------------------------------------------------
module chest_menu_tb;

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

  // Signalen voor de renderer.v interface
  reg  [2:0] hearts;
  reg  [2:0] satisfaction;
  reg  [9:0] coins;
  reg  [2:0] level;
  reg        evolve_now;
  reg  [1:0] combo_len;
  reg  [1:0] chest_state;
  reg  [1:0] chest_sel;
  reg  [2:0] chest_outcome;
  reg  [8:0] chest_contents;
  reg  [9:0] pot;
  reg  [3:0] round;
  reg  [1:0] egg_frame;
  reg  [2:0] dragon_mood_anim;
  reg        flash;
  reg        flame_frame;
  reg        overflow;

  // LET OP: home.v en renderer.v gebruiken (nog) een andere nummering voor de
  // modes -- home.v: M_CHEST = 3'd2, renderer.v: M_CHEST = 3'd3.  Daarom voedt
  // deze bench de renderer met een eigen render_mode i.p.v. rechtstreeks met
  // mode van home.v.  Zodra beide lijstjes gelijk zijn, mag je hieronder
  // gewoon .mode(mode) aansluiten.
  localparam [2:0] R_M_CHEST = 3'd3;   // M_CHEST zoals renderer.v hem kent
  localparam [1:0] C_MENU    = 2'd3;   // chest_state MENU zoals chest_game.v hem kent
  reg  [2:0] render_mode;

  // Output RGB van de renderer (2-bit per kleur)
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  // 25 MHz klokgeneratie (periode 40 ns)
  always #20 clk = ~clk;

  // 1. home.v -- alleen om te controleren dat we netjes in M_CHEST belanden
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

  // 2. renderer.v
  renderer u_renderer (
    .clk              (clk),
    .rst_n            (rst_n),
    .pix_x            (pix_x),
    .pix_y            (pix_y),
    .video_active     (video_active),
    .mode             (render_mode),
    .menu_sel         (menu_sel),
    .hearts           (hearts),
    .satisfaction     (satisfaction),
    .coins            (coins),
    .level            (level),
    .evolve_now       (evolve_now),
    .combo_len        (combo_len),
    .chest_state      (chest_state),
    .chest_sel        (chest_sel),
    .chest_outcome    (chest_outcome),
    .chest_contents   (chest_contents),
    .pot              (pot),
    .round            (round),
    .egg_frame        (egg_frame),
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
    game_over        = 0;
    you_win          = 0;
    minigame_done    = 0;

    // HUD / status tijdens de minigame
    coins            = 10'd40;
    level            = 3'd4;
    hearts           = 3'd3;
    satisfaction     = 3'd2;
    evolve_now       = 1'b0;
    combo_len        = 2'd0;
    dragon_mood_anim = 3'd0;
    flash            = 1'b0;
    flame_frame      = 1'b0;
    overflow         = 1'b0;
    egg_frame        = 2'd0;

    // Kisten-scherm in de MENU-fase:
    //   speler heeft kist 1 geopend, die zat vol munten, pot = 100,
    //   ronde 2 staat klaar.  Alle deksels zijn open (cframe = 2).
    render_mode      = R_M_CHEST;
    chest_state      = C_MENU;
    chest_sel        = 2'd1;        // kist in het midden was gekozen
    chest_outcome    = 3'd0;        // O_COIN
    chest_contents   = {3'd3, 3'd0, 3'd1};  // {kist2=BOMB, kist1=COIN, kist0=2X}
    pot              = 10'd100;
    round            = 4'd2;

    #100;
    rst_n = 1; // Reset loslaten (begint in M_TITLE)
    #40;

    // Frame 1: willekeurige knop -> M_TITLE naar M_HOME
    @(posedge clk);
    frame_tick  = 1'b1;
    btn_pressed = 8'b0001_0000;   // FEED, doet het hier als "start"
    @(posedge clk);
    frame_tick  = 1'b0;
    btn_pressed = 8'd0;

    #40;

    // Frame 2: PLAY (btn 7) -> M_HOME naar M_CHEST
    @(posedge clk);
    frame_tick  = 1'b1;
    btn_pressed = 8'b1000_0000;   // BTN_PLAY
    @(posedge clk);
    frame_tick  = 1'b0;
    btn_pressed = 8'd0;

    #40;
    $display("Mode van home.v: %0d (2 = M_CHEST)", mode);
    $display("chest_state = %0d (3 = C_MENU), chest_sel = %0d, pot = %0d, round = %0d",
             chest_state, chest_sel, pot, round);
    $display("Starten van 640x480 frame rendering...");

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