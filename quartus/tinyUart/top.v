// Adapted from https://github.com/pConst/basic_verilog/UartTxExtreme.v

module top (
    input clk,
    output txd
);

wire tick, baud;

Tick1hz U1(.clk(clk), .tick(tick));

BaudGen U2(.clk(clk), .baud(baud));

UartTx U3(
    .clk(clk),
    .tx_do_sample(baud),
    .tx_data(8`h45), // "E"
    .tx_start(tick),
    .txd(txd)
);

endmodule // top

module Tick1hz (
    input clk,
    output tick
);

reg [31:0] counter = 0;
always @(posedge clk)
    if (counter == 5000000-1)
        counter <= 0;
    else
        counter <= counter + 1;
assign tick = counter == 0;

endmodule // Tick1hz

module BaudGen (
    input clk,
    output baud
);

reg [8:0] tx_sample_cntr = 0;
always @(posedge clk)
    if (tx_sample_cntr == 0)
        tx_sample_cntr <= 434-1; // 50 MHz / 115200
    else
        tx_sample_cntr <= tx_sample_cntr - 1;
assign baud = tx_sample_cntr == 0;

endmodule // BaudGen

module UartTx (
    input clk,
    input tx_do_sample,
    input [7:0] tx_data,
    input tx_start,
    output tx_busy,
    output reg txd = 1
);

reg [9:0] tx_shifter = 0;
always @(posedge clk) begin
    if (tx_start && ~tx_busy)
        tx_shifter <= { 1'b1, tx_data, 1'b0 };
    if (tx_do_sample && tx_busy)
        { tx_shifter, txd } <= tx_shifter;
end
assign tx_busy = tx_shifter != 0;

endmodule // UartTx
