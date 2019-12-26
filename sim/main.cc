#include <iostream>
#include <cstdint>
#include <verilated.h>

#include "Vrevolve.h"
#include "Vrevolve_revolve.h"
#include "Vrevolve_instr_fetch2.h"
#include "Vrevolve_instr_cache_data.h"


Vrevolve *top = nullptr;
uint64_t cycles = 0;


static void reset()
{
    top->i_clk = 0;
    top->i_rst_n = 0;
    top->eval();
    top->i_rst_n = 1;
    top->eval();
}

static void simulate()
{
    while (!Verilated::gotFinish()) {
        std::cout << "[Cycle " << cycles << "] "
            << "Paddr @ " << std::hex << top->revolve->if2->icache_data->i_paddr << std::dec << std::endl;
        
        top->i_clk = 1;
        top->eval();
        top->i_clk = 0;
        top->eval();
        
        cycles++;
    }
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    top = new Vrevolve;
    
    // Load program
    
    // Load firmware
    
    // Reset
    reset();
    
    // Go
    simulate();
}

