`timescale 1ns / 1ps
module vga(
    input clk,           // 100 MHz input clock
    input reset,         // synchronous reset (active high)
    output HS, VS,       // sync signals (active low)
    output [9:0] x,      // current x position (0..799)
    output [9:0] y,      // current y position (0..524)
    output blank         // 1 when outside 640x480 active video
);

reg [9:0] xc, yc;
reg [9:0] xc_next, yc_next;
reg [1:0] prescaler;     // divide 100 MHz -> 25 MHz (pixel clock)
reg HS_reg, VS_reg;

// compute next pixel counters combinationally (these represent the next pixel clock values)
always @(*) begin
    // default next = current
    xc_next = xc;
    yc_next = yc;

    if (xc == 10'd799) begin
        xc_next = 10'd0;
        if (yc == 10'd524)
            yc_next = 10'd0;
        else
            yc_next = yc + 10'd1;
    end else begin
        xc_next = xc + 10'd1;
    end
end

// blanking area detection (based on currently visible pixel)
assign blank = (xc > 10'd639) || (yc > 10'd479);

// HS active low from pixel 656-751 inclusive
wire hs_next_wc;
assign hs_next_wc = ~((xc_next > 10'd655) && (xc_next < 10'd752)); // use xc_next so sync aligns with pixel tick

// VS active low from lines 490-491 inclusive
wire vs_next_wc;
assign vs_next_wc = ~((yc_next > 10'd489) && (yc_next < 10'd492)); // use yc_next

assign x = xc;
assign y = yc;
assign HS = HS_reg;
assign VS = VS_reg;

always @(posedge clk) begin
    if (reset) begin
        // RESET ALL SIGNALS
        xc <= 0;
        yc <= 0;
        prescaler <= 0;
        HS_reg <= 1;
        VS_reg <= 1;
    end else begin
        // prescaler generates 25 MHz enable (100MHz / 4)
        prescaler <= prescaler + 1'b1;

        // only update pixel counters and sync signals when prescaler ticks (pixel clock)
        if (prescaler == 2'b11) begin
            // update pixel counters to next pixel
            xc <= xc_next;
            yc <= yc_next;

            // update sync signals on pixel clock (avoid glitches)
            HS_reg <= hs_next_wc;
            VS_reg <= vs_next_wc;
        end
    end
end

endmodule
