// adapted from example spi slave at http://www.fpga4fun.com/SPI2.html

module SpiPeek (
    input clk,
    // act as slave for microcontroller
    input ucSCLK,
    input ucMOSI,
    output ucMISO,
    input ucSEL_,
    // the data bits to be read and written
    input [PEEK_BITS-1:0] data_in,
    output reg [PEEK_BITS-1:0] data_out
);

parameter PEEK_BITS = 64;

// sync ucSCLK to the FPGA clock using a 3-bits shift register
reg [2:0] SCLKr; always @(posedge clk) SCLKr <= {SCLKr[1:0],ucSCLK};
wire SCLK_rising = SCLKr[2:1] == 2'b01;     // detect ucSCLK rising edges
wire SCLK_falling = SCLKr[2:1] == 2'b10;    // and falling edges

// same thing for ucSEL_
reg [2:0] SSELr; always @(posedge clk) SSELr <= {SSELr[1:0],ucSEL_};
wire SSEL_active = ~SSELr[2];               // ucSEL_ is active low
wire SSEL_start = SSELr[2:1] == 2'b10;      // start on falling edge
wire SSEL_end = SSELr[2:1] == 2'b01;        // stop on rising edge

// and for ucMOSI, but no need to detect edges
reg [1:0] MOSIr; always @(posedge clk) MOSIr <= {MOSIr[0],ucMOSI};
wire MOSI_data = MOSIr[1];

reg incoming;
reg [PEEK_BITS-1:0] outgoing;
always @(posedge clk) begin
    if (SSEL_start)
        outgoing <= data_in;

    if (SSEL_end)
        data_out <= outgoing;

    if (SSEL_active) begin
        if (SCLK_rising) // shift in from the right
            incoming <= MOSI_data;
        if (SCLK_falling) // shift out from the left
            outgoing <= {outgoing[PEEK_BITS-2:0],incoming};
    end
end

// we'll need to tri-state ucMISO if there's more than one slave on the SPI bus
assign ucMISO = outgoing[PEEK_BITS-1]; // send MSB first

endmodule
