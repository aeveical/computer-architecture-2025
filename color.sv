module color #(
    // how often it changes color
    parameter BLINK_INTERVAL = 10000000
)(
    input logic          clk,             
    input logic          pixel_value,     
    output logic [23:0]  colored_pixel_out 
);

    localparam [2:0] RED_STATE     = 3'b000;
    localparam [2:0] YELLOW_STATE  = 3'b001;
    localparam [2:0] GREEN_STATE   = 3'b010;
    localparam [2:0] CYAN_STATE    = 3'b011;
    localparam [2:0] BLUE_STATE    = 3'b100;
    localparam [2:0] MAGENTA_STATE = 3'b101;

    logic [3:0] current_state = MAGENTA_STATE;
    logic [3:0] next_state;
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;

    // set color channels for red, green, and blue
    logic [7:0] alive_r, alive_g, alive_b; 
    
    // set dead lights to be off
    localparam [23:0] LIGHT_OFF = 24'h000000; 

    // cycle through colors (if cell is alive)
    always_ff @(posedge clk) begin
        if (count == BLINK_INTERVAL - 1) begin
            count <= 0;
            current_state <= next_state;
        end else begin
            count <= count + 1;
        end
    end

    always_comb begin
        next_state = current_state; 
        case (current_state)
            RED_STATE:     
                next_state = YELLOW_STATE;
            YELLOW_STATE:  
                next_state = GREEN_STATE;
            GREEN_STATE:   
                next_state = CYAN_STATE;
            CYAN_STATE:    
                next_state = BLUE_STATE;
            BLUE_STATE:    
                next_state = MAGENTA_STATE;
            MAGENTA_STATE: 
                next_state = RED_STATE;
        endcase
    end

    always_comb begin
        // lights off by default
        alive_r = 8'h11; 
        alive_g = 8'h11; 
        alive_b = 8'h11; 
        
        case (current_state)
            RED_STATE:     
                alive_r = 8'hFF;
            YELLOW_STATE:  begin 
                alive_r = 8'hFF; 
                alive_g = 8'hFF; 
            end 
            GREEN_STATE:   
                alive_g = 8'hFF;
            CYAN_STATE:    begin 
                alive_g = 8'hFF; 
                alive_b = 8'hFF; 
            end 
            BLUE_STATE:    
                alive_b = 8'hFF;
            MAGENTA_STATE: begin 
                alive_r = 8'hFF; 
                alive_b = 8'hFF; 
            end 
        endcase
    end
    
    logic [23:0] cycling_alive_color;
    
    // assign color to light
    assign cycling_alive_color = {alive_g, alive_r, alive_b}; 
    always_comb begin
        if (pixel_value == 1'b1) begin
            colored_pixel_out = cycling_alive_color;
        end else begin
            colored_pixel_out = LIGHT_OFF;
        end
    end

endmodule