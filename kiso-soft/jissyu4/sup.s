**
** 順列計算の総和を求めるプログラム
**min.s
**
.section .text
**--------------------------------------
** メインルーチン
**--------------------------------------
start:
	move.l  #0x12345678, %d1 /* レジスタ退避を学ぶため、わざとレジスタd1に値を入れている*/
	lea.l   DATA,%a1/* サブルーチンに移る前の準備としてa1にDATAのアドレスを格納 */
	jsr SUP   /* SUPサブルーチンに移す */
	stop    #0x2700
**---------------------------------------
** サブルーチン（順列計算の総和）
** 入力（引き数）%a1:探索対象データの先頭アドレス
** 出力（戻り値）%d0  :結果(総和)
** nPrのrの部分　%d1
** nPrのnの部分　%d2 （=7）
** 乗算一時保存用%d3
** データ長保存用%d4
**---------------------------------------
SUP:
	movem.l  %a1/%d1,-(%a7)   /* レジスタの退避（push）（a1,d1の値をスタックに格納する） */
	clr.l    %d0 /* d0初期化 */
	clr.l    %d1 /* d1初期化 */
	clr.l    %d2 /* d2初期化 */
	clr.l    %d3 /* d3初期化 */
	moveq.l  #LENGTH,%d4 /* d4 = LENGTH - 4 */
LOOP:
	cmp      #0, %d4
	beq      BACK2MAIN  /* データをすべて探索したらメインルーチンに */
	move.w   (%a1)+, %d1 /* d1にデータを入れる a1のアドレスを+2 */ 
	move     #7, %d2
	move     #1, %d3
PERM:
	mulu     %d2, %d3
	subi     #1, %d2
	subi     #1, %d1
	bne      PERM
	add      %d3, %d0
	subi     #1, %d4
	bra      LOOP

BACK2MAIN:
	movem.l  (%a7)+,%a1/%d1   /* レジスタの復帰（pop）   */
	rts /* サブルーチン呼び出し元に戻る */
**---------------------------------------
** データエリア
**---------------------------------------
.section .data
	.equ   LENGTH, 12  /* データの個数 */
	DATA:   dc.w   7,5,3,2,6,4,5,1,5,1,6,7
