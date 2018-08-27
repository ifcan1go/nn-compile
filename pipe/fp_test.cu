#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <time.h>
#define N (1024*1024)
#define M (1000)
#define THREADS_PER_BLOCK 1024
void serial_add(double *a, double *b, double *c, int n, int m)
{
	for(int index=0;index<n;index++)
	{
		for(int j=0;j<m;j++)
		{
			c[index] = a[index]*a[index] + b[index]*b[index];
		}
	}
}

__global__ void vector_add(double *a, double *b, double *c)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	for(int j=0;j<M;j++)
	{
		c[index]=a[index]*a[index]+b[index]*b[index];
	}
}

int main()
{
	clock_t start,end;
	double *a, *b, *c;
	int size=N*sizeof( double );
	a= (double *)malloc( size );
	b= (double *)malloc( size );
	c= (double *)malloc( size );
	for(int i=0;i<N;i++)
	{
		a[i]=b[i]=i;
		c[i]=0;
	}
	start=clock();
	serial_add(a,b,c,N,M);
	printf("c[%d]=%f\n",0,c[0]);
	printf("c[%d]=%f\n",N-1,c[N-1]);
	end=clock();
	float time1=((float)(end-start))/CLOCKS_PER_SEC;
	printf("CPU: %f seconds\n",time1);
	
	double *d_a,*d_b,*d_c;
	cudaMalloc((void **) &d_a,size);
	cudaMalloc((void **) &d_b,size);
	cudaMalloc((void **) &d_c,size);
	cudaMemcpy(d_a,a,size,cudaMemcpyHostToDevice);
	cudaMemcpy(d_b,b,size,cudaMemcpyHostToDevice);
	start=clock();
	vector_add<<<(N+(THREADS_PER_BLOCK-1))/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(d_a,d_b,d_c);
	cudaMemcpy(c,d_c,size,cudaMemcpyDeviceToHost);
	printf("c[%d]=%f\n",0,c[0]);
	printf("c[%d]=%f\n",N-1,c[N-1]);
	end=clock();
	free(a);
	free(b);
	free(c);
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);
	
	float time2 = ((float)(end-start))/CLOCKS_PER_SEC;
	printf("CUDA: %f seconds, Speedup: %f\n",time2,time1/time2);
	return 0;
}