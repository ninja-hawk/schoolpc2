.section .bss

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
.extern next_task
.extern task_tab
.extern ready

.equ    SIZE_OF_TCB, 0x14
.equ IOBASE,    0x00d00000
.equ LED7,  IOBASE+0x000002f | ボード搭載のLED用レジスタ
.equ LED6,  IOBASE+0x000002d | 使用法については付録 A.4.3.1
.equ LED5,  IOBASE+0x000002b
.equ LED4,  IOBASE+0x0000029
.equ LED3,  IOBASE+0x000003f
.equ LED2,  IOBASE+0x000003d
.equ LED1,  IOBASE+0x000003b
.equ LED0,  IOBASE+0x0000039
.section .text
.even
swtch:
		* %SR,全レジスタの値をスタックに積む
		move.w %SR, -(%SP)
		movem.l %D0-%D7/%A0-%A6, -(%SP)
		move.l  %USP, %a0
		move.l	%a0, -(%SP)
		jsr     get_tcb_ssp              | %a0 <- TCBのSSPの位置
		move.l  %SP, (%a0)               | SSPをTCBの所定の位置に格納
        move.l  next_task, curr_task     
		jsr     get_tcb_ssp              | %a0 <- TCBのSSPの位置
		move.l  (%a0), %SP               | TCBに記録されているSSPを回復
		bra     end_swtch
get_tcb_ssp:
		move.l  curr_task, %d0           | %d0 = 現タスクのID 例 d0 = 2
		move.l  #SIZE_OF_TCB, %d1        | %d1 = TCBのサイズ voidが４バイトで要素が５個だから4*5
		mulu.w  %d0, %d1                 | 該当タスクのTCBにアクセスするためのオフセット
		lea.l   task_tab, %a0            | task_tabの先頭アドレス 
		adda.l  %d1, %a0                 | アドレスとオフセットを加算= 現
		adda.l  #4,  %a0                 | task_tab[ID].stack_ptrの位置を取得
		rts
end_swtch:	
        move.l  (%SP)+, %A0             
		move.l  %A0, %USP
		movem.l (%SP)+, %D0-%D7/%A0-%A6 | 各レジスタを復帰
		rte

pv_handler:

     movem.l %D0-%D7/%A0-%A6, -(%sp) |使用可能性のあるレジスタの退避
     move.w %SR, -(%sp)  |SRの退避
     move.w #0x2700, %SR  |走行レベルを７へ
     movem.l %D1, -(%sp)  |D1を引数としてスタックに積む
     
     cmp.l  #0, %D0       |Pからの呼び出しの場合
     beq    p_order
     cmp.l  #1, %D0       |Qからの呼び出しの場合
     beq    v_order
     
p_order:

     jsr p_body      |p命令実行
     bra end_pv_handler

v_order:
     jsr v_body      |v命令実行
     bra end_pv_handler
     
end_pv_handler: 
     add.l #4, %sp        |引数(d1)分spを上げる
     move.w (%sp)+, %SR  |SRを復帰
     movem.l (%sp)+, %D0-%D7/%A0-%A6  |レジスタの復帰
     rte
     

P:
     movem.l %D0-%D1, -(%sp)
     move.l #0, %D0        |PシステムコールのID＝０をD0レジスタに
     move.l  12(%sp) ,%D1   |スタックに入っている引数をD1に（d0-d1+戻り番地のPC= 12）
     trap #1
     movem.l (%sp)+, %D0-%d1
     rts
     
V:
     movem.l %D0-%D1, -(%sp)
     move.l #1, %D0        |VシステムコールのID＝1をD0レジスタに
     move.l  12(%sp) ,%D1  |スタックに入っている引数をD1に（d0-d1+戻り番地のPC= 12）
     trap #1
     movem.l (%sp)+, %D0-%d1
     rts
     
****************************************************************
** hard_clock
** SW実験1で作成したタイマ用ハードウェア割り込み処理インターフェースから呼び出される
**
** このルーチン内で使用するレジスタをスーパーバイザスタックに積むが、
** タイマ割り込みで実行されるルーチンであるため退避忘れが多いらしい
****************************************************************

hard_clock:
        movem.l %D0-%D7/%A0-%A6, -(%sp)         | 使用可能性のあるレジスタの退避
        move.w  %SR, %D0                        | %SRを%D0へ
        btst.l  #13, %D0                        | SRの13bit目を見てスーパーバイザか否かを確認
        beq     end_hard_clock                  | 13bit目が1でなければ、スーパーバイザモードでなければ終了
        move.l  curr_task, -(%sp)
        move.l  #ready,   -(%sp)
       
        jsr     addq                            | current_taskをreadyの末尾に追加
        add.l   #8, %sp
	
        jsr     sched                           | schedを起動し、次に実行されるタスクIDがnext_taskにセット
	
        jsr     swtch                           | swtchの起動
	

end_hard_clock:
        movem.l (%sp)+, %D0-%D7/%A0-%A6         |レジスタ復帰退避
        rts

init_timer:
        movem.l %D0-%D2, -(%sp)         | 使用可能性のあるレジスタの退避
        move.l  #3, %D0                 | システムコールRESET_TIMERの番号
        trap    #0                      | RESET_TIMER呼び出し
        move.l  #4, %D0                 | システムコールSET_TIMERの番号
        move.w  #1, %D1                 | 割り込み発生周期は1秒に設定(p38)
        move.l  #hard_clock, %d2        | 割り込み時に起動するルーチンの先頭アドレス
        trap    #0                      | SET_TIMER呼び出し
        movem.l (%sp)+,%D0-%D2          | SRの退避
        rts

**************************
**first_task
*************************
first_task:
	    move.l curr_task, %d0     /* TCB先頭番地の計算 */
        lea.l  task_tab, %a1      /* 見つけたアドレスを%a1に */
loop_first_task:
        subq.l #1, %d0            /* 配列の何番目なのか計算 */
        add.l  #0x14, %a1         /* %a1:先頭アドレス */
        cmp    #0, %d0
        bne    loop_first_task
        /*USP,SSPの値の回復*/
        add.l   #4, %a1           /* a1にTCBのSSP */
        move.l  (%a1), %ssp

        movem.l (%sp)+, %a0
        move.l  %a0, %usp
        movem.l (%sp)+, %d0-%d7/%a0-%a6

		rte                       /*rte*/

