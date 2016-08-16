CFLAGS = -Wno-undefined-bool-conversion

all:
	verilator -cc top.v --trace --exe ../main.cpp -CFLAGS "$(CFLAGS)"
	make -C obj_dir -f Vtop.mk

clean:
	rm -rf obj_dir data.vcd
