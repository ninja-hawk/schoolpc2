/* sample program fact.s 階乗  d1 := d0 ! (d0 >= 0)*/
.section .text
start:
	clr.l  %d0 /* d0初期化 */
	clr.l  %d2 /* d2初期化 */
loop:
	add.l %d2, %d0 /* d2をd0に */
	cmp   #0, %d1
	beq   end_of_program /* d1がゼロなら終了 */
	move  %d1, %d2 /* d2乗算一時保存 */
	move  %d1, %d3 /* d3べき乗のカウンター */
	subq  #1,  %d3
power:
	mulu   %d1, %d2
	cmp    #0, %d3
	beq    loop
	subi   #1, %d3
	bra    power		


end_of_program:
	stop      #0x2700 /* 終了*/
