#include <stdio.h>
#include <stdlib.h>
#include<string.h>

int main(void){

    
    int width, height;
    while(1){
    printf("The size of widths(letters) more than 2, less than 80 ");
    scanf("%d", &width);

    
    width += 2;
    printf("The size of heights(letters) ");
    scanf("%d", &height);

    int h,w;
    char column[2*width-1];
    char question[height][width];
    char q = 'a';
    char a = 'e';
    
    int w_answer, h_answer;
    w_answer = rand() % (width - 2);
    h_answer = rand() % height;
    int a1 = 0;
    
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
	//column[w] = w;
      //column[w] = w;
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

    // 描画部分
    // 列名および空白描画
    printf("     |");
    for (w = 1; w < width-1; w++)
      {
        printf("%c", column[2*w]);
	printf("%c|", column[2*w+1]);
      }
      printf("\n   ");
      // printf("  ");
      for (w = 0; w < width-1; w++){
        printf("  |");
      }
    printf("\n");
    // 間違い本体
    for(h=0; h<height; h++){
      // 列名を描画するかどうか
          for (w = 0; w < width; w++)
          {
            if(h == h_answer && w == w_answer && a1 ){
              printf("\x1b[31m%2c\x1b[0m|", question[h][w]);
            }
            else{
              printf("%2c|", question[h][w]);
            }
          }
          printf("\n");
    }
    char *check0 = question[h_answer][0];
    char *check1 = column[2*w_answer];
    char *check2 = column[2*w_answer+1];
    char *check;
    sprintf(check, "%s%s%s\n", check0, check1, check2);
    print("%s\n", check);
    // V(0);

    }
    printf("hello\n");
    return 0;
}
