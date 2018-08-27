#include "systemc.h"
#include "DA.h"
#include "config.h"
#include "math.h"
#include <fstream>
#include <iostream>

SC_MODULE(stage1)
{
    sc_in<float> in_data[INPUT_SIZE];//数据输入,可在numgen.h内改动输入
    sc_out<float> da_res[CROSSBAR_L*(8/DA_WIDTH)]; //da输出 数组大小为8*size
    sc_in<bool> clk;
	sc_in<int> i1;
	sc_out<int> i2;
	
    void generate()
    {
		
		int bitnum;
		int* data = new int[INPUT_SIZE];
		int p=0;
		da dac(DA_V);
		int m = 0;//用作移位
		for (int i = 0; i < DA_WIDTH; i ++)
			m += int(pow(2, double(i)));

		for (int i = 0; i < INPUT_SIZE; i ++)
		{
			data[i] = int(in_data[i].read());
		}

		//cout << "stage1 input test 1108: " << in_data[1052].read() << endl;

		for (int j = 8/DA_WIDTH-1; j >= 0; j--)
		{			
			for (int i = 0; i < INPUT_SIZE; i ++)
			{
				bitnum = static_cast<int>(data[i] & m);
				dac.trans(bitnum, DA_WIDTH);
				//p += 3.6;
				da_res[i+j*INPUT_SIZE].write(bitnum);
				data[i] >>= 1;
			}
		}
		//cout << "stage1 output test: " << da_res[1108] << endl;
		i2.write(i1.read());
		delete[] data;
		/*ofstream out_da;
		out_da.open("da.csv", ios::out);
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_L; j ++)
			{
				if (j < CROSSBAR_L - 1)
					out_da << da_res[j+CROSSBAR_L*i] << ",";
				if (j == CROSSBAR_L-1)
					out_da << da_res[j+CROSSBAR_L*i] << endl;
			}
		}
		out_da.close();*/

    }

    SC_CTOR(stage1)
    {
        SC_METHOD(generate);
		sensitive << i1;
        dont_initialize();
    }
};