/*
 * Simple ld script to create a absolute s-record file. 
 * Since, the target address start with 0x0000,
 * You may have to use .org directive to change it.
 *
 *     .org    0x0000   ;; Nomraly 68000 has a vector table from 0x0000.
 *     DC.L    0x5000   ;; Set startup SSP in vector 0
 *     DC.L    START    ;; Set startup PC  in vector 1
 *
 *     .org 0x400       ;; Set start address.
 *     START:           ;; Place what you want to do.
 *
 * or send -Ttext xxxx option to ld.
 */





/* $Id: ldscript-as.cmd,v 1.2 2004/04/08 02:36:21 itimaru Exp $ */
/* Yoshinari Nomura <nom@csce.kyushu-u.ac.jp> */

OUTPUT_ARCH(m68k)
OUTPUT_FORMAT(srec)

SEARCH_DIR(.)

/* Memory Map of Soft Jikken board computer. */

MEMORY
{
/* Humble MC68VZ328 (DragonBallVZ) */ 
  ram (rwx) : ORIGIN = 0x000000, LENGTH = 0x040000
  rom0	    : ORIGIN = 0xc00000, LENGTH = 0x080000
  device    : ORIGIN = 0xfff000, LENGTH = 0x1000
/* CVME68K, Humo-680 */
/*  ram (rwx) : ORIGIN = 0x000000, LENGTH = 0x040000 */
/*  rom0      : ORIGIN = 0xfc0000, LENGTH = 0x020000 */
/*  device    : ORIGIN = 0xfffc00, LENGTH = 0x400 */
}

/*
 * allocate the stack to be at the top of memory, since the stack
 * grows down
 */

PROVIDE (__stack = 0x3fff0);

/*
 * stick everything in ram
 */
SECTIONS
{
  .text 0x000 :
  {
    *(.text)
  } > ram

  .data :
  {
    . = ALIGN(0x4);
    *(.data)
  } > ram

  .bss :
  {
    . = ALIGN(0x4);
    *(.bss)
  } > ram

  .stab 0 (NOLOAD) :
  {
    *(.stab)
  }

  .stabstr 0 (NOLOAD) :
  {
    *(.stabstr)
  }
}


