module top (
    input clk, reset
);

wire [15:0] abus;
wire [7:0] din;
wire [7:0] dout;
wire irq = 1'b0;
wire nmi = 1'b0;
wire rdy = 1'b0;
wire we;

reg [7:0] mem [8192];
reg [7:0] data;
always @(posedge clk) begin
    if (we)
        mem[abus] <= din;
    data <= mem[abus];
end
assign dout = data;

cpu cpu (
    .clk(clk),
    .reset(reset),
    .AB(abus),
    .DI(din),
    .DO(dout),
    .WE(we),
    .IRQ(irq),
    .NMI(nmi),
    .RDY(rdy)
);

endmodule
