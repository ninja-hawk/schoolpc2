.section .text
start:
	.equ	X1, 15  /* C言語の「#define X1 15」と同じ意味 */
	.equ	X2, 10
	.equ	X3, 30
	.equ	X4, 12

	move.w	#X1, %d0
	sub.w	#X2, %d0
	move.w	#X3, %d0
	sub.w	#X4, %d0

	stop	#0x2700	/* 終了 */
.end
