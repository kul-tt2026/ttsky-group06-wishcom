`default_nettype none
module dragon_draw (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] level,
    input  wire [2:0] mood_anim,
    output wire       px_on,
    output wire [2:0] px_code
);

    // Draden voor de submodule outputs
    wire       egg_px_on,  lvl2_px_on,  lvl3_px_on;
    wire [2:0] egg_px_code, lvl2_px_code, lvl3_px_code;

    // Ei generator (puur combinatorisch, geen clk/rst_n nodig)
    ei_generator u_egg (
        .x         (x),
        .y         (y),
        .mood_anim (mood_anim),
        .px_on     (egg_px_on),
        .px_code   (egg_px_code)
    );

    // Level 2 Draak (gesynchroniseerd op clk)
    dragon_l2_generator u_dragon_lvl2 (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .y         (y),
        .mood_anim (mood_anim),
        .px_on     (lvl2_px_on),
        .px_code   (lvl2_px_code)
    );

    // Level 3 Draak (gesynchroniseerd op clk)
    dragon_l3_generator u_dragon_lvl3 (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .y         (y),
        .mood_anim (mood_anim),
        .px_on     (lvl3_px_on),
        .px_code   (lvl3_px_code)
    );

    // Multiplexer op basis van level
    assign px_on = (level == 3'd1 || level == 3'd2) ? egg_px_on :
                   (level >= 3'd3 && level <= 3'd6) ? lvl2_px_on :
                   (level == 3'd7)                  ? lvl3_px_on :
                   1'b0;

    assign px_code = (level == 3'd1 || level == 3'd2) ? egg_px_code :
                     (level >= 3'd3 && level <= 3'd6) ? lvl2_px_code :
                     (level == 3'd7)                  ? lvl3_px_code :
                     3'd0;

endmodule