// escseq.c  2017/12/15 Y.Katayama
// xterm のescape-sequenceの確認
// printf() の format 文字列として使用、文字列中の %d は後続数値に置換
#define ESC "\x1b"
#define LOCATEHOME    ESC"[H"
#define SAVECURSORLOC ESC"7"
#define RETCURSORLOC  ESC"8"
#define CLEARDISPLAY  ESC"[H"ESC"[2J"
#define DELETELINEAFTERCURSOR  ESC"[0K"
#define DELETELINEBEFORECURSOR ESC"[1K"
#define DELETELINEECURSOR      ESC"[2K"
#define DELETESCREENAFTERCURSOR  ESC"[0J"
#define DELETESCREENBEFORECURSOR ESC"[1J"
#define DELETESCREEN             ESC"[2J"
#define LOCATECURSOR  ESC"[%d;%df"
#define CURSORMOVE    ESC"[%d;%dH"
#define CHANGESCROLLROWS ESC"[%d;%dr"
#define RESETSCROLLROWS  ESC"[r"
#define CURSORMOVENUP    ESC"[%dA"
#define CURSORMOVENDOWN  ESC"[%dB"
#define CURSORMOVENRIGHT ESC"[%dC"
#define CURSORMOVENLEFT  ESC"[%dD"
#define DELETENCHAR      ESC"[%dP"
#define CURSORINVISIBLE  ESC"[?25l"
#define CURSORVISIBLE    ESC"[?25h"
// #define RESETLRMARGIN   ESC"[?69l"
// #define SETLRMARGIN     ESC"[?69h"
// #define CHANGESCROLLCOLS ESC"[%d;%ds" // DECLRMM のセットが必要
// #define RESETSCROLLCOLS  ESC"[s"
#define DECTCEM 25  // カーソル表示/非表示
// #define DECLRMM 69  // 左右マージン有効/無効
#define DECSETMODE    ESC"[?%dh"  // DEC/xterm 拡張モード設定 
#define DECRESETMODE  ESC"[?%dl"  // DEC/xterm 拡張モード解除 
#define SGR  ESC"[%dm"  // SelectGraphicRendition (グラフィック属性)
#define RESETSGR  ESC"[0m"  // SGR 無効化 (グラフィック属性)
#define SGRCOL256 ESC"[38;5;%dm"  // 256色カラーパレット色指定
#define SGRBGCOL256 ESC"[48;5;%dm"  // 256色カラーパレット背景色指定
#define SGRCOL24B ESC"[38;2;%d;%d;%dm"  // 24bit(r,g,b)色指定
#define SGRBGCOL24B ESC"[48;2;%d;%d;%dm"  // 24bit(r,g,b)背景色指定

#include <stdio.h>
#include <stdlib.h>


void waitloop(int times)
{
  int d, e;
  //sleep(1);
  // for (d=0; d<1000000*times; d++){
  for (d=0; d<1000*times; d++){ // fit for experiment-board
    e=100*d;
  }
}

void test1(void)
{
  int x,y,c,d,e;
  printf(CLEARDISPLAY);
  fflush(stdout);

  for (c=0; c<100; c++){
    x = (int)((double)rand()/RAND_MAX*70)+1;
    y = (int)((double)rand()/RAND_MAX*20)+1;
    //printf(CURSORMOVE, y, x);
    printf(LOCATECURSOR, y, x);
    printf(SAVECURSORLOC);
    printf("A(%d,%d)",x,y);
    printf(RETCURSORLOC);
    fflush(stdout);

    waitloop(10);

    printf(DELETELINEAFTERCURSOR);
    fflush(stdout);
  }
}

void test2(void)
{
  int x,y,c,d,e,dx,dy;
  printf(CLEARDISPLAY); fflush(stdout);
  printf(CURSORINVISIBLE);
  x=35; y=10;
  printf(LOCATECURSOR, y, x);
  printf("(^^);"); printf(CURSORMOVENLEFT, 5); fflush(stdout);
  for (c=0; c<300; c++){
    dx = (int)((double)rand()/RAND_MAX*11)-5;
    dy = (int)((double)rand()/RAND_MAX*5)-2;
    x += dx;
    y += dy;
    if (x<1) {
      x -= dx;
      dx = 1-x;
      x=1;
    } else if (x>70){
      x -= dx;
      dx = 70-x;
      x=70;
    }
    if (y<1) {
      y -= dy;
      dy = 1-y;
      y=1;
    } else if (y>20) {
      y -= dy;
      dy = 20-y;
      y=20;
    }
    
    printf(DELETENCHAR, 5);
    if (dx>0){
      printf(CURSORMOVENRIGHT, dx);
    } else if (dx<0){
      printf(CURSORMOVENLEFT, -dx);
    }
    if (dy>0){
      printf(CURSORMOVENDOWN, dy);
    } else if (dy<0){
      printf(CURSORMOVENUP, -dy);
    }
    printf("(^^);"); printf(CURSORMOVENLEFT, 5); fflush(stdout);

    waitloop(10);

  }
  printf(CURSORVISIBLE);
}

void test3(void)
{
  int x,y,c,d,e,r1,r2,dr;
  printf(CLEARDISPLAY); fflush(stdout);
  for (c=0; c<10; c++){
    r1=(int)((double)rand()/RAND_MAX*15)+1;
    dr=(int)((double)rand()/RAND_MAX)*(20-r1)+6;
    r2=r1+dr;
    printf(CHANGESCROLLROWS, r1, r2);
    for (d=0; d<200*dr; d++){
      e=0x20+(int)((double)rand()/RAND_MAX*0x60);
      printf("%c",e); fflush(stdout);
      e=(int)((double)rand()/RAND_MAX*20);
      if (e<2) printf("\n");
    }
  }
  printf(RESETSCROLLROWS);
}

void test4(void)
{
  int x,y,c,d,e,r1,r2,dr,dx,dy,c1,c2,dc;
  printf(CLEARDISPLAY);
  printf(CURSORINVISIBLE);
  fflush(stdout);
  x=35; y=10;
  printf(LOCATECURSOR, y, x);
  printf("*"); printf(CURSORMOVENLEFT, 1); fflush(stdout);
  dx = 1; // (int)((double)rand()/RAND_MAX*11)-5;
  dy = 1; // (int)((double)rand()/RAND_MAX*5)-2;
  for (c=0; c<1000; c++){
    x += dx;
    y += dy;
    if (x<1) {
      dx = -dx;
      x=2;
    } else if (x>70){
      dx = -dx;
      x=69;
    }
    if (y<1) {
      dy = -dy;
      y=2;
    } else if (y>19) {
      dy = -dy;
      y=18;
    }
    
    printf(DELETENCHAR, 1);
    printf(LOCATECURSOR, y, x);
    printf("*"); printf(CURSORMOVENLEFT, 1); fflush(stdout);

    waitloop(5);

  }
  printf(CURSORVISIBLE);
}

void test5(void)
{
  int x,dx,cy,c,t,fl;
  double dy, y, hy;
  printf(CLEARDISPLAY);
  printf(CURSORINVISIBLE);
  fflush(stdout);
  for (c=0; c<9; c++){
    x=1; y=1; cy=(int)y; dx=1; hy=y; fl=0;
    dy = ((double)rand()/RAND_MAX*4)+3; // ry <7
    printf(LOCATECURSOR, 24-cy, x);
    printf("*"); printf(CURSORMOVENLEFT, 1); fflush(stdout);
    for (t=0; t<200; t++){
      x += dx;
      y += dy; cy=(int)y;
      if (hy<y) hy=y;
      if ((x<1) || (x>70)){
        dx = -dx;
        if (x<1) x=1+(1-x); else x=70-(x-70);
      }
      if ((cy<1) || (cy>23)){
        dy = -dy * 0.8;
        if (cy<1) {
          y=1+(1-y)*0.4;
          if (hy < 1.4) fl=1;
          hy=y;
        } else {
          y=23-(y-23)*0.8;
        }
        cy=(int)y;
      }
      dy -= 1.0;
      
      printf(DELETENCHAR, 1);
      printf(LOCATECURSOR, 24-cy, x);
      printf("*"); printf(CURSORMOVENLEFT, 1); fflush(stdout);
      if (fl == 1) break;

      waitloop(50);

    }
    printf(DELETENCHAR, 1);fflush(stdout);
  }
  printf(CURSORVISIBLE);
}

void test6(void)
{
  int i,j,v;
  printf(CLEARDISPLAY); fflush(stdout);
  for (i=0; i<11; i++){
    for (j=0; j<10; j++){
      v=i*10+j;
      printf(SGR,v); printf("%03d",v); printf(RESETSGR);
    }
    printf("\n");
  }
  printf("Hit any key\n");
  getchar();
  for (i=0; i<16; i++){
    for (j=0; j<16; j++){
      v=i*16+j;
      printf(SGRCOL256,v); printf("%02X",v); printf(RESETSGR);
    }
    printf("\n");
  }
  printf("Hit any key\n");
  getchar();
  for (i=0; i<16; i++){
    for (j=0; j<32; j++){
      printf(SGRCOL24B, i<<4, j<<3, 255); printf("X");
    }
    printf(RESETSGR "\n");
  }
  printf("Hit any key\n");
  getchar();
  for (i=0; i<16; i++){
    for (j=0; j<32; j++){
      printf(SGRBGCOL24B, i<<4, j<<3, 255); printf(" ");
    }
    printf(RESETSGR "\n");
  }
  printf("Hit any key\n");
  getchar();
}

void main(void)
{
  
  while(1){
    test1(); // TEST1
    test2(); // TEST2
    test3(); // TEST3
    test4(); // TEST4
    test5(); // TEST4
    test6(); // TEST4
  }
}
