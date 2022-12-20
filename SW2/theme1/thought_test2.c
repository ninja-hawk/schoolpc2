#include <stdio.h>
#define L = 10000
#define M = 20000
#define N = 40000

void task1(){
    while(1){
        // task1-a
        for (j=0;j<L;j++){ 
            /* L: 1秒間ループ、この待機ループの間にタイマ割込みは生じない */ 
        }
        P(0);
        // task1-b
        for (j=0;j<L;j++){ 
            /* L: 1秒間ループ、この待機ループの間にタイマ割込みは生じない */ 
        }
        V(0);
        P(1):
        for (i=0;i<M;i++){
            /* M: 2秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */ 
        }
        V(1);
    }
}

void task2(){
    while(1){
        P(0);
        // task2-a
        for (i=0;i<M;i++){
            /* M: 2秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */ 
        }
        V(0);
        P(1);
        // task2-b
        for (i=0;i<N;i++){
            /* N: 4秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */ 
        }
        V(1);
        for (i=0;i<M;i++){
            /* M: 2秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */ 
        }            
    }
}

void task3(){
    while(1){
        // task3-a
        P(0);
        for (i=0;i<M;i++){ 
            /* M: タスクループ１回につき、この待機ループで1回タイマ割込みが必ず生じる */ 
        }
        V(0);
        // task3-b
        for (j=0;j<L;j++){ 
            /* L: 1秒間ループ、この待機ループの間にタイマ割込みは生じない */ 
        }
        P(1);
        // taask3-c
        for (j=0;j<L;j++){ 
            /* L: 1秒間ループ、この待機ループの間にタイマ割込みは生じない */ 
        }
        V(1);
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