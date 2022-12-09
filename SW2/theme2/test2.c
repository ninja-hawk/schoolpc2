#include <stdio.h>


void task1(){
	while(1){
	printf("u");
	*(char*)0x00d00039 = 'U';	
	}
}

int main(void){
	printf("a");
	*(char*)0x00d00039 = 'A';
	init_kernel();
	set_task(task1);
	begin_sch();
}
