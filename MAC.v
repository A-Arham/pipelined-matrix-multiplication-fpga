module mac (
    input clk,
    input reset,
    input [15:0] multiplier,
    input [15:0] multiplicand,
    input [31:0] acc_in,
    output reg [31:0] acc_out
);
    reg [31:0] product;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc_out <= 32'b0;
        end else begin
            product <= multiplier * multiplicand;
            acc_out <= acc_in + product;
        end
    end
endmodule

module matrix_memory #(
    parameter SIZE = 4,       // SIZE defines a 4x4 matrix
    parameter WIDTH = 16      // Each element is 16-bit wide
)(
    input clk,
    input [3:0] addr,         // 4-bit address (16 locations for a 4x4 matrix)
    input we,                 // Write Enable
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] memory [0:SIZE*SIZE-1];  // Memory array

    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= data_in;  // Write data to memory
        end else begin
            data_out <= memory[addr]; // Read data from memory
        end
    end
endmodule

module MAC #(
    parameter SIZE = 4         // For a 4x4 matrix
)(
    input clk,
    input reset,
    output reg done
);
    reg [3:0] i, j, k;         // Counters for matrix indices
    reg [31:0] acc;            // Accumulator for the MAC
    reg [15:0] a_element, b_element;
    wire [31:0] mac_out;

    // Instantiate MAC unit
    mac mac_unit(
        .clk(clk),
        .reset(reset),
        .multiplier(a_element),
        .multiplicand(b_element),
        .acc_in(acc),
        .acc_out(mac_out)
    );

    // Instantiate matrix memories (A, B, and R)
    reg [15:0] data_a, data_b;
    wire [15:0] data_r;
    wire [3:0] addr_a, addr_b, addr_r;
    reg we_r;

    matrix_memory #(.SIZE(SIZE)) mem_a(
        .clk(clk),
        .addr(addr_a),
        .we(0),
        .data_in(16'b0),
        .data_out(data_a)
    );

    matrix_memory #(.SIZE(SIZE)) mem_b(
        .clk(clk),
        .addr(addr_b),
        .we(0),
        .data_in(16'b0),
        .data_out(data_b)
    );

    matrix_memory #(.SIZE(SIZE)) mem_r(
        .clk(clk),
        .addr(addr_r),
        .we(we_r),
        .data_in(mac_out[15:0]),  // Store the final result in R
        .data_out(data_r)
    );

    // Control logic for the matrix multiplication
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i <= 0;
            j <= 0;
            k <= 0;
            acc <= 0;
            done <= 0;
        end else begin
            if (i < SIZE) begin
                if (j < SIZE) begin
                    if (k < SIZE) begin
                        // Load matrix elements from A and B
                        a_element <= data_a;
                        b_element <= data_b;
                        
                        // Accumulate using MAC
                        acc <= mac_out;

                        // Increment k (to go through A's row and B's column)
                        k <= k + 1;
                    end else begin
                        // Write the result to matrix R when k completes
                        we_r <= 1;
                        k <= 0;
                        j <= j + 1;
                        acc <= 0;
                    end
                end else begin
                    j <= 0;
                    i <= i + 1;
                end
            end else begin
                done <= 1;
            end
        end
    end
endmodule
