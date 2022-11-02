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

***************************************************************
** 初期化
** 内部デバイスレジスタには特定の値が設定されている.
** その理由を知るには,付録 B にある各レジスタの仕様を参照すること.
***************************************************************
.section .text
.even
boot:
		* スーパーバイザ & 各種設定を行っている最中の割込禁止
		move.w #0x2000,%SR
		lea.l SYS_STK_TOP, %SP | Set SSP
		****************
		** 割り込みコントローラの初期化
		****************
		move.b #0x40, IVR      | ユーザ割り込みベクタ番号を
		                       | 0x40+level に設定.
		move.l #0x00ff3ffb,IMR | 全割り込みマスク
		****************
		** 送受信 (UART1) 関係の初期化 ( 割り込みレベルは 4 に固定されている )
		****************
		move.l #UART1_interrupt, 0x110  | 受信割り込みベクタをセット
		move.w #0x0000, USTCNT1 | リセット
		move.w #0xe10c, USTCNT1 | 送受信可能 , パリティなし , 1 stop, 8 bit, /* 変更 */
					| 受信割り込み許可, 送割り込み禁止
		move.w #0x0038, UBAUD1  | baud rate = 230400 bps
		****************
		** タイマ関係の初期化 ( 割り込みレベルは 6 に固定されている )
		*****************
		move.w #0x0004, TCTL1   | restart, 割り込み不可 ,
					| システムクロックの 1/16 を単位として計時,
					| タイマ使用停止
					
	    jsr Init_Q
		bra MAIN

*************************************
** UART1_interrupt
*************************************
UART1_interrupt:
		move.b #'1', LED7
		btst.l #15, UTX1      |  15ビット目は送信キューが空であるか
		bne    CALL_INTERGET  |  if UTX1[15] !=0  (空のとき)
		move.b #'2', LED5
		move.l #0, %d1        |  ch = 0 を明示
		jsr    INTERPUT       |  送信割り込み時処理
		bra    END_interrupt
CALL_INTERGET:
		*jsr   INTERGET
		move.b #'2', LED6
END_interrupt:
		rte

*************************************
** INTERPUT :  送信割り込み時の処理	
** 引数     :  %d1.l = チャネル(ch)	
*************************************
INTERPUT:
		move.b  #'3', LED4
		move.w  #0x2700, %SR | 走行レベルを７に設定
		cmpi.l  #0, %d1      | ch = 0 を確認
		bne     END_INTERPUT | if ch != 0 => 復帰
		/* OUTQがあるとして... */
		move.l  #1, %d0
		jsr     OUT_Q   | %d1.b = data
		cmpi    #0, %d0      | %d0(OUTQの戻り値) == 0(失敗)
		bne     TX_DATA      | ==> 送信割り込みをマスク(真下)
		move.w  #0xe108, USTCNT1
TX_DATA:
		move.b  #'3', LED2
		add.w   #0x0800, %d1 | ヘッダを付与
		move.w  %d1, UTX1
END_INTERPUT:
		move.b  #'3', LED1
		rts

******************************
		** OUTQ
		**入力:キュー番号:d0.l
		**出力:d0:0失敗, d0:1成功
		**取り出したデータ:d1.b
******************************
OUT_Q:		
                move.b #1, %d0
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
bottom0:.ds.b 1
top1:.ds.b B_SIZE-1
bottom1:.ds.b 1
out0:.ds.l 1
out1:.ds.l 1
in0:.ds.l 1
in1:.ds.l 1
s0:.ds.w 1
s1:.ds.w 1
		
		
		
		
***************************************************************
** 現段階での初期化ルーチンの正常動作を確認するため,最後に ’a’ を
** 送信レジスタ UTX1 に書き込む. ’a’ が出力されれば, OK.
***************************************************************
.section .text
.even
MAIN:
	        *move.w #0x0800+'A', UTX1
		
LOOP:
		bra LOOP		


