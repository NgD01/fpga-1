// Listing 11.1, from Pong Chu's "FPGA Prototyping Using Verilog Examples"

module SramCtrl (
    input wire clk, reset,
    // to/from main system
    input wire sram_req, sram_rh_wl,
    input wire [ADDR_WIDTH-1:0] sram_addr,
    input wire [DATA_WIDTH-1:0] sram_data_w,
    output reg sram_data_r_en,
    output wire [DATA_WIDTH-1:0] sram_data_r, sram_data_ur,
    // to/from sram chip
    output wire [ADDR_WIDTH-1:0] zs_addr,
    output wire zs_cs_n, zs_we_n, zs_oe_n,
    inout wire [DATA_WIDTH-1:0] zs_dq
);

parameter ADDR_WIDTH  = 19;
parameter DATA_WIDTH  = 8;

// symbolic state declaration
localparam [2:0] idle = 3'b000,
                 rd1  = 3'b001,
                 rd2  = 3'b010,
                 wr1  = 3'b011,
                 wr2  = 3'b100;

// signal declaration
reg [2:0] state_reg, state_next;
reg [DATA_WIDTH-1:0] data_w_reg, data_w_next, data_r_reg, data_r_next;
reg [ADDR_WIDTH-1:0] addr_reg, addr_next;
reg we_buf, oe_buf, tri_buf;
reg we_reg, oe_reg, tri_reg;

// FSMD state & data registers
always @(posedge clk, posedge reset)
    if (reset) begin
        state_reg <= idle;
        addr_reg <= 0;
        data_w_reg <= 0;
        data_r_reg <= 0;
        tri_reg <= 1'b1;
        we_reg <= 1'b1;
        oe_reg <= 1'b1;
    end else begin
        state_reg <= state_next;
        addr_reg <= addr_next;
        data_w_reg <= data_w_next;
        data_r_reg <= data_r_next;
        tri_reg <= tri_buf;
        we_reg <= we_buf;
        oe_reg <= oe_buf;
    end

// FSMD next-state logic
always @* begin
    addr_next = addr_reg;
    data_w_next = data_w_reg;
    data_r_next = data_r_reg;
    sram_data_r_en = 1'b0;
    case (state_reg)
        idle: begin
            if (sram_req)
                state_next = idle;
            else begin
                addr_next = sram_addr;
                if (~sram_rh_wl) begin  // write
                    state_next = wr1;
                    data_w_next = sram_data_w;
                end else  // read
                   state_next = rd1;
            end
            sram_data_r_en = 1'b1;
        end
        wr1:
           state_next = wr2;
        wr2:
           state_next = idle;
        rd1:
           state_next = rd2;
        rd2: begin
            data_r_next = zs_dq;
            state_next = idle;
        end
        default:
           state_next = idle;
    endcase
end

// look-ahead output logic
always @* begin
    tri_buf = 1'b1;  // signals are active low
    we_buf = 1'b1;
    oe_buf = 1'b1;
    case (state_next)
        idle:
            oe_buf = 1'b1;
        wr1: begin
            tri_buf = 1'b0;
            we_buf = 1'b0;
        end
        wr2:
            tri_buf = 1'b0;
        rd1:
            oe_buf = 1'b0;
        rd2:
            oe_buf = 1'b0;
    endcase
end

// to main system
assign sram_data_r = data_r_reg;
assign sram_data_ur = zs_dq;
// to sram
assign zs_we_n = we_reg;
assign zs_oe_n = oe_reg;
assign zs_addr = addr_reg;
// i/o for sram chip
assign zs_cs_n = 1'b0;
assign zs_dq = (~tri_reg) ? data_w_reg : 16'bz;

endmodule
