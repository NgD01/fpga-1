// Copyright 2014[c]
// File name:        sdram_ctrl.v
// Author:           huaming.huang@link-real.com.cn
// Date:             2014-02-11 09:58
// Version Number:   1.0
// Abstract:         sdram controller
// 2014-02-11 09:58  version 1.0     xxx

module sdram_ctrl (
    //input
    clk,
    reset_l,
    //client interface
    sdram_req,
    sdram_ack,
    sdram_addr,
    sdram_rh_wl,
    sdram_data_w,
    sdram_data_r,
    sdram_data_r_en, //indicate read data valid
    //chip interface
    zs_ck,
    zs_cke,
    zs_cs_n,
    zs_ras_n,
    zs_cas_n,
    zs_we_n,
    zs_ba,
    zs_addr,
    zs_dqm,
    zs_dq
);

parameter     CHIP_ADDR_WIDTH         =  13;
parameter     BANK_ADDR_WIDTH         =  2;
parameter     ROW_WIDTH               =  13;
parameter     COL_WIDTH               =  9;
parameter     DATA_WIDTH              =  16;
parameter     CAS_LATENCY             =  3'b011;
//
// auto refresh cycle calculate: each row must be refreshed every 64ms, and just
// refresh one row each time.  and this chip have 8192 rows, so each refresh
// interval must less than 64ms/8192= 7.8125us 50Mhz clock should count to:
// 7.8125x1000/20 = 390,then have one time refresh

parameter     AUTO_REFRESH_CYCLE      = 390;
parameter     POWERON_WAIT_CYCLE      = 10000; // wait 200us,based on 50m clock

input                     clk;
input                     reset_l;

input                     sdram_req;
output                    sdram_ack;
input   [ROW_WIDTH+COL_WIDTH+BANK_ADDR_WIDTH-1:0] sdram_addr;
input                     sdram_rh_wl;
input   [DATA_WIDTH-1:0]  sdram_data_w;
output  [DATA_WIDTH-1:0]  sdram_data_r;
output                    sdram_data_r_en;

output                        zs_ck;
output                        zs_cke;
output                        zs_cs_n;
output                        zs_ras_n;
output                        zs_cas_n;
output                        zs_we_n;
output  [BANK_ADDR_WIDTH-1:0] zs_ba;
output  [CHIP_ADDR_WIDTH-1:0] zs_addr;
output  [1:0]                 zs_dqm;
inout   [DATA_WIDTH-1:0]      zs_dq;

wire                          zs_ck;
assign zs_ck = clk;

wire                          zs_cke;
assign zs_cke = 1'b1;

wire                          zs_cs_n;
wire                          zs_ras_n;
wire                          zs_cas_n;
wire                          zs_we_n;
reg     [3:0]                 sdram_cmd;
reg     [BANK_ADDR_WIDTH-1:0] zs_ba;
reg     [CHIP_ADDR_WIDTH-1:0] zs_addr;
reg     [1:0]                 zs_dqm;
reg                           zs_dq_o_en;
reg     [DATA_WIDTH-1:0]      zs_dq_o;
wire    [DATA_WIDTH-1:0]      zs_dq_i;
assign zs_dq = (zs_dq_o_en==1'b1)?zs_dq_o:{DATA_WIDTH{1'bz}};
assign zs_dq_i = zs_dq;
assign {zs_cs_n, zs_ras_n, zs_cas_n, zs_we_n} = sdram_cmd;

reg     [DATA_WIDTH-1:0]    sdram_data_r;
reg                         sdram_data_r_en;
reg                         sdram_ack;

parameter   stat_poweron_wait   = 8'b00000001;
parameter   stat_precharge      = 8'b00000010;
parameter   stat_refresh        = 8'b00000100;
parameter   stat_mrs            = 8'b00001000;
parameter   stat_idle           = 8'b00010000;
parameter   stat_active_row     = 8'b00100000;
parameter   stat_read           = 8'b01000000;
parameter   stat_write          = 8'b10000000;

reg     [7:0]   CUR_STATE;
reg     [7:0]   NEXT_STATE;

reg             auto_refresh;
reg   [15:0]    auto_refresh_cnt;
reg             poweron_wait_ok;
reg             init_ok;
reg             precharge_done;
reg             refresh_done;
reg             mrs_done;
reg             active_row_done;
reg             read_done;
reg             write_done;

reg   [15:0]    poweron_wait_cnt;
reg   [3:0]     status_running_cnt;

always @(negedge reset_l or posedge clk) begin
    if(reset_l == 1'b0)
        CUR_STATE <= stat_poweron_wait ;
    else
        CUR_STATE <= NEXT_STATE;
end

always @(*) begin
    NEXT_STATE <= stat_idle;
    case (CUR_STATE)
        stat_poweron_wait : begin
            if(poweron_wait_ok == 1'b1) begin
                NEXT_STATE <= stat_precharge;
            end
            else begin
                NEXT_STATE <= stat_poweron_wait;
            end
        end
        stat_precharge :  begin
            if(precharge_done == 1'b1) begin
                    if(init_ok == 1'b1) begin
                        NEXT_STATE <= stat_idle;
                    end
                    else begin
                        NEXT_STATE <= stat_refresh;
                    end
            end else begin
                    NEXT_STATE <= stat_precharge;
            end
        end
        stat_refresh :  begin
            if(refresh_done == 1'b1) begin
                if(init_ok == 1'b1) begin
                    NEXT_STATE <= stat_idle;
                end
                else begin
                    NEXT_STATE <= stat_mrs;
                end
            end
            else begin
                    NEXT_STATE <= stat_refresh;
            end
        end
        stat_mrs :  begin
            if(mrs_done == 1'b1) begin
                    NEXT_STATE <= stat_idle;
            end
            else begin
                    NEXT_STATE <= stat_mrs;
            end
        end
        stat_idle :  begin
            if(auto_refresh == 1'b1) begin
            NEXT_STATE <= stat_refresh;
            end else if(sdram_req == 1'b1) begin
                    NEXT_STATE <= stat_active_row;
            end
            else begin
                    NEXT_STATE <= stat_idle;
            end
        end
        stat_active_row :  begin
            if(active_row_done == 1'b1) begin
                if(sdram_rh_wl == 1'b1) begin
                        NEXT_STATE <= stat_read;
                    end
                    else begin
                        NEXT_STATE <= stat_write;
                    end
            end
            else begin
                    NEXT_STATE <= stat_active_row;
            end
        end
        stat_read :  begin
            if(read_done == 1'b1) begin
                    NEXT_STATE <= stat_precharge;
            end
            else begin
                    NEXT_STATE <= stat_read;
            end
        end
        stat_write :  begin
            if(write_done == 1'b1) begin
                    NEXT_STATE <= stat_precharge;
            end
            else begin
                    NEXT_STATE <= stat_write;
            end
        end
        default : begin
            NEXT_STATE <= stat_idle ;
        end
    endcase
end

//sdram acknology control
always @ ( negedge reset_l or posedge clk ) begin
    if(reset_l == 1'b0) begin
        sdram_ack <= 1'b0;
    end else begin
        sdram_ack <= 1'b0;
        if(CUR_STATE == stat_active_row) begin
            sdram_ack <= 1'b1;
        end else if(sdram_req == 1'b1) begin
            sdram_ack <= 1'b0;
        end
    end
end

//stat_poweron_wait
always @ ( negedge reset_l or posedge clk ) begin
    if(reset_l == 1'b0) begin
        poweron_wait_cnt <= 16'b0;
        poweron_wait_ok <= 1'b0;
    end else begin
        poweron_wait_ok <= 1'b0;
        if(CUR_STATE == stat_poweron_wait) begin
            if(poweron_wait_cnt >= POWERON_WAIT_CYCLE) begin
                poweron_wait_ok <= 1'b1;
            end else begin
                poweron_wait_cnt <= poweron_wait_cnt + 1;
            end
        end else begin
            poweron_wait_cnt <= 16'b0;
        end
    end
end

//auto refresh control
always @ ( negedge reset_l or posedge clk ) begin
    if(reset_l == 1'b0) begin
        auto_refresh_cnt <= 16'b0;
        auto_refresh <= 1'b0;
    end else begin
        if(auto_refresh == 1'b0) begin
            auto_refresh_cnt <= auto_refresh_cnt + 1;
        end else begin
            auto_refresh_cnt <= 16'b0;
        end
        if(auto_refresh_cnt >= AUTO_REFRESH_CYCLE) begin
            auto_refresh <= 1'b1;
        end else if(CUR_STATE == stat_refresh) begin
            auto_refresh <= 1'b0;
        end
    end
end

//status running control
always @ ( negedge reset_l or posedge clk ) begin
    if(reset_l == 1'b0) begin
        status_running_cnt <= 4'b0;
    end else begin
        if(precharge_done || refresh_done || mrs_done || active_row_done || read_done || write_done) begin
            status_running_cnt <= 4'b0;
        end else if(CUR_STATE == stat_precharge || CUR_STATE == stat_refresh || CUR_STATE == stat_mrs
        || CUR_STATE == stat_active_row || CUR_STATE == stat_read || CUR_STATE == stat_write) begin
            status_running_cnt <= status_running_cnt + 4'b1;
        end else begin
            status_running_cnt <= 4'b0;
        end
    end
end

//other status control
always @ ( negedge reset_l or posedge clk ) begin
    if(reset_l == 1'b0) begin
        sdram_cmd <= {4{1'b1}};
        zs_ba <= {BANK_ADDR_WIDTH{1'b0}};
        zs_addr <= {CHIP_ADDR_WIDTH{1'b0}};
        zs_dqm <= 2'b0;
        zs_dq_o_en <= 1'b0;
        zs_dq_o <= {DATA_WIDTH{1'b0}};

        init_ok <= 1'b0;
        precharge_done <= 1'b0;
        refresh_done <= 1'b0;
        mrs_done <= 1'b0;
        active_row_done <= 1'b0;
        read_done <= 1'b0;
        write_done <= 1'b0;

        sdram_data_r_en <= 1'b0;
        sdram_data_r <= {DATA_WIDTH{1'b0}};
    end else begin
        precharge_done <= 1'b0;
        refresh_done <= 1'b0;
        mrs_done <= 1'b0;
        active_row_done <= 1'b0;
        read_done <= 1'b0;
        write_done <= 1'b0;
        zs_ba <= sdram_addr[ROW_WIDTH+COL_WIDTH+BANK_ADDR_WIDTH-1:ROW_WIDTH+COL_WIDTH];
        zs_dq_o_en <= 1'b0;
        sdram_data_r_en <= 1'b0;
        case (CUR_STATE)
            stat_precharge :    begin
                sdram_cmd <= 4'b0010;
                zs_addr[10] <= 1'b1;
                precharge_done <= 1'b1;
            end
            stat_refresh :  begin
                if(status_running_cnt == 4'b0) begin
                    sdram_cmd <= 4'b0001;
                end else begin
                    sdram_cmd <= 4'b0111;//none operating mode
                end
                if(status_running_cnt >= 4'd8) begin
                    refresh_done <= 1'b1;
                end
            end
            stat_mrs :  begin
                if(status_running_cnt == 4'b0) begin
                    sdram_cmd <= 4'b0000;
                    zs_addr <= {{3{1'b0}},1'b0,2'b00,CAS_LATENCY,4'h0};
                end else begin
                    sdram_cmd <= 4'b0111;//none operating mode
                end
                if(status_running_cnt >= 4'd3) begin
                    mrs_done <= 1'b1;
                    init_ok <= 1'b1;
                end
            end
            stat_active_row :   begin
                sdram_cmd <= 4'b0011;
                zs_addr <= sdram_addr[ROW_WIDTH+COL_WIDTH-1:COL_WIDTH];
                active_row_done <= 1'b1;
            end
            stat_read : begin
                if(status_running_cnt == 4'd0) begin
                    sdram_cmd <= 4'b0101;
                    zs_addr <= sdram_addr[COL_WIDTH-1:0];
                end
                if(status_running_cnt == 4'd3) begin
                    read_done <= 1'b1;
                    sdram_data_r_en <= 1'b1;
                    sdram_data_r <= zs_dq_i;
                end
            end
            stat_write :    begin
                zs_dq_o_en <= 1'b1;
                if(status_running_cnt == 4'd0) begin
                    sdram_cmd <= 4'b0100;
                    zs_addr <= sdram_addr[COL_WIDTH-1:0];
                    zs_dq_o <= sdram_data_w;
                end
                if(status_running_cnt == 4'd1) begin
                    write_done <= 1'b1;
                end
            end
            stat_idle : begin
                sdram_cmd <= 4'b1111; //command disable
                zs_addr <= {CHIP_ADDR_WIDTH{1'b0}};
            end
            default : ;
        endcase
    end
end

endmodule
