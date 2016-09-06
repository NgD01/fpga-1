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
            if (yPos == 258)
                yPos <= 0;
            else
                yPos <= yPos + 9'd1;
        end else
            xPos <= xPos + 10'd1;

reg active, vSync;
always @(*)
    if (xPos < 512 && yPos < 240)
        {active,vSync} = 2'b10;
    else if (yPos < 242)
        {active,vSync} = 2'b00;
    else if (yPos < 244)
        {active,vSync} = 2'b01;
    else if (yPos == 244)
        {active,vSync} = xPos < 534-320 ? 2'b01 : 2'b00;
    else
        {active,vSync} = 2'b00;

wire hSync = 534 <= xPos && xPos < 581;

localparam XMIN=8, XMAX=495, YMIN=18, YMAX=233;
wire vBars = xPos==XMIN || xPos==XMIN+10 || xPos==XMAX-10 || xPos==XMAX;
wire hBars = yPos==YMIN || yPos==YMIN+10 || yPos==YMAX-10 || yPos==YMAX;
wire vTest = vBars && YMIN <= yPos && yPos <= YMAX;
wire hTest = hBars && XMIN <= xPos && xPos <= XMAX;

reg [7:0] vData, vShift, vMem [512*256/8];  // 16 KB
reg [14:0] vAddr;

// delay by one cycle to perform the video ram fetch
reg active_d, vout_d, sync_d;
always @(posedge clk) begin
    if (fetchClk) begin
        vAddr <= {yPos,xPos[8:3]};
        if (vAddr == 15'h2001 || vAddr == 15'h2002 || vAddr == 15'h2003)
            vMem[vAddr] <= 8'hAA;
        else if (vAddr == 15'h2041 || vAddr == 15'h2042 || vAddr == 15'h2043)
            vMem[vAddr] <= 8'hA0;
        else if (vAddr == 15'h2081 || vAddr == 15'h2082 || vAddr == 15'h2083)
            vMem[vAddr] <= 8'h80;
        else if (vAddr == (YMIN*512+XMIN)/8 || vAddr == (YMIN*512+XMAX)/8 ||
                 vAddr == (YMAX*512+XMIN)/8 || vAddr == (YMAX*512+XMAX)/8)
            vMem[vAddr] <= 8'h81;
        if (vAddr == 15'h1001 || vAddr == 15'h1041 || vAddr == 15'h1081)
            vData <= 8'hAA;
        else if (vAddr == 15'h103C || vAddr == 15'h107C || vAddr == 15'h10BC)
            vData <= 8'h55;
        else
            vData <= vMem[vAddr];
    end

    if (fetchClk) begin
        active_d = active;
        vout_d <= vTest || hTest;       // double border test
//      vout_d <= xPos[3] ^ yPos[3];    // 8x8 checkerboard
//      vout_d <= xPos[0] ^ yPos[0];    // 1x1 checkerboard
//      vout_d <= xPos[0];              // fine vertical bars
//      vout_d <= yPos[0];              // fine horizontal bars
        sync_d <= vSync || hSync;
        vShift <= vData;
    end else if (pixClk)
        vShift <= {vShift[6:0],1'b0};
//  vout_d = vShift[7];
end

assign vout = active_d && vout_d;
assign sync_ = !sync_d;

endmodule
