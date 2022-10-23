*******************************
** メモリ破壊（Drawing characters)
*******************************
.section .text
start:
	lea.l   DATA0,%a0       /* 描画する絵の先頭アドレスをa0に格納*/
	lea.l   VIEWTOP,%a1     /* 描画する領域の先頭アドレスをa1に格納*/
	lea.l   CONTROL,%a2     /* 制御用コードの先頭アドレスをa2に格納*/

	jsr     INIT            /* 背景を描画するサブルーチンに分岐*/
	jsr     DRAW            /* 描画領域の左上を初期位置として絵を描画*/

LOOP1:
	cmp.b   #4, (%a2)       /* 制御用コードを見て終了（4）を判定*/
	beq     end_of_program

	jsr     UPDATE          /* 描画位置の更新*/
	jsr     DRAW            /* 更新された位置（正しくは方向）に絵を描画*/
	bra     LOOP1

end_of_program:
	stop    #0x2700         /* プログラムの終了*/

************************************
** 背景を#INITCHARで埋める
** 引数：%a1 = 背景となるデータ領域の先頭アドレス
** #AREASIZE = 描画領域の大きさ
************************************
INIT:
	movem.l %d0/%a1,-(%a7)  /* このサブルーチンで使うレジスタを退避*/
	move.w  #AREASIZE,%d0
LOOP2:
	move.b  #INITCHAR,(%a1)+
	subq.w  #1,%d0
	bne     LOOP2
	
	movem.l (%a7)+,%d0/%a1  /* レジスタの回復*/
	rts
*************************************
** DRAW
** 引数：
**	%a0=動かす絵の先頭アドレス
**	%a1=絵を描画する領域の先頭アドレス（描画位置）
*************************************
DRAW:
	movem.l %d0-%d1/%a0-%a1,-(%a7) /* レジスタの退避*/

	moveq.l #LENGTHX,%d0
	moveq.l #LENGTHY,%d1

LOOP3:
	move.b  (%a0)+,(%a1)+
	subq.w  #1,%d0
	bne     LOOP3

	adda.w  #16-LENGTHX,%a1
	moveq.l #LENGTHX,%d0
	subq.w  #1,%d1
	bne     LOOP3
	movem.l (%a7)+, %d0-%d1/%a0-%a1 /* レジスタの回復*/
	rts

*************************************
** 制御コードによる絵の位置情報（アドレス）の更新
** 引数
**   %a2=現在の制御コードが格納してあるアドレス
** 戻り値
**   %a1=絵を描画する領域の先頭アドレス（位置）
*************************************
UPDATE:
	cmpi.b  #0,(%a2)                /* 右に動かす*/
	beq     RIGHT
	cmpi.b  #1,(%a2)                /* 左に動かす*/
	beq     LEFT
	cmpi.b  #2,(%a2)                /* 上に動かす*/
	beq     UP
	cmpi.b  #3,(%a2)                /* 下に動かす*/
	beq     DOWN
RIGHT:
	adda.w  #1,%a1
	bra     FINISH
LEFT:
	suba.w  #1,%a1
	bra     FINISH
UP:
	suba.w  #0x10,%a1
	bra     FINISH
DOWN:
	adda.w  #0x10,%a1
	bra     FINISH

FINISH:
	adda.w  #1,%a2
	rts
.section .data
***********************************
** Data Area
***********************************
	.equ    LENGTHX, 4      /* 描画する絵の横幅（バイト単位）*/
	.equ    LENGTHY, 4      /* 描画する絵の縦幅（バイト単位）*/
	.equ    INITCHAR, 0xee  /* 背景に使う”文字(0x00-0xff) */
	.equ    AREASIZE, 0x100 /* 描画に使用する領域の大きさ*/

DATA0:  .dc.b   INITCHAR,INITCHAR,INITCHAR,INITCHAR     /* 描画する絵の一部*/
DATA1:  .dc.b   INITCHAR,0x44,0x77,INITCHAR             /* 描画する絵の一部*/
DATA2:  .dc.b   INITCHAR,0x44,0x77,INITCHAR             /* 描画する絵の一部*/
DATA3:  .dc.b   INITCHAR,INITCHAR,INITCHAR,INITCHAR     /* 描画する絵の一部*/

*CONTROL:.dc.b	0,0,0,0,0,0,0,0,0,0,3,3,3,3,3,3,3,3,3,3,3,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,0,0,0,0,0,0,3,3,3,3,3,1,1,1,1,2,2,2,0,0,4
CONTROL:.dc.b 0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,4       /* 絵の制御用コード*/

VIEWTOP:        .ds.b   AREASIZE                /* 領域の確保*/

.end
