module tb_matrix_multiply;
    reg clk, reset;
    wire done;

    // Instantiate matrix multiply module
    MAC #(.SIZE(4)) uut (
        .clk(clk),
        .reset(reset),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;

        // Apply reset
        #10 reset = 0;

        // Wait for the done signal
        wait(done);
        
        $display("Matrix Multiplication Complete");
        //$stop;
    end
endmodule
