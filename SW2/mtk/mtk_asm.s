.section .text

.global first_task
.global pv_handler
.global P
.global V
.global swtch
.global hard_clock
.global init_timer


     move.l #SYS_CALL2, 0x084 /*SYS_CALLの割り込みベクタ設定*/






pv_handler:
     movem.l %D0-%D7/%A0-%A6, -(%sp) |使用可能性のあるレジスタの退避
     movem.l %SR, -(%sp)  |SRの退避


hard_clock:
	movem.l %D0-%D7/%A0-%A6, -(%sp) |使用可能性のあるレジスタの退避
	movem.l %SR, -(%sp)  |SRの退避
	

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
