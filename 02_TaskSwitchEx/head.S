@**************************************************************
@ File: 	head.S
@ Function: 初始化，包括设置SVC模式下的堆栈，关闭WatchDog,初始化LED灯，启动第一个任务Task1。
@			还包括不同任务之间相互切换的功能。
@ Author: 	Guangwei_Jiang
@ Date:		Dec24'10 
@**************************************************************

.extern Task1
.global _start
.global Task_Sw

@******************************************************************************
@ 定义存放Task1/Task2堆顶指针的地址。
@******************************************************************************
.equ	TaskCur_STK_PTR,	0x00000FFC		@ 4096-4
.equ	TaskNext_STK_PTR,	0x00000FF8		@ 4096-8
.equ	Task01_STK_PTR,		0x00000FF4		@ 4096-12
.equ	TaskMin_STK_PTR,	0x00000FF4		@ 4096-12
.equ	Task02_STK_PTR,		0x00000FF0		@ 4096-16
.equ	TaskMax_STK_PTR,	0x00000FF0		@ 4096-16

	
@******************************************************************************
@ CPU reset后运行的第一段代码。
@ 初始化，包括设置SVC模式下的堆栈，关闭WatchDog,初始化LED灯，初始化"下一个任务"的堆栈指针，
@ 最后，启动第一个任务Task1。
@******************************************************************************
_start:
	ldr	sp, =4000			@ 设置SVC模式下的堆栈
	bl 	disable_watch_dog	@ 关闭WatchDog
	bl	init_led			@ 初始化LED灯
	
	@ "下一个任务"的堆栈指针指向任务1
    ldr	r0, =Task01_STK_PTR
    ldr r1, =TaskNext_STK_PTR
    str	r0, [r1]			@ mem[r1] =r0

	ldr	lr, =halt_loop		@ 设置lr
	ldr pc, =Task1			@ 启动第一个任务Task1
halt_loop:
	b	halt_loop
	
@******************************************************************************			
@ 任务切换。这里使用最简单的"轮转法调度"！
@******************************************************************************
Task_Sw:
	@ 将“当前任务”寄存器值压栈。
	stmfd sp!,{lr}              @ PC 入栈
	stmfd sp!,{r0-r12,lr}		@ r0-r12，lr入栈			
	mrs r4,cpsr
	stmfd sp!,{r4}				@ cpsr入栈

	@ 计算存放“当前任务”堆栈指针的地址。
	@ 因为采用最简单的“轮转法调度”，所以，“当前任务”是上一次调度之前的“下一个任务”！
	ldr r0, =TaskCur_STK_PTR	
	ldr r1, =TaskNext_STK_PTR
	ldr r1, [r1]				 
	str	r1, [r0]	
		
	@ 保存“当前任务”的栈顶指针。
	ldr r5,=TaskCur_STK_PTR		@ 取出存放“当前任务”的堆栈指针的地址
	ldr r5, [r5]
	str sp,[r5]                 @ 保存“当前任务”的堆栈指针			
	
	@ 计算“下一个任务”堆栈指针。
	@ “下一个任务”的堆栈指针, 保存在“当前任务”堆栈指针的地址的后面(-4)；
	@ 如果“下一个任务”超出了界限，则指向第一个任务。
	ldr r0, =TaskNext_STK_PTR
	ldr r1, =TaskCur_STK_PTR
	ldr r1, [r1]
	sub r1, r1, #4				@"下一个任务"保存地址 = “当前任务”保存地址 - 4			
	str r1, [r0]	
	ldr r2, =TaskMin_STK_PTR
	ldr r3, =TaskMax_STK_PTR
	cmp r1, r3
	strmi r2, [r0]				@ 如果TaskNext_STK_PTR越界，
								@ 则将TaskMin_STK_PTR的值赋给TaskNext_STK_PTR.			

	@ 取出“下一个任务”的栈顶指针，并将寄存器依次出栈。
	ldr r6, =TaskNext_STK_PTR	@ 取出存放"下一个任务"的Stack Pointer的地址
	ldr r6, [r6]
	ldr sp, [r6]				@ 取出"下一个任务"的堆顶指针,赋给SP         		
	b   POP_ALL					@ 根据设定的栈结构顺序出栈
				
@******************************************************************************			
@ 根据设定的栈结构顺序出栈
@******************************************************************************
POP_ALL:			
	ldmfd sp!,{r4}              @ psr出栈
	msr CPSR_cxsf,r4	
	ldmfd sp!,{r0-r12,lr,pc}    @ r0-r12,lr,pc出栈
