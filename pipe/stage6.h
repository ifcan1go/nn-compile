#include "systemc.h"
#include "DA.h"
#include "reg1.h"
#include "config.h"
#include <vector>

SC_MODULE(stage6)
{
	sc_in<float> num[CROSSBAR_W*8/DA_WIDTH];//ad输出
	sc_out<int> res;
	sc_in<bool> clk;
	sc_in<int> i6;
	sc_out<int> i7;

	void add()//测试用，假设为shiftadd步骤
	{
		//wait(600, SC_NS);
		float** tmp = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp[i] = new float[CROSSBAR_W];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp[i][j] = num[i*CROSSBAR_W+j].read();
			}
		}
		//cout << "stage9 input test: " << tmp[0][0] << endl;
		float* tmp_res = new float[CROSSBAR_W];
		for (int i = 0; i < CROSSBAR_W; i ++)
			tmp_res[i] = 0;
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			for (int j = 0; j < 8/DA_WIDTH; j ++)
			{
				tmp_res[i] = tmp[j][i] + 2*tmp_res[i];
			}
			tmp_res[i] = (tmp_res[i] > 0) ? tmp_res[i] : 0;
		}
		float max = 0;
		int index = 0;
		for (int i = 0; i < 10; i ++)
		{
			if (tmp_res[i] > max)
			{
				max = tmp_res[i];
				index = i;
			}
		}
		res.write(index);
		i7.write(i6.read());
		//wait(10, SC_NS);
		//for (int i = 0; i < 10; i ++)
		//	cout << tmp_res[i]<<",";
		//cout<<endl;
		//cout << "stage9 output test: " << res << endl;
		ofstream y;
		y.open("y.csv", ios::app);
		y << res << endl;
		y.close();
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			delete[] tmp[i];
		}
		delete[] tmp;
		delete[] tmp_res;
	}
	SC_CTOR(stage6)
  	{
    	SC_METHOD(add);
		sensitive << i6;
		dont_initialize();
  	}

};