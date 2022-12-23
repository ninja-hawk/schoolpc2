#include <stdio.h>
#include "mtk_c.h"

extern void init_kernel();
extern void set_task(void *a);
extern void begin_sch();
#define L  500
#define M  1000
#define N  2000
void task1(){
while(1){
	// task1-a
	for (int j = 0;j<L;j++){
		printf("task1-a %d \n", j);
		/* L: 1 秒間ループ、この待機ループの間にタイマ割込みは生じない */
	}
	P(0);
	// task1-b
	for (int j = 0;j<L;j++){
		printf("task1-b %d \n", j);
		/* L: 1 秒間ループ、この待機ループの間にタイマ割込みは生じない */
	}
	V(0);
	P(1);
	// task2-c
	for (int i = 0;i<M;i++){
		printf("task1-c %d \n", i);
		/* M: 2 秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */
	}
	V(1);
}}

void task2(){
while(1){
	P(0);
	// task2-a
	for (int i = 0;i<M;i++){
		printf("task2-a %d \n", i);
		/* M: 2 秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */
	}
	V(0);
	P(1);
	// task2-b
	for (int i = 0;i<N;i++){
		printf("task2-b %d \n", i);
		/* N: 3 秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */
	}
	V(1);
	// task2-c
	for (int i = 0;i<M;i++){
		printf("task2-c %d \n", i);
		/* M: 2 秒間ループ、この待機ループの間にタイマ割込みが必ず生じる */
	}
}}

void task3(){
while(1){
	// task3-a
	P(0);
	for (int i = 0;i<M;i++){
		printf("task3-a %d \n", i);
		/* M: タスクループ1回につき、この待機ループで 1 回タイマ割込みが必ず生
		じる */
	}
	V(0);
	// task3-b
	for (int j = 0;j<L;j++){
		printf("task3-b %d \n", j);
		/* L: 1 秒間ループ、この待機ループの間にタイマ割込みは生じない */
	}
	P(1);
	// taask3-c
	for (int j = 0;j<L;j++){
		printf("task3-c %d \n", j);
		/* L: 1 秒間ループ、この待機ループの間にタイマ割込みは生じない */
	}
	V(1);
}}

int main(void){
init_kernel();
set_task(task1);
set_task(task2);
set_task(task3);
begin_sch();
return 0;
}
