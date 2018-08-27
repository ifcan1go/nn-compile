#include "systemc.h"
#include "string.h"
#include "sim.h"
#include "numgen.h"
#include "stage1.h"
#include "stage2.h"
#include "stage3.h"
#include "stage4.h"
#include "stage5.h"
#include "stage6.h"
#include "display.h"
#include "config.h"

using namespace std;

int sc_main(int, char *[])
{
	sc_signal<bool>   clk;
	sc_signal<int> Count;
	sc_signal<float> in_data[INPUT_SIZE];
	sc_signal<float> da_res[CROSSBAR_L*(8/DA_WIDTH)];
	sc_signal<float> out_data0[CROSSBAR_W*(8/DA_WIDTH)];
	sc_signal<float> out_data1[CROSSBAR_W*(8/DA_WIDTH)];
	sc_signal<float> res1[2*CROSSBAR_W];
	sc_signal<float> da_res2[CROSSBAR_L*(8/DA_WIDTH)];
	sc_signal<float> out_data2[CROSSBAR_W*(8/DA_WIDTH)];
	sc_signal<float> res2[CROSSBAR_W];
	sc_signal<float> da_res3[CROSSBAR_L*(8/DA_WIDTH)];
	sc_signal<float> out_data3[CROSSBAR_W*(8/DA_WIDTH)];
	sc_signal<int> res;
	sc_signal<int> i;
	sc_signal<int> i1;
	sc_signal<int> i2;
	sc_signal<int> i3;
	sc_signal<int> i4;
	sc_signal<int> i5;
	sc_signal<int> i6;
	sc_signal<int> i7;


		sim S("sim");
		S.clk(clk);
		S.i(i);

		numgen N("numgen");
		for (int i = 0; i < INPUT_SIZE; i ++)
			N.out[i](in_data[i]);
		N.clk(clk);
		N.i(i);
		N.i1(i1);
	
		stage1 S1("stage1");
		for (int i = 0; i < INPUT_SIZE; i ++)
			S1.in_data[i](in_data[i]);
		for (int i = 0; i < CROSSBAR_L*(8/DA_WIDTH); i ++)
			S1.da_res[i](da_res[i]);
		S1.clk(clk);
		S1.i1(i1);
		S1.i2(i2);

		stage2 S2("stage2");
		for (int i = 0; i < CROSSBAR_L*(8/DA_WIDTH); i ++)
			S2.input[i](da_res[i]);
		for (int i = 0; i < CROSSBAR_W*(8/DA_WIDTH); i ++)
			S2.out0[i](out_data0[i]);

		S2.clk(clk);
		S2.i2(i2);
		S2.i3(i3);

		stage3 S3("stage3");
		for (int i = 0; i < CROSSBAR_W*(8/DA_WIDTH); i ++)
			S3.num0[i](out_data0[i]);

		for (int i = 0; i < 2*CROSSBAR_W; i ++)
			S3.res[i](res1[i]);
		S3.clk(clk);
		S3.i3(i3);
		S3.i4(i4);

		stage4 S4("stage4");
		for (int i = 0; i < 2*CROSSBAR_W; i ++)
			S4.in_data[i](res1[i]);
		for (int i = 0; i < CROSSBAR_L*(8/DA_WIDTH); i ++)
			S4.da_res[i](da_res2[i]);
		S4.clk(clk);
		S4.i4(i4);
		S4.i5(i5);

		stage5 S5("stage5");
		for (int i = 0; i < CROSSBAR_L*(8/DA_WIDTH); i ++)
			S5.input[i](da_res2[i]);
		for (int i = 0; i < CROSSBAR_W*(8/DA_WIDTH); i ++)
			S5.out[i](out_data2[i]);
		S5.clk(clk);
		S5.i5(i5);
		S5.i6(i6);


		stage6 S6("stage6");
		for (int i = 0; i < CROSSBAR_W*(8/DA_WIDTH); i ++)
			S6.num[i](out_data2[i]);
		S6.res(res);
		S6.clk(clk);
		S6.i6(i6);
		S6.i7(i7);

		display D("display");
		D.clk(clk);
		D.res(res);
		D.i7(i7);
		
	sc_trace_file* Tf;
	Tf = sc_create_vcd_trace_file("traces");
	sc_trace(Tf, clk, "CLK");
	sc_trace(Tf, i, "I");
	sc_trace(Tf, res, "RES");

	sc_start(400, SC_NS);               //Initialize simulation

  	for(int i = 0; i < 10; i++)
  	{
    	clk.write(1);
    	sc_start( 400, SC_NS );
    	clk.write(0);
    	sc_start( 400, SC_NS );
  	}
	
	sc_close_vcd_trace_file(Tf);

	return 0;
}