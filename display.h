#include "config.h"
#include <fstream>
#include <sstream>
#include <string>

using namespace std;

SC_MODULE(display) {
    sc_in<bool>    clk;       //clock
	sc_in<int> res;
	sc_in<int> i7;

    // method to write values to the output ports
    void print()
    {
		//wait(650, SC_NS);
		cout << "result: " << res.read() << endl;
		

			//cout << i << endl;
    }
    
    //Constructor
    SC_CTOR( display ) {
      SC_METHOD( print );   
      sensitive << i7;
	  dont_initialize();
    }
};