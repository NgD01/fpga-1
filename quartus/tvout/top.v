module top (
    input clk,
    output vout, sync_
);

reg [2:0] clkDiv;
always @(posedge clk) begin
    if (clkDiv == 4)
        clkDiv <= 0;
    else
        clkDiv <= clkDiv + 3'd1;
end
wire pixClk = clkDiv == 0;

reg [2:0] pixDiv;
always @(posedge clk)
    pixDiv <= pixDiv + 3'd1;
wire fetchClk = pixDiv == 0;

reg [9:0] xPos;
reg [8:0] yPos;
always @(posedge clk)
    if (pixClk)
        if (xPos == 639) begin
            xPos <= 0;
            if (yPos == 308)
                yPos <= 0;
            else
                yPos <= yPos + 9'd1;
        end else
            xPos <= xPos + 10'd1;

reg active, vSync;
always @(*)
    if (xPos < 512 && yPos < 287)
        {active,vSync} = 2'b10;
    else if (yPos < 288)
        {active,vSync} = 2'b00;
    else if (yPos < 290)
        {active,vSync} = 2'b01;
    else if (yPos == 290)
        {active,vSync} = xPos < 532-320 ? 2'b01 : 2'b00;
    else
        {active,vSync} = 2'b00;

wire hSync = 532 <= xPos && xPos < 579;

localparam XMIN=8, XMAX=495, YMIN=18, YMAX=283;
wire vBars = xPos==XMIN || xPos==XMIN+10 || xPos==XMAX-10 || xPos==XMAX;
wire hBars = yPos==YMIN || yPos==YMIN+10 || yPos==YMAX-10 || yPos==YMAX;
wire vCut = vBars && YMIN <= yPos && yPos <= YMAX;
wire hCut = hBars && XMIN <= xPos && xPos <= XMAX;

// delay by one cycle to perform the video ram fetch
reg active_d, vout_d, sync_d;
always @(posedge clk)
    if (fetchClk) begin
        active_d = active;
        vout_d <= vCut || hCut;
        sync_d <= vSync || hSync;
    end

assign vout = active_d && vout_d;
assign sync_ = !sync_d;

endmodule
