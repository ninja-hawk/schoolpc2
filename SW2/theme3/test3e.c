#include <stdio.h>
#include <stdlib.h>
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

void show(int width, int height, char question[height][width], char column[width], int w_answer, int h_answer, int a1){
    int w,h;
    // 描画部分
    // 列名および空白描画
    printf("     |");
    for (w = 1; w < width-1; w++){
        printf("%c", column[2*w]);
        printf("%c|", column[2*w+1]);
    }
    printf("\n   ");
    for (w = 0; w < width-1; w++){
        printf("  |");
    }
    printf("\n");
    // 間違い本体
    for(h=0; h<height; h++){
        // 列名を描画するかどうか
        for (w = 0; w < width; w++){
          if(h == h_answer && w == w_answer && a1 ){
              printf("\x1b[31m%2c\x1b[0m|", question[h][w]);
          }
          else{
              printf("%2c|", question[h][w]);
          }
        }
        printf("\n");
  }  
}



void task0(){
while(1){
    P(0);
    char s0;
    fscanf(com0in, "%s", &s0);
    fprintf(com0out, "\e[A\e[K");

    P(1);

    if(strncmp(&s0, "start",5)!=0){
        int width, height;
        int width_input, height_input;
        printf("\nThe size of widths(letters) more than 2, less than 40 ");
        scanf("%d", &width_input);
        width = width_input;
        width += 2;

        
        printf("The size of heights(letters) less than 26 ");
        scanf("%d", &height_input);
        printf("\n");
        height = height_input;

        int h,w;
        char column[2*width-1];
        char question[height][width];
        char q = 'a';
        char a = 'e';
        int a1 = 0;
        
        int w_answer, h_answer;
        w_answer = rand() % (width - 2) + 2;
        h_answer = rand() % height;
        
        // 列(int)を作成
        for(w=0; w < width-1; w++){
            if(w<10){
                column[2*w] = '0';
                column[2*w+1] = '0' + w;
            }
            else{
                column[2*w] = '0' + (w/10 % 10);
                column[2*w+1] = '0' + (w % 10);
            }
        }

        // 行(char)を作成（各列の先頭要素を操作）
        for(h=0; h < height; h++){
            question[h][0] = 65 + h;
            // 各列の2列目は空白
            question[h][1] = ' ';
        }
        
        // 間違い本体部分
        for(h=0; h<height; h++){
            for (w = 2; w < width; w++)
            {
                if(h == h_answer && w == w_answer){
                    question[h][w] = a;
                }
                else{
                    question[h][w] = q;
                }
            }
        }

        show(width, height, question, column, w_answer,h_answer,a1);

        char *check0 = &question[h_answer][0];
        char *check1 = &column[2*(w_answer-1)];
        char *check2 = &column[2*(w_answer-1)+1];
        char *check;
        sprintf(check, "%c%c%c\n", check0[0], check1[0], check2[0]);
        // printf("%s\n", check);
        
        // printf("\ncheck! ");
        // scanf("%s", &input);

        // if(strncmp(&input, check,3)==0){
        //   a1 = 1;
        //   printf("That's correct!!!\n\n");
        //   show(width, height, question, column, w_answer,h_answer,a1);
        // }
    }
    V(1);

    //char *a = "A10";
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
}
}

void task1(){
while(1){
    P(1);
    char s1;
    fscanf(com1in, "%s", &s1);
    fprintf(com1out, "\e[A\e[K");
    // V(0);
    // P(1);
    // フォントを緑色に
    fprintf(com0out, "\x1b[32m");
    fprintf(com1out, "\x1b[32m");
    fprintf(com0out, "\e[A\e[K");
    fprintf(com0out, "\n%s\n", &s1);
    fprintf(com1out, "\n%80s\n", &s1);
    fprintf(com0out, "\x1b[0m");
    fprintf(com1out, "\x1b[0m");
    V(1);
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
