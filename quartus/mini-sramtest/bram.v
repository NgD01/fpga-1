// simple BRAM access
// -jcw, 2016-09-10

module BramCtrl (
    clk,
    reset_l,
    //client interface
    sram_req,
    sram_ack,
    sram_addr,
    sram_rh_wl,
    sram_data_w,
    sram_data_r,
    sram_data_r_en, // indicate read data valid
    //chip interface
    zs_oe_n,
    zs_cs_n,
    zs_we_n,
    zs_addr,
    zs_dq
);

parameter ADDR_WIDTH  = 19;
parameter DATA_WIDTH  = 8;

input clk, reset_l, sram_req;

input                   sram_rh_wl;
input  [ADDR_WIDTH-1:0] sram_addr;
input  [DATA_WIDTH-1:0] sram_data_w;
output                  sram_ack;
output                  sram_data_r_en;
output [DATA_WIDTH-1:0] sram_data_r;

output zs_oe_n, zs_cs_n, zs_we_n;
output [ADDR_WIDTH-1:0] zs_addr;
inout  [DATA_WIDTH-1:0] zs_dq;

reg [7:0] data_r, mem [16384];
always @(posedge clk) begin
    if (sram_req && sram_rh_wl == 0)
        mem[sram_addr[13:0]] <= sram_data_w;
    data_r <= mem[sram_addr[13:0]];
end
assign sram_data_r = data_r;
assign sram_ack = sram_req;

reg valid;
always @(posedge clk)
    valid <= sram_req;
assign sram_data_r_en = valid;

// keep the external SRAM chip disabled
assign zs_oe_n = 1, zs_cs_n = 1, zs_we_n = 1, zs_addr = 0;

endmodule
