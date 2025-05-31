`timescale 1ns / 1ps

module countUD4L (
    input clk_i,
    input reset_i, 
    input up_i,
    input dw_i,
    input ld_i,
    input [3:0] din_i,
    output [3:0] q_o,
    output utc_o,
    output dtc_o
);

    wire [3:0] d;
    wire [3:0] q;

    wire up;
    wire dw;
    wire hold; 

    assign up = up_i & ~dw_i & ~ld_i;
    assign dw = ~up_i & dw_i & ~ld_i;
    assign hold = ~(up | dw) & ~ld_i;
    
    assign d[0] = (ld_i & din_i[0]) |
                  (up & ~q[0]) |
                  (dw & ~q[0]) |
                  (hold & q[0]);
    
    assign d[1] = (ld_i & din_i[1]) | 
                  (up & (q[1] ^ q[0])) |    
                  (dw & (q[1] ^ ~q[0])) |   
                  (hold & q[1]);

    assign d[2] = (ld_i & din_i[2]) |
                  (up & (q[2] ^ (q[1] & q[0]))) |
                  (dw & (q[2] ^ (~q[1] & ~q[0]))) |
                  (hold & q[2]);

    assign d[3] = (ld_i & din_i[3]) |
                  (up & (q[3] ^ (q[2] & q[1] & q[0]))) |
                  (dw & (q[3] ^ (~q[2] & ~q[1] & ~q[0]))) |
                  (hold & q[3]);

    FDRE #(.INIT(1'b0)) ff0 (.C(clk_i), .CE(1'b1), .R(reset_i), .D(d[0]), .Q(q[0]));
    FDRE #(.INIT(1'b0)) ff1 (.C(clk_i), .CE(1'b1), .R(reset_i), .D(d[1]), .Q(q[1]));
    FDRE #(.INIT(1'b0)) ff2 (.C(clk_i), .CE(1'b1), .R(reset_i), .D(d[2]), .Q(q[2]));
    FDRE #(.INIT(1'b0)) ff3 (.C(clk_i), .CE(1'b1), .R(reset_i), .D(d[3]), .Q(q[3]));

    assign q_o = q;
    assign utc_o = &q;
    assign dtc_o = ~|q;

endmodule
