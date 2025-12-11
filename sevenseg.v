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
    input [3:0] digit,
    input [2:0] dx,   // 0..4  (5 columns)
    input [2:0] dy,   // 0..6  (7 rows)
    output reg pix
);

reg [6:0] rows;

    always @(*) begin
        case (digit)
            0: rows = 7'b1111110;
            1: rows = 7'b0110000;
            2: rows = 7'b1101101;
            3: rows = 7'b1111001;
            4: rows = 7'b0110011;
            5: rows = 7'b1011011;
            6: rows = 7'b1011111;
            7: rows = 7'b1110000;
            8: rows = 7'b1111111;
            9: rows = 7'b1111011;
            default: rows = 7'b0000000;
        endcase
        
        pix = rows[6 - dy];
    end
endmodule
