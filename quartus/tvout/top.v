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
initial begin
    vmem[17'h01050] = 16'b0000001110011111;
    vmem[17'h01070] = 16'b0000010001000001;
    vmem[17'h01090] = 16'b0000010001000010;
    vmem[17'h010B0] = 16'b0000011111000100;
    vmem[17'h010D0] = 16'b0000010001001000;
    vmem[17'h010F0] = 16'b0000010001010000;
    vmem[17'h01110] = 16'b0000010001010000;

    vmem[17'h01051] = 16'b0011100111110000;
    vmem[17'h01071] = 16'b0100010000010000;
    vmem[17'h01091] = 16'b0100010000100000;
    vmem[17'h010B1] = 16'b0111110001000000;
    vmem[17'h010D1] = 16'b0100010010000000;
    vmem[17'h010F1] = 16'b0100010100000000;
    vmem[17'h01111] = 16'b0100010100000000;

    vmem[17'h01150] = 16'b0000001110011111;
    vmem[17'h01170] = 16'b0000010001000001;
    vmem[17'h01190] = 16'b0000010001000010;
    vmem[17'h011B0] = 16'b0000011111000100;
    vmem[17'h011D0] = 16'b0000010001001000;
    vmem[17'h011F0] = 16'b0000010001010000;
    vmem[17'h01210] = 16'b0000010001010000;

    vmem[17'h01151] = 16'b0011100111110000;
    vmem[17'h01171] = 16'b0100010000010000;
    vmem[17'h01191] = 16'b0100010000100000;
    vmem[17'h011B1] = 16'b0111110001000000;
    vmem[17'h011D1] = 16'b0100010010000000;
    vmem[17'h011F1] = 16'b0100010100000000;
    vmem[17'h01211] = 16'b0100010100000000;
end

// delay by one cycle to perform the video ram fetch
reg active_d, vout_d, sync_d;
always @(posedge clk10) begin
    active_d = active;
//  vout_d <= xpos == 4 || xpos == 14 || xpos == 485 || xpos == 495 ||
//            ypos == 20 || ypos == 30 || ypos == 277 || ypos == 287;
    if (xpos[3:0] == 4'b0)
        vdata <= vmem[{ypos,xpos[8:4]}];
    else
        vdata <= {vdata[14:0],1'b0};
    vout_d = vdata[15];
    sync_d <= vsync || hsync;
end

assign vout = active_d && vout_d;
assign sync_ = !sync_d;

endmodule
