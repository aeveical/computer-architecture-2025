`include "wheel_of_death.sv"

// Fade top level module

module top #(
    parameter PWM_INTERVAL = 1200
) (
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
);

  logic red, green, blue;

  wheel_of_death #(
      .PWM_INTERVAL(PWM_INTERVAL),
      .START_STATE(2'b10), 
      .START_INTERVAL(0.5),
      .START_CYCLE(0)
  ) red_light (
      .clk(clk),
      .LED(red)
  );

  wheel_of_death #(PWM_INTERVAL) green_light (
      .clk(clk),
      .LED(green)
  );

  wheel_of_death #(
      .PWM_INTERVAL(PWM_INTERVAL),
      .START_STATE(2'b11)
  ) blue_light (
      .clk(clk),
      .LED(blue)
  );

  assign RGB_R = ~red;
  assign RGB_G = ~green;
  assign RGB_B = ~blue;
endmodule




