`timescale 1ns / 1ps

module tb_top;
  // Inputs to DUT
  reg         clkin;
  reg  [15:0] sw;
  reg         btnC, btnR, btnL, btnD;
  // Outputs from DUT
  wire [3:0]  an;
  wire [6:0]  seg;
  wire [15:0] led;
  wire        dp;

  // Instantiate DUT
  top dut (
    .clkin(clkin),
    .sw   (sw),
    .btnC (btnC),
    .btnR (btnR),
    .btnL (btnL),
    .btnD (btnD),
    .an   (an),
    .seg  (seg),
    .led  (led),
    .dp   (dp)
  );

  // Clock generator: 100 MHz
  initial begin
    clkin = 0;
    forever #5 clkin = ~clkin;
  end

  // Monitor all key signals
  initial begin
    $display("Time   btnC btnL btnR sw    | an   seg   led      dp");
    $display("--------------------------------------------------------");
    $monitor("%4t   %b    %b    %b   %h | %b %b %h %b", 
              $time, btnC, btnL, btnR, sw, an, seg, led, dp);
  end

  // Test sequence
  initial begin
    // 1) Initial conditions & reset
    sw   = 16'h0000;
    btnC = 0; btnL = 0; btnR = 0;
    btnD = 1;             // assert global reset
    #100;                 
    btnD = 0;             // release reset

    // 2) Round 1: start game
    #100;
    btnC = 1; #10; btnC = 0;  // press btnC to load a target

    // 3) Wait "two seconds" (scaled to 2000 ns here)
    #2000;

    // 4) Test left-player correct match:
    //    force sw[14]=0 so the numbers displayed are random,
    //    then press btnL to submit
    sw[14] = 0;
    #20;
    btnL = 1; #10; btnL = 0;

    // 5) Wait through the 4 s flash window (scaled to 4000 ns)
    #4000;

    // 6) Next round: press btnC again
    btnC = 1; #10; btnC = 0;

    // 7) Wait two seconds
    #2000;

    // 8) Test right-player incorrect match:
    //    force sw[14]=1 to swap in the target onto digit 0, making sum?target
    sw[14] = 1;
    #20;
    btnR = 1; #10; btnR = 0;

    // 9) Let flash expire
    #4000;

    // 10) Test sw[15] blank-digit logic
    sw[15] = 1;
    #100;
    btnC = 1; #10; btnC = 0;  // new round with sw[15]=1

    // let a little time run
    #1000;

    // Finish simulation
    $finish;
  end

endmodule

