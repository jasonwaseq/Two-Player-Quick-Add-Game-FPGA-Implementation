`timescale 1ns / 1ps

module time_counter(
    input clk_i,
    input inc_i,
    input reset_i,
    output [5:0] q_o
);

    wire [15:0] full_q;
    
    countUD16L counter (
        .clk_i(clk_i),
        .up_i(inc_i),        
        .dw_i(1'b0),             
        .ld_i(reset_i),      
        .din_i(16'b0000000000000000),    
        .q_o(full_q),              
        .utc_o(),                  
        .dtc_o()                   
    );
    assign q_o = full_q[5:0];
    
endmodule
