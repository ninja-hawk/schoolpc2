/*	 sample program sub.s               */
/*     間違った箇所が3つあります    */
/*     正しくプログラムが動くように修正せよ */

.section .text
start	
	move.w	#9,x	/* x番地に9を格納 */
	move.w	#4,y	/* y番地に4を格納 */
	move.w	x, %d0  /* c番地の値をレジス夕d0に格納 */
	sub.w	y, %d0  /* y番地の値をレジスタd0から引く */
	move.w	%do,z	/* レジスタd0の値をz番地に格納 */  
	stop	#0x2700	/* 終了 */

.section .data
x:	.ds,w	1	
y:	.ds.w	1
z:	.ds.w	1

.end
