**	lenz.s
**	$00で終了するデータの長さを求めるプログラム
**

**
**	STRから始めて、$00が見つかるまで
**	1バイトずつカウントする
**	カウント結果はレジスタd0に格納する
**

.section .text
start:
	clr.l	%d0	/* clrは指定されたレジスタ(d0)を0でクリア  */
	lea	STR, %a0
SLEN_LP:	
	move.b	(%a0)+, %d1
	cmpi.b	#0, %d1	/* d1と0を比較  */
	beq	STR_END
	addq.l	#1, %d0	/* 1カウントアップする  */
	bra	SLEN_LP

STR_END:	
	** 実行の終り
	stop	#0x2700	/* 終了 */

.section .data
STR:	.dc.b	'm','i','s','s','i','s','s','i','p','p','i',0	
.end
