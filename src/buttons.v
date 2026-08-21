`default_nettype none
// ---------------------------------------------------------------------------
// 8-input controller conditioning.  OWNER: PERSON A.  Done -- nobody edits.
// Debounces all eight inputs, gives clean held-state and press pulses.
// The MEANING of each bit lives in SIGNALS.md, not here.
// ---------------------------------------------------------------------------
module buttons (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] raw,
    output reg  [7:0] level,
    output reg  [7:0] pressed
);
  reg [14:0] tick_cnt;                   // ~768 Hz sampling
  wire tick = (tick_cnt == 15'h7FFF);
  reg [7:0] sync0, sync1;

  // Veranderd: 'or negedge rst_n' toegevoegd voor asynchrone reset
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick_cnt <= 15'd0; 
      sync0    <= 8'd0; 
      sync1    <= 8'd0; 
      level    <= 8'd0; 
      pressed  <= 8'd0;
    end else begin
      tick_cnt <= tick_cnt + 15'd1;
      sync0    <= raw;
      sync1    <= sync0;
      pressed  <= 8'd0;
      if (tick) begin
        level   <= sync1;
        pressed <= sync1 & ~level;
      end
    end
  end
endmodule