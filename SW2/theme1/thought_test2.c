#include <stdio.h>
#define N = 10000
#define M = 20

void task1(){
    while(1){
        P(0);
        for (i=0;i<N;i++){
                /* N: X秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */ 
        }
        for (i=0;i<N;i++){
                /* N: X秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */ 
        }
        V(0);
    }
}

void task2(){
    while(1){
        P(0);
        for (j=0;j<M;j++){ 
            /* M: Y秒間ループ、この待機ループの間にタイマ割込みは生じない */ 
        }
        V(0);
    }
}

void task3(){
    while(1){
    P(0);
	for (i=0;i<N;i++){ 
        /* N: タスクループ１回につき、この待機ループで1回タイマ割込みが必ず生じる */ 
    }
    V(0);
    }
}

void task4(){
    P(0);
	for (j=0;j<M;j++){
        /* M: タスクループ１回につき、この待機ループではタイマ割込みは生じない */
    }
    V(0);
}



int main(void){
	init_kernel();
	set_task(task1);
	set_task(task2);
	set_task(task3);
	set_task(task4);
	begin_sch();
	return 0;
}