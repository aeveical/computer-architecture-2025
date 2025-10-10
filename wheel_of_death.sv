`include "fade.sv"
`include "pwm.sv"

module wheel_of_death #(
    parameter PWM_INTERVAL = 1200,  
    parameter START_STATE = 0,
    parameter START_INTERVAL = 0,
    parameter START_CYCLE = 0
)(
    input logic     clk, 
    output logic    LED
);

    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value;
    logic pwm_out;

    fade #(
        .PWM_INTERVAL     (PWM_INTERVAL),
        .START_STATE      (START_STATE),
        .START_INTERVAL   (START_INTERVAL),
        .START_CYCLE      (START_CYCLE)

    ) u1 (
        .clk            (clk), 
        .pwm_value      (pwm_value)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2 (
        .clk            (clk), 
        .pwm_value      (pwm_value), 
        .pwm_out        (pwm_out)
    );

    assign LED = ~pwm_out;

endmodule
