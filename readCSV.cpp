#include <iostream>
#include <vector>
#include <fstream>
#include <sstream>
#include <string>

using namespace std;

int main()
{
	ifstream inFile("mnist_test_y.csv", ios::in);
	string lineStr;
	int C = 0;
	float* y = new float[10000];
	while (getline(inFile, lineStr))
	{
		//cout<<lineStr<<endl;
		stringstream ss(lineStr);
		string str;
		vector<string> lineArray;
		int c = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			y[C] = num;
			c ++;
		}
		C ++;
	}

	ifstream inFile1("result_1bit_noise.csv", ios::in);
	string lineStr1;
	C = 0;
	float* y1 = new float[10000];
	while (getline(inFile1, lineStr1))
	{
		//cout<<lineStr<<endl;
		stringstream ss(lineStr1);
		string str;
		vector<string> lineArray;
		int c = 0;
		while (getline(ss, str, ','))
		{
			istringstream iss(str);
			float num;
			iss >> num;
			y1[C] = num;
			c ++;
		}
		C ++;
	}
	//cout << y[9999] << endl;
	//cout << y1[9999] << endl;
	int count = 0;
	for (int i = 0; i < 10000; i ++)
	{
		if (y[i] - y1[i] == 0)
			count ++;
	}
	cout << count << endl;
	return 0;
}