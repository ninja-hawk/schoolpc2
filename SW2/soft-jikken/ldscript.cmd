/*
 * Ld script to create a absolute s-record file using newlib m68k.
 * (newlib m68k is in FreeBSD ports collection.)
 * .text section starts with 0x400 to avoid vector table.
 * Also, we have addtional .vector section starts with 0x0000.
 */

/* $Id: ldscript.cmd,v 1.3 2004/04/08 02:36:27 itimaru Exp $ */
/* Yoshinari Nomura <nom@csce.kyushu-u.ac.jp> */

/* Shigemi ISHIDA <ishida@f.ait.kyushu-u.ac.jp>
 * Updated on: 2017/10/16
 *   update search dir.
 */


/* STARTUP(crt0.o) */
OUTPUT_ARCH(m68k)
OUTPUT_FORMAT(srec)

SEARCH_DIR(.)
SEARCH_DIR(/usr/local/lib/gcc/m68k-elf/5)

GROUP(-lidp -lc -lgcc)
__DYNAMIC  =  0;

/*
 * Setup the memory map of the MC68ec0x0 Board (IDP)
 * stack grows down from high memory. This works for
 * both the rom68k and the mon68k monitors.
 *
 * The memory map look like this:
 * +--------------------+ <- low memory
 * | .text              |
 * |        _etext      |
 * |        ctor list   | the ctor and dtor lists are for
 * |        dtor list   | C++ support
 * +--------------------+
 * | .data              | initialized data goes here
 * |        _edata      |
 * +--------------------+
 * | .bss               |
 * |        __bss_start | start of bss, cleared by crt0
 * |        _end        | start of heap, used by sbrk()
 * +--------------------+
 * .                    .
 * .                    .
 * .                    .
 * |        __stack     | top of stack
 * +--------------------+
 */

/*
 * When the IDP is not remapped (see rom68k's MP command in the
 * "M68EC0x0IDP Users Manual", the first 64K bytes are reserved;
 * Otherwise the first 256K bytes are reserved.
 *
 * The following memory map describes a unmapped IDP w/2MB RAM.
 */

MEMORY
{
  ram (rwx) : ORIGIN = 0x000000, LENGTH = 0x040000
  rom0	    : ORIGIN = 0xc00000, LENGTH = 0x080000
  device    : ORIGIN = 0xfff000, LENGTH = 0x1000
}

/*
 * allocate the stack to be at the top of memory, since the stack
 * grows down
 */

PROVIDE (__stack = 0x3fff0);

/*
 * Initalize some symbols to be zero so we can reference them in the
 * crt0 without core dumping. These functions are all optional, but
 * we do this so we can have our crt0 always use them if they exist. 
 * This is so BSPs work better when using the crt0 installed with gcc.
 * We have to initalize them twice, so we cover a.out (which prepends
 * an underscore) and coff object file formats.
 */
PROVIDE (hardware_init_hook  = 0);
PROVIDE (_hardware_init_hook = 0);
PROVIDE (software_init_hook  = 0);
PROVIDE (_software_init_hook = 0);
/*
 * stick everything in ram (of course)
 */
SECTIONS
{
  .vector 0x000 :
  {
    *(.vector)
  } > ram

  .text 0x400 :
  {
    __text_start = .;
    *(.text)
    . = ALIGN(0x4);
     __CTOR_LIST__ = .;
    ___CTOR_LIST__ = .;
    LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
    *(.ctors)
    LONG(0)
    __CTOR_END__ = .;
    __DTOR_LIST__ = .;
    ___DTOR_LIST__ = .;
    LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
    *(.dtors)
     LONG(0)
    __DTOR_END__ = .;
    *(.rodata)
    *(.gcc_except_table) 

    __INIT_SECTION__ = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.init)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    __FINI_SECTION__ = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.fini)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    _etext = .;
    *(.lit)
  } > ram

  .data :
  {
    *(.shdata)
    *(.data)
    _edata = .;
  } > ram

  .bss :
  {
    . = ALIGN(0x4);
    __bss_start = . ;
    *(.shbss)
    *(.bss)
    *(COMMON)
    _end =  ALIGN (0x8);
    __end = _end;
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

