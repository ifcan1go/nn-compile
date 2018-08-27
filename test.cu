#include <iostream>
#include <cstring>
#include <fstream>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda.h>
#include <curand.h>
#include <time.h>
#include <iostream>

using namespace std;

__global__ void CUDA_add(float *a,float *b,float *c,int cols,int rows)
{

        int n_cell= blockIdx.x ;
        int row  = blockIdx.y ;
        int col = threadIdx.x;
        c[n_cell*rows*cols+row*cols+col]=a[n_cell*rows*cols+row*cols+col]+b[n_cell*rows*cols+row*cols+col];

}
__global__ void CUDA_mul(float *a,float b,float *c,int cols,int rows)
{

        int n_cell= blockIdx.x ;
        int row  = blockIdx.y ;
        int col = threadIdx.x;
        c[n_cell*rows*cols+row*cols+col]=a[n_cell*rows*cols+row*cols+col]*b;

}


__global__ void CUDA_mmul(float *a,float *b,float *c,int cols,int rows)
{

        int n_cell= blockIdx.x ;
        int row  = blockIdx.y ;
        int col = threadIdx.x;
        c[n_cell*rows*cols+row*cols+col]=a[n_cell*rows*cols+row*cols+col]*b[n_cell*rows*cols+row*cols+col];
}

__global__ void CUDA_shift(float *a,float b,float *c,int cols,int rows)
{

        int n_cell= blockIdx.x ;
        int row  = blockIdx.y ;
        int col = threadIdx.x;
        c[n_cell*rows*cols+row*cols+col]=a[n_cell*rows*cols+row*cols+col]+b;
}
__global__ void CUDA_MatrixMui(float *a,float *b,float *c,int cols,int rows)
{
    int n_cell= blockIdx.x ;
    int row  = blockIdx.y ;
    //int col = threadIdx.x;
    float temp = 0;
    for (int i=0;i<cols;i++)
    {
        temp+=a[n_cell*cols+i]*b[n_cell*rows*cols+row*cols+i];

    }

    c[n_cell*rows+row]=temp;
}

#define DA_V 1.0f			//DA参考电压
#define AD_V 1.0f			//AD参考电压
#define DA_WIDTH 1			//DA输入数据宽度
#define AD_WIDTH 8			//AD输出数据宽度
#define CROSSBAR_L 1152		//crossbar长度
#define CROSSBAR_W 128		//crossbar宽度
#define CROSSBAR_N 1		//crossbar个数
#define AD_REUSE_NUM 32		//AD复用
#define XB01_I 0.00492679327726364
#define XB2_I 0.00398490577936172
#define XB3_I 0.00257207546383142

#define INPUT_SIZE 1152			//输入8bit数据个数

using namespace std;

typedef struct Crossbar1
{
	float *std_d;
	int CB_l;
	int CB_w;
	float *CB_cell;
	void init(float *CB_cells, int l, int w)
	{
		CB_l=l;
		CB_w=w;
		CB_cell = new float[CB_l*CB_w];
		memcpy(CB_cell, CB_cells, CB_l*CB_w * sizeof(float));
	}

	void MatrixMul(float *input, float *CB_cells, float *output, int w, int l)
	{
		for (int i = 0; i < w; i ++)
		{
			float tmp = 0;
			for (int j = 0; j < l; j ++)
			{
				tmp += input[j] * CB_cells[i*l+j];
			}
			output[i] = tmp;
			//cout << output[i] << endl;
		}
	}
	
    void run(float *input, float *output)
    {
		float *output_d = new float[CB_w];
		float *input_d = new float[CB_l];
		memcpy(input_d, input, CB_l*sizeof(float));
		MatrixMul(input_d,CB_cell,output_d,CB_w,CB_l);
		memcpy(output, output_d, CB_w* sizeof(float));
    }

}CROSSBAR1;

typedef struct Crossbar
{
	float *CB_cell;
	float *std_d;
	int CB_n;
	int CB_l;
	int CB_w;
    curandGenerator_t gen;
	void init(float *CB_cells, int n, int l, int w)
	{
		CB_l=l;
		CB_w=w;
		CB_n=n;
		cudaMalloc((void **)&CB_cell, CB_n*CB_l*CB_w*sizeof(float));
		cudaMemcpy(CB_cell, CB_cells, CB_n*CB_l*CB_w * sizeof(float),cudaMemcpyHostToDevice);
		get_std();
		curandCreateGenerator(&gen, CURAND_RNG_PSEUDO_DEFAULT);
		clock_t time;
	    time=clock();
	    curandSetPseudoRandomGeneratorSeed(gen, (int)time);

	}
	void printcrossbar()
	{
		float *temp_cell;
		temp_cell = (float*)calloc(CB_n*CB_l*CB_w,sizeof(float));
		//temp_cell = new float [CB_n*CB_l*CB_w];
		cudaMemcpy(temp_cell, CB_cell, CB_n*CB_l*CB_w* sizeof(float),cudaMemcpyDeviceToHost) ;
		printf ("_______________\n");
		for (int i=0;i<CB_n;i++)
		{
			for (int j=0;j<CB_l;j++)
			{
				for(int k=0;k<CB_w;k++)
				{
					printf("%f,%d,%d,%d,%d ",temp_cell[i*CB_l*CB_w+j*CB_w+k],i,j,k,i*CB_l*CB_w+j*CB_w+k);

				}
				printf ("\n");
			}
			printf ("\n");
		}
        printf ("_______________\n");
	free(temp_cell);
	}
	void get_std()
	//-0.0006034 * (x * 1e3) ** 2 + 0.06184 * x + 0.7240 * 1e-6
	{
		dim3 numBlocks(CB_n, CB_l);
		cudaMalloc((void **)&std_d, CB_n*CB_l*CB_w*sizeof(float));
		float *temp_1;
		cudaMalloc((void **)&temp_1, CB_n*CB_l*CB_w*sizeof(float));
		cudaMemcpy(temp_1, CB_cell, CB_n*CB_l*CB_w* sizeof(float),cudaMemcpyDeviceToDevice) ;
		float *temp_2;
		cudaMalloc((void **)&temp_2, CB_n*CB_l*CB_w*sizeof(float));
		CUDA_mul<<<numBlocks,CB_l>>>(temp_1,1000,temp_2,CB_w,CB_l);
		cudaMemcpy(temp_1, temp_2, CB_n*CB_l*CB_w* sizeof(float),cudaMemcpyDeviceToDevice) ;
		float *temp_3;
		cudaMalloc((void **)&temp_3, CB_n*CB_l*CB_w*sizeof(float));
		CUDA_mmul<<<numBlocks,CB_w>>>(temp_1,temp_2,temp_3,CB_w,CB_l);
		CUDA_mul<<<numBlocks,CB_w>>>(temp_3,-0.0006034,temp_1,CB_w,CB_l);
		CUDA_mul<<<numBlocks,CB_w>>>(CB_cell,0.06184,temp_2,CB_w,CB_l);
		CUDA_add<<<numBlocks,CB_w>>>(temp_1,temp_2,temp_3,CB_w,CB_l);
		CUDA_shift<<<numBlocks,CB_w>>>(temp_3,0.7240*0.000001,temp_1,CB_w,CB_l);
		cudaMemcpy(std_d, temp_1, CB_n*CB_l*CB_w* sizeof(float),cudaMemcpyDeviceToDevice) ;
		cudaFree( temp_1 );
		cudaFree( temp_2 );
		cudaFree( temp_3 );
	}
	void get_noise(float *noise)
	{


	cudaMalloc((void **)&noise, CB_n*CB_l*CB_w*sizeof(float));
	curandGenerateNormal(gen, noise, CB_n*CB_l*CB_w, 0, 1);
    //printf("%f\n", &noise[1]);
	}

    void printstd()
    {
            printf ("~~~~~~~~~~~~~~~~~~~\n");
            float *temp_cell;
            temp_cell = (float*)calloc(CB_n*CB_l*CB_w,sizeof(float));
            cudaMemcpy(temp_cell, std_d, CB_n*CB_l*CB_w* sizeof(float),cudaMemcpyDeviceToHost) ;
            for (int i=0;i<CB_n;i++)
            {
                    for (int j=0;j<CB_l;j++)
                    {
                            for(int p=0;p<CB_w;p++)
                            {
                                    printf("%f ",temp_cell[i*CB_l*CB_w+j*CB_w+p]);
                            }
                            printf ("\n");
                    }
                    printf ("\n");
            }
            printf ("~~~~~~~~~~~~~~~~~~~\n");
    free(temp_cell);
    }
    void run(float *input, float *output, bool use_noise=true)
    {
    
    float *input_d,*output_d;
    cudaMalloc((void **)&input_d, CB_n*CB_w*sizeof(float));
    cudaMalloc((void **)&output_d, CB_n*CB_l*sizeof(float));
    cudaMemcpy(input_d, input, CB_n*CB_w * sizeof(float),cudaMemcpyHostToDevice);
    dim3 numBlocks(CB_n, CB_l);
    if (use_noise)
        {
        float *temp_noise,*temp_cell;
        cudaMalloc((void **)&temp_noise, CB_n*CB_w*CB_l*sizeof(float));
        cudaMalloc((void **)&temp_cell, CB_n*CB_w*CB_l*sizeof(float));
        get_noise(temp_noise);
        //printf("%f\n", &temp_noise[1]);
        CUDA_add<<<numBlocks,CB_w>>>(CB_cell,temp_noise,temp_cell,CB_w,CB_l);
        CUDA_MatrixMui<<<numBlocks,1>>>(input_d,temp_cell,output_d,CB_w,CB_l);
        //printf("%f\n", &CB_cell[1109]);
        }
    else
        {
        //printf("%f\n", &CB_cell[5000]);
        CUDA_MatrixMui<<<numBlocks,1>>>(input_d,CB_cell,output_d,CB_w,CB_l);
        }
    cudaMemcpy(output, output_d, CB_n*CB_l* sizeof(float),cudaMemcpyDeviceToHost) ;
    cudaFree( input_d );
	cudaFree( output_d );
    }

}CROSSBAR;

double gaussrand()
{
    static double V1, V2, S;
    static int phase = 0;
    double X;
    if ( phase == 0 ) {
        do {
            double U1 = (double)rand() / RAND_MAX;
            double U2 = (double)rand() / RAND_MAX;
            V1 = 2 * U1 - 1;
            V2 = 2 * U2 - 1;
            S = V1 * V1 + V2 * V2;
        } while(S >= 1 || S == 0);
        X = V1 * sqrt(-2 * log(S) / S);
    } else
    X = V2 * sqrt(-2 * log(S) / S);
    phase = 1 - phase;
    return X;

}

float get_noise(float x)
{
    float noise;
    x = fabsf(x);
    float random = 
    noise = -0.0006034 * (x * 1000) * (x * 1000) + 0.06184 * x + 0.948661*0.000001;
    noise = noise * gaussrand();
    return noise;
}

int main()
{	
	float out[INPUT_SIZE];
	float da_res[CROSSBAR_L*(8/DA_WIDTH)];
	float out_data0[CROSSBAR_W*(8/DA_WIDTH)];
	float out_data1[CROSSBAR_W*(8/DA_WIDTH)];
	float res1[2*CROSSBAR_W];

	float da_res2[CROSSBAR_L*(8/DA_WIDTH)];
	float out_data2[CROSSBAR_W*(8/DA_WIDTH)];
	float res2[CROSSBAR_W];
	float da_res3[CROSSBAR_L*(8/DA_WIDTH)];
	float out_data3[CROSSBAR_W*(8/DA_WIDTH)];
	int res;

	int m = 0;//用作移位
	for (int i = 0; i < DA_WIDTH; i ++)
		m += int(pow(2, double(i)));

	CROSSBAR cb0;
	float* cell0 = new float[CROSSBAR_W*CROSSBAR_L];
	float** out_i_tmp0 = new float*[8/DA_WIDTH];
	for (int i = 0; i < 8/DA_WIDTH; i ++)
		out_i_tmp0[i] = new float[CROSSBAR_W];
	//权重读入
	ifstream inFile0("./Desktop/xb_0.csv", ios::in);
	string lineStr0;
	int C = 0;
	while (getline(inFile0, lineStr0))
	{
		//cout<<lineStr<<endl;
		stringstream ss(lineStr0);
		string str;
		int c = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			cell0[C+CROSSBAR_L*c] = num + get_noise(num);
			c ++;
		}
		C ++;
	}

	CROSSBAR cb1;
	float* cell1 = new float[CROSSBAR_W*CROSSBAR_L];
	float** out_i_tmp1 = new float*[8/DA_WIDTH];
	for (int i = 0; i < 8/DA_WIDTH; i ++)
		out_i_tmp1[i] = new float[CROSSBAR_W];
	//权重读入
	ifstream inFile1("./Desktop/xb_1.csv", ios::in);
	string lineStr1;
	C = 0;
	while (getline(inFile1, lineStr1))
	{
		//cout<<lineStr<<endl;
		stringstream ss(lineStr1);
		string str;
		int c = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			cell1[C+CROSSBAR_L*c] = num + get_noise(num);
			c ++;
		}
		C ++;
	}

	CROSSBAR cb2;
	float* cell2 = new float[CROSSBAR_W*CROSSBAR_L];
 	float** out_i_tmp2 = new float*[8/DA_WIDTH];
	for (int i = 0; i < 8/DA_WIDTH; i ++)
		out_i_tmp2[i] = new float[CROSSBAR_W];
	//权重读入
	ifstream inFile2("./Desktop/xb_2.csv", ios::in);
	string lineStr2;
	C = 0;
	while (getline(inFile2, lineStr2))
	{
		//cout<<lineStr<<endl;
		stringstream ss(lineStr2);
		string str;
		int c = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			cell2[C+CROSSBAR_L*c] = num + get_noise(num);
			c ++;
		}
		C ++;
	}

	CROSSBAR cb3;
	float* cell3 = new float[CROSSBAR_W*CROSSBAR_L];
	float** out_i_tmp3 = new float*[8/DA_WIDTH];
	for (int i = 0; i < 8/DA_WIDTH; i ++)
		out_i_tmp3[i] = new float[CROSSBAR_W];
	//权重读入
	ifstream inFile3("./Desktop/xb_3.csv", ios::in);
	string lineStr3;
	C = 0;
	while (getline(inFile3, lineStr3))
	{
		//cout<<lineStr<<endl;
		stringstream ss(lineStr3);
		string str;
		int c = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			cell3[C+CROSSBAR_L*c] = num + get_noise(num);
			c ++;
		}
		C ++;
	}
	
	


	for (int k = 9774; k < 10000; k ++)
	{
		char filename[30]={0};
		char num[5]={0};
		strcpy(filename,"./x/");
		itoa(k,num,10);
		strcat(filename,num);
		strcat(filename,".csv");
		ifstream inFile_x(filename, ios::in);
		string lineStr_x;
		getline(inFile_x, lineStr_x);
		stringstream ss(lineStr_x);
		string str;
		int c = 0;
		for (int i = 0; i < 368; i ++)
			out[i] = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			out[368+c] = num;
			c ++;
		}
		inFile_x.close();
		//cout << "1: " << out[1108] << endl;
		int* data0 = new int[INPUT_SIZE];
		for (int i = 0; i < INPUT_SIZE; i ++)
			data0[i] = int(out[i]);
		int bitnum;
		for (int j = 8/DA_WIDTH-1; j >= 0; j--)
		{
			for (int i = 0; i < INPUT_SIZE; i ++)
			{
				bitnum = static_cast<int>(data0[i] & m);
				da_res[i+j*INPUT_SIZE] = bitnum;
				data0[i] >>= DA_WIDTH;
			}
		}
		//cout << "2: " << da_res[1108+1152*2] << endl;
		float** tmp_v = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp_v[i] = new float[CROSSBAR_L];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_L; j ++)
				tmp_v[i][j] = da_res[i*CROSSBAR_L+j];
		}
		//cout << "3: " << tmp_v[0][1108] << endl;
		
		//cout << cell0[368] << endl;
		cb0.init(cell0, 1, CROSSBAR_W, CROSSBAR_L);
		
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			float* v_in = new float[CROSSBAR_L];
			float* i_out = new float[CROSSBAR_W];
			for (int j = 0; j < CROSSBAR_L; j ++)
			{
				v_in[j] = tmp_v[i][j];
			}
			cb0.run(v_in, i_out, false);
			for (int j = 0; j < CROSSBAR_W; j ++)
				out_i_tmp0[i][j] = i_out[j];
		}
		//cout << out_i_tmp0[0][0] << endl;
		
		//cout << cell1[368] << endl;
		cb1.init(cell1, 1, CROSSBAR_W, CROSSBAR_L);
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			cb1.run(tmp_v[i], out_i_tmp1[i], false);
		}
		//cout << out_i_tmp1[0][1] << endl;

		float max_i01 = 0;
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				if (out_i_tmp0[i][j] > max_i01)
					max_i01 = out_i_tmp0[i][j];
				if (out_i_tmp1[i][j] > max_i01)
					max_i01 = out_i_tmp1[i][j];
			}
		}
		//cout << max_i01 << endl;
		float* tmp_ad0 = new float[CROSSBAR_W*8/DA_WIDTH];//记录ad输出
		float* tmp_ad1 = new float[CROSSBAR_W*8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp_ad0[j+i*CROSSBAR_W] = out_i_tmp0[i][j] * 255 / max_i01;
				tmp_ad1[j+i*CROSSBAR_W] = out_i_tmp1[i][j] * 255 / max_i01;

				tmp_ad0[j+i*CROSSBAR_W] = (tmp_ad0[j+i*CROSSBAR_W] > 0)?floor(tmp_ad0[j+i*CROSSBAR_W] + 0.5):ceil(tmp_ad0[j+i*CROSSBAR_W] - 0.5);
				tmp_ad1[j+i*CROSSBAR_W] = (tmp_ad1[j+i*CROSSBAR_W] > 0)?floor(tmp_ad1[j+i*CROSSBAR_W] + 0.5):ceil(tmp_ad1[j+i*CROSSBAR_W] - 0.5);

				out_data0[j+i*CROSSBAR_W] = tmp_ad0[j+i*CROSSBAR_W];
				out_data1[j+i*CROSSBAR_W] = tmp_ad1[j+i*CROSSBAR_W];
				//cout << tmp[i] << endl;
			}
		}
		//cout << out_data1[0] << endl;
		float** tmp0 = new float*[8/DA_WIDTH];
		float** tmp1 = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			tmp0[i] = new float[CROSSBAR_W];
			tmp1[i] = new float[CROSSBAR_W];
		}
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp0[i][j] = out_data0[i*CROSSBAR_W+j];
				tmp1[i][j] = out_data1[i*CROSSBAR_W+j];
			}
		}
		//cout << "stage3 input test: " << tmp1[3][127] << endl;

		float* tmp_res0 = new float[CROSSBAR_W];
		float* tmp_res1 = new float[CROSSBAR_W];
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			tmp_res0[i] = 0;
			tmp_res1[i] = 0;
		}
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			//wait(10, SC_NS);
			for (int j = 0; j < 8/DA_WIDTH; j ++)
			{
				tmp_res0[i] = tmp0[j][i] + 2*tmp_res0[i];
				tmp_res1[i] = tmp1[j][i] + 2*tmp_res1[i];
			}
			tmp_res0[i] = (tmp_res0[i] > 0) ? tmp_res0[i] : 0;
			tmp_res1[i] = (tmp_res1[i] > 0) ? tmp_res1[i] : 0;
			//cout << tmp_res1[i] << endl;

			res1[i] = tmp_res0[i];
			res1[i+CROSSBAR_W] = tmp_res1[i];
		}
		//cout << res1[255] << endl;

		int* data = new int[CROSSBAR_L];
		for (int i = 0; i < CROSSBAR_L-2*CROSSBAR_W; i ++)
			data[i] = 0;
		for (int i = 0; i < 2*CROSSBAR_W; i ++)
		{
			data[CROSSBAR_L-2*CROSSBAR_W+i] = int(res1[i]);
			//cout << data[1052+i] << endl;
		}
		//cout << data[1151] << endl;
		int high = 0;
		int max = -1;
		int max_index = 0;
		for (int i = 0; i < CROSSBAR_L; i ++)
		{
			if (data[i] > max)
			{
				max = data[i];
				max_index = i;
			}
		}
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
			int move = DA_WIDTH*(8/DA_WIDTH-1-j);
			int bitnum;
			for (int i = 0; i < INPUT_SIZE; i ++)
			{
				bitnum = static_cast<int>((data[i] >> (high - 8 + move)) & m);
				da_res2[i+j*INPUT_SIZE] = bitnum;
			}
		}

		//cout << da_res2[1152*3-1] << endl;
		float** tmp_v2 = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp_v2[i] = new float[CROSSBAR_L];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_L; j ++)
				tmp_v2[i][j] = da_res2[i*CROSSBAR_L+j];
		}
		//cout << tmp_v2[7][1151] << endl;
		
		//cout << cell2[1151] << endl;
		cb2.init(cell2, 1, CROSSBAR_W, CROSSBAR_L);
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			cb2.run(tmp_v2[i], out_i_tmp2[i], false);
		}

		float max_i2 = 0;
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				if (out_i_tmp2[i][j] > max_i2)
					max_i2 = out_i_tmp2[i][j];
			}
		}
		
		float* tmp_ad2 = new float[CROSSBAR_W*8/DA_WIDTH];//记录ad输出
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp_ad2[j+i*CROSSBAR_W] = out_i_tmp2[i][j] * 255 / max_i2;
				tmp_ad2[j+i*CROSSBAR_W] = (tmp_ad2[j+i*CROSSBAR_W] > 0)?floor(tmp_ad2[j+i*CROSSBAR_W] + 0.5):ceil(tmp_ad2[j+i*CROSSBAR_W] - 0.5);
				out_data2[j+i*CROSSBAR_W] = tmp_ad2[j+i*CROSSBAR_W];
				//cout << tmp[i] << endl;
			}
		}

		float** tmp2 = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp2[i] = new float[CROSSBAR_W];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp2[i][j] = out_data2[i*CROSSBAR_W+j];
			}
		}
		//cout << "stage6 input test: " << tmp[0][1] << endl;
		float* tmp_res2 = new float[CROSSBAR_W];
		for (int i = 0; i < CROSSBAR_W; i ++)
			tmp_res2[i] = 0;
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			//wait(10, SC_NS);
			for (int j = 0; j < 8/DA_WIDTH; j ++)
			{
				tmp_res2[i] = tmp2[j][i] + 2*tmp_res2[i];
			}
			tmp_res2[i] = (tmp_res2[i] > 0) ? tmp_res2[i] : 0;
			res2[i] = tmp_res2[i];
		}
		//cout << res2[127] << endl;
		int* data3 = new int[CROSSBAR_L];
		for (int i = 0; i < CROSSBAR_L-CROSSBAR_W; i ++)
			data3[i] = 0;
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			data3[CROSSBAR_L-CROSSBAR_W+i] = int(res2[i]);
			//cout << data[1052+i] << endl;
		}
		//cout << data3[1151] << endl;
		int high3 = 0;
		int max3 = -1;
		int max_index3 = 0;
		for (int i = 0; i < CROSSBAR_L; i ++)
		{
			if (data3[i] > max3)
			{
				max3 = data3[i];
				max_index3 = i;
			}
		}
		//cout << max3 << endl;
		for (int i = 31; i >= 0; i --)
		{
			int m = (data3[max_index3] >> i) & 1;
			if (m == 1)
			{
				high3 = i+1;
				break;
			}
		}
		//cout << high3 << endl;
		for (int j = 8/DA_WIDTH-1; j >= 0; j--)
		{
			int move = DA_WIDTH*(8/DA_WIDTH-1-j);
			int bitnum;
			for (int i = 0; i < INPUT_SIZE; i ++)
			{
				bitnum = static_cast<int>((data3[i] >> (high3 - 8 + move)) & m);
				da_res3[i+j*INPUT_SIZE] = bitnum;
			}
		}

		float** tmp_v3 = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp_v3[i] = new float[CROSSBAR_L];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_L; j ++)
				tmp_v3[i][j] = da_res3[i*CROSSBAR_L+j];
		}
		
		cb3.init(cell3, 1, CROSSBAR_W, CROSSBAR_L);
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			cb3.run(tmp_v3[i], out_i_tmp3[i], false);
		}

		float max_i3 = 0;
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				if (out_i_tmp3[i][j] > max_i3)
					max_i3 = out_i_tmp0[i][j];
			}
		}
		
		float* tmp_ad3 = new float[CROSSBAR_W*8/DA_WIDTH];//记录ad输出
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp_ad3[j+i*CROSSBAR_W] = out_i_tmp3[i][j] * 255 / max_i3;
				tmp_ad3[j+i*CROSSBAR_W] = (tmp_ad3[j+i*CROSSBAR_W] > 0)?floor(tmp_ad3[j+i*CROSSBAR_W] + 0.5):ceil(tmp_ad3[j+i*CROSSBAR_W] - 0.5);
				out_data3[j+i*CROSSBAR_W] = tmp_ad3[j+i*CROSSBAR_W];
				//cout << tmp[i] << endl;
			}
		}

		float** tmp3 = new float*[8/DA_WIDTH];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
			tmp3[i] = new float[CROSSBAR_W];
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			for (int j = 0; j < CROSSBAR_W; j ++)
			{
				tmp3[i][j] = out_data3[i*CROSSBAR_W+j];
			}
		}
		//cout << "stage6 input test: " << tmp[0][1] << endl;
		float* tmp_res3 = new float[CROSSBAR_W];
		for (int i = 0; i < CROSSBAR_W; i ++)
			tmp_res3[i] = 0;
		for (int i = 0; i < CROSSBAR_W; i ++)
		{
			//wait(10, SC_NS);
			for (int j = 0; j < 8/DA_WIDTH; j ++)
			{
				tmp_res3[i] = tmp3[j][i] + 2*tmp_res3[i];
			}
			tmp_res3[i] = (tmp_res3[i] > 0) ? tmp_res3[i] : 0;
		}

		float max4 = 0;
		int index4 = 0;
		for (int i = 0; i < 10; i ++)
		{
			if (tmp_res3[i] > max4)
			{
				max4 = tmp_res3[i];
				index4 = i;
			}
		}

		res = index4;
		cout << "RES: " << res << endl;

		delete[] data0;
		delete[] data;
		delete[] data3;
		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			delete[] tmp_v[i];
		}
		delete[] tmp_v;
		delete[] tmp_ad0;
		delete[] tmp_ad1;
		delete[] tmp_ad2;
		delete[] tmp_ad3;

		for (int i = 0; i < 8/DA_WIDTH; i ++)
		{
			delete[] tmp0[i];
			delete[] tmp1[i];
			delete[] tmp2[i];
			delete[] tmp3[i];
		}
		delete[] tmp0;
		delete[] tmp1;
		delete[] tmp2;
		delete[] tmp3;
		delete[] tmp_res0;
		delete[] tmp_res1;
		delete[] tmp_res2;
		delete[] tmp_res3;

	}
	return 0;
}