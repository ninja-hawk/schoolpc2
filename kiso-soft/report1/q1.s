/*レポート１　問１実験用 */

.section .text
start:
	move.w	(%a0)+, (%a1)+
	move.w  #0x07F7, MASK
	move.w  MASK, %d0
	move.b  %A2,BOTTOM(%A0)
	move.w	BOTTOM, %d1

.section .data
	.equ TOP, 0xFFFC00
	.equ MASK, TOP+0x80
	.dc.b   'a','b','c','d','e',0
	.equ BOTTOM,        50


.end

