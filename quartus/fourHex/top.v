module top (
    input clk,
    output ld1, ld2, ld3, ld4, ld5, ld6, ld7, ld8,
    output an0, an1, an2, an3
);

reg [31:0] count;
always @(posedge clk) count <= count + 1;

reg [3:0] digits;
reg [7:0] segments;
always @(*) begin
    case (count[19:18])
        0:       digits = 4'b0111;
        1:       digits = 4'b1011;
        2:       digits = 4'b1101;
        3:       digits = 4'b1110;
        default: digits = 4'b1111;
    endcase
    case (count[19:18]+1) // display "1234" for now
        0:       segments = 8'b00000011;
        1:       segments = 8'b10011111;
        2:       segments = 8'b00100101;
        3:       segments = 8'b00001101;
        4:       segments = 8'b10011001;
        5:       segments = 8'b01001001;
        6:       segments = 8'b01000001;
        7:       segments = 8'b00011111;
        8:       segments = 8'b00000001;
        9:       segments = 8'b00001001;
        10:      segments = 8'b00010001;
        11:      segments = 8'b11000001;
        12:      segments = 8'b01100011;
        13:      segments = 8'b10000101;
        14:      segments = 8'b01100001;
        15:      segments = 8'b01110001;
        default: segments = 8'b00000000;
    endcase
end

assign { an0,an1,an2,an3 } = digits;

assign ld1 = !segments[7]; // ca
assign ld2 = !segments[6]; // cb
assign ld3 = !segments[5]; // cc
assign ld4 = !segments[4]; // cd
assign ld5 = !segments[3]; // ce
assign ld6 = !segments[2]; // cf
assign ld7 = !segments[1]; // cg
assign ld8 = !segments[0]; // dp

endmodule
