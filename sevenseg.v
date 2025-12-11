`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 10:43:08 AM
// Design Name: 
// Module Name: sevenseg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sevenseg(
    input clk,
    input [3:0] digit0,
    input [3:0] digit3,
    output reg [6:0] seg,
    output reg [3:0] an
);

reg [1:0] mux = 0;

always @(posedge clk) begin
    mux <= mux + 1;

    case (mux)
        2'b00: begin
            an  <= 4'b1110;
            seg <= decode7(digit0);
        end
        2'b01: begin
            an  <= 4'b0111;
            seg <= decode7(digit3);
        end
        default: begin
            an  <= 4'b1111;
            seg <= 7'b1111111;
        end
    endcase
end

function [6:0] decode7(input [3:0] d);
    case (d)
        0: decode7 = 7'b1000000;
        1: decode7 = 7'b1111001;
        2: decode7 = 7'b0100100;
        3: decode7 = 7'b0110000;
        4: decode7 = 7'b0011001;
        5: decode7 = 7'b0010010;
        6: decode7 = 7'b0000010;
        7: decode7 = 7'b1111000;
        8: decode7 = 7'b0000000;
        9: decode7 = 7'b0011000;
        default: decode7 = 7'b1111111;
    endcase
endfunction

endmodule
