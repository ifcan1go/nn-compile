#ifndef REG1
#define REG1
#include <stdio.h>
#include <stdlib.h>
#include <vector>

using namespace std;

typedef struct reg1
{
	vector<float> v_in;

	float get(int index)
	{
		return v_in[index];
	}
	void save(float value)
	{
		v_in.push_back(value);
	}
	void clear()
	{
		//delete v_in;
	}

}R;

#endif