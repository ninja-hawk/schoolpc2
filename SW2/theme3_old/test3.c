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

int main(void){
  init_kernel();
  init_file();
  
    while(1){
        char c[200];
        fprintf(com0out, "入力: ");
        fscanf(com1in, "%s", c);
        fprintf(com1out, "出力: %s\n", c);
    }
    
    return 0;
}

