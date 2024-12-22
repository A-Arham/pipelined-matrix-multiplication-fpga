`timescale 1ns / 1ps

module matrix_multiplication_tb;

    // Testbench signals
    reg clk, rst, start;
    wire done;
    
    // Instantiate the matrix multiplication module
    matrix_multiplication uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done)
    );

    // Clock generation (50 MHz)
    always begin
        #10 clk = ~clk;  // Toggle every 10 ns -> 50 MHz clock
    end

    // Task to reset the system
    task reset_system;
        begin
            rst = 1;
            #20;
            rst = 0;
        end
    endtask

    // Main simulation process
    initial begin
        // Initialize clock and control signals
        clk = 0;
        rst = 0;
        start = 0;

        // Apply reset
        reset_system;

        // Start matrix multiplication
        #20 start = 1;
        #20 start = 0;  // Start pulse

        // Wait for the multiplication to complete
        wait (done);
        #20;  // Allow time for final operations

        // Display the result matrix
        $display("Matrix multiplication completed.");
        display_result;

        // Finish simulation
        #100;
        $stop;
    end

endmodule

