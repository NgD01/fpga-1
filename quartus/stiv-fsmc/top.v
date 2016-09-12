module top (
    input clk,
    input noe, nwe, nce2, nce3,
    input [1:0] addr,
    output [3:0] leds,
    inout [15:0] data,
    output wbCSn
);

wire select = nce2 == 0;

wire c0, reset_l;
pll U1 (
    .inclk0(clk),
    .c0(c0),
    .locked(reset_l)
);

reg [2:0] noe_r;
always @(posedge c0)
    noe_r <= {noe_r[1:0],noe};
wire read = noe_r[2:1] == 2'b01 && select;

reg [2:0] nwe_r;
always @(posedge c0)
    nwe_r <= {nwe_r[1:0],nwe};
wire write = nwe_r[2:1] == 2'b10 && select;

assign leds = index[3:0];
assign wbCSn = 1'b1;  // keep WinBond flash memory deselected

reg [8:0] index;
reg [15:0] latch, mem [512];
always @(posedge c0) begin
    if (write) begin
        if (addr[1] == 1'b1)
            index <= data;
        else if (addr[0] == 1'b0) begin
            mem[index] <= data;
            index <= index + 9'd1;
        end
    end
    if (read) begin
        latch <= mem[index];
        index <= index + 9'd1;
    end
end

assign data = noe_r[1] == 0 && select ? latch : 16'hzzzz;

endmodule
