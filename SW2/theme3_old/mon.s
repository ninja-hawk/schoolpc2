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
** UART2 (送受信)関係のレジスタ
***************
.equ USTCNT2, REGBASE+0x910 | UART2 ステータス / コントロールレジスタ
.equ UBAUD2,  REGBASE+0x912 | UART2 ボーコントロールレジスタ
.equ URX2,    REGBASE+0x914 | UART2 受信レジスタ
.equ UTX2,    REGBASE+0x916 | UART2 送信レジスタ

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
** 初期化
***************************************************************
.section .text
.even
.extern start           | crt0.s内のstartをextern
.global monitor_begin   | 大域変数（関数）の宣言	
monitor_begin:
		* スーパーバイザ & 各種設定を行っている最中の割込禁止
		move.w #0x2000,%SR
		lea.l SYS_STK_TOP, %SP | Set SSP
		****************
		** 割り込みコントローラの初期化
		****************
		move.b #0x40, IVR       | ユーザ割り込みベクタ番号を
		                        | 0x40+level に設定.
		move.l #0x00ffffff, IMR | 全割り込みマスク
		move.l #0x00ff2ff9, IMR | アンマスクMUART1=>0,MTMR1=>1,UART2=>12
		****************
		** 送受信 (UART1) 関係の初期化 ( 割り込みレベルは 4 に固定されている )
		****************
		move.l #UART1_interrupt, 0x110  | 受信割り込みベクタをセット
		move.w #0x0000, USTCNT1 | リセット
		move.w #0xe108, USTCNT1 | 送受信可能 , パリティなし , 1 stop, 8 bit,
					            | 受信割り込み許可, 送信割り込み禁止
		move.w #0x0038, UBAUD1  | baud rate = 230400 bps
		
		****************
		** 送受信 (UART2) 関係の初期化 ( 割り込みレベルは 5 に固定されている )
		****************
		move.l #UART2_interrupt, 0x114  | 受信割り込みベクタをセット
		move.w #0x0000, USTCNT2 | リセット
		move.w #0xe108, USTCNT2 | 送受信可能 , パリティなし , 1 stop, 8 bit,
					            | 受信割り込み許可, 送信割り込み禁止
		move.w #0x0038, UBAUD2  | baud rate = 230400 bps
		
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
		lea.l  top00, %a2
		lea.l  top10, %a3
		move.l %a2, out00
		move.l %a3, out10
		move.l %a2, in00
		move.l %a3, in10
		move.l #0, s00
		move.l #0, s10
		
		lea.l  top01, %a2
		lea.l  top11, %a3
		move.l %a2, out01
		move.l %a3, out11
		move.l %a2, in01
		move.l %a3, in11
		move.l #0, s01
		move.l #0, s11		
	
		jmp start
	
****************************************************************
***プログラム領域
****************************************************************
MAIN:
		**走行モードとレベルの設定(「ユーザモード」への移行処理)
		move.w #0x0000, %SR    | USER MODE, LEVEL 0
		lea.l  USR_STK_TOP,%SP | user stackの設定
		
		
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
		movem.l %d1-%d3, -(%SP)
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
		btst.l #15, UTX1      |  15ビット目は送信FIFOが空であるか
		beq    END_interrupt  |  if UTX1[15] == 0 (送信FIFOが空でないとき終了)
		move.l #0, %d1        |  ch = 0 を明示
		jsr    INTERPUT       |  送信割り込み時処理
END_interrupt:
		movem.l (%SP)+, %d1-%d3
		rte
		
		
*************************************
** UART2_interrupt
** 送受信割り込みを扱うインターフェース(ポート２)
*************************************
/* btst : 指定データの指定ビットが0であるか判断し、0であればCCRのZをセット */		
UART2_interrupt:
		movem.l %d1-%d3, -(%SP)
		/* 受信FIFOが空でないとき(URX[13]==1)受信割り込みであると判断 */
		/* URX[13] ->  0: 受信FIFOが空, 1: 受信FIFOが空でない */
		move.w URX2, %d3
		move.b %d3, %d2             |  %d3.wの下位8bitを%d2.bにコピー
		btst.l #13, %d3             |  13ビット目は受信FIFOにデータが存在するか
		beq    CALL_INTERPUT_PORT1  |  if URX2[13] == 0 (受信FIFOが空のとき)
		move.l #1, %d1              |  ch = 1 を明示
		jsr    INTERGET             |  受信割り込み時処理
		bra    END_interrupt_PORT1
CALL_INTERPUT_PORT1:
		/* 送信FIFOがに空のとき(UTX[15]==1)送信割り込みであると判断 */
		/* UTX[15] ->  0: 送信FIFOが空でない, 1: 送信FIFOが空 */
		btst.l #15, UTX2            |  15ビット目は送信FIFOが空であるか
		beq    END_interrupt_PORT1  |  if UTX1[15] == 0 (送信FIFOが空でないとき終了)
		move.l #1, %d1              |  ch = 1 を明示
		jsr    INTERPUT             |  送信割り込み時処理
END_interrupt_PORT1:
		movem.l (%SP)+, %d1-%d3
		rte


*************************************
** INTERGET  受信割り込みルーチン	
** 引数     :  %d1.l = チャネル(ch)	
**             %d2.b = 受信データdata
**戻り値　なし		
*************************************
INTERGET:
		move.l %d0, -(%SP)
		cmp    #0, %d1       | ch = 0 であるか確認
		bne    INTERGET_PORT1
		move.l #0, %d0       | %d0 = 受信キュー
		move.b %d2, %d1      | %d1 = 受信したデータ
		jsr    IN_Q_0        | %d0 <= 成功したか否か
INTERGET_PORT1:
        cmp    #1, %d1       | ch = 1 であるか確認
        bne    END_INTERGET
        move.l #0, %d0       | %d0 = 受信キュー
		move.b %d2, %d1      | %d1 = 受信したデータ
		jsr    IN_Q_1        | %d0 <= 成功したか否か
END_INTERGET:
		move.l (%SP)+, %d0
		rts

*************************************
** INTERPUT :  送信割り込み時の処理	
** 引数     :  %d1.l = チャネル(ch)	
*************************************
INTERPUT:
		move.l  %d0, -(%SP)
		move.w  #0x2700, %SR   | 走行レベルを７に設定
		cmpi.l  #0, %d1        | ch = 0 を確認
		bne     INTERPUT_PORT1 | if ch != 0 => 復帰
        move.l  #1, %d0
		jsr     OUT_Q_0        | %d1.b = data
		cmpi    #0, %d0        | %d0(OUTQ_0の戻り値) == 0(失敗)
		bne     TX_DATA        | if so => 送信割り込みをマスク(真下)
		move.w  #0xe108, USTCNT1
		bra     END_INTERPUT
TX_DATA:
		add.w   #0x0800, %d1   | ヘッダを付与
		move.w  %d1, UTX1
		bra     END_INTERPUT
* -------- PORT1 --------------------------
INTERPUT_PORT1:
        cmpi.l  #1, %d1          | ch = 0 を確認
		bne     END_INTERPUT     | if ch != 0 => 復帰
        move.l  #1, %d0
		jsr     OUT_Q_1          | %d1.b = data
		cmpi    #0, %d0          | %d0(OUTQ_1の戻り値) == 0(失敗)
		bne     TX_DATA_PORT1    | if so => 送信割り込みをマスク(真下)
		move.w  #0xe108, USTCNT2
		bra     END_INTERPUT
TX_DATA_PORT1:
		add.w   #0x0800, %d1     | ヘッダを付与
		move.w  %d1, UTX2
		bra     END_INTERPUT
END_INTERPUT:
		move.l  (%SP)+, %d0
		rts

******************************
** INQ0
**入力キュー番号,d0.l 書き込むデータ,d1.b
**出力 d0,成功1, 失敗0
******************************
IN_Q_0:		
		cmp.b   #0x00, %d0         |受信キュー、送信キューの判別
		bne     i_loop1
		jsr     INQ00
		rts
i_loop1:
		jsr     INQ10
		rts

INQ00:                                      |受信キュー
		move.w  %sr, -(%sp)        |レジスタ退避
		movem.l %a0-%a4,-(%sp) 
		move.w  #0x2700, %SR       |走行レベルを7に設定
		move.l  s00, %d0            |s=256 => %d0=0:失敗
		sub.l   #0x100, %d0
		beq     i0_Finish0          |s=256 => 復帰
		movea.l in00, %a1           |書き込み先アドレス=%a1
		move.b  %d1, (%a1)+        |データをキューへ入れる,書き込み先アドレスを更新
		lea.l   bottom00, %a2       |次回書き込みアドレスa1<キューデータ領域の末尾アドレスa2=>step1
		cmp.l   %a2, %a1 
		bls     i0_STEP10
		lea.l   top00, %a3          |in=top
		move.l  %a3, %a1
i0_STEP10:
		move.l  %a1, in00           |in更新 
		add.l   #1, s00             |s+1
		move.l  #1, %d0            |d0=1 =>成功
i0_Finish0:
		movem.l (%sp)+, %a0-%a4    |レジスタ復帰
		move.w  (%sp)+, %sr
		rts                        |サブルーチン復帰		
INQ10:                                      |送信キュー
		move.w  %sr,-(%sp)         |レジスタ退避
		movem.l %a0-%a4,-(%sp) 
		move.w  #0x2700, %SR       |走行レベルを7に設定
		move.l  s10, %d0            |s=256 => %d0=0:失敗
		sub.l   #0x100, %d0  
		beq     i1_Finish0         |s=256 => 復帰
		movea.l in10, %a1           |書き込み先アドレス=%a1
		move.b  %d1, (%a1)+        |データをキューへ入れる,書き込み先アドレスを更新
		lea.l   bottom10, %a2       |次回書き込みアドレスa1<キューデータ領域の末尾アドレスa2=>step1
		cmp.l   %a2, %a1 
		bls     i1_STEP10 
		lea.l   top10, %a3          |in=top
		move.l  %a3, %a1
	
i1_STEP10:
		move.l  %a1, in10           |in更新
		add.l   #1, s10             |s+1
		move.l  #1, %d0            |d0=1 =>成功
i1_Finish0:
		movem.l (%sp)+, %a0-%a4    |レジスタ復帰
		move.w  (%sp)+, %sr
rts                        |サブルーチン復帰


******************************
** INQ1
**入力キュー番号,d0.l 書き込むデータ,d1.b
**出力 d0,成功1, 失敗0
******************************
IN_Q_1:		
		cmp.b   #0x00, %d0         |受信キュー、送信キューの判別
		bne     i_loop11
		jsr     INQ01
		rts
i_loop11:
		jsr     INQ11
		rts

INQ01:                                      |受信キュー
		move.w  %sr, -(%sp)        |レジスタ退避
		movem.l %a0-%a4,-(%sp) 
		move.w  #0x2700, %SR       |走行レベルを7に設定
		move.l  s01, %d0            |s=256 => %d0=0:失敗
		sub.l   #0x100, %d0
		beq     i0_Finish1          |s=256 => 復帰
		movea.l in01, %a1           |書き込み先アドレス=%a1
		move.b  %d1, (%a1)+        |データをキューへ入れる,書き込み先アドレスを更新
		lea.l   bottom01, %a2       |次回書き込みアドレスa1<キューデータ領域の末尾アドレスa2=>step1
		cmp.l   %a2, %a1 
		bls     i0_STEP11
		lea.l   top01, %a3          |in=top
		move.l  %a3, %a1
i0_STEP11:
		move.l  %a1, in01           |in更新 
		add.l   #1, s01             |s+1
		move.l  #1, %d0            |d0=1 =>成功
i0_Finish1:
		movem.l (%sp)+, %a0-%a4    |レジスタ復帰
		move.w  (%sp)+, %sr
		rts                        |サブルーチン復帰		
INQ11:                                      |送信キュー
		move.w  %sr,-(%sp)         |レジスタ退避
		movem.l %a0-%a4,-(%sp) 
		move.w  #0x2700, %SR       |走行レベルを7に設定
		move.l  s11, %d0            |s=256 => %d0=0:失敗
		sub.l   #0x100, %d0  
		beq     i1_Finish1          |s=256 => 復帰
		movea.l in11, %a1           |書き込み先アドレス=%a1
		move.b  %d1, (%a1)+        |データをキューへ入れる,書き込み先アドレスを更新
		lea.l   bottom11, %a2       |次回書き込みアドレスa1<キューデータ領域の末尾アドレスa2=>step1
		cmp.l   %a2, %a1 
		bls     i1_STEP11 
		lea.l   top11, %a3          |in=top
		move.l  %a3, %a1
	
i1_STEP11:
		move.l  %a1, in11           |in更新
		add.l   #1, s11             |s+1
		move.l  #1, %d0            |d0=1 =>成功
i1_Finish1:
		movem.l (%sp)+, %a0-%a4    |レジスタ復帰
		move.w  (%sp)+, %sr
		rts



******************************
** OUTQ0
**入力:キュー番号:d0.l
**出力:d0:0失敗, d0:1成功
**取り出したデータ:d1.b
******************************
OUT_Q_0:
		cmp.b #0x00, %d0                |受信キュー、送信キューの判別
		bne o_loop10
		jsr OUTQ00
		rts
o_loop10:
		jsr OUTQ10
		rts
OUTQ00:
		move.w %sr,-(%sp)               |レジスタ退避
		movem.l %a0-%a4,-(%sp)
		move.w  #0x2700, %SR            |走行レベルを7に設定
		move.l  s00, %d0                 |s=0 => %d0=0:失敗
		cmp.l  #0x00, %d0
		beq     o0_Finish0               |s=0 => 復帰
		movea.l out00, %a1               |取り出し先アドレス=%a1
		move.b  (%a1)+, %d1             |キューからデータを取り出し(%d1),取り出し先アドレスを更新
		lea.l bottom00, %a2              |次回取り出すアドレスa1<キューデータ領域の末尾アドレスa2=>step10
		cmp.l  %a2, %a1
		bls     o0_STEP10
		lea.l top00, %a3                 |out=top
		move.l  %a3, %a1
o0_STEP10:
		move.l %a1, out00                |out更新
		sub.l #1, s00                    |s--
		move.l  #1, %d0                 |d0=1 =>成功
o0_Finish0:
		movem.l (%sp)+, %a0-%a4         |レジスタ復帰
		move.w (%sp)+, %sr
		rts                             |サブルーチン復帰
OUTQ10:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp)          |レジスタ退避
		move.w  #0x2700, %SR            |走行レベルを7に設定
		move.l  s10, %d0                 |s=0 => %d0=0:失敗
		cmp.l #0x00, %d0
		beq     o1_Finish0               |s=0 => 復帰
		movea.l out10, %a1               |取り出し先アドレス=%a1
		move.b  (%a1)+, %d1             |キューからデータを取り出し(%d1),取り出し先アドレスを更新
		lea.l bottom10, %a2              |次回取り出すアドレスa1<キューデータ領域の末尾アドレスa2=>step10
		cmp.l  %a2, %a1
		bls     o1_STEP10
		lea.l top10, %a3                 |out=top
		move.l  %a3, %a1
o1_STEP10:
		move.l %a1, out10                |out更新
		sub.l #1, s10                    |s--
		move.l  #1, %d0                 |d0=1 =>成功
o1_Finish0:
		movem.l (%sp)+, %a0-%a4         |レジスタ復帰
		move.w (%sp)+, %sr
		rts                             |サブルーチン復帰


******************************
** OUTQ1
**入力:キュー番号:d0.l
**出力:d0:0失敗, d0:1成功
**取り出したデータ:d1.b
******************************
OUT_Q_1:
		cmp.b #0x00, %d0                |受信キュー、送信キューの判別
		bne o_loop11
		jsr OUTQ01
		rts
o_loop11:
		jsr OUTQ11
		rts
OUTQ01:
		move.w %sr,-(%sp)               |レジスタ退避
		movem.l %a0-%a4,-(%sp)
		move.w  #0x2700, %SR            |走行レベルを7に設定
		move.l  s01, %d0                 |s=0 => %d0=0:失敗
		cmp.l  #0x00, %d0
		beq     o0_Finish1               |s=0 => 復帰
		movea.l out01, %a1               |取り出し先アドレス=%a1
		move.b  (%a1)+, %d1             |キューからデータを取り出し(%d1),取り出し先アドレスを更新
		lea.l bottom01, %a2              |次回取り出すアドレスa1<キューデータ領域の末尾アドレスa2=>step11
		cmp.l  %a2, %a1
		bls     o0_STEP11
		lea.l top01, %a3                 |out=top
		move.l  %a3, %a1
o0_STEP11:
		move.l %a1, out01                |out更新
		sub.l #1, s01                    |s--
		move.l  #1, %d0                 |d0=1 =>成功
o0_Finish1:
		movem.l (%sp)+, %a0-%a4         |レジスタ復帰
		move.w (%sp)+, %sr
		rts                             |サブルーチン復帰
OUTQ11:
		move.w %sr,-(%sp)
		movem.l %a0-%a4,-(%sp)          |レジスタ退避
		move.w  #0x2700, %SR            |走行レベルを7に設定
		move.l  s11, %d0                 |s=0 => %d0=0:失敗
		cmp.l #0x00, %d0
		beq     o1_Finish1               |s=0 => 復帰
		movea.l out11, %a1               |取り出し先アドレス=%a1
		move.b  (%a1)+, %d1             |キューからデータを取り出し(%d1),取り出し先アドレスを更新
		lea.l bottom11, %a2              |次回取り出すアドレスa1<キューデータ領域の末尾アドレスa2=>step11
		cmp.l  %a2, %a1
		bls     o1_STEP11
		lea.l top11, %a3                 |out=top
		move.l  %a3, %a1
o1_STEP11:
		move.l %a1, out11                |out更新
		sub.l #1, s11                    |s--
		move.l  #1, %d0                 |d0=1 =>成功
o1_Finish1:
		movem.l (%sp)+, %a0-%a4         |レジスタ復帰
		move.w (%sp)+, %sr
		rts                             |サブルーチン復帰






*************************************
** PUTSTRING  送信割り込みの処理	
** 引数     :  %d1.l = チャネル(ch)	
**             %d2.l = データ読み込み先の先頭アドレスp いったんa6にさせて
**             %d3.l = 送信するデータ数size
** 出力     :  %d0.l = 取り出した要素数
*************************************
PUTSTRING:
		movem.l %d4/%a5, -(%sp)
		cmp    #0, %d1         | ch = 0 であるか確認
		bne    PUTSTRING_1   | そうでなければ復帰
		move.l #0, %d4         | sz = 0 (取った要素数)
		move.l  %d2, %a5       | i  = %d2 = 読み込み先 address
		cmp    #0, %d3         | 取り出すべきサイズが０であるか確認
		beq    END2_PUTSTRING  | 0であれば復帰
LOOP0_PUTSTRING:
		cmp    %d4, %d3        | 取るべき要素数と取った要素数を比較
		beq    END3_PUTSTRING  | 同等であれば復帰
		move.b #1, %d0         | %d0 = 1 (キューの番号：送信キュー)
		move.b (%a5), %d1      | %d1 = 読み込んだ値
		jsr    IN_Q_0
		cmp    #0, %d0         | IN_Qの復帰値が成功（１）であるか確認
                beq    END3_PUTSTRING  | 失敗ならば復帰
		add    #1, %d4         | sz ++ 
		add    #1, %a5         | i  ++ 
		bra    LOOP0_PUTSTRING

**ch = 1
PUTSTRING_1:
                move.l #0, %d4         | sz = 0 (取った要素数)
		move.l  %d2, %a5       | i  = %d2 = 読み込み先 address
		cmp    #0, %d3         | 取り出すべきサイズが０であるか確認
		beq    END2_PUTSTRING  | 0であれば復帰
LOOP1_PUTSTRING:
		cmp    %d4, %d3        | 取るべき要素数と取った要素数を比較
		beq    END3_PUTSTRING  | 同等であれば復帰
		move.b #1, %d0         | %d0 = 1 (キューの番号：送信キュー)
		move.b (%a5), %d1      | %d1 = 読み込んだ値
		jsr    IN_Q_1
		cmp    #0, %d0         | IN_Qの復帰値が成功（１）であるか確認
                beq    END3_PUTSTRING  | 失敗ならば復帰
		add    #1, %d4         | sz ++ 
		add    #1, %a5         | i  ++ 
		bra    LOOP1_PUTSTRING 

END3_PUTSTRING:
                
		move.w #0xe10c, USTCNT1 | 送信割り込みを許可（アンマスク）
END2_PUTSTRING:
		move.l %d4, %d0         | 返り値　%d0 = sz (取った要素数)
END_PUTSTRING:
		movem.l (%sp)+, %d4/%a5
		rts


		
*************************************
** GETSTRING  受信割り込みの処理	
** 引数     :  %d1.l = チャネル(ch)
** 	       %d2.l = データ書き込み先の先頭アドレスp
**             %d3.l = 取り出すデータ数size
** 出力     :　%d0.l = 実際に取り出したデータ数		
*************************************
GETSTRING:
		movem.l %d4/%a5, -(%sp)
		cmp    #0, %d1           | ch = 0 であるか確認
		bne    GETSTRING_1     | そうでなければ復帰
		move.l #0, %d4           | sz = 0 (取った要素数)
		move.l %d2, %a5          | i  = %d2 = 書き込み先 address
LOOP0_GETSTRING:	
		cmp    %d4, %d3          | 取るべき要素数と取り出した要素数を比較
		beq    END0_GETSTRING    | 同等であれば復帰
		move.l #0, %d0           | %d0 = 0 (キューの番号：受信キュー)
		jsr    OUT_Q_0            | OUT_Q ==> %d0: success?, %d1: 取り出したデータ
		cmp    #0, %d0           | OUT_Qの復帰値が成功(1)であるか確認 
		beq    END0_GETSTRING    | 失敗ならば復帰
		move.b %d1, (%a5)+       | 書き込み先にデータを書き込み
		add    #1, %d4           | sz ++
		bra    LOOP0_GETSTRING
END0_GETSTRING:
		move.l   %d4, %d0          | 返り値 %d0 = sz (実際に取り出したデータ数)
                bra END_GETSTRING

**ch = 1
GETSTRING_1:
                move.l #0, %d4           | sz = 0 (取った要素数)
		move.l %d2, %a5          | i  = %d2 = 書き込み先 address
LOOP1_GETSTRING:	
		cmp    %d4, %d3          | 取るべき要素数と取り出した要素数を比較
		beq    END1_GETSTRING    | 同等であれば復帰
		move.l #0, %d0           | %d0 = 0 (キューの番号：受信キュー)
		jsr    OUT_Q_1             | OUT_Q ==> %d0: success?, %d1: 取り出したデータ
		cmp    #0, %d0           | OUT_Qの復帰値が成功(1)であるか確認 
		beq    END1_GETSTRING    | 失敗ならば復帰
		move.b %d1, (%a5)+       | 書き込み先にデータを書き込み
		add    #1, %d4           | sz ++
		bra    LOOP1_GETSTRING
END1_GETSTRING:
		move.l   %d4, %d0          | 返り値 %d0 = sz (実際に取り出したデータ数)

END_GETSTRING:
		movem.l (%sp)+, %d4/%a5
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
		move.w	#0xce, TPRER1 /* 0.1msec進むとカウンタが1増えるようにする */
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
***************************************************************
** スタック領域の確保
***************************************************************
.section .bss
.even
SYS_STK:
		.ds.b  0x4000 | システムスタック領域
		.even
SYS_STK_TOP: 		      | システムスタック領域の最後尾

task_p:		.ds.l 1	      | タイマ割り込み時に起動するルーチン先頭アドレス代入用
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
		.ds.b 256      |BUF[256]
		.even
USR_STK:
		.ds.b 0x4000   |ユーザスタック領域
		.even
USR_STK_TOP:                   |ユーザスタック領域の最後尾		


******************************
** キュー用のメモリ領域確保
******************************
.section .data
		.equ  B_SIZE, 256
top00:
		.ds.b B_SIZE-1
bottom00:
		.ds.b 1
top10:
		.ds.b B_SIZE-1
bottom10:
		.ds.b 1
out00:
		.ds.l 1
out10:
		.ds.l 1
in00:
		.ds.l 1
in10:
		.ds.l 1
s00:
		.ds.l 1
s10:
		.ds.l 1

top01:
		.ds.b B_SIZE-1
bottom01:
		.ds.b 1
top11:
		.ds.b B_SIZE-1
bottom11:
		.ds.b 1
out01:
		.ds.l 1
out11:
		.ds.l 1
in01:
		.ds.l 1
in11:
		.ds.l 1
s01:
		.ds.l 1
s11:
		.ds.l 1



.end


