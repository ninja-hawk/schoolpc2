.global outbyte
.equ SYSCALL_NUM_PUTSTRING,     2

.text
.even

outbyte:
	movem.l %d0-%d3/%a1, -(%sp)
outbyte_step0:

	**引数のchを取る
	lea.l (%sp), %a1
	move.l #24, %d2	/*4xレジスタ5個+PC分4*/
	add.l %d2, %a1
	move.l (%a1), ch

	**引数の文字を取る
	move.l #7, %d2
	add.l %d2, %a1
	move.b (%a1), buf
	
	move.l #SYSCALL_NUM_PUTSTRING,%D0
	move.l ch,    %d1        | ch = ch
	move.l #buf,  %d2        | p  = #BUF
	move.l #1,    %d3        | size = 1
	trap #0

	cmpi.l #1, %d0
	bne outbyte_step0
	movem.l (%sp)+, %d0-%d3/%a1
	rts
	
	.section .bss
buf:
	.ds.b 1
	.even
ch:
	.ds.l 1
	.even	/*ここのevenは必要*/
