***************************************************************
**各種レジスタ定義
***************************************************************
***************
**レジスタ群の先頭
***************
.equ REGBASE,   0xFFF000          | DMAPを使用．
.equ IOBASE,    0x00d00000
***************
**割り込み関係のレジスタ
***************
.equ IVR,       REGBASE+0x300     |割り込みベクタレジスタ
.equ IMR,       REGBASE+0x304     |割り込みマスクレジスタ
.equ ISR,       REGBASE+0x30c     |割り込みステータスレジスタ
.equ IPR,       REGBASE+0x310     |割り込みペンディングレジスタ
***************
**タイマ関係のレジスタ
***************
.equ TCTL1,     REGBASE+0x600     |タイマ１コントロールレジスタ
.equ TPRER1,    REGBASE+0x602     |タイマ１プリスケーラレジスタ
.equ TCMP1,     REGBASE+0x604     |タイマ１コンペアレジスタ
.equ TCN1,      REGBASE+0x608     |タイマ１カウンタレジスタ
.equ TSTAT1,    REGBASE+0x60a     |タイマ１ステータスレジスタ
***************
** UART1（送受信）関係のレジスタ
***************
.equ USTCNT1,   REGBASE+0x900     | UART1ステータス/コントロールレジスタ
.equ UBAUD1,    REGBASE+0x902     | UART1ボーコントロールレジスタ
.equ URX1,      REGBASE+0x904     | UART1受信レジスタ
.equ UTX1,      REGBASE+0x906     | UART1送信レジスタ
***************
** LED
***************
.equ LED7,      IOBASE+0x000002f  |ボード搭載のLED用レジスタ
.equ LED6,      IOBASE+0x000002d  |使用法については付録A.4.3.1
.equ LED5,      IOBASE+0x000002b
.equ LED4,      IOBASE+0x0000029
.equ LED3,      IOBASE+0x000003f
.equ LED2,      IOBASE+0x000003d
.equ LED1,      IOBASE+0x000003b
.equ LED0,      IOBASE+0x0000039



	***************
	**システムコール番号
	***************
	.equ SYSCALL_NUM_GETSTRING,     1
	.equ SYSCALL_NUM_PUTSTRING,     2
	.equ SYSCALL_NUM_RESET_TIMER,   3
	.equ SYSCALL_NUM_SET_TIMER,     4


	
***************************************************************
**スタック領域の確保
***************************************************************
.section .bss
.even
SYS_STK:
	.ds.b   0x4000  |システムスタック領域
	.even
SYS_STK_TOP:            |システムスタック領域の最後尾
task_p:
	.ds.l 1 |タイマ用
	
***************************************************************
**初期化**内部デバイスレジスタには特定の値が設定されている．
**その理由を知るには，付録Bにある各レジスタの仕様を参照すること．
***************************************************************
.section .text
.even
boot:
	*スーパーバイザ&各種設定を行っている最中の割込禁止
	move.w #0x2700,%SR
	lea.l  SYS_STK_TOP, %SP | Set SSP


	****************
	**割り込みコントローラの初期化
	****************
	move.b #0x40, IVR       |ユーザ割り込みベクタ番号を
				| 0x40+levelに設定.
	move.l #0x00ffffff, IMR  |全割り込みマスク|**割り込みを許可
	****************
	**送受信(UART1)関係の初期化(割り込みレベルは4に固定されている)
	****************
	move.w #0x0000, USTCNT1 |リセット
	move.w #0xE10C, USTCNT1 |送受信可能,パリティなし, 1 stop, 8 bit,
				|送受信割り込み禁止
	move.w #0x0038, UBAUD1  | baud rate = 230400 bps
	****************
	**タイマ関係の初期化(割り込みレベルは6に固定されている)
	*****************
	move.w #0x0004, TCTL1   | restart,割り込み不可,|システムクロックの1/16を単位として計時，
	|タイマ使用停止

	jsr INIT_Q /*Queueの初期化*/

	****************
	**割り込み処理ルーチンの初期化
	****************
	move.l #uart_interrupt, 0x110 /* level 4, (64+4)*4  step2-1 */ 
	move.l #TIMER_CMP, 0x118 /* level 6, (64+6)*4 */
	move.l #SYSTEMCALL, 0x080

	***************************************************************
	**現段階での初期化ルーチンの正常動作を確認するため，最後に’a’を
	**送信レジスタUTX1に書き込む．’a’が出力されれば，OK.
	***************************************************************
	
	move.l #0x00ff3ff9, IMR
	move.w #0x2000,%SR

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
	move.l #TT,    %D2
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
	movem.l %D0-%D7/%A0-%A6,-(%SP)
	cmpi.w #5,TTC            | TTCカウンタで5回実行したかどうか数える
	beq TTKILL               | 5回実行したら，タイマを止める
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
	***初期値のあるデータ領域
	****************************************************************
	.section .data
TMSG:
	.ascii  "******\r\n"      | \r:行頭へ(キャリッジリターン)
	.even                     | \n:次の行へ(ラインフィード)
TTC:
	.dc.w  0
	.even
	****************************************************************
	***初期値の無いデータ領域
	****************************************************************
	.section .bss
BUF:
	.ds.b 256           | BUF[256]
	.even
USR_STK:
	.ds.b 0x4000            |ユーザスタック領域
	.even
USR_STK_TOP:           |ユーザスタック領域の最後尾
	
	

	.section .text
.even


/*割り込み処理*/
uart_interrupt:
	movem.l %a0/%d1-%d3, -(%sp)
	
RCEV_INTERUPT:
        /* ここから受信割り込み */
        move.w  URX1, %d3       /* 受信レジスタを保存 */
        move.b  %d3, %d2        /* d3の下位8bitをコピー */
        andi.w  #8192, %d3      /* URX1の13ビット目を確認し、d3に格納 */
        cmpi.w  #8192, %d3
        bne     SEND_INTERUPT
        move.l  #0, %d1 /* チャンネルを0に指定 */
        jsr     INTERGET        /* 受信割り込み */
	bra	INTERFACE_FINISH
	
SEND_INTERUPT:
        move.w  UTX1, %d3
        andi.w  #0x8000, %d3
        cmp.w   #0x0000, %d3 /*UTX1の15ビット目と比較*/
        /*15bit目が1ならば送信キューが空(空なら待ちがいない)*/
        beq     INTERFACE_FINISH

        move.l  #0, %d1
        jsr     INTERPUT

INTERFACE_FINISH:
        movem.l (%sp)+, %a0/%d1-%d3
        rte	
	


/*送受信キューを一気に初期化*/
INIT_Q:

	/*キューの各先頭アドレス*/
        .equ    Que0, Que_START
        .equ    Que1, Que0 + 0x0000010c
	
	/*キューの各要素のオフセット*/
	.equ	out, 0
	.equ	in, 4
	.equ	s, 8  /*2byte分確保*/
	.equ	top, 10
	.equ	bottom, 266

	
	movem.l %a0-%a1 ,-(%sp)

	movea.l	#Que0, %a0 /*構造体Que0の先頭アドレス*/
	move.l  #top, %a1
	add.l	%a0, %a1 /*a1でキュー０の先頭番地を指定*/
	move.l  %a1, out(%a0) /*enqueポインタ初期化*/
        move.l  %a1, in(%a0) /*dequeポインタ初期化*/
	move.b	#0, s(%a0) /*カウンタの初期化*/
	movea.l #Que1, %a0 /*構造体Que１の先頭アドレス*/
        move.l  #top, %a1
        add.l   %a0, %a1 /*a1でキュー1の先頭番地を指定*/
        move.l  %a1, out(%a0) /*enqueポインタ初期化*/
        move.l  %a1, in(%a0) /*dequeポインタ初期化*/
        move.b  #0, s(%a0) /*カウンタの初期化*/	
	
	movem.l (%sp)+, %a0-%a1
	rts
	
INQ:	/* キューへの入力 */
	move.w	%sr, -(%sp)	/* 現走行レベルの退避 */
	move.w	#0x2700, %sr	/* 割り込み禁止 */
	movem.l	%a0-%a3, -(%sp)	/* レジスタの退避 */
	cmpi.l	#1, %d0	/* キュー番号の確認 */
	beq	INQ_Q1
	movea.l	#Que0, %a0	/* キュー0参照用アドレス */
	bra	INQ_WRITE
INQ_Q1:
	movea.l	#Que1, %a0	/* キュー1参照用アドレス */
INQ_WRITE:
	cmpi.w	#256 ,s(%a0)	/* キュー内のデータの個数を確認 */
	bne	INQ_SETDATA	/* キューが一杯でなければ書き込み可能 */
	moveq.l	#0, %d0	/* 書き込み失敗 */
	bra	INQ_END
INQ_SETDATA:
	movea.l	in(%a0), %a1	/* 書き込み先アドレスを格納 */
	move.b	%d1, (%a1)/* 書き込み処理 */
	movea.l	%a0, %a2
	adda.l	#bottom, %a2	/* キューの末尾のアドレスを格納 */
	cmpa.l	in(%a0), %a2	/* 書き込んだ位置がキューの末尾か確認 */
	beq	INQ_BOTTOM
		/* in != bottom 時の処理 */
	addi.l	#1, in(%a0)	/* 書き込み位置のアドレスを1加算 */
	bra	INQ_SUCCESS
INQ_BOTTOM:	/* in == bottom 時の処理 */
	move.l	#top, %a3
	add.l	%a0, %a3	/* topのアドレスを求める */
	move.l	%a3, in(%a0)	/* 書き込み位置をキューの先頭に移動 */
INQ_SUCCESS:
	addi.w	#1, s(%a0)	/* 個数を1加算 */
	moveq.l	#1, %d0	/* 書き込み成功 */
INQ_END:	/* 終了処理 */
	movem.l	(%sp)+, %a0-%a3	/* レジスタの回復 */
	move.w	(%sp)+, %sr	/* 旧走行レベルの回復 */
	rts

/*a0:選択された構造体の先頭アドレス（変更不可）*/
/*a1:構造体の先頭アドレスのコピー（変更可）*/
	
OUTQ:
	movem.l %a0-%a2, -(%sp)
	move.w	%sr, -(%sp)
	
	move.w	#0x2700, %sr /*割り込み禁止*/

	cmp.l	#0, %d0
	beq	out_init_0
	
	movea.l #Que1, %a0
	bra	out_step1

out_init_0:
	movea.l #Que0, %a0	

out_step1:
	cmp.w	#0, s(%a0)
	bne	out_step2
	move.l	#0, %d0 /*失敗*/
	bra	out_finish

out_step2:
	movea.l	%a0, %a1  /*キューの先頭アドレスを転送*/
	movea.l out(%a0), %a2 
        move.b  (%a2)+, %d1 /*data = m[out]*/
	sub.w	#1, s(%a0) /*s--*/
	move.l	#1, %d0 /*成功*/
        add.l   #bottom, %a1 /*%a1をキューのbottomシンボルのアドレスに*/
        cmpa.l  %a1, %a2
        bls     out_step3
        movea.l %a0, %a2 /*キューの先頭アドレスを転送*/
        add.l   #top, %a2

out_step3:
        move.l  %a2, out(%a0)
        cmpa.l  in(%a0), %a2
out_finish:
	move.w	(%sp)+, %sr
	movem.l (%sp)+, %a0-%a2
	rts


INTERPUT:/*d1が引数*/
	movem.l %d0, -(%sp)
        move.w  #0x2700, %sr /*割り込み禁止*/

	cmp.l	#0, %d1 /*chが1かどうか*/
	bne	FINISH_INTERPUT 

	move.l	#1, %d0 /*引数:no*/
	jsr	OUTQ /*no:d0, data:d1*/

	cmp.l	#0, %d0
	beq	SET_TXEE_INTERPUT
	move.w	#0x0800, %d2 /*上位8bit付与*/
	add.b	%d1, %d2 /*送信データを転送*/
	move.w	%d2, UTX1  /*UTX1に代入して送信*/

	bra	FINISH_INTERPUT

SET_TXEE_INTERPUT:
	move.w	#0xe108, USTCNT1 /*送信割り込みをマスク*/

FINISH_INTERPUT:
	movem.l (%sp)+, %d0
        rts


/* 仮引数：　ch:%d1.l, p:%d2.l, size:%d3.l */
PUTSTRING:
	movem.l	%a0-%a3, -(%sp)
	cmp.l   #0, %d1 /*chが1かどうか*/
       	bne     FINISH_PUTSTRING
	
	/*sz, iの初期化*/
	lea.l	sz, %a0 /*%a0 : sz address*/
	lea.l	i, %a1 /*%a1 : i address*/
 	move.l	#0, (%a0)
	move.l	%d2, (%a1)

	cmp.l	#0, %d3
	beq	RETURN_PUTSTR

loop_PUTSTR:
	cmp.l	(%a0), %d3
	beq	SET_TXEE_PUTSTR
	
	move.l	#1, %d0
	movea.l	(%a1), %a3
	move.b	(%a3), %d1 /*引数:data*/
	jsr	INQ	/*INQ(1, i)*/
	cmp.l	#0, %d0
	beq	SET_TXEE_PUTSTR
	add.l	#1, (%a0) /* sz++ */
	add.l	#1, (%a1) /* i++ */
	bra	loop_PUTSTR
	

SET_TXEE_PUTSTR:
	move.w  #0xe10C, USTCNT1 /*送信割り込みをアンマスク*/
	
RETURN_PUTSTR:	
	move.l	(%a0), %d0	

FINISH_PUTSTRING:
	movem.l	(%sp)+, %a0-%a3
	rts
	

/* step6 */
	
GETSTRING:	/* d1.L:チャネル d2.L:書き込み先アドレス d3.L:取り出すデータ数*/
	movem.l	%d1-%d5/%a0, -(%sp)	/* レジスタ退避 */
	cmpi.l	#0, %d1
	bne	GS_END	/* chが0でなければ何もしない */
	move.l	%d1, %d5	/* chを保存 */
	move.l	#0, %d4	/* szを初期化 */
	movea.l	%d2, %a0	/* iにpの値を代入 */
GS_CHECK:
	cmp.l	%d4, %d3
	beq	GS_SZRETURN	/* これ以上データを取り出さないとき */
	move.l	%d5, %d0	/* キュー番号chを指定 */
	jsr	OUTQ	/* キューからデータを読み込む→d1 */
	cmpi.l	#0, %d0	/* キューからの読込結果を確認 */
	beq	GS_SZRETURN	/* 失敗したとき（キューが空のとき）は強制終了 */
	move.b	%d1, (%a0)+	/* 読み込んだデータをコピー */
	addi.l	#1, %d4	/* 実際に取り出したデータ数を1加算 */
	bra	GS_CHECK	/* 繰り返し */

GS_SZRETURN:	
	move.l	%d4, %d0	/* 実際に取り出したデータ数を返す */
GS_END:	
	movem.l	(%sp)+, %d1-%d5/%a0	/* レジスタ回復 */
	rts

INTERGET:	/* d1.L:チャネル d2.B:受信データ */
	movem.l	%d0-%d2, -(%sp)	/* レジスタ退避 */
	cmpi.l	#0, %d1
	bne	IG_END	/* chが0でなければ何もしない */
	move.l	%d1, %d0	/* キュー番号chを指定 */
	move.b	%d2, %d1	/* キューに格納するデータを準備 */
	jsr	INQ	/* キューにデータを格納 */
IG_END:	
	movem.l	(%sp)+, %d0-%d2	/* レジスタ回復 */
	rts


	/*RESET_TIMER
	【機能】タイマ割り込みを不可にし，タイマも停止する．
	【入力】なし【戻り値】なし*/
RESET_TIMER:
	move.w #0x0004, TCTL1
	rts



	/*SET_TIMER
	【機能】
	タイマ割り込み時に呼び出すべきルーチンを設定する．
	タイマ割り込み周期tを設定し，t*0.1msec秒毎に割り込みが発生するようにする．
	タイマ使用を許可し，タイマ割り込みを許可する．(=タイマをスタートさせる)
	【入力】
	タイマ割り込み発生周期t→%D1.w (型に注意)
	割り込み時に起動するルーチンの先頭アドレスp→%D2.L
	【戻り値】なし*/
SET_TIMER:
	move.l %d2, task_p
	move.w #0x00CE, TPRER1
	move.w %d1, TCMP1
	move.w #0x0015, TCTL1
	rts



	/*【機能】タイマ割り込み時に処理すべきルーチンを呼び出す．
	【入力】なし【戻り値】なし*/
CALL_RP:
	movem.l	%a0, -(%sp)
	movea.l task_p, %a0
	jsr (%a0)
	movem.l (%sp)+, %a0
	rts



TIMER_CMP:
	movem.l %d0, -(%sp)
	move.w TSTAT1, %d0
	andi.w #0x0001, %d0
	bne TIMER_CMP_Step0
	rte
TIMER_CMP_Step0:
	move.w #0x0000, TSTAT1
	jsr CALL_RP
	movem.l (%sp)+, %d0
	rte



	/*【機能】
	呼び出すべきシステムコールを，%D0
	(システムコール番号1-4を格納)を用いて判別する．
	目的のシステムコールを呼び出す
	【入力】
	システムコール番号→%D0.L
	(1:GETSTRING 2:PUTSTRING 3:RESET_TIMER 4:SET_TIMER)
	システムコールの引数→%D1以降
	【戻り値】
	システムコール呼び出しの結果→%D0.L*/
SYSTEMCALL:
	movem.l %a0, -(%sp)
	cmpi.l #1, %d0
	beq SYSTEMCALL_Step1
	cmpi.l #2, %d0
	beq SYSTEMCALL_Step2
	cmpi.l #3, %d0
	beq SYSTEMCALL_Step3
	cmpi.l #4, %d0
	beq SYSTEMCALL_Step4
SYSTEMCALL_Step1:
	lea.l GETSTRING, %a0
	move.l %a0, %d0
	bra SYSTEMCALL_Jump
SYSTEMCALL_Step2:
	lea.l PUTSTRING, %a0
	move.l %a0, %d0
	bra SYSTEMCALL_Jump
SYSTEMCALL_Step3:
	lea.l RESET_TIMER, %a0
	move.l %a0, %d0
	bra SYSTEMCALL_Jump
SYSTEMCALL_Step4:
	lea.l SET_TIMER, %a0
	move.l %a0, %d0
	bra SYSTEMCALL_Jump
SYSTEMCALL_Jump:
	jsr (%a0)
	movem.l (%sp)+, %a0
	rte
	

.section .data

sz:		.ds.l	1
i:		.ds.l	1

Que_START:	.ds.b	536


.end
