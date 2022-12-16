/*
* mtk_c.h
*
* 各種定数を定義する
*/
#ifndef mtk_c_H  /* if not defined this */
#define mtk_c_H  /* define it */

/* 定数の定義 */
#define NULLTASKID      0  /* キューの終端 */
#define NUMTASK         5  /* 最大タスク数 */
#define STKSIZE      1024  /* スタックサイズ = 1KB */
#define NUMSEMAPHORE    3

/* intの型エイリアス */
typedef int TASK_ID_TYPE;

/* 各構造体の定義 */
typedef struct {
    int          count;
    TASK_ID_TYPE task_list;
} SEMAPHORE_TYPE;

typedef struct{
    void         (*task_addr)();
    void         *stack_ptr;
    int          priority;
    int          status;
    TASK_ID_TYPE next;
} TCB_TYPE;

typedef struct{
    char ustack[STKSIZE];
    char sstack[STKSIZE];
} STACK_TYPE;

/* 大域変数の宣言 */
TASK_ID_TYPE curr_task;
TASK_ID_TYPE new_task;
TASK_ID_TYPE next_task;
TASK_ID_TYPE ready;

SEMAPHORE_TYPE semaphore[NUMSEMAPHORE];

TCB_TYPE task_tab[NUMTASK + 2];

STACK_TYPE stacks[NUMTASK];

/* 関数のプロトタイプ宣言 */
void init_kernel(void);
void set_task(void *p);
void* init_stack(int id);
void begin_sch(void);
void sched(void);
TASK_ID_TYPE removeq(TASK_ID_TYPE *q);
void addq(TASK_ID_TYPE *q, TASK_ID_TYPE task_id);
void sleep(int s_id);
void wakeup(int s_id);
void p_body(int s_id);
void v_body(int s_id);

/* 関数のextern宣言 */
extern void first_task(void);
extern void pv_handler(void);
extern void P(int semaphore_id);
extern void V(int semaphore_id);
extern void swtch(void);
extern void hard_clock(void);
extern void init_timer(void);


#endif  /* mtk_c_H */

