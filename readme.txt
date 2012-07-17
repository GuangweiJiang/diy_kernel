一步步实现自己的内核调度程序(v1.0)
--基于TQ2440(ARM9)的实现
作者：姜广伟
日期：2010-12-29
邮箱：Guangwei.jiang@gmail.com

很多程序员对“内核调度”概念并不陌生，但如果让大家去设计并实现“自己”的内核调度程序，也许并非易事。
出于好奇，我记下了自己设计和实现“内核调度”的四部曲。设计十分简单,但对理解“内核调度”会有一些帮助，希望能给大家带来一点启发！

下面对“内核调度”的四部曲作简要的介绍：
1. 简易多任务设计 (1)
-- Task1和Task2通过调用函数Task_Sw_1To2/Task_Sw_2To1实现两个任务间上下文的切换。

2. 简易多任务设计 (2)
-- 加入“轮转法调度”，Task1和Task2通过调用函数Task_Sw即可实现多任务切换。

3. 简易内核调度 (1)
-- 加入时钟中断，当时钟中断发生时，内核调度程序自动切换不同的任务。

4. 简易内核调度 (2)
-- 加入“临界区(Critical Section)”,避免任务间的竞争；
-- 中断发生时，增加判断“时钟中断”。

********************************
For the people, who doesn't understand Chinese:
This is a simple "kernel", which shows the basic conception of kernel, such as "Task Switch", "Memory Manager"...
The code is only for studying, if you have problem, please feel free contact "guangwei.jiang@gmail.com".
