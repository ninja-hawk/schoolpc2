extern void outbyte(unsigned char c);
extern char inbyte();

// Replace backspace keycode from '\x8' to BS defined as macro.
// #define BS '\x8'
#define XTBS '\x7f'
#define ASBS '\x8'

int read(int fd, char *buf, int nbytes)
{
  char c;
  int  i;

  for (i = 0; i < nbytes; i++) {
    c = inbyte();

    if (c == '\r' || c == '\n'){ /* CR -> CRLF */
      outbyte('\r');
      outbyte('\n');
      *(buf + i) = '\n';

    } else if (c == XTBS){      /* backspace */
      if (i > 0){
        outbyte(ASBS); /* bs  */
        outbyte(' ');   /* spc */
        outbyte(ASBS); /* bs  */
        i--;
      }
      i--;
      continue;

    } else {
      outbyte(c);
      *(buf + i) = c;
    }

    if (*(buf + i) == '\n'){
      return (i + 1);
    }
  }
  return (i);
}

int write (int fd, char *buf, int nbytes)
{
  int i, j;
  for (i = 0; i < nbytes; i++) {
    if (*(buf + i) == '\n') {
      outbyte ('\r');          /* LF -> CRLF */
    }
    outbyte (*(buf + i));
    for (j = 0; j < 300; j++);
  }
  return (nbytes);
}
