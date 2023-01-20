#include <stdio.h>

// #define width 5
// #define height 3

int main(){
    // P(0);
    int width, height;
    printf("The size of widths(letters) ");
    scanf("%d", &width);

    
    width += 2;
    printf("The size of heights(letters) ");
    scanf("%d", &height);

    int h,w;
    int column[width-1];
    char question[height][width];
    char q = 'a';
    char a = 'e';
    int w_answer = 4, h_answer= 6;
    int a1 = 0;
    
    // 列(int)を作成
    for(w=0; w < width-1; w++){
      column[w] = w;
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
        printf("%2d|", column[w]);
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
    // V(0);


    printf("hello\n");
    
    return 0;
}