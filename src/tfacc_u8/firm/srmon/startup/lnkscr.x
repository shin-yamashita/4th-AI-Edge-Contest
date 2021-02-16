OUTPUT_FORMAT("elf32-sr")
OUTPUT_ARCH(sr)

/* 2012/10/21 64k -> 96k	*/
/* 2012/12/18 96k -> 64k	*/
/* 2015/09/12 96k -> 128k	*/
MEMORY
{
  ram    : o = 0x00000000, l = 0x00007f00
  stack  : o = 0x00007ff0, l = 0x00000010
}
SECTIONS
{
  .text :
  {
     _stext = . ; 
    *(.vector)
	. = 0x200;
    *(.text*)
    *(.rodata*)
    *(.strings)
     _etext = . ; 
  }  > ram
  .data : AT ( ADDR (.text) + SIZEOF (.text) )
  {
     _sdata = . ; 
    *(.data)
     _edata = . ; 
  }  > ram
  .bss :
  {
     _bss_start = . ; 
    *(.bss)
    *(COMMON)
     _end = . ;  
  }  > ram
  .stack :
  {
     _stack_top = . ; 
    *(.stack)
  } > stack

  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }

}
