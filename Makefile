VERILATOR_DIR = /usr/share/verilator

SIM_OBJS = target/sim/main.o
VERILATED_OBJ = target/rtl/verilated.o
MODEL_AR = target/rtl/Vrevolve__ALL.a

VERILATOR = verilator
VERILATOR_FLAGS = -O3 -Irtl -CFLAGS "-O3"

CXX = g++
CXX_FLAGS = -O3
CXX_INC = -I$(VERILATOR_DIR)/include -I$(VERILATOR_DIR)/include/vltstd -I./target/rtl

.PHONY: all sim build module module_dir driver driver_dir clean rebuild

all: build sim

sim:
	@echo [BUILD] Running simulation
	target/sim/sim

build: module driver

module: module_dir $(MODEL_AR)

module_dir:
	@echo [BUILD] Building RTL
	@mkdir -p target/rtl

$(MODEL_AR): target/rtl/Vrevolve.mk
	cd target/rtl && make -f Vrevolve.mk && cd ../..

target/rtl/Vrevolve.mk: rtl/*.sv
	$(VERILATOR) $(VERILATOR_FLAGS) -cc -Mdir target/rtl rtl/revolve.sv

driver: driver_dir target/sim/sim

driver_dir:
	@echo [BUILD] Building C++ driver
	@mkdir -p target/sim

target/sim/sim: $(SIM_OBJS) $(VERILATED_OBJ) $(MODEL_AR)
	$(CXX) $(CXX_FLAGS) -o $@ $^

$(VERILATED_OBJ): $(VERILATOR_DIR)/include/verilated.cpp
	$(CXX) $(CXX_FLAGS) -c $(CXX_INC) -o $@ $<

target/sim/%.o: sim/%.cc target/rtl/Vrevolve.h
	$(CXX) $(CXX_FLAGS) -c $(CXX_INC) -o $@ $<

clean:
	@echo [BUILD] Cleaning all
	rm -rf target

rebuild: clean build

