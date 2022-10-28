.section .text
Start:
		jsr Init_Q
		**lea.l DATA_QUE, %a0
		move.l #258, %d4
loop:
		move.b (%a0)+, %d1
		sub #1, %d4
		bcs loop2
		jsr IN_Q
		move.b %d0, (%a1)+
		bra loop

loop2:
		move.l #258, %d4
loop3:		
		sub #1, %d4
		bcs END
		jsr OUT_Q
		move.b %d1, (%a2)+
		move.b %d0, (%a3)+
		bra loop3
END:
		stop #0x2700
******************************
** INQ
******************************
IN_Q:		
		cmp.b #0x00, %d0/*noの値で分岐*/
		bne i_loop1
		jsr INQ0
		rts
i_loop1:
		jsr INQ1
		rts

INQ0:
		move.w %sr, -(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.w  s0, %d0 /* 書き込み許可フラグをd0レジスタへ(3) */
		sub.w  #0x100, %d0 /* 書き込み許可フラグ 0x00:禁止 | 0xff:許可 */
		beq     i0_Finish /* 0x100でキューが満杯なら終了 */
		movea.l in0, %a1 /* 書き込み用のポインタアドレスをa1レジスタへ (4)*/
		move.b  %d1, (%a1)+ /* データをキューへ入れ、書き込むデータアドレスと書き込み用ポインタを更新（+2） */
		lea.l botton0, %a2
		cmp.l  %a2, %a1 /* 次書き込もうとしているアドレスa1とキューデータ領域の末尾アドレスa3を比較 (5)*/
		bls     i0_STEP1 /* a1 < a3　ならば、そのままPUT_BUF_STEP1へ */
		lea.l top0, %a3
		move.l  %a3, %a1
i0_STEP1:
		move.l %a1, in0
		add.w #1, s0
		move.w  #1, %d0/* キューが一杯でなくなったので読み出し用ポインタを「許可」に */
i0_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */		
INQ1:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.w  s1, %d0 /* 書き込み許可フラグをd0レジスタへ(3) */
		sub.w  #0x100, %d0 /* 書き込み許可フラグ 0x00:禁止 | 0xff:許可 */
		beq     i1_Finish /* 0x100でキューが満杯なら終了 */
		movea.l in1, %a1 /* 書き込み用のポインタアドレスをa1レジスタへ (4)*/
		move.b  %d1, (%a1)+ /* データをキューへ入れ、書き込むデータアドレスと書き込み用ポインタを更新（+2） */
		lea.l botton1, %a2
		cmp.l  %a2, %a1 /* 次書き込もうとしているアドレスa1とキューデータ領域の末尾アドレスa3を比較 (5)*/
		bls     i1_STEP1 /* a1 < a2　ならば、そのままPUT_BUF_STEP1へ */
		lea.l top1, %a3
		move.l  %a3, %a1
	
i1_STEP1:
		move.l %a1, in1
		add.w #1, s1
		move.w  #1, %d0/* キューが一杯でなくなったので読み出し用ポインタを「許可」に */
i1_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */
******************************
** OUTQ
******************************
OUT_Q:		
		cmp.b #0x00, %d0/*noの値で分岐*/
		bne o_loop1
		jsr OUTQ0
		rts
o_loop1:
		jsr OUTQ1
		rts
OUTQ0:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.w  s0, %d0 /* 書き込み許可フラグをd0レジスタへ(3) */
		cmp.w  #0x00, %d0 /* 書き込み許可フラグ 0x00:禁止 | 0xff:許可 */
		beq     o0_Finish /* 0x100でキューが満杯なら終了 */
		movea.l out0, %a1 /* 書き込み用のポインタアドレスをa1レジスタへ (4)*/
		move.b  (%a1)+, %d1 /* データをキューへ入れ、書き込むデータアドレスと書き込み用ポインタを更新（+2） */
		lea.l botton0, %a2 
		cmp.l  %a2, %a1 /* 次書き込もうとしているアドレスa1とキューデータ領域の末尾アドレスa3を比較 (5)*/
		bls     o0_STEP1 /* a1 < a3　ならば、そのままPUT_BUF_STEP1へ */
		lea.l top0, %a3
		move.l  %a3, %a1
o0_STEP1:
		move.l %a1, out0
		sub.w #1, s0
		move.w  #1, %d0/* キューが一杯でなくなったので読み出し用ポインタを「許可」に */
o0_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */		
OUTQ1:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.w  s1, %d0 /* 書き込み許可フラグをd0レジスタへ(3) */
		cmp.w #0x00, %d0 /* 書き込み許可フラグ 0x00:禁止 | 0xff:許可 */
		beq     o1_Finish /* 0x100でキューが満杯なら終了 */
		movea.l out1, %a1 /* 書き込み用のポインタアドレスをa1レジスタへ (4)*/
		move.b  (%a1)+, %d1 /* データをキューへ入れ、書き込むデータアドレスと書き込み用ポインタを更新（+2） */
		lea.l botton1, %a2
		cmp.l  %a2, %a1 /* 次書き込もうとしているアドレスa1とキューデータ領域の末尾アドレスa3を比較 (5)*/
		bls     o1_STEP1 /* a1 < a3　ならば、そのままPUT_BUF_STEP1へ */
		lea.l top1, %a3
		move.l  %a3, %a1
o1_STEP1:
		move.l %a1, out1
		sub.w #1, s1
		move.w  #1, %d0/* キューが一杯でなくなったので読み出し用ポインタを「許可」に */
o1_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */
******************************
** キューの初期化
******************************
Init_Q:
lea.l top0, %a2
lea.l top1, %a3
move.l %a2, out0
move.l %a3, out1
move.l %a2, in0
move.l %a3, in1
move.l #0, s0
move.l #0, s1
rts





******************************
** キュー用のメモリ領域確保
******************************
.section .data
.equ B_SIZE, 256
top0:.ds.b B_SIZE-1
botton0:.ds.b 1
top1:.ds.b B_SIZE-1
botton1:.ds.b 1
out0:.ds.l 1
out1:.ds.l 1
in0:.ds.l 1
in1:.ds.l 1
s0:.ds.w 1
s1:.ds.w 1
**********
**sannpuru
**********
		.equ S2, 300
D1:	.ds.b S2
D2:	.ds.b S2
D3:	.ds.b S2
D4:		.ascii "ABCDEFGHIJKL"
		
		**DATA_QUE  .ascii "ABC"
		.end
