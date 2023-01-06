#include <stdarg.h>
#include <fcntl.h>
#include <errno.h>


extern void outbyte(int a,unsigned char c);
extern char inbyte(int b);

int read(int fd, char *buf, int nbytes){
  int ch;

  switch(fd){
  case 0:
  case 3:
      ch = 0;
      break;
      
  case 4:
      ch = 1;
      break;
      
  default:
      return EBADF;
      break;
  }
  char c;
  int  i;

  for (i = 0; i < nbytes; i++) {
    c = inbyte(ch);

    if (c == '\r' || c == '\n'){ /* CR -> CRLF */
        outbyte(ch, '\r');
        outbyte(ch, '\n');
        *(buf + i) = '\n';

 /* } else if (c == '\x8'){ */  /* backspace \x8 */
    } else if (c == '\x7f'){    /* backspace \x8 -> \x7f (by terminal config.) */
      if (i > 0){
          outbyte(ch, '\x8'); /* bs  */
          outbyte(ch, ' ');   /* spc */
          outbyte(ch, '\x8'); /* bs  */
	      i--;
      }
      i--;
      continue;

    } else {
        outbyte(ch, c);
        *(buf + i) = c;
    }

    if (*(buf + i) == '\n'){
        return (i + 1);
    }
  }
  return (i);
}

int write (int fd, char *buf, int nbytes){
  int i, j, ch;
  switch(fd){
   case 1:
   case 2:
   case 3:
       ch = 0;
       break;
       
   case 4:
       ch = 1;
       break;
       
   default:
       return EBADF;
  }
  for (i = 0; i < nbytes; i++) {
    if (*(buf + i) == '\n') {
      outbyte (ch, '\r');          /* LF -> CRLF */
    }
    outbyte (ch, *(buf + i));
    for (j = 0; j < 300; j++);
  }
  return (nbytes);
}


int fcntl(int fd, int cmd, ...) {
	if (cmd == F_GETFL) {
		return O_RDWR;

	} else {
		return 0;
	}


}


