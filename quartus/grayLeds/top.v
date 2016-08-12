module top (
    input clk,
    output led0,
    output led1,
    output led2,
    output led3,
    output led4,
    output led5,
    output led6,
    output led7
);

reg [31:0] count;
always @(posedge clk) count <= count + 1;

// gray counter
assign led0 = count[24] ^ count[25];
assign led1 = count[25] ^ count[26];
assign led2 = count[26] ^ count[27];
assign led3 = count[27] ^ count[28];
assign led4 = count[28] ^ count[29];
assign led5 = count[29] ^ count[30];
assign led6 = count[30] ^ count[31];
assign led7 = count[31];

endmodule // top
