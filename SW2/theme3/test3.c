#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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
    fprintf(com0out, "     |");
    fprintf(com1out, "     |");
    for (w = 1; w < width-1; w++){
        fprintf(com0out, "%c", column[2*w]);
        fprintf(com1out ,"%c", column[2*w]);
        fprintf(com0out, "%c|", column[2*w+1]);
        fprintf(com1out, "%c|", column[2*w+1]);
    }
    fprintf(com0out, "\n   ");
    fprintf(com1out, "\n   ");
    for (w = 0; w < width-1; w++){
        fprintf(com0out, "  |");
        fprintf(com1out, "  |");
    }
    fprintf(com0out, "\n");
    fprintf(com1out, "\n");
    // 間違い本体
    for(h=0; h<height; h++){
        // 列名を描画するかどうか
        for (w = 0; w < width; w++){
          if(h == h_answer && w == w_answer && a1 == 0 ){
              fprintf(com0out, "\x1b[101m%2c\x1b[0m|", question[h][w]);
              fprintf(com1out, "\x1b[101m%2c\x1b[0m|", question[h][w]);
	      continue;
          }
          if(h == h_answer && w == w_answer && a1 == 1 ){
              fprintf(com0out, "\x1b[102m%2c\x1b[0m|", question[h][w]);
              fprintf(com1out, "\x1b[102m%2c\x1b[0m|", question[h][w]);
	      continue;
          }
          else{
              fprintf(com0out, "%2c|", question[h][w]);
              fprintf(com1out, "%2c|", question[h][w]);
          }
        }
        fprintf(com0out, "\n");
        fprintf(com1out, "\n");
  }  
}

char *check_answer;
int answerer = 2; 

void task0(){
while(1){
    char s0;
    // 入力受付
    fscanf(com0in, "%s", &s0);

    // トーク画面制限
    P(0);
    // 自分の入力値削除
    fprintf(com0out, "\e[A\e[K");
    // 自分をフォントを赤色にして自分の右側に表示
    fprintf(com0out, "\x1b[31m\n%80s\n\x1b[0m", &s0);
    // 相手のの入力値削除
    fprintf(com1out, "\e[A\e[K");
    // 自分をフォントを赤色にして相手の左側に表示
    fprintf(com1out, "\x1b[31m\n%s\n\x1b[0m\n", &s0);

    // ゲームスタートコマンドかどうか
    if(strncmp(&s0, "start",5) == 0){
        int width, height;
        int width_input, height_input;
        fprintf(com1out, "Player0 is now setting rule ...");
        fprintf(com0out, "\nThe size of widths(letters) more than 2, less than 10 ");
        scanf("%d", &width_input);
        width = width_input;
        fprintf(com1out, "\nThe size of width = %d\n", width);
        width += 2;

        
        fprintf(com0out, "The size of heights(letters) less than 26 ");
        scanf("%d", &height_input);
        fprintf(com0out, "\n");
        height = height_input;

        fprintf(com1out, "\nThe height of width = %d\n", width);

        int h,w;
        char column[2*width-1];
        char question[height][width];
        char q = 'a';
        char a = 'e';
        int a1 = 2;
        
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
        check_answer = check;

        fprintf(com0out, "\nGive cell name faster than your opponent! ex)A01\n");
        fprintf(com1out, "\nGive cell name faster than your opponent! ex)A01\n");


        // トーク画面解放
        V(0);

        while(1){
            // 入力受付
            fscanf(com0in, "%s", &s0);

            // トーク画面制限
            P(0);

            // 自分の入力値削除
            fprintf(com0out, "\e[A\e[K");
            // 自分をフォントを赤色にして自分の右側に表示
            fprintf(com0out, "\x1b[31m\n%80s\n\x1b[0m", &s0);
            // 相手のの入力値削除
            fprintf(com1out, "\e[A\e[K");
            // 自分をフォントを赤色にして相手の左側に表示
            fprintf(com1out, "\x1b[31m\n%s\n\x1b[0m\n", &s0);
            if(answerer == 1){
                fprintf(com0out, "\n\n \x1b[32mPlayer1\x1b[0m solved faster!\n\n");
		    fprintf(com1out, "\n\n \x1b[32mPlayer1\x1b[0m solved faster!\n\n");
                show(width, height, question, column, w_answer,h_answer,1);
                break;
            }        
            if(strncmp(&s0, check_answer, 3) == 0){
                answerer = 0;
                fprintf(com0out, "\n\n \x1b[31mPlayer0\x1b[0m solved faster!\n\n");
	    	fprintf(com1out, "\n\n \x1b[31mPlayer0\x1b[0m solved faster!\n\n");
                show(width, height, question, column, w_answer,h_answer,0);
                break;
            }

            if(strncmp(&s0, "restart",7)==0){
                break;
            }
        }
        // トーク画面解放
        V(0);
    }    
    else{
     	// トーク画面解放
     	V(0);
    }
}
}

void task1(){
while(1){
    char s1;
    // 入力受付
    fscanf(com1in, "%s", &s1);
    
    // トーク画面制限
    P(0);
    // 自分の入力値削除
    fprintf(com1out, "\e[A\e[K");
    // 自分をフォントを緑色にして自分の右側に表示
    fprintf(com1out, "\x1b[32m\n%80s\n\x1b[0m", &s1);
    // 相手のの入力値削除
    fprintf(com0out, "\e[A\e[K");
    // 自分をフォントを緑色にして相手の左側に表示
    fprintf(com0out, "\x1b[32m\n%s\n\x1b[0m\n", &s1);

    if(!check_answer){
        strncmp(&s1, check_answer, 3) == 0;
        answerer = 1;
    }

    // トーク画面解放
    V(0);
}
}



int main(void){
  init_kernel();
  init_file();

  set_task(task0);
  set_task(task1);
  fprintf(com0out, "\nFind 'e'\n");
  fprintf(com1out, "\nFind 'e'\n");
  fprintf(com0out, "\nYou're Player0 You can set rule\n");
  fprintf(com0out, "Give 'start' to play!\n");
  fprintf(com1out, "\nYou're Player1 You can't set rule\n");
  fprintf(com0out, "\nYou can also enjoy chatting\n\n");
  fprintf(com1out, "\nYou can also enjoy chatting\n\n");

  begin_sch();  
  return 0;
}
