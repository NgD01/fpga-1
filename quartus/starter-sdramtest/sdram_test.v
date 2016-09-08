module top (
    clk,
    reset,
    zs_ck,
    zs_cke,
    zs_cs_n,
    zs_ras_n,
    zs_cas_n,
    zs_we_n,
    zs_ba,
    zs_addr,
    zs_dqm,
    zs_dq,
    led
);

input             clk;
input             reset;
output            zs_ck;
output            zs_cke;
output            zs_cs_n;
output            zs_ras_n;
output            zs_cas_n;
output            zs_we_n;
output     [1:0]  zs_ba;
output     [12:0] zs_addr;
output     [1:0]  zs_dqm;
inout      [15:0] zs_dq;
output reg [7:0]  led;

// three state
parameter   IDLE   =  3'b001;
parameter   WRITE  =  3'b010;
parameter   READ   =  3'b100;

parameter  div_400us = 15'd25000; // delay number,for initialization of sdram
parameter  sdram_addr_num = 24'b0; // row col bank: 13+9+2
parameter  sdram_data_w_num = 16'b1111000001010101; // f055

reg          sdram_req;
reg  [23:0]  sdram_addr;
reg          sdram_rh_wl;
reg  [15:0]  sdram_data_w;
reg  [2:0]   current_state;
reg  [2:0]   current_state_dly1;
reg  [2:0]   next_state;
reg  [14:0]  init_wait_cnt;
reg  [7:0]   wr_cnt;
reg  [15:0]  sdram_data_r_lock;
wire [15:0]  sdram_data_r;
wire         sdram_data_r_en;
wire         sdram_ack;
wire         rd_en;
wire         wr_en;
wire         reset_l = ~reset;

always @(posedge clk or negedge reset_l)
    if (!reset_l)
        current_state<=IDLE;
    else
        current_state <= next_state;

always @(posedge clk or negedge reset_l)
    if (!reset_l)
        init_wait_cnt<=15'b0;
    else if (init_wait_cnt<= (div_400us-1))
        init_wait_cnt<=init_wait_cnt+15'b1;

always @(posedge clk or negedge reset_l)
    if (!reset_l)
        wr_cnt <= 8'b0;
    else if (current_state == WRITE && wr_cnt < 8'd250)
        wr_cnt <= wr_cnt + 8'b1;

always @(*)
    case(current_state)
        IDLE:
            if (init_wait_cnt>= (div_400us-1))
                next_state=WRITE;
            else
                next_state=IDLE;
        WRITE:
            if (wr_cnt == 8'd250)
                next_state=READ;
            else
                next_state=WRITE;
        READ:
            next_state=READ;
   endcase

// delay button's signal, make this stable
always @(posedge clk or negedge reset_l)
    if (!reset_l)
        current_state_dly1 <=3'b0;
    else
        current_state_dly1<=current_state;

assign wr_en =  (current_state == WRITE) & (current_state_dly1 != WRITE);

assign rd_en =  (current_state == READ) & (current_state_dly1 != READ);

always @(posedge clk or negedge reset_l)
    if (!reset_l) begin
        sdram_rh_wl<=1'b1;
        sdram_req<=1'b0;
        sdram_addr<=0;
        sdram_data_w<=0;
    end else if (current_state == WRITE) begin
        sdram_addr <= sdram_addr_num;
        sdram_data_w <= sdram_data_w_num;
        sdram_req    <= wr_en;
        sdram_rh_wl  <= 1'b0;
    end else if (current_state == READ) begin
        sdram_rh_wl  <= 1'b1;
        sdram_req    <= rd_en;
    end

always @(posedge clk or negedge reset_l)
    if (!reset_l)
        sdram_data_r_lock <=16'b0;
    else if (sdram_ack == 1'b1 && sdram_rh_wl == 1'b1)
        sdram_data_r_lock <= sdram_data_r;

always @(posedge clk or negedge reset_l)
    if (!reset_l)
        led <=8'b0;
    else if (sdram_data_r_lock == sdram_data_w)
        led <=8'h55;

SdramCtrl u_sdram_ctrl (
    .clk             (clk),
    .reset_l         (reset_l),

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
