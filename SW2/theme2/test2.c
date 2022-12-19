#include <stdio.h>
#include "mtk_c.h"

extern void init_kernel();
extern void set_task(void *a);
extern void begin_sch();

void task1(){
	while(1){
	*(char*)0x00d00039 = '1';
	int a = 1;
	for(int j=0; j<50; j++){
		printf("+ %d", a+j);
	}
	}
}

void task2(){
	while(1){
	*(char*)0x00d00039 = '2';
	int a = 1;
	for(int j=50; j<100; j++){
		printf("- %d", a+j);
	}
	}
}

void task3(){
	while(1){
	*(char*)0x00d00039 = '3';
	int a = 1;
	for(int j=100; j<150; j++){
		printf("* %d", a+j);
	}
	}
}


int main(void){
	init_kernel();
	set_task(task1);
	set_task(task2);
	set_task(task3);
	begin_sch();
	return 0;
}

