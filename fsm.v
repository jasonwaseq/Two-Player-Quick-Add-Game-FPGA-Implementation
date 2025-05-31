`timescale 1ns / 1ps

module fsm(
    input clk_i,
    input go_i,
    input stop_i,
    input four_secs_i,
    input two_secs_i,
    input match_i,
    input game_over_i,
    output load_target_o,
    output reset_timer_o,
    output load_numbers_o,
    output change_score_o,
    output flash_both_o,
    output flash_alt_o
    );

    wire idle, game, flash, game_over;
    wire next_idle, next_game, next_flash, next_game_over;
    
    assign idle = (next_idle & ~go_i) | (next_flash & four_secs_i & ~game_over_i);
    assign game = (next_game & ~two_secs_i) | (next_idle & go_i) | (next_game & two_secs_i & ~stop_i);
    assign flash = (next_game & stop_i & two_secs_i) | (next_flash & ~four_secs_i);
    assign game_over = (next_flash & game_over_i & four_secs_i);

    assign load_target_o = (next_idle & go_i);
    assign reset_timer_o = (next_idle & go_i) | (next_game & two_secs_i);
    assign load_numbers_o = (next_game & two_secs_i & ~stop_i);
    assign change_score_o = next_game & stop_i & two_secs_i;
    assign flash_both_o = next_flash & ~match_i & ~four_secs_i;
    assign flash_alt_o = next_flash & match_i & ~four_secs_i;

    FDRE #(.INIT(1'b1)) NEXT_IDLE      (.C(clk_i), .R(1'b0), .CE(1'b1), .D(idle), .Q(next_idle));
    FDRE #(.INIT(1'b0)) NEXT_GAME      (.C(clk_i), .R(1'b0), .CE(1'b1), .D(game), .Q(next_game));
    FDRE #(.INIT(1'b0)) NEXT_FLASH     (.C(clk_i), .R(1'b0), .CE(1'b1), .D(flash), .Q(next_flash));
    FDRE #(.INIT(1'b0)) NEXT_GAME_OVER (.C(clk_i), .R(1'b0), .CE(1'b1), .D(game_over), .Q(next_game_over));

endmodule