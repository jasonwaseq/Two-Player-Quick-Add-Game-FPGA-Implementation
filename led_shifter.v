`timescale 1ns / 1ps

module led_shifter(
    input clk_i,
    input left,
    input right,
    input change_score,
    input match,
    output [15:0] q_o,
    output game_over
    );
    
    wire [15:0] q, d;
    
    assign q_o[8] = left;
    assign q_o[7] = right;
    assign q_o[15:10] = q[15:10];
    assign q_o[5:0] = q[5:0];
    assign game_over = (q[10]|q[5]) | (q[15] ^ q[0]);
    
    assign d = ({16{left}} &{16{right}} & {16{match}} & q & {16{change_score}}) //left&right&match/do nothing
               | ( {16{left}} &  {16{right}} & ~{16{match}} & {q[14:10], 1'b0,4'b0000,1'b0, q[5:1]} & {16{change_score}}) //left&right&notmatch/-1left&-1right
               | ( {16{left}} & ~{16{right}} &  {16{match}} & {1'b1, q[15:11],4'b0000,q[5:0]} & {16{change_score}}) //left&match/+1left
               | (~{16{left}} &  {16{right}} &  {16{match}} & {q[15:10],4'b0000,q[4:0], 1'b1} & {16{change_score}}) //right&match/+1right
               | ( {16{left}} &  ~{16{right}} & ~{16{match}} & {q[14:10], 1'b0,4'b0000, q[5:0]} & {16{change_score}}) //left&notmatch/-1left
               | (~{16{left}} & {16{right}} & ~{16{match}} & {q[15:10],4'b0000,1'b0, q[5:1]} & {16{change_score}}) //right&notmatch/-1right
               | ( q & ~{16{change_score}});

    FDRE #(.INIT(1'b1)) LEFT_LEDS       [2:0] (.C({3{clk_i}}), .R({3{1'b0}}), .CE({3{1'b1}}), .D(d[15:13]), .Q(q[15:13]));
    FDRE #(.INIT(1'b1)) RIGHT_LEDS      [2:0] (.C({3{clk_i}}), .R({3{1'b0}}), .CE({3{1'b1}}), .D(d[2:0]), .Q(q[2:0]));
    FDRE #(.INIT(1'b0)) LEFT_GAME_LEDS  [2:0] (.C({3{clk_i}}), .R({3{1'b0}}), .CE({3{1'b1}}), .D(d[12:10]), .Q(q[12:10]));
    FDRE #(.INIT(1'b0)) RIGHT_GAME_LEDS [2:0] (.C({3{clk_i}}), .R({3{1'b0}}), .CE({3{1'b1}}), .D(d[5:3]), .Q(q[5:3]));
    
endmodule