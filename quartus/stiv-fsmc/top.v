module top (
    input clk,
    // fsmc interface
    input noe, nwe, nce2, nce3, ale, cle,
    output [3:0] leds,
    inout [15:0] data,
    // vga video output
    output red, green, blue, hsync, vsync,
    // flash memory enable
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
wire read = noe_r[2:1] == 2'b10 && select;  // falling edge

reg [2:0] nwe_r;
always @(posedge c0)
    nwe_r <= {nwe_r[1:0],nwe};
wire write = nwe_r[2:1] == 2'b01 && select;  // rising edge

assign leds = index[3:0];
assign wbCSn = 1'b1;  // keep WinBond flash memory deselected

reg [9:0] index;
reg [15:0] latch, tlatch, mem [1024];
always @(posedge c0) begin
    if (write) begin
        if (ale == 1'b1)
            index <= data[9:0];
        else if (cle == 1'b0) begin
            mem[index] <= data;
            index <= index + 10'd1;
        end
    end else if (read) begin
        latch <= mem[index];
        index <= index + 10'd1;
    end
    tlatch <= mem[taddr];
end

assign data = noe == 0 && select ? latch : 16'hzzzz;

wire [9:0] taddr;
vga U2 (
    .clk(clk),
    .red(red),
    .green(green),
    .blue(blue),
    .hsync(hsync),
    .vsync(vsync),
    .taddr(taddr),
    .tvalue(~tlatch[11:3]) // scanline counter runs from top to bottom
);

endmodule
