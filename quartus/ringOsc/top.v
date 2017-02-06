module top (
    input clk,      // 50 MHz
    output out      // test pin output
);

wire [15:0] counter;
ring_counter U1 (.clk(clk), .rst(0), .out(counter));
defparam U1.DELAY = 100;

assign out = counter[0];

endmodule // top
