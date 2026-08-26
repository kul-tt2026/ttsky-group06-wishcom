`default_nettype none
`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// CHEST PICK RENDER-TESTBENCH
//
// Zelfde opzet als chest_menu_tb.v, maar dit keer voor de KIST-LAYOUT zelf
// (chest_state != C_MENU), dus het scherm met de drie kisten erop.
//
// Verschil met chest_menu_tb.v: home.v hangt er niet meer tussen.  Voor een
// pure teken-test heeft die niets toe te voegen -- de bench forceert mode en
// chest_* toch met de hand -- en zo hoef je de FSM niet door drie frames te
// duwen voor je een plaatje hebt.
//
// Deze bench schrijft DRIE frames, want de layout ziet er in elke fase anders
// uit en je wil ze naast elkaar kunnen leggen:
//
//   chest_pick.ppm    C_PICK    alle deksels dicht, kader rond chest_sel
//   chest_open.ppm    C_OPEN    gekozen kist open, andere twee dicht
//   chest_result.ppm  C_RESULT  alle drie open
// ---------------------------------------------------------------------------
module chest_pick_tb;

  // ---- renderer-interface --------------------------------------------------
  reg        clk;
  reg        rst_n;
  reg  [9:0] pix_x, pix_y;
  reg        video_active;

  reg  [2:0] mode;
  reg  [2:0] menu_sel;
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
  reg  [8:0] chest_contents;
  reg  [9:0] pot;
  reg  [3:0] round;

  reg  [2:0] dragon_mood_anim;
  reg        flash;
  reg        flame_frame;
  reg        evolve_blink;
  reg        frame_tick;
  reg        overflow;
  reg  [2:0] egg_frame;

  wire [1:0] R, G, B;

  // mode- en state-codes zoals renderer.v ze kent
  localparam [2:0] R_M_CHEST = 3'd3;
  localparam [1:0] C_PICK    = 2'd0,
                   C_OPEN    = 2'd1,
                   C_RESULT  = 2'd2;

  // outcome-codes zoals chest_game.v ze kent
  localparam [2:0] O_COIN = 3'd0, O_2X = 3'd1, O_CURSED = 3'd2,
                   O_BOMB = 3'd3, O_BOMB2 = 3'd4;

  // 25 MHz (periode 40 ns)
  always #20 clk = ~clk;

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
    .evolve_blink     (evolve_blink),
    .frame_tick       (frame_tick),
    .overflow         (overflow),
    .chest_contents   (chest_contents),
    .pot              (pot),
    .round            (round),
    .egg_frame        (egg_frame),
    .R                (R),
    .G                (G),
    .B                (B)
  );

  integer f, xi, yi;

  // ---- een volledig 640x480 frame naar een .ppm schrijven -------------------
  task render_frame(input [8*32-1:0] fname);
    begin
      f = $fopen(fname, "w");
      $fwrite(f, "P3\n640 480\n255\n");
      for (yi = 0; yi < 480; yi = yi + 1) begin
        for (xi = 0; xi < 640; xi = xi + 1) begin
          pix_x = xi[9:0];
          pix_y = yi[9:0];
          @(posedge clk);
          @(negedge clk);
          // 2 bits -> 0, 85, 170, 255
          $fwrite(f, "%0d %0d %0d\n", R * 85, G * 85, B * 85);
        end
      end
      $fclose(f);
      $display("  -> %0s geschreven", fname);
    end
  endtask

  initial begin
    clk              = 0;
    rst_n            = 0;
    pix_x            = 0;
    pix_y            = 0;
    video_active     = 1'b1;

    // HUD tijdens de minigame
    menu_sel         = 3'd0;
    coins            = 10'd40;
    level            = 3'd4;
    hearts           = 3'd3;
    satisfaction     = 3'd2;
    evolve_now       = 1'b0;
    evolve_blink     = 1'b0;
    combo_len        = 2'd0;
    dragon_mood_anim = 3'd0;
    flash            = 1'b0;
    flame_frame      = 1'b0;
    frame_tick       = 1'b0;
    overflow         = 1'b0;
    egg_frame        = 3'd0;

    // De minigame zelf.  Ronde 2, de middelste kist staat onder de cursor,
    // en daar zit een munt in.
    mode             = R_M_CHEST;
    chest_frame      = 2'd0;
    chest_sel        = 2'd1;
    chest_contents   = {O_BOMB, O_COIN, O_2X};   // {kist2, kist1, kist0}
    chest_outcome    = O_COIN;                   // inhoud van kist 1
    pot              = 10'd100;
    round            = 4'd2;

    #100;
    rst_n = 1;
    #40;

    $display("Renderen van de kist-layout, chest_sel = %0d, pot = %0d, round = %0d",
             chest_sel, pot, round);

    chest_state = C_PICK;   @(posedge clk); render_frame("chest_pick.ppm");
    chest_state = C_OPEN;   @(posedge clk); render_frame("chest_open.ppm");
    chest_state = C_RESULT; @(posedge clk); render_frame("chest_result.ppm");

    $display("Render klaar!");
    $finish;
  end

endmodule