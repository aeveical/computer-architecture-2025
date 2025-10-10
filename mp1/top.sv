`include "fsm.sv"

// Finite State Machine Top-Level Module

module top(
    input logic     clk, 
    output logic    RGB_R, 
    output logic    RGB_G, 
    output logic    RGB_B
);

    logic red, green, blue;

    fsm u0(
        .clk    (clk), 
        .red    (red), 
        .green  (green), 
        .blue   (blue)
    );

    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;

endmodule
