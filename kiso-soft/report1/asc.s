**
** Selection Sort
** ex2.s
**

.section .text
** Main Routine
start:
	lea.l  DATA,%a1   /* a1はソートするデータの先頭を指す*/
	jsr    SELECTION  /* 選択ソートのサブルーチンに分岐*/
	stop   #0x2700    /* 終了*/

** Sub Routine
SELECTION:
	movem.l  %d0-%d2/%a1-%a3,-(%a7)  /* レジスタの退避*/
	moveq.l  #LENGTH,%d0
	subq.w   #1,%d0   /* d0は外側のループの繰返回数= LENGTH -1 */
LOOP2:
	move.w   %a1,%a3   /* a3は最小値のデータの場所を表す*/
	move.w   (%a3),%d2 /* d2は最小値のデータを表す*/
	move.w   %a1,%a2
	adda.w   #2,%a2
	move.w   %d0,%d1   /* d1 = d0 */
LOOP1:
	cmp.w    (%a2),%d2
	bcs      LABEL1
	move.w   %a2,%a3
	move.w   (%a3),%d2
LABEL1:
	adda.w   #2,%a2  /* a2 <-a2 + 2 */
	subq.w   #1,%d1  /* d1 <-d1 -1 */
	bne      LOOP1   /* 内側のループの終了判定*/

	move.w   (%a1),(%a3) /* swap(a1,a3) */
	move.w   %d2,(%a1)
	
	adda.w   #2,%a1
	subq.w   #1,%d0
	bne      LOOP2   /* 外側のループの終了判定*/
	movem.l  (%a7)+,%d0-%d2/%a1-%a3  /* レジスタの回復*/
	rts

** Data Area
.section .data
	 .equ   LENGTH, 7
	DATA:  .dc.w  9,5,3,7,6,4,8
.end
