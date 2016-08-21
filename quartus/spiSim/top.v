module newspi (
    input clk,
    input wr,
    input [7:0] data_in,
    output done,
    output [7:0] data_out,
    output sclk, mosi,
    input miso
);

reg [4:0] count;
reg [7:0] shifter;
reg active;

wire sclk = !count[0];
wire busy = count[4];
wire done = !active;
wire data_out = shifter;

wire active_n, mosi_n;
wire [7:0] shifter_n;
wire [4:0] count_n;

always @(*) begin
    { active_n,shifter_n,count_n,mosi_n } = { active,shifter,count,mosi };
    case (active)
        1'b0:
            if (wr) begin
                active_n = 1;
                shifter_n = data_in;
                count_n = 5'b10000;
            end
        1'b1: begin
            if (busy)
                count_n = count + 1;
            else
                active_n = 0;
            if (sclk)
                mosi_n = shifter[7];
            else
                shifter_n = { shifter[6:0], miso };
        end
    endcase
end

always @(posedge clk) begin
	active <= active_n;
	mosi <= mosi_n;
	shifter <= shifter_n;
    count <= count_n;
end

endmodule
