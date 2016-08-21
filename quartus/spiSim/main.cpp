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


    while (simTime <= 150 && !Verilated::gotFinish()) {
        dut.clk = !dut.clk;

        switch (simTime) {
          case  4: dut.data_in = 0xB5; break;
          case  5: dut.wr = 1; break;
          case  6: dut.wr = 0; break;
          case 48: dut.data_in = 0xF1; break;
          case 49: dut.wr = 1; break;
        }

        // if ((simTime & 2) == 0) dut.miso = (simTime & 4) != 0;
        dut.miso = dut.mosi;

        dut.eval();
        tfp.dump(simTime);
        simTime += 1;
    }

    tfp.close();
    return 0;
}
