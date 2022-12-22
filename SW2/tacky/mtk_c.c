/*
*
* sched()   : タスクのスケジュール関数
* removeq() : キューからタスクを取り出す
* addq()    : キューの最後尾にタスクを登録
* sleep()   : タスクを休眠状態にしてタスクスイッチをする
* wakeup()  : 休眠状態のタスクを実行可能状態にする
*
* In the future, these functions will be included into mtk_c.c 
*/
#include "mtk_c.h"

void init_kernel() {
	ready = 0;                  //readyの初期化
	*(int*)0x084 = (int)pv_handler;  //pv_handlerをtrap#1の割り込みベクタに登録
	for (int i=0; i<NUMSEMAPHORE; i++) {
	    semaphore[i].count = 1;
            semaphore[i].task_list=0;
	}
        for (int i=0; i<NUMTASK; i++) {
            task_tab[i+1].task_addr=0;
            task_tab[i+1].stack_ptr=0;
            task_tab[i+1].priority=0;
            task_tab[i+1].status=0;
            task_tab[i+1].next=0;
        }
	
}

void set_task(void *p) {
	int i = 1;
	while (1) {                                     //タスクIDの捜索
		if (task_tab[i].status == 0) {
			break;
		}
		i = i+1;
	}
	new_task = i;                                  
    task_tab[new_task].task_addr = p;                        //TCBの更新
    task_tab[new_task].status = 1;                          
    task_tab[new_task].stack_ptr = init_stack( new_task );          //スタックの初期化
    addq(&ready, new_task);                         //キューへの登録
	
}

void *init_stack(int id) {
	int *ssp1;                            //4バイト用int
	unsigned short int *ssp2;             //2バイト用unsigned short int
	void *back;                           //戻り値用
	ssp1 = (int *)&stacks[id-1].sstack[STKSIZE];    //stacks[id-1]に各値を代入
	*(--ssp1) = (int)task_tab[id].task_addr;
	ssp2 = (unsigned short int *)ssp1;    //2バイトに切り替え
	*(--ssp2) = 0x0000;
	ssp1 = (int *)ssp2;
	for (int i=0; i<15; i++) {            //15*4バイト戻す
		*(--ssp1);
	}
	
	*(--ssp1) = (int *)&stacks[id-1].ustack[STKSIZE];
	
	back = (void *)ssp1;
	return back;
}

void begin_sch()
{
    int i;
    i = removeq(&ready);
    curr_task = i;

    init_timer();
    first_task();
    return;
}

TASK_ID_TYPE removeq(TASK_ID_TYPE *q){
    // 先頭タスクのidを保存
    TASK_ID_TYPE head_task_id = *q;
    // 先頭タスクを除去して新たなタスクidを登録
    *q = task_tab[head_task_id].next;
    
    return head_task_id;
}

void sched(void) {
    print("\n\n TIMER!!!! \n\n");
    // readyキューの先頭タスクを取り出してnext_taskへ
    next_task = removeq(&ready);
    // next_taskがNULLの場合はタイマ割り込みが来るまでループ
    while(!next_task);
}

void addq(TASK_ID_TYPE *q, TASK_ID_TYPE task_id){
    // idとして先頭idを保存
    TASK_ID_TYPE id = *q;
    *(char *)0x00d0002f = 'a';
    if (!id) { // 渡されたqueueの先頭がNULLだった場合
        *q = task_id;
        task_tab[task_id].next = NULLTASKID;
        return;
    }
    *(char *)0x00d0002d = 'a';
    // task_tabのnextがNULLになるまでたどる
    while (task_tab[id].next) id = task_tab[id].next;
    *(char *)0x00d00039 = 'a';
    // 最後尾にタスクidを追加
    task_tab[id].next = task_id;
    task_tab[task_id].next = NULLTASKID;
    
}

void sleep(int s_id){
    TASK_ID_TYPE* head_q = &(semaphore[s_id].task_list);
    // 該当セマフォの待ち行列に現タスクをつなぐ
    addq(head_q, curr_task);
    // 次に実行するタスクidをnext_taskにセット
    sched();
    // タスクを切り替え
    swtch();
}

void wakeup(int s_id){
    // セマフォの待ち行列の先頭タスクを取得
    TASK_ID_TYPE head_sem = semaphore[s_id].task_list;
    // セマフォの待ち行列の先頭タスクをキューから除去
    TASK_ID_TYPE head_task = removeq(&head_sem);
    // readyキューにその先頭タスクを追加
    addq(&ready, head_task);
}

void p_body(int s_id){
   
   semaphore[s_id].count--; //セマフォのcount値を1減らす

   if (semaphore[s_id].count < 0){
         sleep(s_id);       //セマフォが獲得できない場合は休眠状態に入る
}

}

void v_body(int s_id){

   semaphore[s_id].count++; //セマフォのcount値を１増やす

   if (semaphore[s_id].count <= 0){
         wakeup(s_id);      //セマフォが空けばそのセマフォを待っているタスクを１つ実行可能状態にする

}
}



