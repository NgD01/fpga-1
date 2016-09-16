module vga (
    input clk, // 50 MHz
    output red, green, blue, hsync, vsync,
    // trace access
    output [9:0] taddr,
    input [8:0] tvalue
);

reg pixClk;
always @(posedge clk)
    pixClk <= ~pixClk;  // 25 MHz

reg [2:0] pixDiv;
always @(posedge clk)
    pixDiv <= pixDiv + 3'd1;

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
    else if (yPos < 484)
        {active,vSync} = 2'b00;
    else if (yPos < 486)
        {active,vSync} = 2'b01;
    else
        {active,vSync} = 2'b00;

wire hSync = 658 <= xPos && xPos < 754;

localparam XMIN=0, XMAX=639, YMIN=0, YMAX=479;
wire vBars = xPos==XMIN || xPos==XMAX;
wire hBars = yPos==YMIN || yPos==YMAX;
wire vBorder = vBars && YMIN <= yPos && yPos <= YMAX;
wire hBorder = hBars && XMIN <= xPos && xPos <= XMAX;
wire tMatch = tvalue == yPos;

// delay by one cycle to perform the video ram fetch
reg active_d, vout_d, hSync_d, vSync_d;
always @(posedge clk) begin
    if (pixClk) begin
        active_d = active;
        vout_d <= vBorder || hBorder || tMatch;
        hSync_d <= hSync;
        vSync_d <= vSync;
    end
end

assign {red,green,blue} = {3{active_d && vout_d}};
assign hsync = hSync_d;
assign vsync = vSync_d;
assign taddr = xPos;

endmodule
