module fsm #(
    parameter BLINK_INTERVAL = 2000000,     // CLK freq is 12MHz, so 6,000,000 cycles is 0.5s
)(
    input logic     clk, 
    output logic    red, 
    output logic    green, 
    output logic    blue
);

    // Define state variable values
        localparam RED = 4'b0000;
        localparam YELLOW = 4'b0001;
        localparam GREEN  = 4'b0010;
        localparam CYAN = 4'b0011;
        localparam BLUE = 4'b0100;
        localparam MAGENTA = 4'b0101;

        // Declare state variables
        logic [2:0] current_state = MAGENTA;
        logic [2:0] next_state;

        // Declare next output variables
        logic next_red, next_green, next_blue;

        // Declare counter variables for blinking in the BLUE state
        logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;

        // Register the next state of the FSM
        always_ff @(posedge clk) begin
            if (count == BLINK_INTERVAL - 1) begin
                count <= 0;
                current_state <= next_state;  // state updates only when count expires
            end
            else begin
                count <= count + 1;
            end
        end

        // Compute the next state of the FSM
        always_comb begin
            next_state = 4'bxxxx;
            case (current_state)
                RED: begin
                    next_state = YELLOW;
                end
                YELLOW: begin
                    next_state = GREEN;
                end
                GREEN: begin
                    next_state = CYAN;
                end
                CYAN: begin
                    next_state = BLUE;
                end
                BLUE: begin
                    next_state = MAGENTA;
                end
                MAGENTA: begin
                    next_state = RED;
                end
            endcase
        end

        // Register the FSM outputs
        always_ff @(posedge clk) begin
            red <= next_red;
            green <= next_green;
            blue <= next_blue;
        end

        // Compute next output values
        always_comb begin
            next_red = 1'b0;
            next_green = 1'b0;
            next_blue = 1'b0;
            case (current_state)
                RED: begin
                    // red + green
                    next_red = 1'b1;
                    next_green = 1'b1;   
                end            
                YELLOW: begin
                    // just green
                    next_green = 1'b1;
                end
                GREEN: begin
                    // green + blue;
                    next_green = 1'b1;
                    next_blue = 1'b1;
                end
                CYAN: begin
                    // just blue
                    next_blue = 1'b1;
                end
                BLUE: begin
                    // blue and red
                    next_blue = 1'b1;
                    next_red = 1'b1;
                end
                MAGENTA: begin
                    // just red
                    next_red = 1'b1;
                end
            endcase
        end

endmodule