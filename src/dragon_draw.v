`default_nettype none
module dragon_draw (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [1:0] dragon_bob,
    input  wire [2:0] level,
    output wire       px_on,
    output wire [2:0] px_code
);

    // Draden voor de submodule outputs
    wire         lvl2_px_on,  lvl3_px_on,  lvl4_px_on;
    wire [2:0]  lvl2_px_code, lvl3_px_code, lvl4_px_code;

    

    // Level 2 Draak (gesynchroniseerd op clk)
    dragon_l2_generator u_dragon_lvl2 (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .y         (yb),
        .px_on     (lvl2_px_on),
        .px_code   (lvl2_px_code)
    );

    // Level 3 Draak (gesynchroniseerd op clk)
    dragon_l3_generator u_dragon_lvl3 (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .y         (yb),
        .px_on     (lvl3_px_on),
        .px_code   (lvl3_px_code)
    );

    dragon_l4_generator u_dragon_lvl4 (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .y         (yb),
        .px_on     (lvl4_px_on),
        .px_code   (lvl4_px_code)
    );

    // Multiplexer op basis van level
    assign px_on = (level == 3'd1 || level == 3'd2) ? lvl2_px_on :
                   (level >= 3'd3 && level <= 3'd6) ? lvl3_px_on :
                   (level == 3'd7)                  ? lvl4_px_on :
                   lvl4_px_on;

    assign px_code = (level == 3'd1 || level == 3'd2) ? lvl2_px_code :
                     (level >= 3'd3 && level <= 3'd6) ? lvl3_px_code :
                     (level == 3'd7)                  ? lvl4_px_code :
                     lvl4_px_code;

endmodule