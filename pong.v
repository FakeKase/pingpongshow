`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025
// Design Name: Pong for Basys-3
// Module Name: pong
// Description: Full Pong game with VGA 640x480, frame-synced movement, reset,
//              player (left) control, AI (right) paddle, and color rendering.
// 
//////////////////////////////////////////////////////////////////////////////////
//test
module pong(
    input clk,          // 100 MHz system clock
    input btn_reset,    // active-high reset button
    input btn_up,       // move player paddle up
    input btn_dn,       // move player paddle down
    input btn_left,
    input btn_right,
    output HS,          // VGA horizontal sync
    output VS,          // VGA vertical sync
    output [3:0] RED,   // VGA red channel
    output [3:0] GREEN, // VGA green channel
    output [3:0] BLUE   // VGA blue channel
);

// -------------------------------------------------------------------------
// 1. Internal signals & VGA interface
// -------------------------------------------------------------------------
wire [9:0] x, y;        // current pixel coordinates
wire blank;             // high when outside visible area
reg [11:0] color;       // registered color output

// instantiate VGA module (from previous working module)
vga v(
    .clk(clk),
    .reset(btn_reset),
    .HS(HS),
    .VS(VS),
    .x(x),
    .y(y),
    .blank(blank)
);

// -------------------------------------------------------------------------
// 2. Frame tick generator (1 pulse per frame, ~60Hz)
// -------------------------------------------------------------------------
reg VS_old;
wire frame_tick;

always @(posedge clk)
    VS_old <= VS;

assign frame_tick = (VS == 1 && VS_old == 0); // 1 clk pulse at rising edge of VS

// -------------------------------------------------------------------------
// 3. Game parameters
// -------------------------------------------------------------------------
localparam SCREEN_W   = 640;
localparam SCREEN_H   = 480;
localparam BALL_SIZE  = 8;
localparam BALL_SPX   = 5;      // ball speed per frame
localparam BALL_SPY   = 3;
localparam PAD_WIDTH  = 10;
localparam PAD_HEIGHT = 48;
localparam PAD_OFFS   = 32;     // distance from edge
localparam PAD_SPY    = 3;      // paddle speed per frame
localparam PAD_SPX    = 3;

parameter NEW_GAME = 2'b00;
parameter PLAY     = 2'b01;

// -------------------------------------------------------------------------
// 4. Game state registers
// -------------------------------------------------------------------------
reg [9:0] ball_x, ball_y;       // ball top-left position
reg ball_dx, ball_dy;           // ball direction: dx=1 right, dy=1 up
reg [9:0] padl_x;               //player's x
reg [9:0] padl_y, padr_y;       // paddle Y positions
reg coll_l, coll_r;             // collision flags
reg [1:0] state = NEW_GAME;

// pixel combinational flags
reg ball_pix, padl_pix, padr_pix;

// -------------------------------------------------------------------------
// 5. Rendering logic
// -------------------------------------------------------------------------
always @(*) begin
    // ball rectangle
    ball_pix = (x >= ball_x) && (x < ball_x + BALL_SIZE) &&
               (y >= ball_y) && (y < ball_y + BALL_SIZE);
    
    // left paddle rectangle
    padl_pix = (x >= padl_x) && (x < padl_x + PAD_WIDTH) &&
               (y >= padl_y) && (y < padl_y + PAD_HEIGHT);
    
    // right paddle rectangle
    padr_pix = (x >= SCREEN_W - PAD_OFFS - PAD_WIDTH) && (x < SCREEN_W - PAD_OFFS) &&
               (y >= padr_y) && (y < padr_y + PAD_HEIGHT);
    
    // assign color
    if (ball_pix)
        color = 12'h0F0;      // green ball
    else if (padl_pix || padr_pix)
        color = 12'hFFF;      // white paddles
    else
        color = 12'h000;      // black background
end

// assign VGA outputs
assign RED   = (blank ? 0 : color[11:8]);
assign GREEN = (blank ? 0 : color[7:4]);
assign BLUE  = (blank ? 0 : color[3:0]);

// -------------------------------------------------------------------------
// 6. Game update logic (synchronous)
// -------------------------------------------------------------------------
always @(posedge clk) begin
    if (btn_reset) begin
        // reset positions
        state <= NEW_GAME;
        padl_x <= PAD_OFFS;
        padl_y <= (SCREEN_H - PAD_HEIGHT)/2;
        padr_y <= (SCREEN_H - PAD_HEIGHT)/2;
        ball_x <= SCREEN_W/2 - BALL_SIZE/2;
        ball_y <= SCREEN_H/2 - BALL_SIZE/2;
        ball_dx <= 1; // start moving right
        ball_dy <= 0; // start moving down
        coll_l <= 0;
        coll_r <= 0;
    end
    else if (frame_tick) begin
        case (state)
            NEW_GAME: begin
                // center ball and paddles
                ball_x <= SCREEN_W/2 - BALL_SIZE/2;
                ball_y <= SCREEN_H/2 - BALL_SIZE/2;
                padl_x <= PAD_OFFS;
                padl_y <= (SCREEN_H - PAD_HEIGHT)/2;
                padr_y <= (SCREEN_H - PAD_HEIGHT)/2;
                
                // initial ball direction
                ball_dx <= 1; // right
                ball_dy <= 0; // down
                
                coll_l <= 0;
                coll_r <= 0;
                
                state <= PLAY;
            end
            
            PLAY: begin
                // --- Ball X movement ---
                if (ball_dx) begin // moving right
                    if (ball_x + BALL_SIZE + BALL_SPX >= SCREEN_W) begin
                        ball_x <= SCREEN_W - BALL_SIZE;
                        coll_r <= 1; // left player scores
                    end
                    else if ((ball_x + BALL_SIZE + BALL_SPX >= SCREEN_W - PAD_OFFS - PAD_WIDTH) &&
                             (ball_y + BALL_SIZE >= padr_y) && (ball_y <= padr_y + PAD_HEIGHT)) begin
                        ball_dx <= 0; // bounce left
                        ball_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH - BALL_SIZE - 1;
                    end
                    else
                        ball_x <= ball_x + BALL_SPX;
                end else begin // moving left
                    if (ball_x < BALL_SPX) begin
                        ball_x <= 0;
                        coll_l <= 1; // right player scores
                    end
                    else if (
                        (ball_x > padl_x + PAD_WIDTH) && // ball was outside paddle last frame
                        (ball_x - BALL_SPX <= padl_x + PAD_WIDTH) && // will cross paddle this frame
                        (ball_y + BALL_SIZE >= padl_y) && 
                        (ball_y <= padl_y + PAD_HEIGHT)
                    ) begin
                        ball_dx <= 1; // bounce right
                        ball_x <= padl_x + PAD_WIDTH + 1;
                    end
                    else
                        ball_x <= ball_x - BALL_SPX;
                end
                
                // --- Ball Y movement ---
                if (ball_dy == 0) begin // down
                    if (ball_y + BALL_SIZE + BALL_SPY >= SCREEN_H) begin
                        ball_y <= SCREEN_H - BALL_SIZE;
                        ball_dy <= 1; // reverse up
                    end else
                        ball_y <= ball_y + BALL_SPY;
                end else begin // up
                    if (ball_y < BALL_SPY) begin
                        ball_y <= 0;
                        ball_dy <= 0; // reverse down
                    end else
                        ball_y <= ball_y - BALL_SPY;
                end
                
                // --- Player paddle control ---
                if (btn_dn) begin
                    if (padl_y + PAD_HEIGHT + PAD_SPY >= SCREEN_H)
                        padl_y <= SCREEN_H - PAD_HEIGHT;
                    else
                        padl_y <= padl_y + PAD_SPY;
                end else if (btn_up) begin
                    if (padl_y < PAD_SPY)
                        padl_y <= 0;
                    else
                        padl_y <= padl_y - PAD_SPY;
                end else if(btn_left) begin
                    if(padl_x < PAD_SPX)
                        padl_x <= 0;
                    else
                        padl_x <= padl_x - PAD_SPX;
                end else if(btn_right) begin
                    if(padl_x + PAD_WIDTH + PAD_SPX >= SCREEN_W)
                        padl_x <= SCREEN_W - PAD_WIDTH;
                    else
                        padl_x <= padl_x + PAD_SPX;
                end
                
                // --- AI paddle control (simple follow) ---
                if (padr_y + PAD_HEIGHT/2 < ball_y) begin
                    if (padr_y + PAD_HEIGHT + PAD_SPY >= SCREEN_H)
                        padr_y <= SCREEN_H - PAD_HEIGHT;
                    else
                        padr_y <= padr_y + PAD_SPY;
                end else if (padr_y + PAD_HEIGHT/2 > ball_y + BALL_SIZE) begin
                    if (padr_y < PAD_SPY)
                        padr_y <= 0;
                    else
                        padr_y <= padr_y - PAD_SPY;
                end
                
                // --- Check for scoring ---
                if (coll_l || coll_r)
                    state <= NEW_GAME; // reset round
            end
        endcase
    end
end

endmodule
