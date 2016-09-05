module top (
    input clk,
    output vout, sync_
);

reg [2:0] count;
wire clk10 = count[2];
always @(posedge clk) begin
    if (count == 4)
        count <= 0;
    else
        count <= count + 3'd1;
end

reg [9:0] xpos;
reg [8:0] ypos;
always @(posedge clk10) begin
    if (xpos == 639) begin
        xpos <= 0;
        if (ypos == 308)
            ypos <= 0;
        else
            ypos <= ypos + 9'd1;
    end else
        xpos <= xpos + 10'd1;
end

reg active, vsync;
always @(*)
    if (xpos < 512 && ypos < 288)
        {active,vsync} = 2'b10;
    else if (ypos < 290)
        {active,vsync} = 2'b00;
    else if (ypos < 292)
        {active,vsync} = 2'b01;
    else if (ypos == 292)
        {active,vsync} = xpos < 320 ? 2'b01 : 2'b00;
    else
        {active,vsync} = 2'b00;

wire hsync = 533 <= xpos && xpos < 580;

reg [15:0] vdata, vmem [512*288/16]; // 18 KB

reg vwr;
reg [13:0] vaddr, vaddr_r;
reg [15:0] vdatin, vdatout;

// delay by one cycle to perform the video ram fetch
reg active_d, vout_d, sync_d;
always @(posedge clk10) begin
    if (vwr)
        vmem[vaddr] <= vdatin;
    vdatout = vmem[vaddr];

    vaddr_r <= {ypos,xpos[8:4]};
    if (xpos[3:0] == 4'b0)
        vdata <= 16'h5555; //vmem[vaddr_r];
    else
        vdata <= {vdata[14:0],1'b0};
    vout_d = vdata[15];

    active_d = active;
    sync_d <= vsync || hsync;
end

assign vout = active_d && vout_d;
assign sync_ = !sync_d;

endmodule
