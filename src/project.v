`default_nettype none
// ---------------------------------------------------------------------------
// TOP LEVEL.  OWNER: PERSON A.  Nobody else commits here.  Wiring only.
// Every signal below is documented in SIGNALS.md -- that page is the law.
// ---------------------------------------------------------------------------
module tt_um_dragonchi (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
  // ---- screen timing + 60 Hz heartbeat ----
  // wire hsync, vsync, video_active;
  // wire [9:0] pix_x, pix_y;
  // hvsync_generator u_hvsync (
  //   .clk(clk), .reset(~rst_n),
  //   .hsync(hsync), .vsync(vsync), .display_on(video_active),
  //   .hpos(pix_x), .vpos(pix_y)
  // );
  reg vsync_d;

  // ---- screen painter (render group) ----

  // VGA singals:
  wire hsync, vsync, video_active;
  wire [1:0] R, G, B;
  wire [9:0] pix_x, pix_y;

  
  always @(posedge clk) begin
    if (!rst_n) vsync_d <= 1'b1; else vsync_d <= vsync;
  end
  wire frame_tick = vsync_d & ~vsync;

  // ---- controller: all 8 inputs ----
  wire [7:0] btn_level, btn_pressed;
  buttons u_buttons (
    .clk(clk), .rst_n(rst_n), .raw(ui_in),
    .level(btn_level), .pressed(btn_pressed)
  );

// ---- the dragon's stats: wire decleration (Person A) ----
  wire [2:0] hearts, satisfaction;
  wire [2:0] level;
  wire [9:0] coins_amount;

  // ---- home screen / mode control (Person A) ----
  wire [2:0] mode;
  wire [2:0] menu_sel;
  wire [1:0] egg_frame;
  wire you_win, overflow, evolve_now;
  wire act_feed, act_drink, act_sleep, act_minigame, req_evolve, restart;
  wire game_over, minigame_done;
  wire [9:0] coins;
  home u_home (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .btn_pressed(btn_pressed),
    .game_over(game_over), .minigame_done(minigame_done), .coins(coins),
    .mode(mode), .menu_sel(menu_sel),
    .act_feed(act_feed), .act_drink(act_drink), .act_sleep(act_sleep),
    .req_evolve(req_evolve), .restart(restart), .you_win(you_win), .act_minigame(act_minigame),
    .egg_frame(egg_frame)
  );

  // ---- balance game (Person B) ----
  wire req_heart_gain, req_heart_lose, req_sat_up, req_sat_down;
  wire [1:0] combo_len;
  balance u_balance (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick), .restart(restart),
    .act_feed(act_feed), .act_drink(act_drink), .act_sleep(act_sleep),
    .req_heart_gain(req_heart_gain), .req_heart_lose(req_heart_lose),
    .req_sat_up(req_sat_up), .req_sat_down(req_sat_down),
    .combo_len(combo_len),
    .act_minigame(act_minigame), .satisfaction(satisfaction)
  );

  // ---- chest minigame (Person C) ----
  wire [1:0] chest_state, chest_sel;
  wire [2:0] chest_outcome;
  wire req_coins_add, req_heart_lose_chest;
  chest_game u_chest_game (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .active(mode == 3'd3),
    .btn_pressed(btn_pressed),
    .pot_payout(coins_amount),
    .chest_state(chest_state), .chest_sel(chest_sel),
    .chest_outcome(chest_outcome),
    .req_coins_add(req_coins_add), 
    .req_heart_lose_chest(req_heart_lose_chest),
    .minigame_done(minigame_done)
  );

  // ---- the dragon's stats: the one owner (Person A) ----
  // wires defined above
  dragon_state u_state (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick), .restart(restart),
    .req_heart_gain(req_heart_gain), .req_heart_lose(req_heart_lose),
    .req_sat_up(req_sat_up), .req_sat_down(req_sat_down),
    .req_coins_add(req_coins_add),
    .req_heart_lose_chest(req_heart_lose_chest),
    .req_evolve(req_evolve),
    .hearts(hearts), .satisfaction(satisfaction),
    .coins_amount(coins_amount),
    .you_win(you_win), .overflow(overflow), .evolve_now(evolve_now),
    .coins(coins), .level(level), .game_over(game_over)
  );

  // ---- animation heartbeat (Person B) ----
  wire [1:0] dragon_bob, chest_frame;
  wire [2:0] dragon_mood_anim;
  wire flash, flame_frame;
  anim u_anim (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .mode(mode), .satisfaction(satisfaction), .chest_state(chest_state),
    .dragon_bob(dragon_bob), .dragon_mood_anim(dragon_mood_anim),
    .chest_frame(chest_frame), .flash(flash), .flame_frame(flame_frame)
  );

  // ---- TinyVGA Pmod.  Do not touch. ----
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  hvsync_generator u_hvsync (
    .clk(clk), .reset(~rst_n),
    .hsync(hsync), .vsync(vsync), .display_on(video_active),
    .hpos(pix_x), .vpos(pix_y)
  );


  renderer u_renderer (
    .pix_x(pix_x), .pix_y(pix_y), .video_active(video_active),
    .mode(mode), .menu_sel(menu_sel),
    .hearts(hearts), .satisfaction(satisfaction),
    .coins(coins), .level(level), .combo_len(combo_len),
    .chest_state(chest_state), .chest_sel(chest_sel),
    .chest_outcome(chest_outcome),
    .dragon_bob(dragon_bob), .dragon_mood_anim(dragon_mood_anim),
    .chest_frame(chest_frame), .flash(flash), .flame_frame(flame_frame),
    .R(R), .G(G), .B(B), .overflow(overflow), .evolve_now(evolve_now),
    .egg_frame(egg_frame)
  );

  

  

  // audio later: assign uio_out[0] = spkr; uio_oe[0] = 1;
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  wire _unused = &{ena, uio_in, btn_level, chest_outcome, 1'b0};
endmodule
