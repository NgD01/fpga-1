module top (
    input clk,
    input noe, nwe, nce2, nce3,
    input [1:0] addr,
    output [3:0] leds,
    inout [15:0] data,
    output wbCSn
);

reg [15:0] latch, mem [512];
reg [8:0] index;

reg [2:0] noe_r, nwe_r;
always @(posedge clk)
    noe_r <= {noe_r[1:0],noe};
wire read = noe_r[2:1] == 2'b10;
always @(posedge clk)
    nwe_r <= {nwe_r[1:0],nwe};
wire write = nwe_r[2:1] == 2'b01;

assign leds = data[3:0];
assign wbCSn = 1'b1;  // keep WinBond flash memory deselected

always @(posedge clk) begin
    if (write && nce2 == 0)
        if (addr[1] == 0)
            index <= data;
        else begin
            mem[index] <= data;
            index <= index + 1;
        end
    if (read && nce2 == 0) begin
        latch <= mem[index];
        index <= index + 1;
    end
end

assign data = read ? 16'hz : latch;

endmodule
