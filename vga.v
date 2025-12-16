`timescale 1ns / 1ps
module vga(
    input clk,
    input reset, 
    output HS, VS,    
    output [9:0] x,  
    output [9:0] y,    
    output blank         
);

reg [9:0] xc, yc;
reg [9:0] xc_next, yc_next;
reg [1:0] prescaler;   
reg HS_reg, VS_reg;

always @(*) begin
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


assign blank = (xc > 10'd639) || (yc > 10'd479);

wire hs_next_wc;
assign hs_next_wc = ~((xc_next > 10'd655) && (xc_next < 10'd752)); 

wire vs_next_wc;
assign vs_next_wc = ~((yc_next > 10'd489) && (yc_next < 10'd492)); 

assign x = xc;
assign y = yc;
assign HS = HS_reg;
assign VS = VS_reg;

always @(posedge clk) begin
    if (reset) begin
        xc <= 0;
        yc <= 0;
        prescaler <= 0;
        HS_reg <= 1;
        VS_reg <= 1;
    end else begin
        
        prescaler <= prescaler + 1'b1;

        if (prescaler == 2'b11) begin
            xc <= xc_next;
            yc <= yc_next;

            HS_reg <= hs_next_wc;
            VS_reg <= vs_next_wc;
        end
    end
end

endmodule
