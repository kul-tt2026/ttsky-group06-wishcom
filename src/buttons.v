`default_nettype none
module buttons (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick, 
    input  wire [7:0] raw,  // de echte stroompulsen die van de knop binnenkomen
    output reg  [7:0] level,  // vorige stabiele toestand v/d knop
    output wire [7:0] pressed     // <--- LET OP: Nu een WIRE, geen reg!
);
  reg [7:0] sync0, sync1; // vermijd metastabiliteit

  always @(posedge clk) begin
    if (!rst_n) begin
      sync0 <= 0; sync1 <= 0; level <= 0;
    end else begin
      // Debounce: haal de knop naar het snelle klokdomein
      sync0 <= raw;
      sync1 <= sync0;
      
      // Update de langzame status (level) alleen op een frame_tick
      if (frame_tick) begin
        level <= sync1;
      end
    end
  end

  // DE MAGIE: Zodra frame_tick hoog wordt, en er is een nieuwe knop (sync1) 
  // ingedrukt ten opzichte van de vorige status (level), vuren we DIRECT.
  // Zodra de klok tikt, leest home.v deze kabel uit op de exacte juiste nanoseconde!
  assign pressed = frame_tick ? (sync1 & ~level) : 8'd0;

endmodule