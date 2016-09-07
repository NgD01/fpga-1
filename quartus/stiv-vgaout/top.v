module top (
    input clk, // 50 MHz
    output red,
    output green,
    output blue,
    output hsync, vsync
);

reg pixClk;
always @(posedge clk)
    pixClk <= ~pixClk;  // 25 MHz

reg [2:0] pixDiv;
always @(posedge clk)
    pixDiv <= pixDiv + 3'd1;
wire fetchClk = pixDiv == 0;

reg [9:0] xPos;
reg [8:0] yPos;
always @(posedge clk)
    if (pixClk)
        if (xPos == 799) begin
            xPos <= 0;
            if (yPos == 524)
                yPos <= 0;
            else
                yPos <= yPos + 9'd1;
        end else
            xPos <= xPos + 10'd1;

reg active, vSync;
always @(*)
    if (xPos < 640 && yPos < 480)
        {active,vSync} = 2'b10;
    else if (yPos < 481)
        {active,vSync} = 2'b00;
    else if (yPos < 483)
        {active,vSync} = 2'b01;
    else
        {active,vSync} = 2'b00;

wire hSync = 658 <= xPos && xPos < 754;

localparam XMIN=0, XMAX=639, YMIN=0, YMAX=479;
wire vBars = xPos==XMIN || xPos==XMIN+10 || xPos==XMAX-10 || xPos==XMAX;
wire hBars = yPos==YMIN || yPos==YMIN+10 || yPos==YMAX-10 || yPos==YMAX;
wire vTest = vBars && YMIN <= yPos && yPos <= YMAX;
wire hTest = hBars && XMIN <= xPos && xPos <= XMAX;

// delay by one cycle to perform the video ram fetch
reg active_d, vout_d, hSync_d, vSync_d;
always @(posedge clk) begin
    if (pixClk) begin
        active_d = active;
        vout_d <= vTest || hTest;       // double border test
//      vout_d <= xPos[3] ^ yPos[3];    // 8x8 checkerboard
//      vout_d <= xPos[0] ^ yPos[0];    // 1x1 checkerboard
//      vout_d <= xPos[0];              // fine vertical bars
//      vout_d <= yPos[0];              // fine horizontal bars
        hSync_d <= hSync;
        vSync_d <= vSync;
    end
end

assign {red,green,blue} = {3{active_d && vout_d}};
assign hsync = hSync_d;
assign vsync = vSync_d;

endmodule
