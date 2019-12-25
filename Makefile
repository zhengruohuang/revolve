VERILATOR = verilator
CXX = g++

VERILATOR_FLAGS = -O3
CXX_FLAGS = -O3

VERILATOR_DIR = /usr/share/verilator

SIM_OBJS = target/sim/main.o
VERILATOR_OBJ = target/rtl/verilated.o

.PHONY: all clean

all: sim
	@echo [BUILD] Running simulation
	target/sim/sim

sim: module driver

module: module_dir target/rtl/Vrevolve__ALL.a

module_dir:
	@echo [BUILD] Building RTL
	@mkdir -p target/rtl

target/rtl/Vrevolve__ALL.a: target/rtl/Vrevolve.mk
	cd target/rtl && make -f Vrevolve.mk && cd ../..

target/rtl/Vrevolve.mk: rtl/*.v
	$(VERILATOR) $(VERILATOR_FLAGS) -cc -Mdir target/rtl rtl/*.v

driver: driver_dir target/sim/sim

driver_dir:
	@echo [BUILD] Building C++ driver
	@mkdir -p target/sim

target/sim/sim: $(SIM_OBJS) $(VERILATOR_OBJ) target/rtl/Vrevolve__ALL.a
	$(CXX) $(CXX_FLAGS) -o $@ $^

$(VERILATOR_OBJ): $(VERILATOR_DIR)/include/verilated.cpp
	$(CXX) $(CXX_FLAGS) -c -I$(VERILATOR_DIR)/include -I./target/rtl -o $@ $<

target/sim/%.o: sim/%.cc
	$(CXX) $(CXX_FLAGS) -c -I$(VERILATOR_DIR)/include -I./target/rtl -o $@ $<

clean:
	@echo [BUILD] Cleaning all
	rm -rf target

