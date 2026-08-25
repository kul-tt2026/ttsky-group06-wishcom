`default_nettype none
module egg_draw (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] egg_frame,
    output wire       px_on,
    output wire [2:0] px_code
);


// Draden voor de submodule outputs


    wire       egg0_px_on, egg1_px_on,  egg2_px_on,  egg3_px_on,  egg4_px_on, egg5_px_on;
    wire [2:0] egg0_px_code, egg1_px_code, egg2_px_code, egg3_px_code, egg4_px_code, egg5_px_code;

    egg0_generator egg0(
            .clk(clk),
            .rst_n(rst_n),
            .x(x),
            .y(y),
            .egg_frame(egg_frame),
            .px_on(egg0_px_on),
            .px_code(egg0_px_code)
    );

    egg1_generator egg1(
            .clk(clk),
            .rst_n(rst_n),
            .x(x),
            .y(y),
            .egg_frame(egg_frame),
            .px_on(egg1_px_on),
            .px_code(egg1_px_code)
    );

    egg2_generator egg2(
            .clk(clk),
            .rst_n(rst_n),
            .x(x),
            .y(y),
            .egg_frame(egg_frame),
            .px_on(egg2_px_on),
            .px_code(egg2_px_code)
    );

    egg3_generator egg3(
            .clk(clk),
            .rst_n(rst_n),
            .x(x),
            .y(y),
            .egg_frame(egg_frame),
            .px_on(egg3_px_on),
            .px_code(egg3_px_code)
    );

    egg4_generator egg4(
            .clk(clk),
            .rst_n(rst_n),
            .x(x),
            .y(y),
            .egg_frame(egg_frame),
            .px_on(egg4_px_on),
            .px_code(egg4_px_code)
    );

    egg5_generator egg5(
            .clk(clk),
            .rst_n(rst_n),
            .x(x),
            .y(y),
            .egg_frame(egg_frame),
            .px_on(egg5_px_on),
            .px_code(egg5_px_code)
    );

    assign px_on = (egg_frame == 3'd0) ? egg0_px_on :
                    (egg_frame == 3'd1) ? egg1_px_on :
                   (egg_frame == 3'd2) ? egg2_px_on :
                   (egg_frame == 3'd3) ? egg3_px_on :
                   (egg_frame == 3'd4) ? egg4_px_on :
                   egg5_px_on;

    assign px_code = (egg_frame == 3'd0) ? egg0_px_code :
                     (egg_frame == 3'd1) ? egg1_px_code :
                     (egg_frame == 3'd2) ? egg2_px_code :
                     (egg_frame == 3'd3) ? egg3_px_code :
                     (egg_frame == 3'd4) ? egg4_px_code :
                     egg5_px_code;

endmodule

