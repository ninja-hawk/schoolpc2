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
	char c[200];
	P(0);
	fprintf(com0out, "画面0から入力");
	fscanf(com0in, "%s", c);
	V(0);
	while(1){
		fprintf(com0out, "画面0だぜぇ");
		fprintf(com1out, "画面1だぜぇ");
    	}
}

void task2(){
	//P(0);
    	// フォントを緑色に
    	fprintf(com0out, "\x1b[32m");
    	fprintf(com1out, "\x1b[32m");
    	//char d[200];
	fprintf(com1out, "画面1だぜぇ　入力: ");
	//fscanf(com1in, "%s", d);
	//fprintf(com1out, "出力: %s\n", d);
	//fprintf(com0out, "出力: %s\n", d);
    while(1){
	fprintf(com1out, "画面1だぜぇ");
    }
}

void task3(){
while(1){
    P(0);
    // フォントを赤色に
    fprintf(com0out, "\x1b[31m");
    fprintf(com1out, "\x1b[31m");
    char s;
    fprintf(com0out, "画面0から入力：\n");
    fscanf(com0in, "%s", &s);
    fprintf(com0out, "画面0からの出力： %s\n", &s);
    fprintf(com1out, "画面0からの出力： %s\n", &s);
    V(0);
}
}

void task4(){
while(1){
    P(0);
    // フォントを緑色に
    fprintf(com0out, "\x1b[32m");
    fprintf(com1out, "\x1b[32m");
    char s;
    fprintf(com1out, "画面1から入力：\n");
    fscanf(com1in, "%s", &s);
    fprintf(com0out, "画面1からの出力： %s\n", &s);
    fprintf(com1out, "画面1からの出力： %s\n", &s);
    V(0);
}
}

int main(void){
  init_kernel();
  init_file();
  //set_task(task1);
  //set_task(task2);
  set_task(task3);
  set_task(task4);
  begin_sch();  
  return 0;
}
