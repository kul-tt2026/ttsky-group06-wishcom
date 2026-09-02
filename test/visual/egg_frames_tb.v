`default_nettype none
`timescale 1ns/1ps

module egg_frames_tb;

  reg clk;
  reg rst_n;
  reg [9:0] pix_x, pix_y;
  reg video_active;
  reg frame_tick;
  reg [7:0] btn_pressed;
  reg game_over;
  reg you_win;
  reg minigame_done;
  reg [9:0] coins;
  reg [2:0] render_egg_frame;

  wire [2:0] mode;
  wire [2:0] menu_sel;
  wire act_feed, act_drink, act_sleep, act_minigame, req_evolve, restart;
  wire [1:0] R, G, B;

  localparam [2:0] M_EGG = 3'd1;

  always #20 clk = ~clk;

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

  renderer u_renderer (
    .clk              (clk),
    .rst_n            (rst_n),
    .pix_x            (pix_x),
    .pix_y            (pix_y),
    .video_active     (video_active),
    .mode             (mode),
    .menu_sel         (menu_sel),
    .hearts           (3'd1),
    .satisfaction     (3'd1),
    .coins            (coins),
    .level            (3'd1),
    .evolve_now       (1'b0),
    .combo_len        (2'd0),
    .chest_frame      (2'd0),
    .chest_state      (2'd0),
    .chest_sel        (2'd0),
    .chest_outcome    (3'd0),
    .dragon_mood_anim (3'd0),
    .flash            (1'b0),
    .flame_frame      (1'b0),
    .evolve_blink     (1'b0),
    .overflow         (1'b0),
    .chest_contents   (9'd0),
    .pot              (10'd0),
    .round            (4'd0),
    .egg_frame        (render_egg_frame),
    .R                (R),
    .G                (G),
    .B                (B)
  );

  integer frame_file;
  integer frame_number;
  integer xi;
  integer yi;
  reg [8*32-1:0] filename;

  task render_frame;
    input integer selected_frame;
    begin
      render_egg_frame = selected_frame[2:0];
      #40;
      case (selected_frame)
        0: filename = "egg_frame_0.ppm";
        1: filename = "egg_frame_1.ppm";
        2: filename = "egg_frame_2.ppm";
        3: filename = "egg_frame_3.ppm";
        4: filename = "egg_frame_4.ppm";
        5: filename = "egg_frame_5.ppm";
        default: filename = "egg_frame_invalid.ppm";
      endcase
      frame_file = $fopen(filename, "w");
      if (frame_file == 0) $fatal(1, "Kan %s niet openen", filename);
      $fwrite(frame_file, "P3\n640 480\n255\n");

      for (yi = 0; yi < 480; yi = yi + 1) begin
        for (xi = 0; xi < 640; xi = xi + 1) begin
          pix_x = xi[9:0];
          pix_y = yi[9:0];
          @(posedge clk);
          #1;
          $fwrite(frame_file, "%0d %0d %0d\n", R * 85, G * 85, B * 85);
        end
      end

      $fclose(frame_file);
      $display("Egg frame %0d klaar: %s", selected_frame, filename);
    end
  endtask

  initial begin
    clk            = 1'b0;
    rst_n          = 1'b0;
    pix_x          = 10'd0;
    pix_y          = 10'd0;
    video_active   = 1'b1;
    frame_tick     = 1'b0;
    btn_pressed    = 8'd0;
    game_over      = 1'b0;
    you_win        = 1'b0;
    minigame_done  = 1'b0;
    coins          = 10'd0;
    render_egg_frame = 3'd1;

    #100;
    rst_n = 1'b1;
    #40;

    // Verlaat het title screen met dezelfde startactie als de game.
    @(posedge clk);
    frame_tick  = 1'b1;
    btn_pressed = 8'b0001_0000;
    @(posedge clk);
    frame_tick  = 1'b0;
    btn_pressed = 8'd0;
    #40;

    if (mode !== M_EGG)
      $fatal(1, "Verwacht M_EGG (1) na verlaten title screen, kreeg %0d", mode);
    $display("Mode bevestigd: M_EGG (%0d)", mode);

    for (frame_number = 0; frame_number <= 5; frame_number = frame_number + 1)
      render_frame(frame_number);

    $display("Alle egg frames 0 t/m 5 zijn als PPM opgeslagen.");
    $finish;
  end

endmodule
