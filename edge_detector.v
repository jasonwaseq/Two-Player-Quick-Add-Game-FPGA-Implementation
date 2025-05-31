`timescale 1ns / 1ps

module edge_detector(
    input clk_i,
    input sig_i,
    output edge_o
    );
    
    wire previous;
    
    FDRE ff (
        .Q(previous),
        .C(clk_i),
        .CE(1'b1),
        .R(1'b0),
        .D(sig_i)
    );
    
    assign edge_o = ~previous & sig_i;
    
endmodule
