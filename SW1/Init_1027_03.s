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
		move.l #0x00fffffb,IMR | 全割り込みマスク
		****************
		** 送受信 (UART1) 関係の初期化 ( 割り込みレベルは 4 に固定されている )
		****************
		move.l #UART1_interrupt, 0x110  | 受信割り込みベクタをセット
		move.w #0x0000, USTCNT1 | リセット
		move.w #0xe138, USTCNT1 | 送受信可能 , パリティなし , 1 stop, 8 bit, /* 変更 */
					| 受信割り込み許可, 送割り込み禁止
		move.b #'4', LED4
		move.w #0x0038, UBAUD1  | baud rate = 230400 bps
		****************
		** タイマ関係の初期化 ( 割り込みレベルは 6 に固定されている )
		*****************
		move.b #'4', LED3
		move.w #0x0004, TCTL1   | restart, 割り込み不可 ,
					| システムクロックの 1/16 を単位として計時,
					| タイマ使用停止
		move.b #'4', LED2
		bra MAIN

*************************************
** UART1_interrupt
*************************************
UART1_interrupt:
		btst.l #15, UTX1      |  15ビット目は送信キューが空であるか
		bne    CALL_INTERGET  |  if UTX1[15] == 1 (空のとき)
		jsr    INTERPUT
		bra    END_interrupt
CALL_INTERGET:
		*jsr   INTERGET
END_interrupt:
		rte

*************************************
** INTERPUT :  送信割り込み時の処理	
** 引数     :  %d1.l = チャネル(ch)	
*************************************
INTERPUT:
		move.b  #'1', LED7
		move.w  #0x2700, %SR | 走行レベルを７に設定
		cmpi.l  #0, %d1      | ch = 0 を確認
		bne     END_INTERPUT | if ch != 0 => 復帰
		/* OUTQがあるとして... */
		jsr     OUTQ_STUB    | %d1.b = data
		cmpi    #0, %d0      | %d0(OUTQの戻り値) == 0(失敗)
		bne     TX_DATA      | ==> 送信割り込みをマスク(真下)
		move.w  #0xe138, USTCNT1
TX_DATA:
		add.w   #0x0800, %d1
		move.w  %d1, UTX1
END_INTERPUT:
		rte

*********************************
** OUTQ_STUB
*********************************
OUTQ_STUB:
		move.b  'a', %d1
		*move.b #0, %d0
		move.b  #1, %d0
		rts
		
		
		
		
***************************************************************
** 現段階での初期化ルーチンの正常動作を確認するため,最後に ’a’ を
** 送信レジスタ UTX1 に書き込む. ’a’ が出力されれば, OK.
***************************************************************
.section .text
.even
MAIN:
		move.b #'3', LED5
	        move.w #0x0800+'A', UTX1
		move.b #'2', LED6
		
LOOP:
		move.b #'3', LED3
		bra LOOP		

