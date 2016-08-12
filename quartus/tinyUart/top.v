// Adapted from https://github.com/pConst/basic_verilog/UartTxExtreme.v

module top (
    input clk,      // 50 MHz
    output txd      // UART tx pin
);

wire tick, baud;
Tick1hz U1(.clk(clk), .tick(tick));
BaudGen U2(.clk(clk), .baud(baud));

UartTx U3(
    .clk(clk),
    .tx_clock(baud),
    .tx_data(8'h45), // "E"
    .tx_start(tick),
    .txd(txd)
);

endmodule // top

module Tick1hz (
    input clk,      // 50 MHz
    output tick     // one short pulse every 1s
);

reg [31:0] counter = 0;
always @(posedge clk)
    if (counter == 50000000-1)
        counter <= 0;
    else
        counter <= counter + 1;
assign tick = counter == 0;

endmodule // Tick1hz

module BaudGen (
    input clk,      // 50 MHz
    output baud     // 115.2 KHz (approx)
);

reg [8:0] tx_sample_cntr = 0;
always @(posedge clk)
    if (tx_sample_cntr == 0)
        tx_sample_cntr <= 50000000/115200-1;
    else
        tx_sample_cntr <= tx_sample_cntr - 1;
assign baud = tx_sample_cntr == 0;

endmodule // BaudGen

module UartTx (
    input clk,              // 50 MHz
    input tx_clock,         // 115.2 KHz
    input [7:0] tx_data,    // byte to send
    input tx_start,         // start sending
    output tx_busy,         // is busy sending
    output reg txd = 1      // uart tx pin
);

reg [9:0] tx_shifter = 0;
always @(posedge clk) begin
    if (tx_start && ~tx_busy)
        tx_shifter <= { 1'b1, tx_data, 1'b0 };
    if (tx_clock && tx_busy)
        { tx_shifter, txd } <= tx_shifter;
end
assign tx_busy = tx_shifter != 0;

endmodule // UartTx
