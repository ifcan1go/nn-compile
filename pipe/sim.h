#include "config.h"
#include <fstream>
#include <sstream>
#include <string>

using namespace std;

SC_MODULE(sim) {
    sc_in<bool>    clk;       //clock
	sc_out<int> i;

    // method to write values to the output ports
    void generate()
    {
		static int a = 1;
		while(a <= 1000)
		{
			i.write(a);
			wait(10, SC_NS);
			a += 1;
		}
    }
    
    //Constructor
    SC_CTOR( sim ) {
      SC_THREAD( generate );   
      sensitive << clk.pos();	       
    }
};