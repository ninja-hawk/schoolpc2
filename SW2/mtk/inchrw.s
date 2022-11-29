.global inbyte

.text
.even
	
inbyte:
	movem.l	%a0-%a1/%d1-%d3,-(%sp)
	lea.l	inbyte_buf, %a0	/* 一時保存領域 */
inbyte_do:	
	move.l	#1, %d0	/* GETSTRING呼び出し */
	move.l	%sp, %a1
	adda.l	#24, %a1
	move.l	(%a1), %d1 /* chを指定 */
	move.l	%a0, %d2	/* 一時保存領域に保存する */
	move.l	#1, %d3	/* 1文字だけ読み込む */
	trap	#0	/* 呼び出し */
	cmpi.l	#1, %d0	/* 結果確認 */
	bne	inbyte_do	/* 失敗した場合はリトライ */
	move.b	(%a0), %d0	/* 保存した文字を戻り値用領域にコピー */
	movem.l	(%sp)+, %a0-%a1/%d1-%d3
	rts

.section .bss
inbyte_buf:	ds.b 1	/* 一時保存領域 */
		.even
