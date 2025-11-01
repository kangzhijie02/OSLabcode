#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
//测试指令异常
void test_illegal_instruction(void) {
    // 插入一个未定义的指令
    __asm__ volatile (".word 0x00000000\n");  
}
void test_more_illegal_instruction(void) {
    // 插入一个未定义的指令
    __asm__ volatile (
        ".word 0x00000000\n"
        ".word 0xFFFFFFFF\n"
        ".word 0x00000000\n"
    );  
}
//测试断点异常
void test_breakpoint(void) {
    // ebreak指令会触发断点异常
    __asm__ volatile ("ebreak\n");
}
void test_more_breakpoint(void) {
    // ebreak指令会触发断点异常
    __asm__ volatile (
    "ebreak\n"
    "ebreak\n"
    "ebreak\n"
    );
}
int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init();  // init the console
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);

    print_kerninfo();

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table

    pmm_init();  // init physical memory management

    idt_init();  // init interrupt descriptor table

    //clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt
    // 打印 test_illegal_instruction 函数的地址（即汇编指令的地址）
    //cprintf("calling test_breakpoint\n");
    //test_more_illegal_instruction();
    cprintf("calling test_more_breakpoint\n");
    test_more_breakpoint(); // 调用断点测试函数
    /* do nothing */
    while (1)
    ;
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

