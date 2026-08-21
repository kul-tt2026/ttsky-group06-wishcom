`default_nettype none
// ---------------------------------------------------------------------------
// SATISFACTION
// ---------------------------------------------------------------------------
module satisfactionbar (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [2:0] sat,         // how many of the 5 segments are lit
    output wire       px_on,
    output wire [2:0] px_code        // 0     = frame + dividers
                                    // 1..5  = segment 0..4, ramp colour
                                    // 6     = highlight ring on the selected
                                    // 7     = dark / unlit segment
);
  // satisfaction: 5 levels an satisfaction, wordt gwn meegegeven via aantal bit (5 vakjes nodig) 
  // ======================= mode ===========================================
  // 1 = CURSOR : all five keep their colour, a white ring marks `sat`.
  // 0 = FILL   : segments 0..sat are coloured, the rest go dark (code 7),
  //              no ring.  Reads faster from a distance; you lose sight of
  //              the top of the scale.  Flip this one bit and re-render.
  localparam CURSOR_MODE = 1'b1;
 
  // ======================= geometry =======================================
  localparam [9:0] NSEG  = 10'd5;
  localparam [9:0] FRAME = 10'd3;      // border thickness
  localparam [9:0] PITCH = 10'd32;     // segment stride -- MUST be a power of 2
  localparam [9:0] SEG_W = 10'd28;     // segment body; PITCH-SEG_W = 4px divider
  localparam [9:0] SEG_H = 10'd18;     // segment height
  localparam [9:0] RING  = 10'd2;      // thickness of the selection ring
 
  // Outer size.  The last segment needs no divider after it, hence the -gap.
  localparam [9:0] BAR_W = FRAME + (NSEG * PITCH) - (PITCH - SEG_W) + FRAME;
  localparam [9:0] BAR_H = FRAME + SEG_H + FRAME;
 
  // ======================= where are we ===================================
  // Local coords wrap to ~1023 left of / above the origin, so an unsigned
  // "< BAR_W" doubles as the left/top edge test.  No signed compare needed.
  wire in_bar = (x < BAR_W) && (y < BAR_H);
 
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);
 
  // In satisfactionbar.v regel 43:
  wire [9:0] diff_x = x - FRAME;
  wire [7:0] rx     = diff_x[7:0];
  wire [2:0] idx = rx[7:5];            // which segment: rx / PITCH, as a slice
  wire [4:0] sx  = rx[4:0];            // position within this segment's pitch
 
  wire in_seg = in_inner && (sx < SEG_W[4:0]) && (idx < NSEG[2:0]);
 
  // ======================= selection ======================================
  wire selected = (idx == sat);
 
  // White inset ring around the selected segment.
  wire ring = CURSOR_MODE && in_seg && selected &&
              ((sx < RING[4:0]) || (sx >= SEG_W[4:0] - RING[4:0]) ||
               (y  < FRAME + RING) || (y >= BAR_H - FRAME - RING));
 
  // In CURSOR mode every segment shows its colour; in FILL mode only up to
  // and including the current level.
  wire coloured = CURSOR_MODE ? 1'b1 : (idx <= sat);
 
  // ======================= output =========================================
  // The whole rectangle is opaque: frame and dividers share code 0, so the
  // bar reads as one solid object instead of showing the background through.
  assign px_on   = in_bar;
  assign px_code = !in_seg  ? 3'd0             :   // frame + dividers
                   ring     ? 3'd6             :   // selection ring
                   coloured ? (idx + 3'd1)     :   // ramp colour 1..5
                              3'd7;                // dark / unlit
endmodule

 
