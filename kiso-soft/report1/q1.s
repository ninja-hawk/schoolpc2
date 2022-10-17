/*レポート１　問１実験用 */

.section .text
start:
	move.w	(%a0)+, (%a1)+
	move.w  #0x07F7, MASK

.section .data
	.equ TOP, 0xFFFC00
	.equ MASK, TOP+0x80
		

.end

