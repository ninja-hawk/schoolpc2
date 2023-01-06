#include <stdio.h>
#include "mtk_c.h"
FILE* com0in;
FILE* com0out;
FILE* com1in;
FILE* com1out;

void init_file(){
   

   com0in = fdopen(3, "r");
   com0out = fdopen(3, "w");
   com1in = fdopen(4, "r");
   com1out = fdopen(4, "w");
}

void task1(){ 
    int i = 1;
    int a = 0;
    P(0);
    fprintf(com1in, "count[p] %d\n", semaphore[0].count);
    while(1){
        //printf("task1: %d\n", i/*semaphore[0].count*/);
        fprintf(com1in, "\%d (1)", i);
        i++;
        if (i == 2000){
        for (int k=0; k < 400000000; k++);
        break;
};
    }
    V(0);
    fprintf(com1in, "\n%d",semaphore[0].task_list );
    while(1) {fprintf(com1in, "end1 ");
    //printf("\nready %d\n", ready);
}
}


void task2(){
    int j = 20000;
    printf("\ntask2 change\n");
    P(0);
    printf("\nccount[p] %d\n", semaphore[0].count);
    while(1){
        for (int k=0; k < 400000; k++);
        //printf("task2: %d\n", j/*semaphore[0].count*/);
        printf("%d (2)", j);
        j--;
        if (j == 19000) break;
    }
    printf("\nwait %d\n", semaphore[0].task_list);
    V(0);
    printf("\nccccount[p] %d\n", semaphore[0].count);
    printf("\nready %d\n", ready);
    printf("\nwait %d\n", semaphore[0].task_list);
    while(1) printf("end2 ");
}


void task3(){
    int k = 100000;
    printf("\ntask3 change\n");
    P(0);
    printf("\ncccount[p] %d\n", semaphore[0].count);
    while(1){
        for (int k=0; k < 400000; k++);
        //printf("task2: %d\n", j/*semaphore[0].count*/);
        printf("%d (3)", k);
        k--;
        if (k == 95000) break;
    }
    V(0);
    while(1) printf("task3");
}



int main(void){
    init_file();
    printf("\033[s\n\n\n\033[u");
    init_kernel();
    set_task(task1);
    set_task(task2);
    //printf("%d\n", task_tab[1].next);
    //set_task(task3);
    //printf("%d\n", task_tab[1].next);
   // printf("%d\n", task_tab[2].next);
    //printf("%d\n", task_tab[3].next);
    

    begin_sch();
    
    return 0;
}

