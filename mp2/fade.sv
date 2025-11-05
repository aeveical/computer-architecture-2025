// Fade

module fade #(
    parameter INC_DEC_INTERVAL = 12000,     // CLK frequency is 12MHz, so 12,000 cycles is 1ms
    parameter INC_DEC_MAX = 200,            // Transition to next state after 200 increments / decrements, which is 0.2s
    parameter HOLD_MAX = INC_DEC_MAX * 2,   // hold states for double the inc dec amount
    parameter PWM_INTERVAL = 1200,          // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX,
    // initalize all start values to be 0 (will set custom in top.sv)
    parameter START_STATE = 0,
    parameter START_INTERVAL = 0,
    parameter START_CYCLE = 0
)(
    input logic clk, 
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value
);

    // Define state variable values
    // 4 states are what value 
    localparam PWM_INC = 2'b00;
    localparam PWM_DEC = 2'b01;
    localparam PWM_HIGH = 2'b10;
    localparam PWM_LOW = 2'b11;

    // Declare state variables
    logic [1:0] current_state = START_STATE;
    logic [1:0] next_state;

    // Declare variables for timing state transitions
    logic [$clog2(INC_DEC_INTERVAL) - 1:0] count = 0;
    logic [$clog2(HOLD_MAX) - 1:0] inc_dec_count = 0;
    logic time_to_inc_dec = 1'b0;

    initial begin
        pwm_value = 0;
    end

    // Compute the next state of the FSM
    always_comb begin
        next_state = 1'bx;
        case (current_state)
            PWM_INC:
                next_state = PWM_HIGH;
            PWM_HIGH:
                next_state = PWM_DEC;
            PWM_DEC:
                next_state = PWM_LOW;
            PWM_LOW:
                next_state = PWM_INC;
        endcase
    end

    // Implement counter for incrementing / decrementing PWM value
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL) begin
            count <= 0;
            time_to_inc_dec <= 1'b1;
        end
        else begin
            count <= count + 1;
            time_to_inc_dec <= 1'b0;
        end
    end

    // Increment / Decrement PWM value as appropriate given current state
    always_ff @(posedge time_to_inc_dec) begin
        case (current_state)
            PWM_INC:
                pwm_value = pwm_value + INC_DEC_VAL;
            PWM_DEC:
                pwm_value = pwm_value - INC_DEC_VAL;
        endcase
    end

    // Implement counter for timing state transitions
    always_ff @(posedge time_to_inc_dec) begin
        if (inc_dec_count == HOLD_MAX || inc_dec_count == INC_DEC_MAX && current_state[1] == 1'b0) begin
            inc_dec_count <= 0;
            current_state <= next_state;
        end
        else begin
            inc_dec_count <= inc_dec_count + 1;
        end
    end

endmodule
