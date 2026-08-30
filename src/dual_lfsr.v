`default_nettype none   // zorgt dat verilog niet vanzelf een nieuwe wire aanmaakt als je ergens een typefout maakt maar gwn meteen error geeft

module dual_lfsr (
    input wire clk,
    input wire rst_n,
    input wire frame_tick,
    output wire [2:0] rand_val
);
    reg [15:0] lfsr_a;
    reg [15:0] lfsr_b;

    wire feedback_a = lfsr_a[15] ^ lfsr_a[13] ^ lfsr_a[12] ^ lfsr_a[10];    // choose different values from the loop to avoid it getting stuck
    wire feedback_b = lfsr_b[15] ^ lfsr_b[14] ^ lfsr_b[12] ^ lfsr_b[3];

    always @(posedge clk) begin
        if (!rst_n) begin
            lfsr_a <= 16'hACE1;
            lfsr_b <= 16'hBED2;
        end else if (frame_tick) begin  // 60Hz
            lfsr_a <= {lfsr_a[14:0], feedback_a};
            if (lfsr_a[0]) begin
                lfsr_b <= {lfsr_b[14:0], feedback_b};   // 2de lfsr die enkel shift_b als bit 0 van lfsr_a 1 is
            end
        end
    end

    // stuur de onderste 3 bits van de lfsr_b naar buiten
    assign rand_val = lfsr_b[2:0];

endmodule
