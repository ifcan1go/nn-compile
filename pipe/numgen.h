#include "config.h"
#include <fstream>
#include <sstream>
#include <string>

using namespace std;

SC_MODULE(numgen) {
    sc_out<float> out[INPUT_SIZE];      //output
    sc_in<bool>    clk;       //clock
	sc_in<int> i;
	sc_out<int> i1;

    // method to write values to the output ports
    void generate()
    {
		int k = i.read();
		cout << "picture number: " <<k-1 << endl;
		char filename[30]={0};
		char num[5]={0};
		strcpy(filename,"./x/");
		itoa(k-1,num,10);
		strcat(filename,num);
		strcat(filename,".csv");
		ifstream inFile_x(filename, ios::in);
		string lineStr_x;
		getline(inFile_x, lineStr_x);
		stringstream ss(lineStr_x);
		string str;
		int c = 0;
		for (int ii = 0; ii < 368; ii ++)
			out[ii].write(0);
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			out[368+c].write(num);
			c ++;
		}
		i1.write(i.read());
		//wait(10, SC_NS);
		//cout << out[1109] << endl;
		
    }
    
    //Constructor
    SC_CTOR( numgen ) {
      SC_METHOD( generate );   
      sensitive << i;
	  dont_initialize();
    }
};