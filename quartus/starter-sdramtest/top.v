module top (
    input clk,
    input reset,
    // SDRAM pins
    output zs_ck,
    output zs_cke,
    output zs_cs_n,
    output zs_ras_n,
    output zs_cas_n,
    output zs_we_n,
    output [1:0]  zs_ba,
    output [12:0] zs_addr,
    output [1:0]  zs_dqm,
    inout [ 15:0] zs_dq,
    // act as slave w.r.t microcontroller
    input ucSEL_,
    input ucSCLK,
    input ucMOSI,
    output ucMISO,
    // debugging
    output [7:0] led
);

wire         sdram_req;
wire [23:0]  sdram_addr;
wire         sdram_rh_wl;
wire [15:0]  sdram_data_w;
wire [15:0]  sdram_data_r_lock;
wire [15:0]  sdram_data_r;
wire         sdram_data_r_en;
wire         sdram_ack;

wire [63:0] ins = {
    sdram_ack,          // 63
    sdram_data_r_en,    // 62
    14'b0,
    sdram_data_r,       // 47:32
    32'b1
};

wire [63:0] outs;
assign sdram_req    = outs[63];
assign sdram_rh_wl  = outs[62];
assign led          = outs[55:48];
assign sdram_data_w = outs[47:32];
assign sdram_addr   = outs[23:0];

SpiPeek U0 (
    .clk(clk),
    .ucSCLK(ucSCLK),
    .ucMOSI(ucMOSI),
    .ucMISO(ucMISO),
    .ucSEL_(ucSEL_),
    .data_in(ins),
    .data_out(outs)
);

SdramCtrl U1 (
    .clk             (clk),
    .reset_l         (~reset),

    .sdram_req       (sdram_req),
    .sdram_ack       (sdram_ack),
    .sdram_addr      (sdram_addr),
    .sdram_rh_wl     (sdram_rh_wl),
    .sdram_data_w    (sdram_data_w),
    .sdram_data_r    (sdram_data_r),
    .sdram_data_r_en (sdram_data_r_en),

    .zs_ck           (zs_ck),
    .zs_cke          (zs_cke),
    .zs_cs_n         (zs_cs_n),
    .zs_ras_n        (zs_ras_n),
    .zs_cas_n        (zs_cas_n),
    .zs_we_n         (zs_we_n),
    .zs_ba           (zs_ba),
    .zs_addr         (zs_addr),
    .zs_dqm          (zs_dqm),
    .zs_dq           (zs_dq)
);

endmodule
