module controller (
    input logic clk,
    input logic [7:0] red_data,
    input logic [7:0] green_data,
    input logic [7:0] blue_data,
    output logic [5:0] mem_address,
    output logic load_sreg,
    output logic transmit_pixel,
    output logic pixel_value,
    output logic cycle_complete
);

    // timing variables
    localparam [2:0] READ_CH_VALS   = 3'b001;
    localparam [2:0] LOAD_SREG      = 3'b010;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;
    localparam [8:0] TRANSMIT_CYCLES = 9'd360;       // driver sends in 15 clk cycles, 24 bits per light = 24 * 15
    localparam [17:0] IDLE_CYCLES = 18'd5631360;      // 0.50 second idle delay
    localparam [4:0] MAX_FRAME_COUNT = 5'd16;

    localparam[2:0] DELAY = 3'b001;
    localparam[2:0] PREPARE_MATRIX = 3'b010;
    localparam[2:0] GAME_LOGIC_COUNT = 3'b011;
    localparam[2:0] GAME_LOGIC_UPDATE = 3'b100;
    localparam[2:0] COPY_MATRIX = 3'b101;
    localparam[2:0] TRANSMIT_FRAME = 3'b110;
    localparam[2:0] IDLE = 3'b111;

    logic [2:0] current_state = DELAY;
    logic current_matrix [7:0][7:0]; 
    logic next_matrix [7:0][7:0];    
    logic [3:0] neighbor_count = 4'd0;
    logic [2:0] row = 0;
    logic [2:0] col = 0;
    logic [2:0] row_above = 7;
    logic [2:0] row_below = 1;
    logic [2:0] col_right = 1;
    logic [2:0] col_left = 7;
    logic [2:0] current_pixel_row;
    logic [2:0] current_pixel_col;
    
    // Initialize matrices to zero (all dead)
    initial begin
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                current_matrix[i][j] = 1'b0;
                next_matrix[i][j] = 1'b0;
            end
        end
    end

    // Transmission control
    logic [2:0] transmit_state = READ_CH_VALS;
    logic [5:0] pixel_counter = 6'd0;
    logic [4:0] frame_counter = 5'd0;
    logic [8:0] transmit_counter = 9'd0;
    logic [17:0] idle_counter = 18'd0;
    
    logic transmit_pixel_done;
    logic idle_done;

    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1);
    assign idle_done = (idle_counter == IDLE_CYCLES - 1);
    assign cycle_complete = (frame_counter == MAX_FRAME_COUNT - 1);
    
    always_ff @(posedge clk) begin
        case (current_state)
            DELAY: begin
                // Adding one cycle delay for memory read
                current_state <= PREPARE_MATRIX;
            end
            
            PREPARE_MATRIX: begin
                // create a model 8x8 matrix that keeps track of which lights are on or off (color independent)
                // so that we can determine the next frame of the game


                // don't care about color, only if cell is on or off -> if ANY cell values
                // are greater than 0, cell is on/alive
                if (green_data != 8'h00 || red_data != 8'h00 || blue_data != 8'h00) begin
                    current_matrix[row][col] <= 1'b1;
                end else begin
                    current_matrix[row][col] <= 1'b0;
                end
                
                // check for each cell (reads one row all columns, then moves to next row)
                // (reading top left to bottom right)
                if (col == 7) begin
                    // reset col count
                    col <= 0;
                    if (row == 7) begin
                        // count is done, reset everything
                        row <= 0;
                        col <= 0;
                        // ready to transmit to board
                        current_state <= TRANSMIT_FRAME; 
                        frame_counter <= 5'd0;
                    end else begin
                        // if not ready, it's time to move to next row
                        row <= row + 1;
                        // give one clk cycle delay
                        current_state <= DELAY;
                    end
                end else begin
                    // move to next column
                    col <= col + 1;
                    // give one clk cycle delay
                    current_state <= DELAY;
                end
            end
            
            GAME_LOGIC_COUNT: begin
                // calculate neighbor alive cell count

                // implement cyclical boundary conditions
                if (row == 7) begin
                    row_below = 0;
                    row_above = row - 1;
                end else if (row == 0) begin
                    row_below = row + 1;
                    row_above = 7;
                end else begin
                    row_below = row + 1;
                    row_above = row - 1;
                end

                if (col == 7) begin
                    col_right = 0;
                    col_left = col - 1;
                end else if (col == 0) begin
                    col_right = col + 1;
                    col_left = 7;
                end else begin
                    col_right = col + 1;
                    col_left = col - 1;
                end

                // sum up all neighbor alive counts
                neighbor_count <=
                // for the three neighbors above (top left, top middle, top right)
                    current_matrix[row_above][col_left]
                    + current_matrix[row_above][col]
                    + current_matrix[row_above][col_right]
                // for the two neighbors on the same row (left and right of cell)
                    + current_matrix[row][col_left]
                    + current_matrix[row][col_right]
                // for the three neighbors below (bottom left, bottom middle, bottom right)
                    + current_matrix[row_below][col_left]
                    + current_matrix[row_below][col]
                    + current_matrix[row_below][col_right];

                current_state <= GAME_LOGIC_UPDATE;
            end
            
            GAME_LOGIC_UPDATE: begin
                // apple game of life rules based on neighbor counts for all cells
                if (current_matrix[row][col]) begin
                    // cell is currently alive
                    if (neighbor_count == 2 || neighbor_count == 3) begin
                        next_matrix[row][col] <= 1'b1; 
                    end else begin
                        next_matrix[row][col] <= 1'b0; 
                    end
                end else begin
                    // cell is currently dead
                    if (neighbor_count == 3) begin
                        next_matrix[row][col] <= 1'b1; 
                    end else begin
                        next_matrix[row][col] <= 1'b0; 
                    end
                end
                
                // go to next cell, also reads top left to bottom right duh
                if (col == 7) begin
                    col <= 0;
                    if (row == 7) begin
                        // you're on the last row, time to copy the matrix over
                        current_state <= COPY_MATRIX;
                        row <= 0;
                        frame_counter <= 5'd0;
                    end else begin
                        row <= row + 1;
                        current_state <= GAME_LOGIC_COUNT;
                    end
                end else begin
                    col <= col + 1;
                    current_state <= GAME_LOGIC_COUNT;
                end
            end
            
            COPY_MATRIX: begin
                // copy next matrix to current
                current_matrix[row][col] <= next_matrix[row][col];
                
                // move to next cell, still reads top left to bottom right
                if (col == 7) begin
                    col <= 0;
                    if (row == 7) begin
                        // you're done yay!
                        current_state <= TRANSMIT_FRAME;
                        row <= 0;
                    end else begin
                        row <= row + 1;
                    end
                end else begin
                    col <= col + 1;
                end
            end
            
            TRANSMIT_FRAME: begin
                // transmit frame by pixel
                case (transmit_state)
                    READ_CH_VALS: begin
                        transmit_state <= LOAD_SREG;
                    end
                    LOAD_SREG: begin
                        transmit_state <= TRANSMIT_PIXEL;
                    end
                    TRANSMIT_PIXEL: begin
                        if (transmit_pixel_done) begin
                            transmit_state <= READ_CH_VALS;
                            pixel_counter <= pixel_counter + 1;
                            if (pixel_counter == 6'd63) begin
                                pixel_counter <= 6'd0;
                                current_state <= IDLE;
                            end
                        end
                    end
                    default: begin
                        transmit_state <= READ_CH_VALS;
                    end
                endcase
            end
            
            IDLE: begin
                // wait
                if (idle_done) begin
                    frame_counter <= frame_counter + 1;
                    if  (cycle_complete) begin
                        row <= 0;
                        col <= 0;
                        current_state <= GAME_LOGIC_COUNT;
                        frame_counter <= 5'd0;
                    end else begin
                        current_state <= TRANSMIT_FRAME;
                    end
                end
            end
            default: begin
                current_state <= DELAY;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (transmit_state == TRANSMIT_PIXEL) begin
            transmit_counter <= transmit_counter + 1;
        end else begin
            transmit_counter <= 9'd0;
        end
    end

    always_ff @(posedge clk) begin
        if (current_state == IDLE) begin
            idle_counter <= idle_counter + 1;
        end else begin
            idle_counter <= 18'd0;
        end
    end

    // convert pixel counter to use matrix
    assign current_pixel_row = pixel_counter[5:3]; // every 
    assign current_pixel_col = pixel_counter[2:0]; // Lower 3 bits for col (0-7)

    // outputs
    always_comb begin
        if (current_state == DELAY || current_state == PREPARE_MATRIX) begin
            mem_address = {row, col};
        end else begin
            mem_address = 6'd0;
        end
    end
    assign pixel_value = current_matrix[current_pixel_row][current_pixel_col];
    assign load_sreg = (transmit_state == LOAD_SREG);
    assign transmit_pixel = (transmit_state == TRANSMIT_PIXEL);

endmodule