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
		move.w #0x2000,%SR /* superviser-mode level 0 */
		lea.l SYS_STK_TOP, %SP | Set SSP
		****************
		** 割り込みコントローラの初期化
		****************
		move.b #0x40, IVR      | ユーザ割り込みベクタ番号を
		                       | 0x40+level に設定.
		move.l #0x00ff3ff9,IMR | 全割り込みマスク
		****************
		** 送受信 (UART1) 関係の初期化 ( 割り込みレベルは 4 に固定されている )
		****************
		move.l #UART1_interrupt, 0x110  | 受信割り込みベクタをセット
		move.w #0x0000, USTCNT1 | リセット
		/* バグの原因はここ(下)であることが多い  */
		move.w #0xe108, USTCNT1 | 送受信可能 , パリティなし , 1 stop, 8 bit, /* 変更 */
					| 受信割り込み許可, 送割り込み禁止
		move.w #0x0038, UBAUD1  | baud rate = 230400 bps
		****************
		** タイマ関係の初期化 ( 割り込みレベルは 6 に固定されている )
		*****************
		move.w #0x0004, TCTL1   | restart, 割り込み不可 ,
					| システムクロックの 1/16 を単位として計時,
					| タイマ使用停止
                
                jsr Init_Q              | キューの初期化 
		bra MAIN

*************************************
** UART1_interrupt
** 送受信割り込みを扱うインターフェース
** #0d8192 = 0b0010_0000_0000_0000
** #0x8000 = 0b1000_0000_0000_0000
*************************************
/* btst : 指定データの指定ビットが0であるか判断し、0であればCCRのZに0を代入 */		
UART1_interrupt:
		/* 受信FIFOが空でないとき(URX[13]==1)受信割り込みであると判断 */
		/* URX[13] ->  0: 受信FIFOが空, 1: 受信FIFOが空でない */
		move.w URX1, %d3
		move.b %d3, %d2       |  %d3.wの下位8bitを%d2.bにコピー
                andi.w #8192, %d3     |  URX1と#8192をAND演算
		cmpi.w #0, %d3        |  
		beq    CALL_INTERPUT  |  if URX1[13] == 0 (受信FIFOが空のとき)
		move.l #0, %d1        |  ch = 0 を明示
		jsr    INTERGET       |  受信割り込み時処理
		bra    END_interrupt
CALL_INTERPUT:
		/* 送信FIFOがに空のとき(UTX[15]==1)送信割り込みであると判断 */
		/* UTX[15] ->  0: 送信FIFOが空でない, 1: 送信FIFOが空 */
                move.w UTX1, %d3
		andi.w #0x8000, %d3   |  UTX1と0x8000をAND演算
                cmp.w  #0x0000, %d3   |  
		beq    END_interrupt  |  if UTX1[15] == 0 (送信FIFOが空でないとき終了)
		move.l #0, %d1        |  ch = 0 を明示
		jsr    INTERPUT       |  送信割り込み時処理
END_interrupt:
		rte

*************************************
** INTERPUT :  送信割り込み時の処理	
** 引数     :  %d1.l = チャネル(ch)	
*************************************
INTERPUT:
                move.b #'3', LED5/*デバック用*/
		move.w  #0x2700, %SR | 走行レベルを７に設定
		cmpi.l  #0, %d1      | ch = 0 を確認
		bne     END_INTERPUT | if ch != 0 => 復帰
		/* OUTQ */
                move.b #1, %d0
		jsr     OUT_Q    | %d1.b = data
		cmpi    #0, %d0      | %d0(OUTQの戻り値) == 0(失敗)
		bne     TX_DATA      | if so => 送信割り込みをマスク(真下)
		move.w  #0xe108, USTCNT1
TX_DATA:
		move.b #'4', LED4/*デバック用*/
                add.w   #0x0800, %d1 | ヘッダを付与
		move.w  %d1, UTX1
END_INTERPUT:
		rts

*************************************
** INTERGET  受信割り込みルーチン	
** 引数     :  %d1.l = チャネル(ch)	
             **%d2.b = 受信データdata
**戻り値　なし		
*************************************
INTERGET:
		cmp #0, %d1 /*(1)*/
		bne END_INTERGET
		move.l #0, %d0 /*(2)INQ(引数:d0,d1 戻り値:d0)*/
		move.l %d2, %d1
		jsr IN_Q
END_INTERGET:
		rts


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
		move.l  s0, %d0 /* sの値で実行可能か判別(3) */
		sub.l  #0x100, %d0 /* sが256のときd0を 0x0:失敗 */
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
		add.l #1, s0
		move.l  #1, %d0/* 処理をおこなうことができたのでd0を1に */
i0_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */		
INQ1:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.l  s1, %d0  /* sの値で実行可能か判別(3) */
		sub.l  #0x100, %d0  /* sが256のときd0を 0x0:失敗 */
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
		add.l #1, s1
		move.l  #1, %d0/* 処理をおこなうことができたのでd0を1に */
i1_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */
******************************
		** OUTQ
		**入力:キュー番号:d0.l
		**出力:d0:0失敗, d0:1成功
		**取り出したデータ:d1.b
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
		move.l  s0, %d0 /* sの値によって実行できるか判定(3) */
		cmp.l  #0x00, %d0 /* sが0のときd0を0x0:失敗  */
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
		sub.l #1, s0 /*s--*/
		move.l  #1, %d0/* 処理できたのでd0を1に */
o0_Finish:
		movem.l (%sp)+, %a0-%a4 /* レジスタ復帰 */
		move.w (%sp)+, %sr
		rts /* サブルーチンを抜ける */		
OUTQ1:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp) /* レジスタ退避(1) */
		move.w  #0x2700, %SR /*走行レベル7(2)*/
		move.l  s1, %d0 /* sの値によって実行できるか判定(3) */
		cmp.l #0x00, %d0 /* sが0のときd0を0x0:失敗  */
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
		sub.l #1, s1
		move.l  #1, %d0/* 処理できたのでd0を1に */
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
		cmp #0x00, %d1
		bne END_PUTSTRING
		move.b #0, %d4
		lea.l TDATA1, %a5 /*デバック用*/
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
                 move.b #'2', LED6/*デバック用*/
		move.w  #0xe10c, USTCNT1
END2_PUTSTRING:
		move %d4, %d0
END_PUTSTRING:
                
		rts
*************************************
** GETTRING  受信割り込みの処理	
** 引数     :  %d1.l = チャネル(ch)	
             **%d2.l = データ書き込み先の先頭アドレスp
             **%d3.l = 取り出すデータ数size
** szはd4レジスタ
** iはa5レジスタ
**戻り値　実際に取り出したデータ数sz:%d0.l		
*************************************
GETSTRING:
		cmp #0, %d1 /*(1)*/
		bne END_GETSTRING 
		move.l #0, %d4 /*(2)*/
		move.l %d2, %a5
LOOP1_GETSTRING:	
		cmp %d4, %d3 /*(3)*/
		beq END2_GETSTRING
		move.b #0, %d0 /*(4) d0:成功かどうか, d1:取り出したデータ*/
		jsr OUT_Q
		cmp #0, %d0 /*(5)*/
		beq END2_GETSTRING
		move.b %d1, (%a5)+ /*(6)*/
		add #1, %d4 /*(7)*/
		bra LOOP1_GETSTRING
END2_GETSTRING:
		move %d4, %d0
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



TEST_LIGHT:
		move.b	#'G', LED7
		move.b	#'R', LED6
		move.b	#'8', LED5
		move.b	#'T', LED4
		move.b	#'I', LED3
		move.b	#'M', LED2
		move.b	#'E', LED1
		move.b	#'R', LED0
		rts



******************************
** キュー用のメモリ領域確保
******************************
.section .data
.equ B_SIZE, 256
top0:.ds.b B_SIZE-1
bottom0:.ds.b 1
top1:.ds.b B_SIZE-1
bottom1:.ds.b 1
out0:.ds.l 1
out1:.ds.l 1
in0:.ds.l 1
in1:.ds.l 1
s0:.ds.l 1                                                      
s1:.ds.l 1
/* step5のテスト */
TDATA1: .ascii "0123456789ABCDEF"
TDATA2: .ascii "klmnopqrstuvwxyz"
		
		
		
***************************************************************
** 現段階での初期化ルーチンの正常動作を確認するため,最後に ’a’ を
** 送信レジスタ UTX1 に書き込む. ’a’ が出力されれば, OK.
***************************************************************
.section .text
.even
MAIN:
	        *move.w #0x0800+'A', UTX1
		jsr	RESET_TIMER
		move.l	#TEST_LIGHT, %d2
		move.w	#50000, %d1
		jsr	SET_TIMER
		move.b	#'G', LED7

		
LOOP:
******************************
** COMPARE_INTERPUT:	タイマ用のハードウェア割り込みインターフェース
******************************
COMPARE_INTERPUT:
		btst	#0, TSTAT1 /* タイマ1ステータスレジスタの0ビット目が0か、否か */
		beq	COMPARE_END /* 0ならコンペアイベントなし、つまりカウンタ値とコンペアレジスタ値が異なる */
		move.w	#0x0000, TSTAT1 /* タイマ1ステータスレジスタを0クリア */
		jsr	CALL_RP /* CALL_RPを呼び出す */

COMPARE_END:
		*rte

		bra LOOP	

