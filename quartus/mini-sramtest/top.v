module top (
    input clk,
    // SRAM pins
    output zs_oe_n,
    output zs_cs_n,
    output zs_we_n,
    output [18:0] zs_addr,
    inout [7:0] zs_dq,
    // act as slave w.r.t microcontroller
    input ucSEL_,
    input ucSCLK,
    input ucMOSI,
    output ucMISO,
    // debugging
    output [7:0] led
);

wire        sram_req;
wire [18:0] sram_addr;
wire        sram_rh_wl;
wire [7:0]  sram_data_w;
wire [7:0]  sram_data_r_lock;
wire [7:0]  sram_data_r;
wire        sram_data_r_en;

wire [31:0] ins = {
    1'b0,              // 31
    sram_data_r_en,    // 30
    sram_data_r,       // 29:22
    22'b1
};

wire [31:0] outs;
assign sram_req    = outs[31];
assign sram_rh_wl  = outs[30];
assign sram_data_w = outs[29:22];
assign led         = outs[21:14];
assign sram_addr   = outs[18:0];

wire c0, reset_l;
pll U1 (
    .inclk0(clk),
    .c0(c0),
    .locked(reset_l)
);

SpiPeek U2 (
    .clk(c0),
    .ucSCLK(ucSCLK),
    .ucMOSI(ucMOSI),
    .ucMISO(ucMISO),
    .ucSEL_(ucSEL_),
    .data_in(ins),
    .data_out(outs)
);
defparam U2.WIDTH = 32;

SramCtrl U3 (
    .clk            (c0),
    .reset          (~reset_l),

    .sram_req       (sram_req),
    .sram_addr      (sram_addr),
    .sram_rh_wl     (sram_rh_wl),
    .sram_data_w    (sram_data_w),
    .sram_data_r    (sram_data_r),
    .sram_data_r_en (sram_data_r_en),

    .zs_oe_n        (zs_oe_n),
    .zs_cs_n        (zs_cs_n),
    .zs_we_n        (zs_we_n),
    .zs_addr        (zs_addr),
    .zs_dq          (zs_dq)
);

endmodule
