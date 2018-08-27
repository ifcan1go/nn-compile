#include "systemc.h"
#include "DA.h"
#include "config.h"
#include "math.h"
#include <fstream>
#include <iostream>

SC_MODULE(stage4)
{
    sc_in<float> in_data[2*CROSSBAR_W];
    sc_out<float> da_res[CROSSBAR_L*(8/DA_WIDTH)]; //da输出 数组大小为8*size
    sc_in<bool> clk;
	sc_in<int> i4;
	sc_out<int> i5;
	
    void generate()
    {
		//wait(250, SC_NS);
		int bitnum;
		int* data = new int[CROSSBAR_L];
		da dac(DA_V);
		int m = 0;//用作移位
		for (int i = 0; i < DA_WIDTH; i ++)
			m += int(pow(2, double(i)));
		for (int i = 0; i < CROSSBAR_L-CROSSBAR_W; i ++)
			data[i] = 0;
		for (int i = 0; i < 100; i ++)
		{
			data[CROSSBAR_L-100+i] = int(in_data[i].read());
		}
		//cout << "stage4 input:"<<data[1152-128] << endl;
		int high = 0;
		int max = INT_MIN;
		int max_index = 0;
		for (int i = 0; i < CROSSBAR_L; i ++)
		{
			if (data[i] > max)
			{
				max = data[i];
				max_index = i;
			}
		}
		//cout << max_index << endl;
		//cout << data[max_index] << endl;
		for (int i = 31; i >= 0; i --)
		{
			int m = (data[max_index] >> i) & 1;
			if (m == 1)
			{
				high = i+1;
				break;
			}
		}
		//cout << high << endl;
		for (int j = 8/DA_WIDTH-1; j >= 0; j--)
		{
			//wait(10, SC_NS);
			int move = 8/DA_WIDTH-1-j;
			for (int i = 0; i < INPUT_SIZE; i ++)
			{
				bitnum = static_cast<int>((data[i] >> (high - 8 + move)) & m);
				dac.trans(bitnum, DA_WIDTH);
				da_res[i+j*INPUT_SIZE].write(bitnum);
			}
		}
		//wait(10, SC_NS);
		//cout << "stage4 output test: " << da_res[1152*8-1] << endl;
		delete[] data;
		i5.write(i4.read());
		/*ofstream out_da;
		out_da.open("da2.csv", ios::out);
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

    SC_CTOR(stage4)
    {
        SC_METHOD(generate);
		sensitive << i4;
        dont_initialize();
    }
};