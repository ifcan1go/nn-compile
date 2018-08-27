#include "systemc.h"
#include "AD.h"
#include "crossbar.h"
#include "config.h"
#include <fstream>
#include <sstream>
#include <string>
#include <time.h>

using namespace std;

SC_MODULE(stage2)
{
	sc_in<float> input[CROSSBAR_L*(8/DA_WIDTH)];//crossbar输入
	sc_out<float> out0[CROSSBAR_W*8/DA_WIDTH];//计算+AD处理后输出

	sc_in<bool> clk;
	sc_in<int> i2;
	sc_out<int> i3;

	CROSSBAR cb0;

	void InitCb0()		//权重读入
	{
		float* cell0 = new float[CROSSBAR_W*CROSSBAR_L];
		ifstream inFile0("./weight/xb0.csv", ios::in);
		string lineStr0;
		int C = 0;
		while (getline(inFile0, lineStr0))
		{
			stringstream ss(lineStr0);
			string str;
			int c = 0;
			while (getline(ss, str, ','))
			{
				istringstream iss(str);
				float num;
				iss >> num;
				cell0[C+CROSSBAR_L*c] = num;
				c ++;
			}
			C ++;
		}
		inFile0.close();		
		cb0.init(cell0, CROSSBAR_L, CROSSBAR_W);	
		delete[] cell0;
	}

	void run()
	{
		clock_t start, end;
		float** tmp_v = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp_v[i] = new float[CROSSBAR_L];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_L; j ++)
				tmp_v[i][j] = input[i*CROSSBAR_L+j].read();
		}		

		float** out_i_tmp0 = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			out_i_tmp0[i] = new float[CROSSBAR_W];
			
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			cb0.run(tmp_v[i], out_i_tmp0[i]);
		}
		
///////////////////////////////////////////////////////////////////////


		ad adc0(AD_V);

		float* tmp_ad0 = new float[CROSSBAR_W*8/DA_WIDTH];//记录ad输出

		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				//ad处理
				adc0.trans(out_i_tmp0[i][j]);
				tmp_ad0[j+i*CROSSBAR_W] = adc0.AD_out / XB01_I;


				tmp_ad0[j+i*CROSSBAR_W] = (tmp_ad0[j+i*CROSSBAR_W] > 0)?floor(tmp_ad0[j+i*CROSSBAR_W] + 0.5):ceil(tmp_ad0[j+i*CROSSBAR_W] - 0.5);


				out0[j+i*CROSSBAR_W].write(tmp_ad0[j+i*CROSSBAR_W]);

				//cout << tmp[i] << endl;
			}
		}


		//cout << "stage2 output test: " <<out_i_tmp0[0][0]<<","<<tmp_ad0[0]<<","<<out0[0] << endl;
		//cout << "compute time: " << (double)(end - start) / CLOCKS_PER_SEC << endl;
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			delete[] tmp_v[i];
			delete[] out_i_tmp0[i];

		}
		delete[] tmp_v;
		delete[] out_i_tmp0;

		delete[] tmp_ad0;

		//delete[] cell0;
		//delete[] cell1;
		i3.write(i2.read());
	}

	SC_CTOR(stage2)
  	{
		InitCb0();


    	SC_METHOD(run);
		sensitive << i2;
		dont_initialize();
  	}

	~stage2()
	{
		cb0.free_space();  		

	}
};