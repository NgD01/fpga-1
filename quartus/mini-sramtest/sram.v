// simple SRAM controller
// -jcw, 2016-09-10

module SramCtrl (
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

wire zs_oe_n = 1'b1, zs_cs_n, zs_we_n;

endmodule
