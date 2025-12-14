`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pong for Basys-3 - 2 Players (VGA score on-screen)
// - Player 1: on-board buttons (active-high)
// - Player 2: external buttons on PMOD (active-low with PULLUP in XDC)
// - Paddles: move UP/DOWN/LEFT/RIGHT
// - Score: reset BOTH to 0 when either side would reach 11
//////////////////////////////////////////////////////////////////////////////////

module pong(
    input  clk,
    input  btn_reset,

    // Player 1 (external now)
    input  btn1_up,
    input  btn1_dn,
    input  btn1_left,
    input  btn1_right,   // ✅ comma

    // VGA
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE,

    output reg [3:0] ledL,
    output reg [3:0] ledR,

    // Player 2
    input  btn2_up,
    input  btn2_dn,
    input  btn2_left,
    input  btn2_right
);

    // -------------------------------------------------------------------------
    // 1) VGA interface
    // -------------------------------------------------------------------------
    wire [9:0] x, y;
    wire blank;
    reg  [11:0] color;

    vga v(
        .clk(clk),
        .reset(btn_reset),
        .HS(HS),
        .VS(VS),
        .x(x),
        .y(y),
        .blank(blank)
    );
    
    // Player 1 buttons: active-low -> invert to active-high
    wire p1_up    = ~btn1_up;
    wire p1_dn    = ~btn1_dn;
    wire p1_left  = ~btn1_left;
    wire p1_right = ~btn1_right;

    // Player 2 buttons: active-low -> invert to active-high
    wire p2_up    = ~btn2_up;
    wire p2_dn    = ~btn2_dn;
    wire p2_left  = ~btn2_left;
    wire p2_right = ~btn2_right;

    // -------------------------------------------------------------------------
    // 2) Frame tick generator (~60Hz): rising edge of VS
    // -------------------------------------------------------------------------
    reg VS_old;
    wire frame_tick;

    always @(posedge clk)
        VS_old <= VS;

    assign frame_tick = (VS == 1 && VS_old == 0);

    // -------------------------------------------------------------------------
    // 3) Game parameters
    // -------------------------------------------------------------------------
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;
    
    localparam PAD_WIDTH   = 10;
    localparam PADL_HEIGHT = 48;
    localparam PADR_HEIGHT = 48;
    
    localparam MID_X = SCREEN_W/2;      // 320
    localparam GAP   = 4;
    
    // paddle allowed x range (top-left of paddle)
    localparam P1_X_MIN = 0;
    localparam P1_X_MAX = MID_X - GAP - PAD_WIDTH;
    
    localparam P2_X_MIN = MID_X + GAP;
    localparam P2_X_MAX = SCREEN_W - PAD_WIDTH;
    
    // center line
    localparam LINE_W  = 4;
    localparam LINE_X0 = MID_X - (LINE_W/2);
    
    localparam BALL_SIZE = 8;
    localparam BALL_SPX  = 3;
    localparam BALL_SPY  = 3;
    
    localparam PAD_OFFS = 32;
    
    localparam PADL_SPX = 5;
    localparam PADL_SPY = 5;
    localparam PADR_SPX = 5;
    localparam PADR_SPY = 5;
    
    localparam MAX_SCORE = 11;
    
    // FSM
    localparam NEW_GAME = 2'b00;
    localparam PLAY     = 2'b01;
    localparam GAME_OVER = 2'b10;
    localparam integer WIN_DELAY_FRAMES = 60;
    reg [15:0] win_cnt;
    
    localparam SCORE_SCALE   = 6;
    localparam DIGIT_W       = 5 * SCORE_SCALE;
    localparam DIGIT_H       = 7 * SCORE_SCALE;
    localparam DIGIT_SPACING = SCORE_SCALE * 2;
    localparam DOUBLE_W      = DIGIT_W * 2 + DIGIT_SPACING;
    
    localparam SCORE_Y    = 30;
    localparam integer SCORE_MARGIN = 10; // เว้นระยะจากเส้นกลาง
    localparam P1_SCORE_X = LINE_X0 - SCORE_MARGIN - DOUBLE_W; // เผื่อ 2 หลักไว้ก่อน;
    localparam P2_SCORE_X = LINE_X0 + LINE_W + SCORE_MARGIN;   // ฝั่งขวาเริ่มหลังเส้น
    // -------------------------------------------------------------------------
    // 4) State registers
    // -------------------------------------------------------------------------
    reg [1:0] state;

    reg [9:0] ball_x, ball_y;
    reg       ball_dx;    // 1 = right, 0 = left
    reg       ball_dy;    // 1 = up,    0 = down

    reg [9:0] padl_x, padl_y;
    reg [9:0] padr_x, padr_y;

    reg [7:0] score_left;
    reg [7:0] score_right;

    // scoring flags for current frame
    reg scored_l; // ball out LEFT  -> right scores
    reg scored_r; // ball out RIGHT -> left scores

    // -------------------------------------------------------------------------
    // 5) Digit bitmap (5x7 = 35 bits)
    // -------------------------------------------------------------------------
    function [34:0] digit_bitmap;
        input [3:0] value;
        case (value)
            4'd0: digit_bitmap = 35'b11111_10001_10001_10001_10001_10001_11111;
            4'd1: digit_bitmap = 35'b00100_01100_00100_00100_00100_00100_01110;
            4'd2: digit_bitmap = 35'b11111_00001_00001_11111_10000_10000_11111;
            4'd3: digit_bitmap = 35'b11111_00001_00001_11111_00001_00001_11111;
            4'd4: digit_bitmap = 35'b10001_10001_10001_11111_00001_00001_00001;
            4'd5: digit_bitmap = 35'b11111_10000_10000_11111_00001_00001_11111;
            4'd6: digit_bitmap = 35'b11111_10000_10000_11111_10001_10001_11111;
            4'd7: digit_bitmap = 35'b11111_00001_00001_00001_00001_00001_00001;
            4'd8: digit_bitmap = 35'b11111_10001_10001_11111_10001_10001_11111;
            4'd9: digit_bitmap = 35'b11111_10001_10001_11111_00001_00001_11111;
            default: digit_bitmap = 35'b0;
        endcase
    endfunction

    wire [3:0] sl_tens = score_left / 10;
    wire [3:0] sl_ones = score_left % 10;
    wire [3:0] sr_tens = score_right / 10;
    wire [3:0] sr_ones = score_right % 10;

    wire [34:0] sl_tens_bm = digit_bitmap(sl_tens);
    wire [34:0] sl_ones_bm = digit_bitmap(sl_ones);
    wire [34:0] sr_tens_bm = digit_bitmap(sr_tens);
    wire [34:0] sr_ones_bm = digit_bitmap(sr_ones);

    // bitmap indexing regs
    reg [2:0] row_idx;
    reg [2:0] col_idx;
    reg [5:0] bit_idx;

    // pixel flags
    reg ball_pix, padl_pix, padr_pix;

    // -------------------------------------------------------------------------
    // 6) Rendering (combinational)
    // -------------------------------------------------------------------------
    always @(*) begin
        color    = 12'h000;

        row_idx  = 0;
        col_idx  = 0;
        bit_idx  = 0;

        ball_pix = 0;
        padl_pix = 0;
        padr_pix = 0;

        // ---------------- LEFT SCORE ----------------
        if ((x >= P1_SCORE_X) &&
            (x <  P1_SCORE_X + ((score_left >= 10) ? DOUBLE_W : DIGIT_W)) &&
            (y >= SCORE_Y) &&
            (y <  SCORE_Y + DIGIT_H)) begin

            row_idx = (y - SCORE_Y) / SCORE_SCALE;

            if (score_left >= 10) begin
                // tens
                if (x < P1_SCORE_X + DIGIT_W) begin
                    col_idx = (x - P1_SCORE_X) / SCORE_SCALE;
                    if (row_idx < 7 && col_idx < 5) begin
                        bit_idx = row_idx * 5 + col_idx;
                        if (sl_tens_bm[34 - bit_idx]) color = 12'hFFF;
                    end
                end
                // ones
                else if (x >= P1_SCORE_X + DIGIT_W + DIGIT_SPACING) begin
                    col_idx = (x - (P1_SCORE_X + DIGIT_W + DIGIT_SPACING)) / SCORE_SCALE;
                    if (row_idx < 7 && col_idx < 5) begin
                        bit_idx = row_idx * 5 + col_idx;
                        if (sl_ones_bm[34 - bit_idx]) color = 12'hFFF;
                    end
                end
            end
            else begin
                // single digit
                col_idx = (x - P1_SCORE_X) / SCORE_SCALE;
                if (row_idx < 7 && col_idx < 5) begin
                    bit_idx = row_idx * 5 + col_idx;
                    if (sl_ones_bm[34 - bit_idx]) color = 12'hFFF;
                end
            end
        end

        // ---------------- RIGHT SCORE ----------------
        else if ((x >= P2_SCORE_X) &&
                 (x <  P2_SCORE_X + ((score_right >= 10) ? DOUBLE_W : DIGIT_W)) &&
                 (y >= SCORE_Y) &&
                 (y <  SCORE_Y + DIGIT_H)) begin

            row_idx = (y - SCORE_Y) / SCORE_SCALE;

            if (score_right >= 10) begin
                // tens
                if (x < P2_SCORE_X + DIGIT_W) begin
                    col_idx = (x - P2_SCORE_X) / SCORE_SCALE;
                    if (row_idx < 7 && col_idx < 5) begin
                        bit_idx = row_idx * 5 + col_idx;
                        if (sr_tens_bm[34 - bit_idx]) color = 12'hFFF;
                    end
                end
                // ones
                else if (x >= P2_SCORE_X + DIGIT_W + DIGIT_SPACING) begin
                    col_idx = (x - (P2_SCORE_X + DIGIT_W + DIGIT_SPACING)) / SCORE_SCALE;
                    if (row_idx < 7 && col_idx < 5) begin
                        bit_idx = row_idx * 5 + col_idx;
                        if (sr_ones_bm[34 - bit_idx]) color = 12'hFFF;
                    end
                end
            end
            else begin
                // single digit
                col_idx = (x - P2_SCORE_X) / SCORE_SCALE;
                if (row_idx < 7 && col_idx < 5) begin
                    bit_idx = row_idx * 5 + col_idx;
                    if (sr_ones_bm[34 - bit_idx]) color = 12'hFFF;
                end
            end
        end
        
        // ---------------- CENTER LINE ----------------
        else if ((x >= LINE_X0) && (x < LINE_X0 + LINE_W) &&
                 (y[4] == 1'b0)) begin
            // y[4]==0 ทำให้เป็นเส้นประ (สลับทุก 16 พิกเซล)
            color = 12'hFFF; // สีขาว
        end

        // ---------------- BALL + PADDLES ----------------
        else begin
            ball_pix = (x >= ball_x) && (x < ball_x + BALL_SIZE) &&
                       (y >= ball_y) && (y < ball_y + BALL_SIZE);

            padl_pix = (x >= padl_x) && (x < padl_x + PAD_WIDTH) &&
                       (y >= padl_y) && (y < padl_y + PADL_HEIGHT);

            padr_pix = (x >= padr_x) && (x < padr_x + PAD_WIDTH) &&
                       (y >= padr_y) && (y < padr_y + PADR_HEIGHT);

            if (ball_pix)
                color = 12'h0F0;   // green ball
            else if (padl_pix || padr_pix)
                color = 12'hFFF;   // white paddles
            else
                color = 12'h000;   // black bg
        end
    end

    assign RED   = (blank ? 0 : color[11:8]);
    assign GREEN = (blank ? 0 : color[7:4]);
    assign BLUE  = (blank ? 0 : color[3:0]);

    // -------------------------------------------------------------------------
    // 7) Game update (sequential) - update only on frame_tick
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
    
        if (btn_reset) begin
            state <= NEW_GAME;

            padl_x <= PAD_OFFS;
            padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;

            padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
            padr_y <= (SCREEN_H - PADR_HEIGHT)/2;

            ball_x <= SCREEN_W/2 - BALL_SIZE/2;
            ball_y <= SCREEN_H/2 - BALL_SIZE/2;

            ball_dx <= 1;
            ball_dy <= 0;

            score_left  <= 0;
            score_right <= 0;

            ledL <= 0;
            ledR <= 0;

            scored_l <= 0;
            scored_r <= 0;
            win_cnt <= 0;
        end
        else if (frame_tick) begin

            // optional debug LEDs (low nibble)
            ledL <= score_left[3:0];
            ledR <= score_right[3:0];

            case (state)
            
              NEW_GAME: begin
                  ball_x <= SCREEN_W/2 - BALL_SIZE/2;
                  ball_y <= SCREEN_H/2 - BALL_SIZE/2;
            
                  padl_x <= PAD_OFFS;
                  padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;
            
                  padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
                  padr_y <= (SCREEN_H - PADR_HEIGHT)/2;
            
                  ball_dx <= 1'b1;
                  ball_dy <= 1'b0;
            
                  state <= PLAY;
              end
            
              PLAY: begin
                  // 1) OUT LEFT? (ขอบซ้าย) -> right scores
                  if ((!ball_dx) && (ball_x < BALL_SPX)) begin
            
                      // อัปเดตคะแนน: 10->11 แล้วเข้า GAME_OVER
                      if (score_right == MAX_SCORE-1) begin
                          score_right <= score_right + 1;     // = 11
                          win_cnt     <= WIN_DELAY_FRAMES;
                          state       <= GAME_OVER;
                      end else begin
                          score_right <= score_right + 1;
                          state       <= NEW_GAME;
                      end
            
                      // reset round กันนับซ้ำ (และให้ค้างกลางตอน GAME_OVER)
                      ball_x  <= SCREEN_W/2 - BALL_SIZE/2;
                      ball_y  <= SCREEN_H/2 - BALL_SIZE/2;
                      ball_dx <= 1'b1;
                      ball_dy <= 1'b0;
            
                      padl_x <= PAD_OFFS;
                      padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;
                      padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
                      padr_y <= (SCREEN_H - PADR_HEIGHT)/2;
                  end
            
                  // 2) OUT RIGHT? (ขอบขวา) -> left scores
                  else if ((ball_dx) && (ball_x + BALL_SIZE + BALL_SPX >= SCREEN_W)) begin
            
                      if (score_left == MAX_SCORE-1) begin
                          score_left <= score_left + 1;       // = 11
                          win_cnt    <= WIN_DELAY_FRAMES;
                          state      <= GAME_OVER;
                      end else begin
                          score_left <= score_left + 1;
                          state      <= NEW_GAME;
                      end
            
                      // reset round กันนับซ้ำ
                      ball_x  <= SCREEN_W/2 - BALL_SIZE/2;
                      ball_y  <= SCREEN_H/2 - BALL_SIZE/2;
                      ball_dx <= 1'b1;
                      ball_dy <= 1'b0;
            
                      padl_x <= PAD_OFFS;
                      padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;
                      padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
                      padr_y <= (SCREEN_H - PADR_HEIGHT)/2;
                  end
            
                  // 3) ไม่ OUT -> เดินลูก + ชน + เดินไม้
                  else begin
                      // --------- Ball X ---------
                      if (ball_dx) begin // right
                          if ((ball_x + BALL_SIZE + BALL_SPX >= padr_x) &&
                              (ball_y + BALL_SIZE >= padr_y) &&
                              (ball_y <= padr_y + PADR_HEIGHT)) begin
                              ball_dx <= 1'b0;
                              ball_x  <= padr_x - BALL_SIZE - 1;
                          end else begin
                              ball_x <= ball_x + BALL_SPX;
                          end
                      end else begin // left
                          if ((ball_x > padl_x + PAD_WIDTH) &&
                              (ball_x - BALL_SPX <= padl_x + PAD_WIDTH) &&
                              (ball_y + BALL_SIZE >= padl_y) &&
                              (ball_y <= padl_y + PADL_HEIGHT)) begin
                              ball_dx <= 1'b1;
                              ball_x  <= padl_x + PAD_WIDTH + 1;
                          end else begin
                              ball_x <= ball_x - BALL_SPX;
                          end
                      end
            
                      // --------- Ball Y ---------
                      if (!ball_dy) begin // down
                          if (ball_y + BALL_SIZE + BALL_SPY >= SCREEN_H) begin
                              ball_y  <= SCREEN_H - BALL_SIZE;
                              ball_dy <= 1'b1;
                          end else begin
                              ball_y <= ball_y + BALL_SPY;
                          end
                      end else begin // up
                          if (ball_y < BALL_SPY) begin
                              ball_y  <= 0;
                              ball_dy <= 1'b0;
                          end else begin
                              ball_y <= ball_y - BALL_SPY;
                          end
                      end
            
                      // --------- Player 1 (LEFT) Y ---------
                      if (p1_dn) begin
                          if (padl_y + PADL_HEIGHT + PADL_SPY >= SCREEN_H)
                              padl_y <= SCREEN_H - PADL_HEIGHT;
                          else
                              padl_y <= padl_y + PADL_SPY;
                      end
                      else if (p1_up) begin
                          if (padl_y < PADL_SPY)
                              padl_y <= 0;
                          else
                              padl_y <= padl_y - PADL_SPY;
                      end
                      
                      // --------- Player 1 (LEFT) X ---------
                      if (p1_left) begin
                          if (padl_x <= P1_X_MIN + PADL_SPX)
                              padl_x <= P1_X_MIN;
                          else
                              padl_x <= padl_x - PADL_SPX;
                      end
                      else if (p1_right) begin
                          if (padl_x + PADL_SPX >= P1_X_MAX)
                              padl_x <= P1_X_MAX;
                          else
                              padl_x <= padl_x + PADL_SPX;
                      end

            
                      // --------- Player 2 (RIGHT) Y ---------
                      if (p2_dn) begin
                          if (padr_y + PADR_HEIGHT + PADR_SPY >= SCREEN_H)
                              padr_y <= SCREEN_H - PADR_HEIGHT;
                          else
                              padr_y <= padr_y + PADR_SPY;
                      end else if (p2_up) begin
                          if (padr_y < PADR_SPY)
                              padr_y <= 0;
                          else
                              padr_y <= padr_y - PADR_SPY;
                      end
            
                      // --------- Player 2 (RIGHT) X (ครึ่งสนาม) ---------
                      if (p2_left) begin
                          if (padr_x <= P2_X_MIN + PADR_SPX)
                              padr_x <= P2_X_MIN;
                          else
                              padr_x <= padr_x - PADR_SPX;
                      end else if (p2_right) begin
                          if (padr_x + PADR_SPX >= P2_X_MAX)
                              padr_x <= P2_X_MAX;
                          else
                              padr_x <= padr_x + PADR_SPX;
                      end
                  end
              end
            
              GAME_OVER: begin
                  // หยุดลูก/หยุดไม้: state นี้ไม่อัปเดตตำแหน่ง
                  if (win_cnt == 0) begin
                      score_left  <= 0;
                      score_right <= 0;
                      state <= NEW_GAME;
                  end else begin
                      win_cnt <= win_cnt - 1;
                  end
              end
            
              default: state <= NEW_GAME;
            
            endcase
        end
    end

endmodule
