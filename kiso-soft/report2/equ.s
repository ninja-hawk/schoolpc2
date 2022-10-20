.section .text
start:
	move.l    B_SIZE, %d0
	move.l   #1, B_SIZE
	move.l   B_SIZE, %d1

.equ	B_SIZE, 2


start:
	move.l   0x02, %d0
	move.l   #1, 0x02
	move.l   0x02, %d1
