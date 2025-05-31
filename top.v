`timescale 1ns / 1ps

module top(
    input clkin,
    input [15:0] sw,
    input btnC,
    input btnR,
    input btnL,
    input btnD,
    output [3:0] an,
    output [6:0] seg,
    output [15:0] led,
    output dp
    );

    wire clk, digsel, qsec;
    lab5_clks slowit(
        .clkin(clkin),
        .greset(btnD),
        .clk(clk),
        .digsel(digsel),
        .qsec(qsec)
    );
    
    wire [5:0] sec_q;
    wire reset_timer;
    time_counter time_counter(
        .clk_i(clk),
        .inc_i(qsec),
        .reset_i(reset_timer),
        .q_o(sec_q)
    );
   wire two_secs  = ~sec_q[4] & sec_q[3] & sec_q[2] & ~sec_q[1] & ~sec_q[0];        
   wire four_secs = sec_q[4] & sec_q[3] & ~sec_q[2] & ~sec_q[1] & ~sec_q[0]; 
    
    wire [7:0] random;
    lfsr lfsr (
    .clk_i(clk),
    .q_o(random)
    );
    
    wire [15:0] q;
    wire [7:0] q_o;
    FDRE #(.INIT(1'b0)) NUMBERS[7:0] (.C({8{clk}}), .R({8{1'b0}}), .CE({8{load_numbers}}), .D(random), .Q(q_o[7:0]));
    FDRE #(.INIT(1'b0)) TARGET[3:0]  (.C({4{clk}}), .R({4{1'b0}}), .CE({4{load_target}}), .D(random[3:0]), .Q(q[15:12]));
    assign q[3:0] = (q_o[3:0] & ~{4{sw[14]}}) | ({4{sw[14]}} & q[15:12]); //if sw[14] then an[0]=target
    assign q[7:4] = (q_o[7:4] & ~{4{sw[14]}}) | ({4{sw[14]}} & 4'b0000); //if sw[14] the an[1]="0"

    wire [7:0] sum8;
    wire ovfl, carry_out;
    adder8 u_adder (
        .A    ({4'b0, q[7:4]}),    
        .B    ({4'b0, q[3:0]}),    
        .Cin  (1'b0),
        .S    (sum8),
        .ovfl (ovfl),
        .Cout (carry_out)
    );
    assign q[11:8] = sum8[3:0];
    wire match;
    assign match = ~|(q[15:12] ^ q[11:8]);

    wire numbers_on, stop, stop_r, round_ended, left, right, game_over;
    FDRE #(.INIT(1'b0)) NUMBERS_ON  (.C(clk), .R(load_target), .CE(load_numbers), .D(1'b1), .Q(numbers_on));
    FDRE #(.INIT(1'b0)) STOP        (.C(clk), .R(load_target&~game_over), .CE((btnL | btnR) & numbers_on), .D(1'b1), .Q(stop));
    FDRE #(.INIT(1'b0)) STOP_R      (.C(clk), .R(load_target & ~game_over), .CE(1'b1), .D(stop), .Q(stop_r));
    FDRE #(.INIT(1'b0)) ROUND_ENDED (.C(clk), .R(load_target&~game_over_temp&~two_secs), .CE(two_secs&stop), .D(1'b1), .Q(round_ended));
    FDRE #(.INIT(1'b0)) LEFT        (.C(clk), .R(load_target&~game_over), .CE(btnL&~round_ended&numbers_on), .D(1'b1), .Q(left));
    FDRE #(.INIT(1'b0)) RIGHT       (.C(clk), .R(load_target&~game_over), .CE(btnR&~round_ended&numbers_on), .D(1'b1), .Q(right));
    wire change_score;
    fsm fsm (
        .clk_i(clk),
        .go_i(btnC),
        .stop_i(stop_r),
        .four_secs_i(four_secs),
        .two_secs_i(two_secs),
        .match_i(match),
        .game_over_i(game_over_temp),
        .load_target_o(load_target),
        .reset_timer_o(reset_timer),
        .load_numbers_o(load_numbers),
        .change_score_o(change_score),
        .flash_both_o(flash_both),
        .flash_alt_o(flash_alt)
    );

    wire [3:0] data;
    ring_counter ring_counter (
    .advance_i(digsel),
    .clk_i(clk),
    .data_o(data)
    );

    wire [3:0] h;
    selector selector (
    .N(q),
    .sel(data),
    .H(h)
    );

    wire [6:0] seg_o;
    wire game_over_four_secs;
    hex7seg hex7seg (
    .n(h),
    .seg(seg_o)
    );
    assign seg = seg_o |(~{7{1'b0}} & {7{game_over}} & {7{game_over_four_secs}}); //if gameover all segs off else all segs on

    led_shifter led_shifter (
    .clk_i(clk),
    .left(left),
    .right(right),
    .match(match),
    .change_score(change_score),
    .game_over(game_over_temp),
    .q_o(led)
    );

    FDRE #(.INIT(1'b0)) GAME_OVER           (.C(clk), .R(btnC&~game_over_temp), .CE(game_over_temp), .D(1'b1), .Q(game_over)); //game over state
    FDRE #(.INIT(1'b0)) GAME_OVER_FOUR_SECS (.C(clk), .R(btnC&~game_over_temp), .CE(four_secs&game_over), .D(1'b1), .Q(game_over_four_secs)); //game over and 4secs elapsed
    
    wire flash;
    FDRE #(.INIT(1'b0)) FLASH (.C(clk), .R(1'b0), .CE(qsec), .D(~flash), .Q(flash));
    
    wire blank_right;
    FDRE #(.INIT(1'b0)) BLANK_RIGHT (.C(clk),.R(load_numbers|game_over), .CE(load_target), .D(1'b1), .Q(blank_right));
    
    assign an[0] = blank_right //off if blankright
                   | ~((~flash_both & ~flash_alt & data[0]) //on if not flashing
                   | (flash_both & ~flash_alt & flash & data[0]) //flash if flashboth
                   | (~flash_both &  flash_alt & flash & data[0]) //flash if flashalt
                   | (game_over_four_secs & ~flash_both & ~flash_alt & data[0])); //off after gameover & if notflashing

    assign an[1] = blank_right //off if blankright
                   | ~((~flash_both & ~flash_alt & data[1]) //on if notflashing
                   | (flash_both & ~flash_alt & flash & data[1]) //flash if flashboth
                   | (~flash_both &  flash_alt & flash & data[1]) //flash if flashalt
                   | (game_over_four_secs & ~flash_both & ~flash_alt & data[1]));//off after gameover & if notflashing
                   
    assign an[2] = ~((sw[15] & data[2]) //on if sw[15]
                   | (game_over_four_secs & ~flash_both & ~flash_alt & data[2])); //off after gameover & if notflashing 
                   
    assign an[3] = ~((~flash_both & ~flash_alt & data[3] ) //on if notflashing
                   | (flash_both & ~flash_alt & flash & data[3] ) //flash if flashboth
                   | (~flash_both & flash_alt & ~flash & data[3] ) //flash if flashalt
                   | (game_over_four_secs & ~flash_both & ~flash_alt & data[3])); //off after gameover & if notflashing

    assign dp = ~game_over_four_secs; //on after gameover

    endmodule