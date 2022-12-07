.section .text

.global first_task
.global pv_handler
.global P
.global V
.global swtch
.global hard_clock
.global init_timer

.extern addq
.extern sched
.extern curr_task
.extern ready

     move.l #SYS_CALL2, 0x084 /*SYS_CALLの割り込みベクタ設定*/






pv_handler:
     movem.l %D0-%D7/%A0-%A6, -(%sp) |使用可能性のあるレジスタの退避
     movem.l %SR, -(%sp)  |SRの退避

****************************************************************
** hard_clock
** SW実験1で作成したタイマ用ハードウェア割り込み処理インターフェースから呼び出される
**
** このルーチン内で使用するレジスタをスーパーバイザスタックに積むが、
** タイマ割り込みで実行されるルーチンであるため退避忘れが多いらしい
****************************************************************

hard_clock:
	movem.l %D0-%D7/%A0-%A6, -(%sp)		|使用可能性のあるレジスタの退避
	move.w	%SR, %D0			|%SRを%D0へ
	btst.l	#13, %D0			|SRの13bit目を見てスーパーバイザか否かを確認
	bne	end_hard_clock			|13bit目が1でなければ、スーパーバイザモードでなければ終了
	jsr	addq				|current_taskをreadyの末尾に追加
	jsr	sched				|schedを起動し、次に実行されるタスクIDがnext_taskにセット
	jsr	swtch				|swtchの起動

end_hard_clock:
	movem.l (%sp)+, %D0-%D7/%A0-%A6  	|レジスタ復帰退避
	

init_timer:
	movem.l %D0-%D2, -(%sp) 	|使用可能性のあるレジスタの退避
	move.l	#3, %D3			|システムコールRESET_TIMERの番号
	trap	#0			|RESET_TIMER呼び出し
	move.l	#4, %D3			|システムコールSET_TIMERの番号
	move.l	#10000, %D1 		|割り込み発生周期は1秒に設定(p38)
	move.l	#hard_clock, %d2	|割り込み時に起動するルーチンの先頭アドレス
	trap	#0			|SET_TIMER呼び出し
	movem.l (%sp)+,%D0-%D2  	|SRの退避
	rte
