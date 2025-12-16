`timescale 1ns / 1ps

module pong(
    input  clk,
    input  btn_reset,
    input  pause,

    // Player 1
    input  btn1_up,
    input  btn1_dn,
    input  btn1_left,
    input  btn1_right,

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

    // vga interface
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

    wire p1_up, p1_dn, p1_left, p1_right;
    wire p2_up, p2_dn, p2_left, p2_right;

    assign p1_up    = ~btn2_up;
    assign p1_dn    = ~btn2_dn;
    assign p1_left  = ~btn2_left;
    assign p1_right = ~btn2_right;

    assign p2_up    = ~btn1_up;
    assign p2_dn    = ~btn1_dn;
    assign p2_left  = ~btn1_left;
    assign p2_right = ~btn1_right;

    // frame tick gen
    reg VS_old;
    wire frame_tick;

    always @(posedge clk) begin
        VS_old <= VS;
    end

    assign frame_tick = (VS == 1'b1) && (VS_old == 1'b0);

    // all parameters
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    localparam PAD_WIDTH   = 10;
    localparam PADL_HEIGHT = 48;
    localparam PADR_HEIGHT = 48;

    localparam MID_X = SCREEN_W/2;   //half screen clamps
    localparam GAP   = 4;

    localparam P1_X_MIN = 0;
    localparam P1_X_MAX = MID_X - GAP - PAD_WIDTH;

    localparam P2_X_MIN = MID_X + GAP;
    localparam P2_X_MAX = SCREEN_W - PAD_WIDTH;

    localparam LINE_W  = 4;
    localparam LINE_X0 = MID_X - (LINE_W/2);

    localparam BALL_SIZE = 8;
    localparam BALL_SPX  = 3;
    localparam BALL_SPY  = 3;

    localparam DECOY_SIZE = 6;

    localparam PAD_OFFS = 32;

    localparam PADL_SPX = 5;
    localparam PADL_SPY = 5;
    localparam PADR_SPX = 5;
    localparam PADR_SPY = 5;

    localparam MAX_SCORE = 11;

    // State
    localparam NEW_GAME  = 2'b00;
    localparam PLAY      = 2'b01;
    localparam GAME_OVER = 2'b10;

    localparam integer WIN_DELAY_FRAMES   = 60*4;
    localparam integer START_DELAY_FRAMES = 60*10;

    // Score rendering
    localparam SCORE_SCALE   = 6;
    localparam DIGIT_W       = 5 * SCORE_SCALE;
    localparam DIGIT_H       = 7 * SCORE_SCALE;
    localparam DIGIT_SPACING = SCORE_SCALE * 2;
    localparam DOUBLE_W      = DIGIT_W * 2 + DIGIT_SPACING;

    localparam SCORE_Y    = 30;
    localparam integer SCORE_MARGIN = 10;
    localparam P1_SCORE_X = LINE_X0 - SCORE_MARGIN - DOUBLE_W;
    localparam P2_SCORE_X = LINE_X0 + LINE_W + SCORE_MARGIN;

    // items
    localparam ITEM_SIZE   = 12;
    localparam ITEM_MARGIN = 8;

    localparam integer POWER_FRAMES  = 60*15;
    localparam integer SPEED_FRAMES  = 60*10;
    localparam integer SLOW_FRAMES   = 60*10;
    localparam integer RESPAWN_DELAY = 60*2;

    localparam [2:0] ITEM_LONG  = 3'd0;
    localparam [2:0] ITEM_SPEED = 3'd1;
    localparam [2:0] ITEM_SLOW  = 3'd2;
    localparam [2:0] ITEM_DECOY = 3'd3;

    // Ending message
    localparam MSG_SCALE   = 10;
    localparam MSG_CHAR_W  = 5 * MSG_SCALE;
    localparam MSG_CHAR_H  = 7 * MSG_SCALE;
    localparam MSG_SPACING = 2 * MSG_SCALE;

    localparam integer MSG_Y0 = (SCREEN_H/2) - (MSG_CHAR_H/2);

    localparam integer WIN_W  = (3*MSG_CHAR_W) + (2*MSG_SPACING);
    localparam integer LOSE_W = (4*MSG_CHAR_W) + (3*MSG_SPACING);

    localparam integer LEFT_WIN_X0  = (MID_X/2) - (WIN_W/2);
    localparam integer LEFT_LOSE_X0 = (MID_X/2) - (LOSE_W/2);

    localparam integer RIGHT_WIN_X0  = MID_X + (MID_X/2) - (WIN_W/2);
    localparam integer RIGHT_LOSE_X0 = MID_X + (MID_X/2) - (LOSE_W/2);

   
    reg [1:0] state;

    reg [9:0] ball_x, ball_y;
    reg       ball_dx;    // 1=right, 0=left
    reg       ball_dy;    // 1=up,    0=down
    reg [3:0] ball_spx, ball_spy;
    reg [9:0] next_ball_x;

    reg [9:0] padl_x, padl_y;
    reg [9:0] padr_x, padr_y;

    reg [7:0] score_left;
    reg [7:0] score_right;

    reg [15:0] win_cnt;
    reg [15:0] start_cnt;
    reg first_start;

    reg winner_left; // 1 = left wins
    reg serve_left;  // 1 = left serve

    reg        item_active;
    reg        spawn_pending;
    reg [2:0]  item_type;
    reg [9:0]  item_x, item_y;
    reg [15:0] lfsr;

    reg [15:0] p1_long_cnt,  p2_long_cnt;
    reg [15:0] p1_speed_cnt, p2_speed_cnt;
    reg [15:0] p1_slow_cnt,  p2_slow_cnt;

    reg [15:0] spawn_delay_cnt;

    // Decoy regs
    reg        decoy_active;
    reg        padl_preactive, padr_preactive; 
    reg [9:0]  decoy_x, decoy_y;
    reg signed [10:0] decoy_vx, decoy_vy;
    reg [1:0]  decoy_grace; // prevent early collision with it own paddle

    reg signed [10:0] p1_decoy_vx, p1_decoy_vy;
    reg signed [10:0] p2_decoy_vx, p2_decoy_vy;

    // isEffected?
    wire p1_long, p2_long, p1_speed, p2_speed, p1_slowed, p2_slowed;
    assign p1_long   = (p1_long_cnt  != 0);
    assign p2_long   = (p2_long_cnt  != 0);
    assign p1_speed  = (p1_speed_cnt != 0);
    assign p2_speed  = (p2_speed_cnt != 0);
    assign p1_slowed = (p1_slow_cnt  != 0);
    assign p2_slowed = (p2_slow_cnt  != 0);

    wire [9:0] padl_h, padr_h;
    assign padl_h = p1_long ? (PADL_HEIGHT*2) : PADL_HEIGHT;
    assign padr_h = p2_long ? (PADR_HEIGHT*2) : PADR_HEIGHT;

    // slow
    wire [3:0] p1_spx_eff, p1_spy_eff, p2_spx_eff, p2_spy_eff;
    assign p1_spx_eff = p1_slowed ? ((PADL_SPX * 3) / 4) : PADL_SPX;
    assign p1_spy_eff = p1_slowed ? ((PADL_SPY * 3) / 4) : PADL_SPY;

    assign p2_spx_eff = p2_slowed ? ((PADR_SPX * 3) / 4) : PADR_SPX;
    assign p2_spy_eff = p2_slowed ? ((PADR_SPY * 3) / 4) : PADR_SPY;

    // tentative spawn point
    wire [9:0] cand_x, cand_y;
    assign cand_x = (lfsr[9:0]  % (SCREEN_W - 2*ITEM_MARGIN - ITEM_SIZE)) + ITEM_MARGIN;
    assign cand_y = (lfsr[15:6] % (SCREEN_H - 2*ITEM_MARGIN - ITEM_SIZE)) + ITEM_MARGIN;

   //print score & ending (bitmap)
    function [34:0] digit_bitmap;
        input [3:0] value;
        begin
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
        end
    endfunction

    localparam [34:0] BM_W = 35'b10001_10001_10001_10101_10101_11011_10001;
    localparam [34:0] BM_I = 35'b11111_00100_00100_00100_00100_00100_11111;
    localparam [34:0] BM_N = 35'b10001_11001_10101_10011_10001_10001_10001;
    localparam [34:0] BM_L = 35'b10000_10000_10000_10000_10000_10000_11111;
    localparam [34:0] BM_O = 35'b01110_10001_10001_10001_10001_10001_01110;
    localparam [34:0] BM_S = 35'b01111_10000_10000_01110_00001_00001_11110;
    localparam [34:0] BM_E = 35'b11111_10000_10000_11110_10000_10000_11111;

    function automatic is_bad_spawn;
        input [9:0] sx;
        input [9:0] sy;
        reg in_left_score, in_right_score, in_center, out_border;
        begin
            out_border =
                (sx < ITEM_MARGIN) ||
                (sy < ITEM_MARGIN) ||
                (sx + ITEM_SIZE >= SCREEN_W - ITEM_MARGIN) ||
                (sy + ITEM_SIZE >= SCREEN_H - ITEM_MARGIN);

            in_left_score =
                (sx < (P1_SCORE_X + DOUBLE_W)) && (sx + ITEM_SIZE > P1_SCORE_X) &&
                (sy < (SCORE_Y + 7*SCORE_SCALE)) && (sy + ITEM_SIZE > SCORE_Y);

            in_right_score =
                (sx < (P2_SCORE_X + DOUBLE_W)) && (sx + ITEM_SIZE > P2_SCORE_X) &&
                (sy < (SCORE_Y + 7*SCORE_SCALE)) && (sy + ITEM_SIZE > SCORE_Y);

            in_center =
                (sx < (LINE_X0 + LINE_W)) && (sx + ITEM_SIZE > LINE_X0);

            is_bad_spawn = out_border || in_left_score || in_right_score || in_center;
        end
    endfunction

    //score 
    wire [3:0] sl_tens = score_left / 10;
    wire [3:0] sl_ones = score_left % 10;
    wire [3:0] sr_tens = score_right / 10;
    wire [3:0] sr_ones = score_right % 10;

    wire [34:0] sl_tens_bm = digit_bitmap(sl_tens);
    wire [34:0] sl_ones_bm = digit_bitmap(sl_ones);
    wire [34:0] sr_tens_bm = digit_bitmap(sr_tens);
    wire [34:0] sr_ones_bm = digit_bitmap(sr_ones);

    reg [2:0] row_idx;
    reg [2:0] col_idx;
    reg [5:0] bit_idx;

    reg ball_pix, padl_pix, padr_pix, item_pix, decoy_pix;

    integer msg_x0;
    integer word_is_win;

    // rendering
    always @(*) begin
        color    = 12'h000;

        row_idx  = 0;
        col_idx  = 0;
        bit_idx  = 0;

        ball_pix  = 0;
        padl_pix  = 0;
        padr_pix  = 0;
        item_pix  = 0;
        decoy_pix = 0;

        msg_x0 = 0;
        word_is_win = 0;

        if (state == GAME_OVER) begin
            if (x < MID_X) begin
                color = (winner_left) ? 12'h0F0 : 12'hF00;
            end else begin
                color = (winner_left) ? 12'hF00 : 12'h0F0;
            end

            if (x < MID_X) begin
                word_is_win = (winner_left) ? 1 : 0;
                msg_x0      = (winner_left) ? LEFT_WIN_X0 : LEFT_LOSE_X0;
            end else begin
                word_is_win = (winner_left) ? 0 : 1;
                msg_x0      = (word_is_win) ? RIGHT_WIN_X0 : RIGHT_LOSE_X0;
            end

            if ((y >= MSG_Y0) && (y < MSG_Y0 + MSG_CHAR_H)) begin
                row_idx = (y - MSG_Y0) / MSG_SCALE;

                if (word_is_win) begin
                    if ((x >= msg_x0) && (x < msg_x0 + MSG_CHAR_W)) begin
                        col_idx = (x - msg_x0) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_W[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if ((x >= msg_x0 + (MSG_CHAR_W + MSG_SPACING)) &&
                                 (x <  msg_x0 + (MSG_CHAR_W + MSG_SPACING) + MSG_CHAR_W)) begin
                        col_idx = (x - (msg_x0 + (MSG_CHAR_W + MSG_SPACING))) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_I[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if ((x >= msg_x0 + 2*(MSG_CHAR_W + MSG_SPACING)) &&
                                 (x <  msg_x0 + 2*(MSG_CHAR_W + MSG_SPACING) + MSG_CHAR_W)) begin
                        col_idx = (x - (msg_x0 + 2*(MSG_CHAR_W + MSG_SPACING))) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_N[34 - bit_idx]) color = 12'hFFF;
                        end
                    end
                end else begin
                    if ((x >= msg_x0) && (x < msg_x0 + MSG_CHAR_W)) begin
                        col_idx = (x - msg_x0) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_L[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if ((x >= msg_x0 + (MSG_CHAR_W + MSG_SPACING)) &&
                                 (x <  msg_x0 + (MSG_CHAR_W + MSG_SPACING) + MSG_CHAR_W)) begin
                        col_idx = (x - (msg_x0 + (MSG_CHAR_W + MSG_SPACING))) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_O[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if ((x >= msg_x0 + 2*(MSG_CHAR_W + MSG_SPACING)) &&
                                 (x <  msg_x0 + 2*(MSG_CHAR_W + MSG_SPACING) + MSG_CHAR_W)) begin
                        col_idx = (x - (msg_x0 + 2*(MSG_CHAR_W + MSG_SPACING))) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_S[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if ((x >= msg_x0 + 3*(MSG_CHAR_W + MSG_SPACING)) &&
                                 (x <  msg_x0 + 3*(MSG_CHAR_W + MSG_SPACING) + MSG_CHAR_W)) begin
                        col_idx = (x - (msg_x0 + 3*(MSG_CHAR_W + MSG_SPACING))) / MSG_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (BM_E[34 - bit_idx]) color = 12'hFFF;
                        end
                    end
                end
            end
        end else begin
            if ((x >= P1_SCORE_X) &&
                (x <  P1_SCORE_X + ((score_left >= 10) ? DOUBLE_W : DIGIT_W)) &&
                (y >= SCORE_Y) &&
                (y <  SCORE_Y + 7*SCORE_SCALE)) begin

                row_idx = (y - SCORE_Y) / SCORE_SCALE;

                if (score_left >= 10) begin
                    if (x < P1_SCORE_X + DIGIT_W) begin
                        col_idx = (x - P1_SCORE_X) / SCORE_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (sl_tens_bm[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if (x >= P1_SCORE_X + DIGIT_W + DIGIT_SPACING) begin
                        col_idx = (x - (P1_SCORE_X + DIGIT_W + DIGIT_SPACING)) / SCORE_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (sl_ones_bm[34 - bit_idx]) color = 12'hFFF;
                        end
                    end
                end else begin
                    col_idx = (x - P1_SCORE_X) / SCORE_SCALE;
                    if (row_idx < 7 && col_idx < 5) begin
                        bit_idx = row_idx * 5 + col_idx;
                        if (sl_ones_bm[34 - bit_idx]) color = 12'hFFF;
                    end
                end
            end
            else if ((x >= P2_SCORE_X) &&
                     (x <  P2_SCORE_X + ((score_right >= 10) ? DOUBLE_W : DIGIT_W)) &&
                     (y >= SCORE_Y) &&
                     (y <  SCORE_Y + 7*SCORE_SCALE)) begin

                row_idx = (y - SCORE_Y) / SCORE_SCALE;

                if (score_right >= 10) begin
                    if (x < P2_SCORE_X + DIGIT_W) begin
                        col_idx = (x - P2_SCORE_X) / SCORE_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (sr_tens_bm[34 - bit_idx]) color = 12'hFFF;
                        end
                    end else if (x >= P2_SCORE_X + DIGIT_W + DIGIT_SPACING) begin
                        col_idx = (x - (P2_SCORE_X + DIGIT_W + DIGIT_SPACING)) / SCORE_SCALE;
                        if (row_idx < 7 && col_idx < 5) begin
                            bit_idx = row_idx * 5 + col_idx;
                            if (sr_ones_bm[34 - bit_idx]) color = 12'hFFF;
                        end
                    end
                end else begin
                    col_idx = (x - P2_SCORE_X) / SCORE_SCALE;
                    if (row_idx < 7 && col_idx < 5) begin
                        bit_idx = row_idx * 5 + col_idx;
                        if (sr_ones_bm[34 - bit_idx]) color = 12'hFFF;
                    end
                end
            end
            else if ((x >= LINE_X0) && (x < LINE_X0 + LINE_W) && (y[4] == 1'b0)) begin
                color = 12'hFFF;
            end
            else begin
                item_pix = item_active &&
                           (x >= item_x) && (x < item_x + ITEM_SIZE) &&
                           (y >= item_y) && (y < item_y + ITEM_SIZE);

                ball_pix = (x >= ball_x) && (x < ball_x + BALL_SIZE) &&
                           (y >= ball_y) && (y < ball_y + BALL_SIZE);

                decoy_pix = decoy_active &&
                            (x >= decoy_x) && (x < decoy_x + DECOY_SIZE) &&
                            (y >= decoy_y) && (y < decoy_y + DECOY_SIZE);

                padl_pix = (x >= padl_x) && (x < padl_x + PAD_WIDTH) &&
                           (y >= padl_y) && (y < padl_y + padl_h);

                padr_pix = (x >= padr_x) && (x < padr_x + PAD_WIDTH) &&
                           (y >= padr_y) && (y < padr_y + padr_h);

                if (item_pix) begin
                    case (item_type)
                        ITEM_LONG :  color = 12'hF00;
                        ITEM_SPEED:  color = 12'h0FF;
                        ITEM_SLOW :  color = 12'hFF0;
                        default  :   color = 12'hbf40bf; // DECOY
                    endcase
                end
                else if (ball_pix)
                    color = 12'h0F0; 
                else if (decoy_pix)
                    color = 12'h0F0; 
                else if (padl_pix || padr_pix)
                    color = 12'hFFF;
                else
                    color = 12'h000;
            end
        end
    end

    assign RED   = (blank ? 4'b0000 : color[11:8]);
    assign GREEN = (blank ? 4'b0000 : color[7:4]);
    assign BLUE  = (blank ? 4'b0000 : color[3:0]);

   //in game
    integer signed dx_tmp;
    integer signed dy_tmp;

    always @(posedge clk) begin
        if (btn_reset) begin
            first_start <= 1'b1;
            start_cnt   <= START_DELAY_FRAMES;
            serve_left  <= 1'b1;

            // decoy reset
            decoy_active    <= 1'b0;
            padl_preactive  <= 1'b0;
            padr_preactive  <= 1'b0;
            decoy_x         <= 10'd0;
            decoy_y         <= 10'd0;
            decoy_vx        <= 11'sd0;
            decoy_vy        <= 11'sd0;
            decoy_grace     <= 2'd0;

            p1_decoy_vx <= 11'sd3;  p1_decoy_vy <= 11'sd1;
            p2_decoy_vx <= -11'sd3; p2_decoy_vy <= 11'sd1;

            state <= NEW_GAME;

            padl_x <= PAD_OFFS;
            padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;

            padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
            padr_y <= (SCREEN_H - PADR_HEIGHT)/2;

            ball_x <= SCREEN_W/2 - BALL_SIZE/2;
            ball_y <= SCREEN_H/2 - BALL_SIZE/2;

            ball_dx  <= 1'b1;
            ball_dy  <= 1'b0;
            ball_spx <= BALL_SPX;
            ball_spy <= BALL_SPY;

            score_left  <= 0;
            score_right <= 0;

            ledL <= 0;
            ledR <= 0;

            win_cnt      <= 0;
            winner_left  <= 1'b0;

            item_active     <= 1'b0;
            spawn_pending   <= 1'b0;
            item_type       <= ITEM_LONG;
            item_x          <= 100;
            item_y          <= 200;
            lfsr            <= 16'hACE1;

            p1_long_cnt     <= 0;
            p2_long_cnt     <= 0;
            p1_speed_cnt    <= 0;
            p2_speed_cnt    <= 0;
            p1_slow_cnt     <= 0;
            p2_slow_cnt     <= 0;

            spawn_delay_cnt <= 0;

        end else if (frame_tick) begin
            ledL <= score_left[3:0];
            ledR <= score_right[3:0];

            if (!pause) begin
                lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

                // effect durations
                if (p1_long_cnt  != 0) p1_long_cnt  <= p1_long_cnt  - 1;
                if (p2_long_cnt  != 0) p2_long_cnt  <= p2_long_cnt  - 1;
                if (p1_speed_cnt != 0) p1_speed_cnt <= p1_speed_cnt - 1;
                if (p2_speed_cnt != 0) p2_speed_cnt <= p2_speed_cnt - 1;
                if (p1_slow_cnt  != 0) p1_slow_cnt  <= p1_slow_cnt  - 1;
                if (p2_slow_cnt  != 0) p2_slow_cnt  <= p2_slow_cnt  - 1;

                // spawn delay , request spawn
                if (!item_active) begin
                    if (spawn_delay_cnt != 0)
                        spawn_delay_cnt <= spawn_delay_cnt - 1;
                    else if (!spawn_pending)
                        spawn_pending <= 1'b1;
                end

                if (spawn_pending) begin
                    if (!is_bad_spawn(cand_x, cand_y)) begin
                        item_x <= cand_x;
                        item_y <= cand_y;

                        case (lfsr[2:0])
                            3'b000: item_type <= ITEM_LONG;
                            3'b001: item_type <= ITEM_SPEED;
                            3'b010: item_type <= ITEM_SLOW;
                            3'b011: item_type <= ITEM_DECOY;
                            default: item_type <= ITEM_LONG;
                        endcase

                        item_active   <= 1'b1;
                        spawn_pending <= 1'b0;
                    end
                end

                if (decoy_grace != 0)
                    decoy_grace <= decoy_grace - 1;

                case (state)
                    NEW_GAME: begin
                        if (first_start && start_cnt != 0) begin
                            start_cnt <= start_cnt - 1;
                        end else begin
                            first_start <= 1'b0;
                            serve_left  <= ~serve_left;

                            ball_x <= serve_left
                                      ? (PAD_OFFS + PAD_WIDTH + 2)
                                      : (SCREEN_W - PAD_OFFS - PAD_WIDTH - BALL_SIZE - 2);
                            ball_y <= SCREEN_H/2 - BALL_SIZE/2;

                            
                            padl_x <= PAD_OFFS;
                            padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;
                            padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
                            padr_y <= (SCREEN_H - PADR_HEIGHT)/2;

                            ball_dx <= serve_left ? 1'b1 : 1'b0;
                            ball_dy <= 1'b0;

                            
                            ball_spx <= BALL_SPX;
                            ball_spy <= BALL_SPY;

                            state <= PLAY;
                        end
                    end

                    PLAY: begin
                        if ((!ball_dx) && (ball_x < ball_spx)) begin
                            if (score_right == MAX_SCORE-1) begin
                                score_right <= score_right + 1;
                                win_cnt     <= WIN_DELAY_FRAMES;
                                state       <= GAME_OVER;
                                winner_left <= 1'b0;
                            end else begin
                                score_right <= score_right + 1;
                                state       <= NEW_GAME;
                            end

                            ball_x  <= SCREEN_W/2 - BALL_SIZE/2;
                            ball_y  <= SCREEN_H/2 - BALL_SIZE/2;
                            ball_dx <= 1'b1;
                            ball_dy <= 1'b0;

                            ball_spx <= BALL_SPX;
                            ball_spy <= BALL_SPY;

                            padl_x <= PAD_OFFS;
                            padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;
                            padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
                            padr_y <= (SCREEN_H - PADR_HEIGHT)/2;
                        end

                        else if ((ball_dx) && (ball_x + BALL_SIZE + ball_spx >= SCREEN_W)) begin
                            if (score_left == MAX_SCORE-1) begin
                                score_left  <= score_left + 1;
                                win_cnt     <= WIN_DELAY_FRAMES;
                                state       <= GAME_OVER;
                                winner_left <= 1'b1;
                            end else begin
                                score_left <= score_left + 1;
                                state      <= NEW_GAME;
                            end

                            ball_x  <= SCREEN_W/2 - BALL_SIZE/2;
                            ball_y  <= SCREEN_H/2 - BALL_SIZE/2;
                            ball_dx <= 1'b1;
                            ball_dy <= 1'b0;

                            ball_spx <= BALL_SPX;
                            ball_spy <= BALL_SPY;

                            padl_x <= PAD_OFFS;
                            padr_x <= SCREEN_W - PAD_OFFS - PAD_WIDTH;
                            padl_y <= (SCREEN_H - PADL_HEIGHT)/2;
                            padr_y <= (SCREEN_H - PADR_HEIGHT)/2;
                        end
                        else begin
                            // ITEM PICKUP
                            if (item_active) begin
                                if ((padl_x < item_x + ITEM_SIZE) && (padl_x + PAD_WIDTH > item_x) &&
                                    (padl_y < item_y + ITEM_SIZE) && (padl_y + padl_h     > item_y)) begin

                                    item_active <= 1'b0;

                                    if (item_type == ITEM_LONG)
                                        p1_long_cnt  <= POWER_FRAMES;
                                    else if (item_type == ITEM_SPEED)
                                        p1_speed_cnt <= SPEED_FRAMES;
                                    else if (item_type == ITEM_DECOY) begin
                                        padl_preactive <= 1'b1;
                                        case (lfsr[5:3])
                                            3'd0: begin p1_decoy_vx <=  11'sd3; p1_decoy_vy <=  11'sd1; end
                                            3'd1: begin p1_decoy_vx <=  11'sd3; p1_decoy_vy <= -11'sd1; end
                                            3'd2: begin p1_decoy_vx <=  11'sd2; p1_decoy_vy <=  11'sd2; end
                                            3'd3: begin p1_decoy_vx <=  11'sd2; p1_decoy_vy <= -11'sd2; end
                                            3'd4: begin p1_decoy_vx <=  11'sd4; p1_decoy_vy <=  11'sd1; end
                                            3'd5: begin p1_decoy_vx <=  11'sd4; p1_decoy_vy <= -11'sd1; end
                                            3'd6: begin p1_decoy_vx <=  11'sd3; p1_decoy_vy <=  11'sd3; end
                                            default: begin p1_decoy_vx <=  11'sd3; p1_decoy_vy <= -11'sd3; end
                                        endcase
                                    end
                                    else
                                        p2_slow_cnt  <= SLOW_FRAMES;

                                    spawn_pending   <= 1'b0;
                                    spawn_delay_cnt <= RESPAWN_DELAY;
                                end
                                else if ((padr_x < item_x + ITEM_SIZE) && (padr_x + PAD_WIDTH > item_x) &&
                                         (padr_y < item_y + ITEM_SIZE) && (padr_y + padr_h     > item_y)) begin

                                    item_active <= 1'b0;

                                    if (item_type == ITEM_LONG)
                                        p2_long_cnt  <= POWER_FRAMES;
                                    else if (item_type == ITEM_SPEED)
                                        p2_speed_cnt <= SPEED_FRAMES;
                                    else if (item_type == ITEM_DECOY) begin
                                        padr_preactive <= 1'b1;
                                        case (lfsr[5:3])
                                            3'd0: begin p2_decoy_vx <= -11'sd3; p2_decoy_vy <=  11'sd1; end
                                            3'd1: begin p2_decoy_vx <= -11'sd3; p2_decoy_vy <= -11'sd1; end
                                            3'd2: begin p2_decoy_vx <= -11'sd2; p2_decoy_vy <=  11'sd2; end
                                            3'd3: begin p2_decoy_vx <= -11'sd2; p2_decoy_vy <= -11'sd2; end
                                            3'd4: begin p2_decoy_vx <= -11'sd4; p2_decoy_vy <=  11'sd1; end
                                            3'd5: begin p2_decoy_vx <= -11'sd4; p2_decoy_vy <= -11'sd1; end
                                            3'd6: begin p2_decoy_vx <= -11'sd3; p2_decoy_vy <=  11'sd3; end
                                            default: begin p2_decoy_vx <= -11'sd3; p2_decoy_vy <= -11'sd3; end
                                        endcase
                                    end
                                    else
                                        p1_slow_cnt  <= SLOW_FRAMES;

                                    spawn_pending   <= 1'b0;
                                    spawn_delay_cnt <= RESPAWN_DELAY;
                                end
                            end

                            // paddle/ball collsion
                            if (ball_dx) begin
                                next_ball_x = ball_x + ball_spx;

                                if ((next_ball_x + BALL_SIZE >= padr_x) &&
                                    (next_ball_x <= padr_x + PAD_WIDTH) &&
                                    (ball_y + BALL_SIZE >= padr_y) &&
                                    (ball_y <= padr_y + padr_h)) begin

                                    // hit right paddle
                                    ball_dx <= 1'b0;
                                    ball_x  <= padr_x - BALL_SIZE - 1;

                                    //spawn decoy
                                    if (padr_preactive && !decoy_active) begin
                                        decoy_active <= 1'b1;
                                        decoy_grace  <= 2'd2;

                                
                                        decoy_x <= (padr_x > (DECOY_SIZE+6)) ? (padr_x - DECOY_SIZE - 6) : 10'd0;
                                        decoy_y <= (ball_y + 2);

                                        decoy_vx <= p2_decoy_vx;
                                        decoy_vy <= p2_decoy_vy;

                                        padr_preactive <= 1'b0;
                                    end

                                    if (p2_speed) begin
                                        ball_spx <= (BALL_SPX * 3) / 2;
                                        ball_spy <= (BALL_SPY * 3) / 2;
                                    end else begin
                                        ball_spx <= BALL_SPX;
                                        ball_spy <= BALL_SPY;
                                    end
                                end else begin
                                    ball_x <= next_ball_x;
                                end

                            end else begin
                                next_ball_x = ball_x - ball_spx;

                                if ((next_ball_x <= padl_x + PAD_WIDTH) &&
                                    (next_ball_x + BALL_SIZE >= padl_x) &&
                                    (ball_y + BALL_SIZE >= padl_y) &&
                                    (ball_y <= padl_y + padl_h)) begin

                                    // hit left paddle
                                    ball_dx <= 1'b1;
                                    ball_x  <= padl_x + PAD_WIDTH + 1;

                                   
                                    if (padl_preactive && !decoy_active) begin
                                        decoy_active <= 1'b1;
                                        decoy_grace  <= 2'd2;

                                        decoy_x <= padl_x + PAD_WIDTH + 6;
                                        decoy_y <= (ball_y + 2);

                                        decoy_vx <= p1_decoy_vx;
                                        decoy_vy <= p1_decoy_vy;

                                        padl_preactive <= 1'b0;
                                    end

                                    if (p1_speed) begin
                                        ball_spx <= (BALL_SPX * 3) / 2;
                                        ball_spy <= (BALL_SPY * 3) / 2;
                                    end else begin
                                        ball_spx <= BALL_SPX;
                                        ball_spy <= BALL_SPY;
                                    end
                                end else begin
                                    ball_x <= next_ball_x;
                                end
                            end

                            // Ball Y
                            if (!ball_dy) begin
                                if (ball_y + BALL_SIZE + ball_spy >= SCREEN_H) begin
                                    ball_y  <= SCREEN_H - BALL_SIZE;
                                    ball_dy <= 1'b1;
                                end else begin
                                    ball_y <= ball_y + ball_spy;
                                end
                            end else begin
                                if (ball_y < ball_spy) begin
                                    ball_y  <= 0;
                                    ball_dy <= 1'b0;
                                end else begin
                                    ball_y <= ball_y - ball_spy;
                                end
                            end

                            
                            //decoy
                            if (decoy_active) begin
                                dx_tmp = $signed({1'b0, decoy_x}) + decoy_vx;
                                dy_tmp = $signed({1'b0, decoy_y}) + decoy_vy;

                                // if out
                                if (dx_tmp <= 0 || (dx_tmp + DECOY_SIZE) >= SCREEN_W) begin
                                    decoy_active <= 1'b0;
                                end else begin
                                    // top/bottom bounce
                                    if (dy_tmp <= 0) begin
                                        dy_tmp   = 0;
                                        decoy_vy <= -decoy_vy;
                                    end else if ((dy_tmp + DECOY_SIZE) >= SCREEN_H) begin
                                        dy_tmp   = SCREEN_H - DECOY_SIZE;
                                        decoy_vy <= -decoy_vy;
                                    end

                                    decoy_x <= dx_tmp[9:0];
                                    decoy_y <= dy_tmp[9:0];

                                    // if hit paddle
                                    if (decoy_grace == 0) begin
                                        if ( (dx_tmp < (padr_x + PAD_WIDTH)) && ((dx_tmp + DECOY_SIZE) > padr_x) &&
                                             (dy_tmp < (padr_y + padr_h))     && ((dy_tmp + DECOY_SIZE) > padr_y) )
                                            decoy_active <= 1'b0;
                                        else if ( (dx_tmp < (padl_x + PAD_WIDTH)) && ((dx_tmp + DECOY_SIZE) > padl_x) &&
                                                  (dy_tmp < (padl_y + padl_h))     && ((dy_tmp + DECOY_SIZE) > padl_y) )
                                            decoy_active <= 1'b0;
                                    end
                                end
                            end

                            // Player 1 movement
                            if (p1_dn) begin
                                if (padl_y + padl_h + p1_spy_eff >= SCREEN_H)
                                    padl_y <= SCREEN_H - padl_h;
                                else
                                    padl_y <= padl_y + p1_spy_eff;
                            end else if (p1_up) begin
                                if (padl_y < p1_spy_eff)
                                    padl_y <= 0;
                                else
                                    padl_y <= padl_y - p1_spy_eff;
                            end

                            if (p1_left) begin
                                if (padl_x <= P1_X_MIN + p1_spx_eff)
                                    padl_x <= P1_X_MIN;
                                else
                                    padl_x <= padl_x - p1_spx_eff;
                            end else if (p1_right) begin
                                if (padl_x + p1_spx_eff >= P1_X_MAX)
                                    padl_x <= P1_X_MAX;
                                else
                                    padl_x <= padl_x + p1_spx_eff;
                            end

                            // Player 2 movement
                            if (p2_dn) begin
                                if (padr_y + padr_h + p2_spy_eff >= SCREEN_H)
                                    padr_y <= SCREEN_H - padr_h;
                                else
                                    padr_y <= padr_y + p2_spy_eff;
                            end else if (p2_up) begin
                                if (padr_y < p2_spy_eff)
                                    padr_y <= 0;
                                else
                                    padr_y <= padr_y - p2_spy_eff;
                            end

                            if (p2_left) begin
                                if (padr_x <= P2_X_MIN + p2_spx_eff)
                                    padr_x <= P2_X_MIN;
                                else
                                    padr_x <= padr_x - p2_spx_eff;
                            end else if (p2_right) begin
                                if (padr_x + p2_spx_eff >= P2_X_MAX)
                                    padr_x <= P2_X_MAX;
                                else
                                    padr_x <= padr_x + p2_spx_eff;
                            end
                        end
                    end

                    GAME_OVER: begin
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
            end // !pause
        end // frame_tick
    end // always

endmodule
