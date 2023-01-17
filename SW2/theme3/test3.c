#include <stdio.h>
#include<string.h>
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

void task0(){
while(1){
    //P(0);
    char s0;
    //fprintf(com0out, "\n%s\n","------------------------------------画面0から入力：------------------------------------");
    fscanf(com0in, "%s", &s0);
    //char *a = "A10";
    P(0);
    fprintf(com0out, "\e[A\e[K");
    //if(strcmp(&s0,a)==0){
	//fprintf(com0out, "Correct!!!!! \n");
    //}
    // フォントを赤色に
    fprintf(com0out, "\x1b[31m");
    fprintf(com1out, "\x1b[31m");
    fprintf(com0out, "\n%80s\n", &s0);
    fprintf(com1out, "\e[A\e[K");
    fprintf(com1out, "\n%s\n", &s0);
    fprintf(com0out, "\x1b[0m");
    fprintf(com1out, "\x1b[0m");
    V(0);
    //V(0);
}
}

void task1(){
while(1){
    //P(0);
    char s1;
    //fprintf(com1out, "\n%s\n","------------------------------------画面1から入力：------------------------------------");
    fscanf(com1in, "%s", &s1);
    P(0);
    fprintf(com1out, "\e[A\e[K");
    // フォントを緑色に
    fprintf(com0out, "\x1b[32m");
    fprintf(com1out, "\x1b[32m");
    fprintf(com0out, "\e[A\e[K");
    fprintf(com0out, "\n%s\n", &s1);
    fprintf(com1out, "\n%80s\n", &s1);
    fprintf(com0out, "\x1b[0m");
    fprintf(com1out, "\x1b[0m");
    V(0);
    //V(0);
}
}



int main(void){
  init_kernel();
  init_file();

  set_task(task0);
  set_task(task1);
  begin_sch();  
  return 0;
}
