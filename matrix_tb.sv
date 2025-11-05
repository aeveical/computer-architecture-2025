`include "controller.sv"

module matrix_tb;

    logic clk = 0;
    logic [7:0] red_data, green_data, blue_data;
    logic [5:0] mem_address;
    logic load_sreg, transmit_pixel, pixel_value, cycle_complete;
    
    logic [7:0] memory [0:63];
    
    always begin
        #41.67 clk = ~clk; 
    end
    
    controller dut (
        .clk(clk),
        .red_data(red_data),
        .green_data(green_data),
        .blue_data(blue_data),
        .mem_address(mem_address),
        .load_sreg(load_sreg),
        .transmit_pixel(transmit_pixel),
        .pixel_value(pixel_value),
        .cycle_complete(cycle_complete)
    );
    
    assign red_data = memory[mem_address];
    assign green_data = 8'h00;
    assign blue_data = 8'h00;
    
    // Initialize test pattern
    initial begin
        // Clear memory
        for (int i = 0; i < 64; i++) begin
            memory[i] = 8'h00;
        end
        
        // lightweight spaceship (an attempt)
        memory[1*8 + 2] = 8'hFF;
        memory[1*8 + 3] = 8'hFF;
        memory[1*8 + 4] = 8'hFF;
        memory[1*8 + 5] = 8'hFF;
        memory[2*8 + 1] = 8'hFF;
        memory[2*8 + 5] = 8'hFF;
        memory[3*8 + 5] = 8'hFF;
        memory[4*8 + 1] = 8'hFF;
        memory[4*8 + 4] = 8'hFF;
    end
    
    // print matrix
    int frame = 0;
    always @(posedge cycle_complete) begin
        $display("\nFrame %0d:", frame);
        for (int row = 0; row < 8; row++) begin
            $write("Row %0d: ", row);
            for (int col = 0; col < 8; col++) begin
                $write("%0d ", dut.current_matrix[row][col]);
            end
            $display("");
        end
        frame++;
        
        if (frame >= 8) begin 
            $finish;
        end
    end
    
    // Run for 2 seconds
    initial begin
        #2000000000; 
        $finish;
    end

endmodule