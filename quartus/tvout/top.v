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
    if (xpos < 492 && ypos < 268)
        mode = VISIBLE;
    else if (ypos < 270)
        mode = BLANKED;
    else if (ypos < 272)
        mode = VSYNC;
    else if (ypos == 272)
        mode = xpos < 320 ? VSYNC : BLANKED;
    else
        mode = BLANKED;

wire enable = mode == VISIBLE;
wire vsync = mode == VSYNC;
wire hsync = 529 <= xpos && xpos < 576;

assign vout = enable && (xpos == 0 || xpos == 491 || ypos == 0 || ypos == 267);
assign sync_ = enable || !(vsync || hsync);

endmodule
