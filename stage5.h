#include "systemc.h"
#include "AD.h"
#include "crossbar.h"
#include "config.h"
#include <fstream>
#include <sstream>
#include <string>
#include <time.h>

using namespace std;

SC_MODULE(stage5)
{
	sc_in<float> input[CROSSBAR_L*8/DA_WIDTH];//crossbar输入
	sc_out<float> out[CROSSBAR_W*8/DA_WIDTH];//计算+AD处理后输出
	sc_in<bool> clk;
	sc_in<int> i5;
	sc_out<int> i6;

	void run()
	{
		//wait(300, SC_NS);
		clock_t start, end;
		float** tmp_v = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp_v[i] = new float[CROSSBAR_L];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_L; j ++)
				tmp_v[i][j] = input[i*CROSSBAR_L+j].read();
		}
		//cout << "stage5 input test: " << tmp_v[7][1151] << endl;

		//crossbar GPU compute
		
		CROSSBAR cb;
		float* cell = new float[CROSSBAR_W*CROSSBAR_L];
		float** out_i_tmp = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			out_i_tmp[i] = new float[CROSSBAR_W];
		//权重读入
		ifstream inFile("./weight/xb1.csv", ios::in);
		string lineStr;
		int C = 0;
		while (getline(inFile, lineStr))
		{
			//cout<<lineStr<<endl;
			stringstream ss(lineStr);
			string str;
			int c = 0;
			while (getline(ss, str, ','))
			{
				istringstream iss(str);
				float num;
				iss >> num;
				cell[C+CROSSBAR_L*c] = num;
				c ++;
			}
			C ++;
		}

		//cout << cell[1152*128-1] << endl;
		start = clock();
		
		cb.init(cell, CROSSBAR_L, CROSSBAR_W);
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			cb.run(tmp_v[i], out_i_tmp[i]);
		}
		end = clock();
		cb.free_space();
		//cout << "crossbar out test: " << out_i_tmp[0][0] << endl;

		/*ofstream out_y;
		out_y.open("y_xb2_me.csv", ios::out);
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				if (j < CROSSBAR_W - 1)
					out_y << out_i_tmp[i][j] << ",";
				if (j == CROSSBAR_W-1)
					out_y << out_i_tmp[i][j] << endl;
			}
		}
		out_y.close();*/
		
		ad adc(AD_V);
		float* tmp_ad = new float[CROSSBAR_W*8/DA_WIDTH];//记录ad输出
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			//wait(10, SC_NS);
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				//ad处理
				adc.trans(out_i_tmp[i][j]);
				tmp_ad[j+i*CROSSBAR_W] = adc.AD_out / XB2_I;
				tmp_ad[j+i*CROSSBAR_W] = (tmp_ad[j+i*CROSSBAR_W] > 0)?floor(tmp_ad[j+i*CROSSBAR_W] + 0.5):ceil(tmp_ad[j+i*CROSSBAR_W] - 0.5);
				out[j+i*CROSSBAR_W].write(tmp_ad[j+i*CROSSBAR_W]);
				//cout << tmp[i] << endl;
			}
		}

		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			delete[] tmp_v[i];
			delete[] out_i_tmp[i];
		}
		delete[] tmp_v;
		delete[] out_i_tmp;
		delete[] tmp_ad;
		delete[] cell;
		i6.write(i5.read());
	}

	SC_CTOR(stage5)
  	{
    	SC_METHOD(run);
		sensitive << i5;
		dont_initialize();
  	}
};