#include <iostream>
#include <verilated.h>
#include <Vrevolve.h>


Vrevolve *top = nullptr;


int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    top = new Vrevolve;
    
    // Load program
    
    // Load firmware
    
    // Reset
    top->clk = 0;
    top->rst_n = 0;
    top->eval();
    top->rst_n = 1;
    top->eval();
    
    // Go
    while (!Verilated::gotFinish()) {
        top->clk = !top->clk;
        top->eval();
    }
}

