/* sample program fact.s 階乗  d1 := d0 ! (d0 >= 0)*/
.section .text
start:
	clr.l  %d0 /* d0初期化 */
	clr.l  %d2 /* d2初期化 */
	cmp    #0, %d1
	beq    end_of_program /* d1がゼロなら終了 */
loop:
	move   #1, %d2 /* d2乗算一時保存 */
	move   %d1, %d3 /* d3べき乗のカウンター */
power:
	mulu   %d1, %d2 /* d2にd1をかける */
	subi   #1, %d3 /* d3から1引く */
	bne    power /* d3が0になればべき乗終了 */
	add   %d2, %d0 /* d0にd2を入れる*/
	subi   #1, %d1 /* d1から1引く */
	beq    end_of_program /* d1がゼロになれば終了 */
	bra    loop /* d1がゼロでなければループ */


end_of_program:
	stop      #0x2700 /* 終了*/
