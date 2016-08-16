#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

vluint64_t simTime;

double sc_time_stamp () { return simTime; }

int main (int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop dut;
    dut.eval();
    dut.eval();

    Verilated::traceEverOn(true);
    VerilatedVcdC tfp;
    dut.trace(&tfp, 99);
    tfp.open("data.vcd");

    dut.RdAddr = 0x12345;
    dut.WrAddr = 0x67890;
    dut.WrData = 0xABCD;

    while (simTime <= 100 && !Verilated::gotFinish()) {
        dut.clk = !dut.clk;

        switch (simTime) {
            case  5: dut.RdReq = 1; break;
            case 15: dut.RdReq = 0; break;
            case 25: dut.WrReq = 1; break;
            case 35: dut.WrReq = 0; break;
        }

        dut.eval();
        tfp.dump(simTime);
        ++simTime;
    }

    tfp.close();
    return 0;
}
