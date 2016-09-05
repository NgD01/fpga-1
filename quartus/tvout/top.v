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
        count <= count + 1;
end

reg [9:0] xpos;
reg [8:0] ypos;
always @(posedge clk10) begin
    if (xpos == 639) begin
        xpos <= 0;
        if (ypos == 308)
            ypos <= 0;
        else
            ypos <= ypos + 1;
    end else
        xpos <= xpos + 1;
end

localparam VISIBLE=2'b00, BLANKED=2'b01, VSYNC=2'b10;

reg [1:0] mode;
always @(*)
    if (xpos < 512 && ypos < 288)
        mode = VISIBLE;
    else if (ypos < 290)
        mode = BLANKED;
    else if (ypos < 292)
        mode = VSYNC;
    else if (ypos == 292)
        mode = xpos < 320 ? VSYNC : BLANKED;
    else
        mode = BLANKED;

wire enable = mode == VISIBLE;
wire vsync = mode == VSYNC;
wire hsync = 533 <= xpos && xpos < 580;

assign vout = enable && (xpos==4 || xpos == 14 || xpos == 485 || xpos==495 ||
                        ypos==20 || ypos == 30 || ypos == 277 || ypos==287);
assign sync_ = enable || !(vsync || hsync);

endmodule
