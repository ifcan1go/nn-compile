#include "systemc.h"
#include "DA.h"
#include "reg1.h"
#include <algorithm>
#include <vector>

SC_MODULE(stage3)
{
	sc_in<float> num0[CROSSBAR_W*8/DA_WIDTH];//ad ‰≥ˆ

	sc_out<float> res[2*CROSSBAR_W];
	sc_in<bool> clk;
	sc_in<int> i3;
	sc_out<int> i4;

	void add()//shiftadd≤Ω÷Ë
	{
		//wait(200, SC_NS);
		float** tmp0 = new float*[8/DA_WIDTH];

		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			tmp0[i] = new float[CROSSBAR_W];

		}
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp0[i][j] = num0[i*CROSSBAR_W+j].read();

			}
		}
		//cout << "stage3 input test: " << tmp0[0][0] << endl;

		float* tmp_res0 = new float[CROSSBAR_W];

		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			tmp_res0[i] = 0;

		}
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			//wait(10, SC_NS);
			for (int j = 0; j < 8/DA_WIDTH; j ++)
			{
				tmp_res0[i] = tmp0[j][i] + 2*tmp_res0[i];

			}
			tmp_res0[i] = (tmp_res0[i] > 0) ? tmp_res0[i] : 0;

			//cout <<"stage3:out" <<tmp_res0[i] << endl;

			res[i].write(tmp_res0[i]);

		}
		//wait(10, SC_NS);

		/*ofstream out0;
		out0.open("y0_shift.csv", ios::out);
		for (int j = 0; j < CROSSBAR_W; j ++)
		{
			if (j < CROSSBAR_W - 1)
				out0 << res[j] << ",";
			if (j == CROSSBAR_W-1)
				out0 << res[j] << endl;
		}
		out0.close();

		ofstream out1;
		out1.open("y1_shift.csv", ios::out);
		for (int j = 0; j < CROSSBAR_W; j ++)
		{
			if (j < CROSSBAR_W - 1)
				out1 << res[j+CROSSBAR_W] << ",";
			if (j == CROSSBAR_W-1)
				out1 << res[j+CROSSBAR_W] << endl;
		}
		out1.close();*/
		//cout << "stage3 output test: " << res[18] << endl;
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			delete[] tmp0[i];

		}
		delete[] tmp0;

		delete[] tmp_res0;

		i4.write(i3.read());
	}
	SC_CTOR(stage3)
  	{
    	SC_METHOD(add);
		sensitive << i3;
		dont_initialize();
  	}

};