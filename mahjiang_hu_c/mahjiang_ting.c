#include <stdio.h>
#include <stdbool.h>

#define GET_ARRAY_LEN(array,len){len = (sizeof(array) / sizeof(array[0]));}

bool has(int *p,int c,int num);
int check_hu_var(int *p ,int bai_da);

int main(int argc, char const *argv[])
{
	int cards[] = {1,2,3,4,5,6,7,9};
	int num ;
	GET_ARRAY_LEN(cards,num);
	int card  =9;
	//int *p;
	//printf("%lu\n", sizeof(p));
	int x= check_hu_var(cards,card);
	printf("结果%d\n", x);
	return 0;
}

int check_hu_var(int *p ,int bai_da)
{
	int num;
	GET_ARRAY_LEN(&p,num)
	printf("???%d\n", num);
	// if (num/3 != 2 )
	// 	return

	return 0;
}

bool has(int *p,int c,int num)
{
	for (int i = 0; i < num; ++i)
	{
		if (*(p+i) == c )
		{
			return true;
		}
	}
	printf("(%s)\n", "enter111");
	return false;
}