***************************************************************
** 各種レジスタ定義
***************************************************************

***************
** レジスタ群の先頭
***************
.equ REGBASE, 0xFFF000  | DMAP を使用.
.equ IOBASE,  0x00d00000

***************
** 割り込み関係のレジスタ
***************
.equ IVR,     REGBASE+0x300 | 割り込みベクタレジスタ
.equ IMR,     REGBASE+0x304 | 割り込みマスクレジスタ
.equ ISR,     REGBASE+0x30c | 割り込みステータスレジスタ
.equ IPR,     REGBASE+0x310 | 割り込みペンディングレジスタ


***************
** タイマ関係のレジスタ
***************
.equ TCTL1,   REGBASE+0x600 | タイマ1コントロールレジスタ
.equ TPRER1,  REGBASE+0x602 | タイマ1プリスケーラレジスタ
.equ TCMP1,   REGBASE+0x604 | タイマ1コンペアレジスタ
.equ TCN1,    REGBASE+0x608 | タイマ1カウンタレジスタ
.equ TSTAT1,  REGBASE+0x60a | タイマ1ステータスレジスタ
***************
** UART1 (送受信)関係のレジスタ
***************
.equ USTCNT1, REGBASE+0x900 | UART1 ステータス / コントロールレジスタ
.equ UBAUD1,  REGBASE+0x902 | UART1 ボーコントロールレジスタ
.equ URX1,    REGBASE+0x904 | UART1 受信レジスタ
.equ UTX1,    REGBASE+0x906 | UART1 送信レジスタ
***************
** LED
***************
.equ LED7,  IOBASE+0x000002f | ボード搭載のLED用レジスタ
.equ LED6,  IOBASE+0x000002d | 使用法については付録 A.4.3.1
.equ LED5,  IOBASE+0x000002b
.equ LED4,  IOBASE+0x0000029
.equ LED3,  IOBASE+0x000003f
.equ LED2,  IOBASE+0x000003d
.equ LED1,  IOBASE+0x000003b
.equ LED0,  IOBASE+0x0000039

**************
**システムコール番号
**************
.equ SYSCALL_NUM_GETSTRING,    1
.equ SYSCALL_NUM_PUTSTRING,    2
.equ SYSCALL_NUM_RESET_TIMER,  3
.equ SYSCALL_NUM_SET_TIMER,    4

***************************************************************
** スタック領域の確保
***************************************************************
.section .bss
.even
SYS_STK:
		.ds.b  0x4000 | システムスタック領域
		.even
SYS_STK_TOP: 		      | システムスタック領域の最後尾

task_p:		.ds.l 1		| タイマ割り込み時に起動するルーチン先頭アドレス代入用

***************************************************************
** 初期化
** 内部デバイスレジスタには特定の値が設定されている.
** その理由を知るには,付録 B にある各レジスタの仕様を参照すること.
***************************************************************
.section .text
.even
boot:
		* スーパーバイザ & 各種設定を行っている最中の割込禁止
		move.w #0x2700,%SR
		lea.l SYS_STK_TOP, %SP | Set SSP
		****************
		** 割り込みコントローラの初期化
		****************
		move.b #0x40, IVR      | ユーザ割り込みベクタ番号を
		                       | 0x40+level に設定.
		/* 要確認　！！ */
		move.l #0x00ff3fff,IMR | 全割り込みマスク
		****************
		** 送受信 (UART1) 関係の初期化 ( 割り込みレベルは 4 に固定されている )
		****************
		move.l #UART1_interrupt, 0x110  | 受信割り込みベクタをセット
		move.w #0x0000, USTCNT1 | リセット
		/* バグの原因はここ(下)であることが多い  */
		move.w #0xe10c, USTCNT1 | 送受信可能 , パリティなし , 1 stop, 8 bit, /* 変更 */
					| 受信割り込み許可, 送割り込み禁止
		move.w #0x0038, UBAUD1  | baud rate = 230400 bps
		****************
		** タイマ関係の初期化 ( 割り込みレベルは 6 に固定されている )
		*****************
		move.w #0x0004, TCTL1   | restart, 割り込み不可 ,
					| システムクロックの 1/16 を単位として計時,
					| タイマ使用停止
	        move.l #COMPARE_INTERPUT, 0x118 /* level 6 */

                move.l #SYS_CALL, 0x080 /*SYS_CALLの割り込みベクタ設定*/

		******************************
		** キューの初期化
		******************************
		lea.l  top0, %a2
		lea.l  top1, %a3
		move.l %a2, out0
		move.l %a3, out1
		move.l %a2, in0
		move.l %a3, in1
		move.l #0, s0
		move.l #0, s1
	
		move.l #0x00ff3ff9, IMR
		bra MAIN
	
****************************************************************
***プログラム領域
****************************************************************
.section .text
.even
MAIN:
**走行モードとレベルの設定(「ユーザモード」への移行処理)
move.w #0x0000, %SR  | USER MODE, LEVEL 0
lea.l USR_STK_TOP,%SP  | user stackの設定
**システムコールによるRESET_TIMERの起動
move.l #SYSCALL_NUM_RESET_TIMER,%D0
trap   #0
**システムコールによるSET_TIMERの起動
move.l #SYSCALL_NUM_SET_TIMER, %D0
move.w #50000, %D1
move.l #TT,%D2
trap #0
******************************
* sys_GETSTRING, sys_PUTSTRINGのテスト
*ターミナルの入力をエコーバックする
******************************
LOOP:
move.l #SYSCALL_NUM_GETSTRING, %D0
move.l #0,   %D1        | ch    = 0
move.l #BUF, %D2        | p    = #BUF
move.l #256, %D3        | size = 256
trap #0
move.l %D0, %D3         | size = %D0 (length of given string)
move.l #SYSCALL_NUM_PUTSTRING, %D0
move.l #0,  %D1         | ch = 0
move.l #BUF,%D2         | p  = #BUF
trap #0
bra LOOP
******************************
*タイマのテスト
* ’******’を表示し改行する．
*５回実行すると，RESET_TIMERをする．
******************************
TT:
move.b	#'T', LED3
move.b	#'T', LED2
move.b	#'T', LED1
move.b	#'T', LED0
movem.l %D0-%D7/%A0-%A6,-(%SP)
cmpi.w #5,TTC            | TTCカウンタで5回実行したかどうか数える
beq TTKILL               | 5回実行したら，タイマを止める
bra TT
move.l #SYSCALL_NUM_PUTSTRING,%D0
move.l #0,    %D1        | ch = 0
move.l #TMSG, %D2        | p  = #TMSG
move.l #8,    %D3        | size = 8
trap #0
addi.w #1,TTC            | TTCカウンタを1つ増やして
bra TTEND                |そのまま戻る
TTKILL:
move.l #SYSCALL_NUM_RESET_TIMER,%D0
trap #0
TTEND:
movem.l (%SP)+,%D0-%D7/%A0-%A6
rts

****************************************************************
***初期値のあるデータ領域****************************************************************
.section .data
TMSG:
.ascii  "******\r\n"      | \r:行頭へ(キャリッジリターン)
.even                     | \n:次の行へ(ラインフィード)
TTC:
.dc.w  0
.even

****************************************************************
***初期値の無いデータ領域****************************************************************
.section .bss
BUF:
.ds.b 256           | BUF[256]
.even
USR_STK:
.ds.b 0x4000            |ユーザスタック領域
.even
USR_STK_TOP:           |ユーザスタック領域の最後尾		

******************************
** キュー用のメモリ領域確保
******************************
.section .data
.equ B_SIZE, 256
top0:
		.ds.b B_SIZE-1
bottom0:
		.ds.b 1
top1:
		.ds.b B_SIZE-1
bottom1:
		.ds.b 1
out0:
		.ds.l 1
out1:
		.ds.l 1
in0:
		.ds.l 1
in1:
		.ds.l 1
s0:
		.ds.w 1
s1:
		.ds.w 1

******************************
** COMPARE_INTERPUT:	タイマ用のハードウェア割り込みインターフェース
******************************
COMPARE_INTERPUT:
		movem.l %d0, -(%sp) /* d0退避 */
		move.w  TSTAT1, %d0 /* TSTATの値をd0へ */
		btst	#0, %d0 /* タイマ1ステータスレジスタの0ビット目が0か、否か */
		beq	COMPARE_END /* 0ならコンペアイベントなし、つまりカウンタ値とコンペアレジスタ値が異なる */
		move.w	#0x0000, TSTAT1 /* タイマ1ステータスレジスタを0クリア */
		jsr	CALL_RP /* CALL_RPを呼び出す */

COMPARE_END:
		movem.l (%sp)+, %d0 /* d0復帰 */
		rte

*************************************
** UART1_interrupt
** 送受信割り込みを扱うインターフェース
*************************************
/* btst : 指定データの指定ビットが0であるか判断し、0であればCCRのZをセット */		
UART1_interrupt:
		/* 受信FIFOが空でないとき(URX[13]==1)受信割り込みであると判断 */
		/* URX[13] ->  0: 受信FIFOが空, 1: 受信FIFOが空でない */
		move.w URX1, %d3
		move.b %d3, %d2       |  %d3.wの下位8bitを%d2.bにコピー
		btst.l #13, %d3       |  13ビット目は受信FIFOにデータが存在するか
		beq    CALL_INTERPUT  |  if URX1[13] == 0 (受信FIFOが空のとき)
		move.l #0, %d1        |  ch = 0 を明示
		jsr    INTERGET       |  受信割り込み時処理
		bra    END_interrupt
CALL_INTERPUT:
		/* 送信FIFOがに空のとき(UTX[15]==1)送信割り込みであると判断 */
		/* UTX[15] ->  0: 送信FIFOが空でない, 1: 送信FIFOが空 */
        move.w UTX1, %d3
		btst.l #15, UTX1      |  15ビット目は送信FIFOが空であるか
		beq    END_interrupt  |  if UTX1[15] == 0 (送信FIFOが空でないとき終了)
		move.l #0, %d1        |  ch = 0 を明示
		jsr    INTERPUT       |  送信割り込み時処理
END_interrupt:
		rte

*************************************
** INTERGET  受信割り込みルーチン	
** 引数     :  %d1.l = チャネル(ch)	
**             %d2.b = 受信データdata
**戻り値　なし		
*************************************
INTERGET:
		cmp    #0, %d1 /*(1)*/
		bne    END_INTERGET
		move.l #0, %d0 /*(2)INQ(引数:d0,d1 戻り値:d0)*/
		move.b %d2, %d1
		jsr    IN_Q
END_INTERGET:
		rts

*************************************
** INTERPUT :  送信割り込み時の処理	
** 引数     :  %d1.l = チャネル(ch)	
*************************************
INTERPUT:
		move.w  #0x2700, %SR | 走行レベルを７に設定
		cmpi.l  #0, %d1      | ch = 0 を確認
		bne     END_INTERPUT | if ch != 0 => 復帰
		jsr     OUT_Q        | %d1.b = data
		cmpi    #0, %d0      | %d0(OUTQの戻り値) == 0(失敗)
		bne     TX_DATA      | if so => 送信割り込みをマスク(真下)
		move.w  #0xe108, USTCNT1
		bra     END_INTERPUT
TX_DATA:
		add.w   #0x0800, %d1 | ヘッダを付与
		move.w  %d1, UTX1
END_INTERPUT:
		rts

******************************
** INQ
**入力キュー番号,d0.l 書き込むデータ,d1.b
**出力 d0,成功1, 失敗0
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
		move.w  s0, %d0 /* sの値で実行可能か判別(3) */
		sub.w  #0x100, %d0 /* sが256のときd0を 0x0:失敗 */
		beq     i0_Finish /* sが0x100でキューが満杯なら終了 */
		movea.l in0, %a1 /* 書き込み用のポインタアドレスをa1レジスタへ (4)*/
		move.b  %d1, (%a1)+ /* データをキューへ入れ、書き込み用ポインタを更新（+2） */
		lea.l bottom0, %a2/* 次書き込もうとしているアドレスa1とキューデータ領域の末尾アドレスa2を比較 (5)*/
		cmp.l  %a2, %a1 
		bls     i0_STEP1 /* a1 < a2　ならば、そのままSTEP1へ(in++) */
		lea.l top0, %a3 /*in=top*/
		move.l  %a3, %a1
i0_STEP1:
		move.l %a1, in0 
		add.w #1, s0
		move.w  #1, %d0/* 処理をおこなうことができたのでd0を1に */
i0_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */		
INQ1:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.w  s1, %d0  /* sの値で実行可能か判別(3) */
		sub.w  #0x100, %d0  /* sが256のときd0を 0x0:失敗 */
		beq     i1_Finish /* 0x100でキューが満杯なら終了 */
		movea.l in1, %a1 /* 書き込み用のポインタアドレスをa1レジスタへ (4)*/
		move.b  %d1, (%a1)+ /* データをキューへ入れ、書き込み用ポインタを更新（+2） */
		lea.l bottom1, %a2/* 次書き込もうとしているアドレスa1とキューデータ領域の末尾アドレスa2を比較 (5)*/
		cmp.l  %a2, %a1 
		bls     i1_STEP1 /* a1 < a2　ならば、そのままSTEP1へ(in++) */
		lea.l top1, %a3/*in=top*/
		move.l  %a3, %a1
	
i1_STEP1:
		move.l %a1, in1
		add.w #1, s1
		move.w  #1, %d0/* 処理をおこなうことができたのでd0を1に */
i1_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */
		
******************************
** OUTQ
** 入力:
**  キュー番号:d0.l
**      0 -> 受信, 1 -> 送信
** 出力:d0:0失敗, d0:1成功
** 取り出したデータ:d1.b
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
		move.w  s0, %d0 /* sの値によって実行できるか判定(3) */
		cmp.w  #0x00, %d0 /* sが0のときd0を0x0:失敗  */
		beq     o0_Finish /* 0x0でキューが空なら終了 */
		movea.l out0, %a1 /* 次に取り出すのポインタアドレスをa1レジスタへ (4)*/
		move.b  (%a1)+, %d1 /* キューからデータを読み出し、d1に転送 */
		lea.l bottom0, %a2 /*次に読み出そうとしているアドレスとキュー領域の末尾アドレスを比較(5)*/
		cmp.l  %a2, %a1 
		bls     o0_STEP1 /* a1 < a2　ならばSTEP1へ(out++) */
		lea.l top0, %a3 /*out=top*/
		move.l  %a3, %a1
o0_STEP1:
		move.l %a1, out0
		sub.w #1, s0 /*s--*/
		move.w  #1, %d0/* 処理できたのでd0を1に */
o0_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */		
OUTQ1:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.w  s1, %d0 /* sの値によって実行できるか判定(3) */
		cmp.w #0x00, %d0 /* sが0のときd0を0x0:失敗  */
		beq     o1_Finish /* 0x0でキューが空なら終了 */
		movea.l out1, %a1 /* 次に取り出すのポインタアドレスをa1レジスタへ (4)*/
		move.b  (%a1)+, %d1 /* キューからデータを読み出し、d1に転送 */
		lea.l bottom1, %a2/*次に読み出そうとしているアドレスとキュー領域の末尾アドレスを比較(5)*/
		cmp.l  %a2, %a1 
		bls     o1_STEP1/* a1 < a2　ならばSTEP1へ(out++) */
		lea.l top1, %a3/*out=top*/
		move.l  %a3, %a1
o1_STEP1:
		move.l %a1, out1
		sub.w #1, s1
		move.w  #1, %d0/* 処理できたのでd0を1に */
o1_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */

*************************************
** PUTSTRING  送信割り込みの処理	
** 引数     :  %d1.l = チャネル(ch)	
**             %d2.l = データ読み込み先の先頭アドレスp いったんa6にさせて
**             %d3.l = 送信するデータ数size
** szはd4レジスタ
** iはa5レジスタ
*************************************
PUTSTRING:
		cmp #0, %d1
		bne END_PUTSTRING
		move.w #0, %d4
		move.l %d2, %a5 /**/
		cmp #0, %d3
		beq END2_PUTSTRING
LOOP1_PUTSTRING:
		cmp %d4, %d3
		beq END3_PUTSTRING
		move.b #1, %d0
		move.b (%a5), %d1
		jsr IN_Q
		cmp #0, %d0
                beq END3_PUTSTRING
		add #1, %d4
		add #1, %a5 
		bra LOOP1_PUTSTRING
END3_PUTSTRING:
                
		move.w  #0xe10c, USTCNT1
END2_PUTSTRING:
		move %d4, %d0
END_PUTSTRING:
		rts


		
*************************************
** GETSTRING  受信割り込みの処理	
** 引数     :  %d1.l = チャネル(ch)
** 	       %d2.l = データ書き込み先の先頭アドレスp
**             %d3.l = 取り出すデータ数size
** szはd4レジスタ
** iはa5レジスタ
**戻り値　実際に取り出したデータ数sz:%d0.l		
*************************************
GETSTRING:
		cmp    #0, %d1 /*(1)*/
		bne    END_GETSTRING 
		move.w #0, %d4 /*(2)*/
		move.l %d2, %a5
LOOP1_GETSTRING:	
		cmp    %d4, %d3 /*(3)*/
		beq    END2_GETSTRING
		move.b #0, %d0 /*(4) d0:成功かどうか, d1:取り出したデータ*/
		jsr    OUT_Q
		cmp    #0, %d0 /*(5)*/
		beq    END2_GETSTRING
		move.b %d1, (%a5)+ /*(6)*/
		add    #1, %d4 /*(7)*/
		bra    LOOP1_GETSTRING
END2_GETSTRING:
		move   %d4, %d0
END_GETSTRING:
		rts

******************************
** RESET_TIMER():	タイマ割り込み→不可、タイマ→停止
******************************
RESET_TIMER:
		move.w	#0x0004, TCTL1 /* タイマ1コントロールレジスタに0x0004を設定→割り込み不可、(SYSCLK/16選択)、タイマ禁止 */
		rts
		
******************************
** SET_TIMER(t,p):	タイマ割り込み時に呼び出すルーチン設定 
**			タイマ割り込み周期tを設定（t * 0.1 msec毎に割り込み発生）
**			タイマ使用およびタイマ割り込み	
** 引数 :		t→%d1.w:	タイマの発生周期
** 			p→%d2.l	割り込み時に起動するルーチンの先頭アドレス			
******************************
SET_TIMER:
		move.l	%d2, task_p /* 割り込み時に起動するルーチンの先頭アドレスpを大域変数task_pへ */
		move.w	#0206, TPRER1 /* 0.1msec進むとカウンタが1増えるようにする */
		move.w	%d1, TCMP1 /* t秒周期に設定 */
		move.w  #0x0015, TCTL1 /* タイマ1コントロールレジスタに0x0015を設定→割り込み許可、(SYSCLK/16選択)、タイマ許可 */
		move.b	#'t', LED7
		move.b	#'e', LED6
		move.b	#'s', LED5
		move.b	#'t', LED4	
		rts

******************************
** CALL_RP():	タイマ割り込み時に処理すべきルーチン呼び出し
******************************
CALL_RP:
		movem.l	%a0, -(%sp)
		movea.l task_p, %a0
		jsr (%a0)
		movem.l (%sp)+, %a0
		rts

*******************************************
** システムコールインターフェース
** 入力：
**　　　　システムコール番号   : %d0.l
**　　　　システムコールの引数 : %d1以降
** 出力：
**　　　　システムコール呼び出しの結果 : %d0.l
** ========================================		
**        +---+---------------+
**        | 1 | GETSTRING     |
**        | 2 | PUTSTRING     |
**        | 3 | RESET_TIMER   |
**        | 4 | SET_TIMER     |
**        +---+---------------+
*******************************************
SYS_CALL:
		
CALL_1:		
		cmpi.l #1, %d0   | コール番号の確認(no.1)
		bne    CALL_2    | 異なれば他のコール番号の確認
		jsr    GETSTRING | 対応するシステムコールを呼び出し
                bra    END_SYS_CALL
CALL_2:
		cmpi.l #2, %d0
		bne    CALL_3
		jsr    PUTSTRING
                bra    END_SYS_CALL
CALL_3:
		cmpi.l #3, %d0
		bne    CALL_4
		jsr    RESET_TIMER
                bra    END_SYS_CALL
CALL_4:
		cmpi.l #4, %d0
		bne    END_SYS_CALL
		jsr    SET_TIMER
END_SYS_CALL:	
		rte		
