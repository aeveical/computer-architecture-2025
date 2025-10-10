`include "fade.sv" // Your single-channel fader
`include "pwm.sv"  // Your PWM generator

// Define the state values from the fade module for clarity
localparam PWM_INC  = 2'b00; // Ramp Up
localparam PWM_DEC  = 2'b01; // Ramp Down
localparam PWM_HIGH = 2'b10; // Hold Max
localparam PWM_LOW  = 2'b11; // Hold Min

module top #(
    // Use the PWM_INTERVAL from your pwm module
    parameter PWM_INTERVAL = 1200, 
    localparam PWM_BITS = $clog2(PWM_INTERVAL) 
) (
    input logic clk, 
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

    // Wires to carry the multi-bit duty cycle value (0 to 1199) from FADE to PWM
    logic [PWM_BITS-1:0] r_duty_cycle, g_duty_cycle, b_duty_cycle;
    
    // Wires to carry the High-True PWM signal from PWM module
    logic r_pwm_out, g_pwm_out, b_pwm_out;

    // --- PART 1: FADE MODULES (Generating the duty cycle values) ---
    // Stagger the START_STATEs to achieve the full color cycle.

    // RED Fader: Start at Hold Max (to transition Red -> Yellow)
    fade #(
        // NOTE: Parameters must be updated if fade.sv uses different defaults
        .PWM_INTERVAL(PWM_INTERVAL),
        .START_STATE(PWM_HIGH) 
    ) R_Fader (
        .clk(clk),
        .pwm_value(r_duty_cycle) 
    );

    // GREEN Fader: Start at Ramp Down (to transition Yellow -> Green)
    // Staggered 2 states (1/2 cycle) relative to Red to follow the color wheel.
    fade #(
        .PWM_INTERVAL(PWM_INTERVAL),
        .START_STATE(PWM_DEC)
    ) G_Fader (
        .clk(clk),
        .pwm_value(g_duty_cycle) 
    );

    // BLUE Fader: Start at Ramp Up (to transition Blue -> Magenta)
    // Staggered 1 state (1/4 cycle) relative to Green.
    fade #(
        .PWM_INTERVAL(PWM_INTERVAL),
        .START_STATE(PWM_INC) 
    ) B_Fader (
        .clk(clk),
        .pwm_value(b_duty_cycle) 
    );

    // --- PART 2: PWM GENERATOR MODULES (Converting value to signal) ---

    // R PWM Generator
    pwm #(
        .PWM_INTERVAL(PWM_INTERVAL)
    ) R_PWM (
        .clk(clk),
        .pwm_value(r_duty_cycle),
        .pwm_out(r_pwm_out) // High-True PWM output
    );

    // G PWM Generator
    pwm #(
        .PWM_INTERVAL(PWM_INTERVAL)
    ) G_PWM (
        .clk(clk),
        .pwm_value(g_duty_cycle),
        .pwm_out(g_pwm_out) 
    );

    // B PWM Generator
    pwm #(
        .PWM_INTERVAL(PWM_INTERVAL)
    ) B_PWM (
        .clk(clk),
        .pwm_value(b_duty_cycle),
        .pwm_out(b_pwm_out) 
    );
    
    // --- PART 3: FINAL OUTPUT (Inversion for Common Anode) ---
    // Your original code used inversion (assign RGB_R = ~red;). We apply it here.
    // This assumes a Common Anode RGB LED where LOW = ON.

    assign RGB_R = ~r_pwm_out;
    assign RGB_G = ~g_pwm_out;
    assign RGB_B = ~b_pwm_out;

endmodule