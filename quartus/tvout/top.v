module top (
    input clk,
    output vout, sync_
);

reg [2:0] count;
always @(posedge clk) begin
    if (count == 4)
        count <= 0;
    else
        count <= count + 3'd1;
end
wire clk10 = count == 0;

reg [9:0] xpos;
reg [8:0] ypos;
always @(posedge clk)
    if (clk10)
        if (xpos == 639) begin
            xpos <= 0;
            if (ypos == 308)
                ypos <= 0;
            else
                ypos <= ypos + 9'd1;
        end else
            xpos <= xpos + 10'd1;

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

// delay by one clk10 cycle to perform the video ram fetch
reg active_d, vout_d, sync_d;
always @(posedge clk) begin
    active_d = active;
    vout_d <= xpos == 4 || xpos == 14 || xpos == 485 || xpos == 495 ||
              ypos == 20 || ypos == 30 || ypos == 277 || ypos == 287;
    sync_d <= vsync || hsync;
end

assign vout = active_d && vout_d;
assign sync_ = !sync_d;

endmodule
