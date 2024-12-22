`timescale 1ns / 1ps

module memory (
    input clk,
    input [3:0] addr, // Address for accessing memory (4-bit for 9 elements)
    input [15:0] data_in, // Data input for writing
    input write_enable, // Enable signal for write operation
    output reg [15:0] data_out // Data output for read operation
);
    reg [15:0] mem [0:8]; // Memory with 9 elements for a 3x3 matrix

    // Writing to memory or outputting data based on write enable
    always @(posedge clk) begin
        if (write_enable) begin
            mem[addr] <= data_in;
        end else begin
            data_out <= mem[addr];
        end
    end
endmodule

module memA (
	 input clk,
    input [3:0] addr,
    output reg [15:0] data_out
);
    reg [15:0] mem [0:8];

    // Initialize Matrix A values
    initial begin
        mem[0] = 16'd1;  mem[1] = 16'd2;  mem[2] = 16'd3;
        mem[3] = 16'd4;  mem[4] = 16'd5;  mem[5] = 16'd6;
        mem[6] = 16'd7;  mem[7] = 16'd8;  mem[8] = 16'd9;
    end

    always @ (posedge clk) data_out <= mem[addr];
endmodule

module memB (
	 input clk,
    input [3:0] addr,
    output reg [15:0] data_out
);
    reg [15:0] mem [0:8];

    // Initialize Matrix B values
    initial begin
        mem[0] = 16'd9;  mem[1] = 16'd8;  mem[2] = 16'd7;
        mem[3] = 16'd6;  mem[4] = 16'd5;  mem[5] = 16'd4;
        mem[6] = 16'd3;  mem[7] = 16'd2;  mem[8] = 16'd1;
    end

    always @ (posedge clk) data_out <= mem[addr];
endmodule

module memR (
    input clk,
    input [3:0] addr,
    input [15:0] data_in,
    input write_enable,
    output [15:0] data_out
);
    memory result_memory (
        .clk(clk),
        .addr(addr),
        .data_in(data_in),
        .write_enable(write_enable),
        .data_out(data_out)
    );
endmodule

module matrix_multiplication (
    input clk,
    input rst,
    input start,
    output reg done,
	 output [15:0] dataR
);
    parameter SIZE = 2'd3; // 3x3 matrix size

    // FSM states
    parameter IDLE = 3'b000, LOAD = 3'b001, MAC = 3'b010, STORE = 3'b011, DONE = 3'b100;

    // Registers for FSM state
    reg [2:0] state, next_state;

    // Address and control signals
    reg [3:0] addrA, addrB, addrR; // 4 bits to address elements
    reg [1:0] i, j, k; // Loop counters
    reg write_enable;

    // Data and result signals
    wire [15:0] dataA, dataB;
    reg [31:0] accumulator; // Accumulate the MAC result
    reg [15:0] mac_result;   // Store final MAC output

    // Instantiate memories
    memA A (.clk(clk), .addr(addrA), .data_out(dataA));
    memB B (.clk(clk), .addr(addrB), .data_out(dataB));
    memR R (.clk(clk), .addr(addrR), .data_in(mac_result), .write_enable(write_enable), .data_out(dataR));

    // FSM - State Transition Logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM - Next State Logic
    always @(*) begin
        case (state)
            IDLE: 
                if (start) next_state = LOAD;
                else next_state = IDLE;

            LOAD: 
                next_state = MAC;

            MAC: 
                if (k <= SIZE - 2'd1) next_state = LOAD;
                else next_state = STORE;

            STORE: 
                if (j <= SIZE - 2'd1 || i <= SIZE - 2'd1) next_state = LOAD;
                else next_state = DONE;

            DONE: 
                next_state = IDLE;

            default: 
                next_state = IDLE;
        endcase
    end

    // Control Logic for Matrix Multiplication

		always @(posedge clk or posedge rst) begin
			 if (rst) begin
				  i <= 0;
				  j <= 0;
				  k <= 0;
				  accumulator <= 0;
				  done <= 0;
				  write_enable <= 0;
			 end else begin
				  case (state)
						LOAD: begin
							 // Calculate addresses for the current elements
							 write_enable <= 0;
							 addrA <= (i * SIZE + k); 
							 addrB <= (k * SIZE + j); 

							 // Reset accumulator for the next MAC operation
							 if (k == 0) 
								  accumulator <= 0;
						end

						MAC: begin
							 // Perform MAC operation: Accumulate the product
							 accumulator <= accumulator + dataA * dataB;

							 // Increment k to move to the next element
							 if (k < SIZE - 2'd1) begin
								  k <= k + 2'd1;
							 end else begin
								  k <= 0;  // Reset k after processing all elements
							 end
						end

						STORE: begin
							 // Store the lower 16 bits of the accumulator to memory
							 mac_result <= accumulator[15:0];
							 addrR <= (i * SIZE + j);
							 write_enable <= 1;
							 
							 // Update column and row counters
							 if (j < SIZE - 2'd1) begin
								  j <= j + 2'd1;  // Move to the next column
							 end else begin
								  j <= 0;  // Reset column to 0
								  if (i < SIZE - 2'd1) begin
										i <= i + 2'd1;  // Move to the next row
								  end else begin
										i <= 0;  // Reset row to 0 after all rows are processed
								  end
							 end
						end

						DONE: begin
							 // Signal completion
							 write_enable <= 0;
							 done <= 1;
						end
				  endcase
			 end
		end
		
endmodule
