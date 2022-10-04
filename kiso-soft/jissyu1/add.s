/*	sample program add.s */

.section .text
start:
	move.w	#3,x	/* x番地に3を格納 */
	move.w	#4,y	/* y番地に4を格納 */
	move.w	x, %d0  /* x番地の値をレジスタd0に格納 */
	add.w	y, %d0  /* y番地の値をレジスタd0に加える */
	move.w	%d0,z	/* レジスタd0の値をz番地に格納 */
	stop	#0x2700	/* 終了 */

.section .data
x:	.ds.w	1
y:	.ds.w	1
z:	.ds.w	1

.end

