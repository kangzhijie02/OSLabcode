
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
    );
}
int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	657010ef          	jal	ra,ffffffffc0201ec2 <memset>
    dtb_init();
ffffffffc0200070:	3ea000ef          	jal	ra,ffffffffc020045a <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3d8000ef          	jal	ra,ffffffffc020044c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e8050513          	addi	a0,a0,-384 # ffffffffc0201ef8 <etext+0x24>
ffffffffc0200080:	09e000ef          	jal	ra,ffffffffc020011e <cputs>

    print_kerninfo();
ffffffffc0200084:	0ea000ef          	jal	ra,ffffffffc020016e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	78e000ef          	jal	ra,ffffffffc0200816 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	6ba010ef          	jal	ra,ffffffffc0201746 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	786000ef          	jal	ra,ffffffffc0200816 <idt_init>

    //clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt
ffffffffc0200094:	776000ef          	jal	ra,ffffffffc020080a <intr_enable>
    // 打印 test_illegal_instruction 函数的地址（即汇编指令的地址）
    //cprintf("calling test_breakpoint\n");
    //test_more_illegal_instruction();
    cprintf("calling test_more_breakpoint\n");
ffffffffc0200098:	00002517          	auipc	a0,0x2
ffffffffc020009c:	e4050513          	addi	a0,a0,-448 # ffffffffc0201ed8 <etext+0x4>
ffffffffc02000a0:	046000ef          	jal	ra,ffffffffc02000e6 <cprintf>
    __asm__ volatile (
ffffffffc02000a4:	9002                	ebreak
ffffffffc02000a6:	9002                	ebreak
ffffffffc02000a8:	9002                	ebreak
    test_more_breakpoint(); // 调用断点测试函数
    /* do nothing */
    while (1)
ffffffffc02000aa:	a001                	j	ffffffffc02000aa <kern_init+0x56>

ffffffffc02000ac <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000ac:	1141                	addi	sp,sp,-16
ffffffffc02000ae:	e022                	sd	s0,0(sp)
ffffffffc02000b0:	e406                	sd	ra,8(sp)
ffffffffc02000b2:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000b4:	39a000ef          	jal	ra,ffffffffc020044e <cons_putc>
    (*cnt) ++;
ffffffffc02000b8:	401c                	lw	a5,0(s0)
}
ffffffffc02000ba:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000bc:	2785                	addiw	a5,a5,1
ffffffffc02000be:	c01c                	sw	a5,0(s0)
}
ffffffffc02000c0:	6402                	ld	s0,0(sp)
ffffffffc02000c2:	0141                	addi	sp,sp,16
ffffffffc02000c4:	8082                	ret

ffffffffc02000c6 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c6:	1101                	addi	sp,sp,-32
ffffffffc02000c8:	862a                	mv	a2,a0
ffffffffc02000ca:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	00000517          	auipc	a0,0x0
ffffffffc02000d0:	fe050513          	addi	a0,a0,-32 # ffffffffc02000ac <cputch>
ffffffffc02000d4:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000d6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	0b9010ef          	jal	ra,ffffffffc0201992 <vprintfmt>
    return cnt;
}
ffffffffc02000de:	60e2                	ld	ra,24(sp)
ffffffffc02000e0:	4532                	lw	a0,12(sp)
ffffffffc02000e2:	6105                	addi	sp,sp,32
ffffffffc02000e4:	8082                	ret

ffffffffc02000e6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000e6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000ec:	8e2a                	mv	t3,a0
ffffffffc02000ee:	f42e                	sd	a1,40(sp)
ffffffffc02000f0:	f832                	sd	a2,48(sp)
ffffffffc02000f2:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f4:	00000517          	auipc	a0,0x0
ffffffffc02000f8:	fb850513          	addi	a0,a0,-72 # ffffffffc02000ac <cputch>
ffffffffc02000fc:	004c                	addi	a1,sp,4
ffffffffc02000fe:	869a                	mv	a3,t1
ffffffffc0200100:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200102:	ec06                	sd	ra,24(sp)
ffffffffc0200104:	e0ba                	sd	a4,64(sp)
ffffffffc0200106:	e4be                	sd	a5,72(sp)
ffffffffc0200108:	e8c2                	sd	a6,80(sp)
ffffffffc020010a:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020010c:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020010e:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200110:	083010ef          	jal	ra,ffffffffc0201992 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200114:	60e2                	ld	ra,24(sp)
ffffffffc0200116:	4512                	lw	a0,4(sp)
ffffffffc0200118:	6125                	addi	sp,sp,96
ffffffffc020011a:	8082                	ret

ffffffffc020011c <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020011c:	ae0d                	j	ffffffffc020044e <cons_putc>

ffffffffc020011e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020011e:	1101                	addi	sp,sp,-32
ffffffffc0200120:	e822                	sd	s0,16(sp)
ffffffffc0200122:	ec06                	sd	ra,24(sp)
ffffffffc0200124:	e426                	sd	s1,8(sp)
ffffffffc0200126:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200128:	00054503          	lbu	a0,0(a0)
ffffffffc020012c:	c51d                	beqz	a0,ffffffffc020015a <cputs+0x3c>
ffffffffc020012e:	0405                	addi	s0,s0,1
ffffffffc0200130:	4485                	li	s1,1
ffffffffc0200132:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200134:	31a000ef          	jal	ra,ffffffffc020044e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200138:	00044503          	lbu	a0,0(s0)
ffffffffc020013c:	008487bb          	addw	a5,s1,s0
ffffffffc0200140:	0405                	addi	s0,s0,1
ffffffffc0200142:	f96d                	bnez	a0,ffffffffc0200134 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200144:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200148:	4529                	li	a0,10
ffffffffc020014a:	304000ef          	jal	ra,ffffffffc020044e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020014e:	60e2                	ld	ra,24(sp)
ffffffffc0200150:	8522                	mv	a0,s0
ffffffffc0200152:	6442                	ld	s0,16(sp)
ffffffffc0200154:	64a2                	ld	s1,8(sp)
ffffffffc0200156:	6105                	addi	sp,sp,32
ffffffffc0200158:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020015a:	4405                	li	s0,1
ffffffffc020015c:	b7f5                	j	ffffffffc0200148 <cputs+0x2a>

ffffffffc020015e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200162:	2f4000ef          	jal	ra,ffffffffc0200456 <cons_getc>
ffffffffc0200166:	dd75                	beqz	a0,ffffffffc0200162 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020016e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200170:	00002517          	auipc	a0,0x2
ffffffffc0200174:	da850513          	addi	a0,a0,-600 # ffffffffc0201f18 <etext+0x44>
void print_kerninfo(void) {
ffffffffc0200178:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020017a:	f6dff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020017e:	00000597          	auipc	a1,0x0
ffffffffc0200182:	ed658593          	addi	a1,a1,-298 # ffffffffc0200054 <kern_init>
ffffffffc0200186:	00002517          	auipc	a0,0x2
ffffffffc020018a:	db250513          	addi	a0,a0,-590 # ffffffffc0201f38 <etext+0x64>
ffffffffc020018e:	f59ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200192:	00002597          	auipc	a1,0x2
ffffffffc0200196:	d4258593          	addi	a1,a1,-702 # ffffffffc0201ed4 <etext>
ffffffffc020019a:	00002517          	auipc	a0,0x2
ffffffffc020019e:	dbe50513          	addi	a0,a0,-578 # ffffffffc0201f58 <etext+0x84>
ffffffffc02001a2:	f45ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a6:	00006597          	auipc	a1,0x6
ffffffffc02001aa:	e8258593          	addi	a1,a1,-382 # ffffffffc0206028 <free_area>
ffffffffc02001ae:	00002517          	auipc	a0,0x2
ffffffffc02001b2:	dca50513          	addi	a0,a0,-566 # ffffffffc0201f78 <etext+0xa4>
ffffffffc02001b6:	f31ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ba:	00006597          	auipc	a1,0x6
ffffffffc02001be:	2e658593          	addi	a1,a1,742 # ffffffffc02064a0 <end>
ffffffffc02001c2:	00002517          	auipc	a0,0x2
ffffffffc02001c6:	dd650513          	addi	a0,a0,-554 # ffffffffc0201f98 <etext+0xc4>
ffffffffc02001ca:	f1dff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001ce:	00006597          	auipc	a1,0x6
ffffffffc02001d2:	6d158593          	addi	a1,a1,1745 # ffffffffc020689f <end+0x3ff>
ffffffffc02001d6:	00000797          	auipc	a5,0x0
ffffffffc02001da:	e7e78793          	addi	a5,a5,-386 # ffffffffc0200054 <kern_init>
ffffffffc02001de:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001ec:	95be                	add	a1,a1,a5
ffffffffc02001ee:	85a9                	srai	a1,a1,0xa
ffffffffc02001f0:	00002517          	auipc	a0,0x2
ffffffffc02001f4:	dc850513          	addi	a0,a0,-568 # ffffffffc0201fb8 <etext+0xe4>
}
ffffffffc02001f8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001fa:	b5f5                	j	ffffffffc02000e6 <cprintf>

ffffffffc02001fc <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001fc:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001fe:	00002617          	auipc	a2,0x2
ffffffffc0200202:	dea60613          	addi	a2,a2,-534 # ffffffffc0201fe8 <etext+0x114>
ffffffffc0200206:	04d00593          	li	a1,77
ffffffffc020020a:	00002517          	auipc	a0,0x2
ffffffffc020020e:	df650513          	addi	a0,a0,-522 # ffffffffc0202000 <etext+0x12c>
void print_stackframe(void) {
ffffffffc0200212:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200214:	1cc000ef          	jal	ra,ffffffffc02003e0 <__panic>

ffffffffc0200218 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200218:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020021a:	00002617          	auipc	a2,0x2
ffffffffc020021e:	dfe60613          	addi	a2,a2,-514 # ffffffffc0202018 <etext+0x144>
ffffffffc0200222:	00002597          	auipc	a1,0x2
ffffffffc0200226:	e1658593          	addi	a1,a1,-490 # ffffffffc0202038 <etext+0x164>
ffffffffc020022a:	00002517          	auipc	a0,0x2
ffffffffc020022e:	e1650513          	addi	a0,a0,-490 # ffffffffc0202040 <etext+0x16c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200232:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200234:	eb3ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
ffffffffc0200238:	00002617          	auipc	a2,0x2
ffffffffc020023c:	e1860613          	addi	a2,a2,-488 # ffffffffc0202050 <etext+0x17c>
ffffffffc0200240:	00002597          	auipc	a1,0x2
ffffffffc0200244:	e3858593          	addi	a1,a1,-456 # ffffffffc0202078 <etext+0x1a4>
ffffffffc0200248:	00002517          	auipc	a0,0x2
ffffffffc020024c:	df850513          	addi	a0,a0,-520 # ffffffffc0202040 <etext+0x16c>
ffffffffc0200250:	e97ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
ffffffffc0200254:	00002617          	auipc	a2,0x2
ffffffffc0200258:	e3460613          	addi	a2,a2,-460 # ffffffffc0202088 <etext+0x1b4>
ffffffffc020025c:	00002597          	auipc	a1,0x2
ffffffffc0200260:	e4c58593          	addi	a1,a1,-436 # ffffffffc02020a8 <etext+0x1d4>
ffffffffc0200264:	00002517          	auipc	a0,0x2
ffffffffc0200268:	ddc50513          	addi	a0,a0,-548 # ffffffffc0202040 <etext+0x16c>
ffffffffc020026c:	e7bff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    }
    return 0;
}
ffffffffc0200270:	60a2                	ld	ra,8(sp)
ffffffffc0200272:	4501                	li	a0,0
ffffffffc0200274:	0141                	addi	sp,sp,16
ffffffffc0200276:	8082                	ret

ffffffffc0200278 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200278:	1141                	addi	sp,sp,-16
ffffffffc020027a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020027c:	ef3ff0ef          	jal	ra,ffffffffc020016e <print_kerninfo>
    return 0;
}
ffffffffc0200280:	60a2                	ld	ra,8(sp)
ffffffffc0200282:	4501                	li	a0,0
ffffffffc0200284:	0141                	addi	sp,sp,16
ffffffffc0200286:	8082                	ret

ffffffffc0200288 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200288:	1141                	addi	sp,sp,-16
ffffffffc020028a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020028c:	f71ff0ef          	jal	ra,ffffffffc02001fc <print_stackframe>
    return 0;
}
ffffffffc0200290:	60a2                	ld	ra,8(sp)
ffffffffc0200292:	4501                	li	a0,0
ffffffffc0200294:	0141                	addi	sp,sp,16
ffffffffc0200296:	8082                	ret

ffffffffc0200298 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200298:	7115                	addi	sp,sp,-224
ffffffffc020029a:	ed5e                	sd	s7,152(sp)
ffffffffc020029c:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020029e:	00002517          	auipc	a0,0x2
ffffffffc02002a2:	e1a50513          	addi	a0,a0,-486 # ffffffffc02020b8 <etext+0x1e4>
kmonitor(struct trapframe *tf) {
ffffffffc02002a6:	ed86                	sd	ra,216(sp)
ffffffffc02002a8:	e9a2                	sd	s0,208(sp)
ffffffffc02002aa:	e5a6                	sd	s1,200(sp)
ffffffffc02002ac:	e1ca                	sd	s2,192(sp)
ffffffffc02002ae:	fd4e                	sd	s3,184(sp)
ffffffffc02002b0:	f952                	sd	s4,176(sp)
ffffffffc02002b2:	f556                	sd	s5,168(sp)
ffffffffc02002b4:	f15a                	sd	s6,160(sp)
ffffffffc02002b6:	e962                	sd	s8,144(sp)
ffffffffc02002b8:	e566                	sd	s9,136(sp)
ffffffffc02002ba:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002bc:	e2bff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002c0:	00002517          	auipc	a0,0x2
ffffffffc02002c4:	e2050513          	addi	a0,a0,-480 # ffffffffc02020e0 <etext+0x20c>
ffffffffc02002c8:	e1fff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    if (tf != NULL) {
ffffffffc02002cc:	000b8563          	beqz	s7,ffffffffc02002d6 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002d0:	855e                	mv	a0,s7
ffffffffc02002d2:	724000ef          	jal	ra,ffffffffc02009f6 <print_trapframe>
ffffffffc02002d6:	00002c17          	auipc	s8,0x2
ffffffffc02002da:	e7ac0c13          	addi	s8,s8,-390 # ffffffffc0202150 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002de:	00002917          	auipc	s2,0x2
ffffffffc02002e2:	e2a90913          	addi	s2,s2,-470 # ffffffffc0202108 <etext+0x234>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e6:	00002497          	auipc	s1,0x2
ffffffffc02002ea:	e2a48493          	addi	s1,s1,-470 # ffffffffc0202110 <etext+0x23c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ee:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002f0:	00002b17          	auipc	s6,0x2
ffffffffc02002f4:	e28b0b13          	addi	s6,s6,-472 # ffffffffc0202118 <etext+0x244>
        argv[argc ++] = buf;
ffffffffc02002f8:	00002a17          	auipc	s4,0x2
ffffffffc02002fc:	d40a0a13          	addi	s4,s4,-704 # ffffffffc0202038 <etext+0x164>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200300:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200302:	854a                	mv	a0,s2
ffffffffc0200304:	211010ef          	jal	ra,ffffffffc0201d14 <readline>
ffffffffc0200308:	842a                	mv	s0,a0
ffffffffc020030a:	dd65                	beqz	a0,ffffffffc0200302 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030c:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200310:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200312:	e1bd                	bnez	a1,ffffffffc0200378 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200314:	fe0c87e3          	beqz	s9,ffffffffc0200302 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200318:	6582                	ld	a1,0(sp)
ffffffffc020031a:	00002d17          	auipc	s10,0x2
ffffffffc020031e:	e36d0d13          	addi	s10,s10,-458 # ffffffffc0202150 <commands>
        argv[argc ++] = buf;
ffffffffc0200322:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200324:	4401                	li	s0,0
ffffffffc0200326:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200328:	341010ef          	jal	ra,ffffffffc0201e68 <strcmp>
ffffffffc020032c:	c919                	beqz	a0,ffffffffc0200342 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032e:	2405                	addiw	s0,s0,1
ffffffffc0200330:	0b540063          	beq	s0,s5,ffffffffc02003d0 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200334:	000d3503          	ld	a0,0(s10)
ffffffffc0200338:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020033a:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020033c:	32d010ef          	jal	ra,ffffffffc0201e68 <strcmp>
ffffffffc0200340:	f57d                	bnez	a0,ffffffffc020032e <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200342:	00141793          	slli	a5,s0,0x1
ffffffffc0200346:	97a2                	add	a5,a5,s0
ffffffffc0200348:	078e                	slli	a5,a5,0x3
ffffffffc020034a:	97e2                	add	a5,a5,s8
ffffffffc020034c:	6b9c                	ld	a5,16(a5)
ffffffffc020034e:	865e                	mv	a2,s7
ffffffffc0200350:	002c                	addi	a1,sp,8
ffffffffc0200352:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200356:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200358:	fa0555e3          	bgez	a0,ffffffffc0200302 <kmonitor+0x6a>
}
ffffffffc020035c:	60ee                	ld	ra,216(sp)
ffffffffc020035e:	644e                	ld	s0,208(sp)
ffffffffc0200360:	64ae                	ld	s1,200(sp)
ffffffffc0200362:	690e                	ld	s2,192(sp)
ffffffffc0200364:	79ea                	ld	s3,184(sp)
ffffffffc0200366:	7a4a                	ld	s4,176(sp)
ffffffffc0200368:	7aaa                	ld	s5,168(sp)
ffffffffc020036a:	7b0a                	ld	s6,160(sp)
ffffffffc020036c:	6bea                	ld	s7,152(sp)
ffffffffc020036e:	6c4a                	ld	s8,144(sp)
ffffffffc0200370:	6caa                	ld	s9,136(sp)
ffffffffc0200372:	6d0a                	ld	s10,128(sp)
ffffffffc0200374:	612d                	addi	sp,sp,224
ffffffffc0200376:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200378:	8526                	mv	a0,s1
ffffffffc020037a:	333010ef          	jal	ra,ffffffffc0201eac <strchr>
ffffffffc020037e:	c901                	beqz	a0,ffffffffc020038e <kmonitor+0xf6>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200384:	00040023          	sb	zero,0(s0)
ffffffffc0200388:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	d5c9                	beqz	a1,ffffffffc0200314 <kmonitor+0x7c>
ffffffffc020038c:	b7f5                	j	ffffffffc0200378 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020038e:	00044783          	lbu	a5,0(s0)
ffffffffc0200392:	d3c9                	beqz	a5,ffffffffc0200314 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200394:	033c8963          	beq	s9,s3,ffffffffc02003c6 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200398:	003c9793          	slli	a5,s9,0x3
ffffffffc020039c:	0118                	addi	a4,sp,128
ffffffffc020039e:	97ba                	add	a5,a5,a4
ffffffffc02003a0:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a4:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a8:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003aa:	e591                	bnez	a1,ffffffffc02003b6 <kmonitor+0x11e>
ffffffffc02003ac:	b7b5                	j	ffffffffc0200318 <kmonitor+0x80>
ffffffffc02003ae:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b2:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b4:	d1a5                	beqz	a1,ffffffffc0200314 <kmonitor+0x7c>
ffffffffc02003b6:	8526                	mv	a0,s1
ffffffffc02003b8:	2f5010ef          	jal	ra,ffffffffc0201eac <strchr>
ffffffffc02003bc:	d96d                	beqz	a0,ffffffffc02003ae <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00044583          	lbu	a1,0(s0)
ffffffffc02003c2:	d9a9                	beqz	a1,ffffffffc0200314 <kmonitor+0x7c>
ffffffffc02003c4:	bf55                	j	ffffffffc0200378 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c6:	45c1                	li	a1,16
ffffffffc02003c8:	855a                	mv	a0,s6
ffffffffc02003ca:	d1dff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
ffffffffc02003ce:	b7e9                	j	ffffffffc0200398 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003d0:	6582                	ld	a1,0(sp)
ffffffffc02003d2:	00002517          	auipc	a0,0x2
ffffffffc02003d6:	d6650513          	addi	a0,a0,-666 # ffffffffc0202138 <etext+0x264>
ffffffffc02003da:	d0dff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    return 0;
ffffffffc02003de:	b715                	j	ffffffffc0200302 <kmonitor+0x6a>

ffffffffc02003e0 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003e0:	00006317          	auipc	t1,0x6
ffffffffc02003e4:	06030313          	addi	t1,t1,96 # ffffffffc0206440 <is_panic>
ffffffffc02003e8:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003ec:	715d                	addi	sp,sp,-80
ffffffffc02003ee:	ec06                	sd	ra,24(sp)
ffffffffc02003f0:	e822                	sd	s0,16(sp)
ffffffffc02003f2:	f436                	sd	a3,40(sp)
ffffffffc02003f4:	f83a                	sd	a4,48(sp)
ffffffffc02003f6:	fc3e                	sd	a5,56(sp)
ffffffffc02003f8:	e0c2                	sd	a6,64(sp)
ffffffffc02003fa:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003fc:	020e1a63          	bnez	t3,ffffffffc0200430 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200400:	4785                	li	a5,1
ffffffffc0200402:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200406:	8432                	mv	s0,a2
ffffffffc0200408:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	862e                	mv	a2,a1
ffffffffc020040c:	85aa                	mv	a1,a0
ffffffffc020040e:	00002517          	auipc	a0,0x2
ffffffffc0200412:	d8a50513          	addi	a0,a0,-630 # ffffffffc0202198 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200416:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200418:	ccfff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020041c:	65a2                	ld	a1,8(sp)
ffffffffc020041e:	8522                	mv	a0,s0
ffffffffc0200420:	ca7ff0ef          	jal	ra,ffffffffc02000c6 <vcprintf>
    cprintf("\n");
ffffffffc0200424:	00002517          	auipc	a0,0x2
ffffffffc0200428:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0201fe0 <etext+0x10c>
ffffffffc020042c:	cbbff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200430:	3e0000ef          	jal	ra,ffffffffc0200810 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200434:	4501                	li	a0,0
ffffffffc0200436:	e63ff0ef          	jal	ra,ffffffffc0200298 <kmonitor>
    while (1) {
ffffffffc020043a:	bfed                	j	ffffffffc0200434 <__panic+0x54>

ffffffffc020043c <clock_set_next_event>:
volatile size_t ticks;

static inline uint64_t get_cycles(void) {
#if __riscv_xlen == 64
    uint64_t n;
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200440:	67e1                	lui	a5,0x18
ffffffffc0200442:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200446:	953e                	add	a0,a0,a5
ffffffffc0200448:	19b0106f          	j	ffffffffc0201de2 <sbi_set_timer>

ffffffffc020044c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044c:	8082                	ret

ffffffffc020044e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044e:	0ff57513          	zext.b	a0,a0
ffffffffc0200452:	1770106f          	j	ffffffffc0201dc8 <sbi_console_putchar>

ffffffffc0200456 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200456:	1a70106f          	j	ffffffffc0201dfc <sbi_console_getchar>

ffffffffc020045a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020045a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020045c:	00002517          	auipc	a0,0x2
ffffffffc0200460:	d5c50513          	addi	a0,a0,-676 # ffffffffc02021b8 <commands+0x68>
void dtb_init(void) {
ffffffffc0200464:	fc86                	sd	ra,120(sp)
ffffffffc0200466:	f8a2                	sd	s0,112(sp)
ffffffffc0200468:	e8d2                	sd	s4,80(sp)
ffffffffc020046a:	f4a6                	sd	s1,104(sp)
ffffffffc020046c:	f0ca                	sd	s2,96(sp)
ffffffffc020046e:	ecce                	sd	s3,88(sp)
ffffffffc0200470:	e4d6                	sd	s5,72(sp)
ffffffffc0200472:	e0da                	sd	s6,64(sp)
ffffffffc0200474:	fc5e                	sd	s7,56(sp)
ffffffffc0200476:	f862                	sd	s8,48(sp)
ffffffffc0200478:	f466                	sd	s9,40(sp)
ffffffffc020047a:	f06a                	sd	s10,32(sp)
ffffffffc020047c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020047e:	c69ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200482:	00006597          	auipc	a1,0x6
ffffffffc0200486:	b7e5b583          	ld	a1,-1154(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	d3e50513          	addi	a0,a0,-706 # ffffffffc02021c8 <commands+0x78>
ffffffffc0200492:	c55ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200496:	00006417          	auipc	s0,0x6
ffffffffc020049a:	b7240413          	addi	s0,s0,-1166 # ffffffffc0206008 <boot_dtb>
ffffffffc020049e:	600c                	ld	a1,0(s0)
ffffffffc02004a0:	00002517          	auipc	a0,0x2
ffffffffc02004a4:	d3850513          	addi	a0,a0,-712 # ffffffffc02021d8 <commands+0x88>
ffffffffc02004a8:	c3fff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004ac:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	d4050513          	addi	a0,a0,-704 # ffffffffc02021f0 <commands+0xa0>
    if (boot_dtb == 0) {
ffffffffc02004b8:	120a0463          	beqz	s4,ffffffffc02005e0 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004bc:	57f5                	li	a5,-3
ffffffffc02004be:	07fa                	slli	a5,a5,0x1e
ffffffffc02004c0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004c4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ca:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004d0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004dc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	8ec9                	or	a3,a3,a0
ffffffffc02004e4:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004e8:	1b7d                	addi	s6,s6,-1
ffffffffc02004ea:	0167f7b3          	and	a5,a5,s6
ffffffffc02004ee:	8dd5                	or	a1,a1,a3
ffffffffc02004f0:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004f2:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02004f8:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc02004fc:	10f59163          	bne	a1,a5,ffffffffc02005fe <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200500:	471c                	lw	a5,8(a4)
ffffffffc0200502:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200504:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200506:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020050a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020050e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200516:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200530:	01146433          	or	s0,s0,a7
ffffffffc0200534:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200538:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200542:	8c49                	or	s0,s0,a0
ffffffffc0200544:	0166f6b3          	and	a3,a3,s6
ffffffffc0200548:	00ca6a33          	or	s4,s4,a2
ffffffffc020054c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200550:	8c55                	or	s0,s0,a3
ffffffffc0200552:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200556:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200558:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020055a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020055c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200560:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200562:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200568:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020056a:	00002917          	auipc	s2,0x2
ffffffffc020056e:	cd690913          	addi	s2,s2,-810 # ffffffffc0202240 <commands+0xf0>
ffffffffc0200572:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200574:	4d91                	li	s11,4
ffffffffc0200576:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200578:	00002497          	auipc	s1,0x2
ffffffffc020057c:	cc048493          	addi	s1,s1,-832 # ffffffffc0202238 <commands+0xe8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200580:	000a2703          	lw	a4,0(s4)
ffffffffc0200584:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200588:	0087569b          	srliw	a3,a4,0x8
ffffffffc020058c:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200590:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200594:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	0107571b          	srliw	a4,a4,0x10
ffffffffc020059c:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059e:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005a6:	8fd5                	or	a5,a5,a3
ffffffffc02005a8:	00eb7733          	and	a4,s6,a4
ffffffffc02005ac:	8fd9                	or	a5,a5,a4
ffffffffc02005ae:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005b0:	09778c63          	beq	a5,s7,ffffffffc0200648 <dtb_init+0x1ee>
ffffffffc02005b4:	00fbea63          	bltu	s7,a5,ffffffffc02005c8 <dtb_init+0x16e>
ffffffffc02005b8:	07a78663          	beq	a5,s10,ffffffffc0200624 <dtb_init+0x1ca>
ffffffffc02005bc:	4709                	li	a4,2
ffffffffc02005be:	00e79763          	bne	a5,a4,ffffffffc02005cc <dtb_init+0x172>
ffffffffc02005c2:	4c81                	li	s9,0
ffffffffc02005c4:	8a56                	mv	s4,s5
ffffffffc02005c6:	bf6d                	j	ffffffffc0200580 <dtb_init+0x126>
ffffffffc02005c8:	ffb78ee3          	beq	a5,s11,ffffffffc02005c4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005cc:	00002517          	auipc	a0,0x2
ffffffffc02005d0:	cec50513          	addi	a0,a0,-788 # ffffffffc02022b8 <commands+0x168>
ffffffffc02005d4:	b13ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005d8:	00002517          	auipc	a0,0x2
ffffffffc02005dc:	d1850513          	addi	a0,a0,-744 # ffffffffc02022f0 <commands+0x1a0>
}
ffffffffc02005e0:	7446                	ld	s0,112(sp)
ffffffffc02005e2:	70e6                	ld	ra,120(sp)
ffffffffc02005e4:	74a6                	ld	s1,104(sp)
ffffffffc02005e6:	7906                	ld	s2,96(sp)
ffffffffc02005e8:	69e6                	ld	s3,88(sp)
ffffffffc02005ea:	6a46                	ld	s4,80(sp)
ffffffffc02005ec:	6aa6                	ld	s5,72(sp)
ffffffffc02005ee:	6b06                	ld	s6,64(sp)
ffffffffc02005f0:	7be2                	ld	s7,56(sp)
ffffffffc02005f2:	7c42                	ld	s8,48(sp)
ffffffffc02005f4:	7ca2                	ld	s9,40(sp)
ffffffffc02005f6:	7d02                	ld	s10,32(sp)
ffffffffc02005f8:	6de2                	ld	s11,24(sp)
ffffffffc02005fa:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02005fc:	b4ed                	j	ffffffffc02000e6 <cprintf>
}
ffffffffc02005fe:	7446                	ld	s0,112(sp)
ffffffffc0200600:	70e6                	ld	ra,120(sp)
ffffffffc0200602:	74a6                	ld	s1,104(sp)
ffffffffc0200604:	7906                	ld	s2,96(sp)
ffffffffc0200606:	69e6                	ld	s3,88(sp)
ffffffffc0200608:	6a46                	ld	s4,80(sp)
ffffffffc020060a:	6aa6                	ld	s5,72(sp)
ffffffffc020060c:	6b06                	ld	s6,64(sp)
ffffffffc020060e:	7be2                	ld	s7,56(sp)
ffffffffc0200610:	7c42                	ld	s8,48(sp)
ffffffffc0200612:	7ca2                	ld	s9,40(sp)
ffffffffc0200614:	7d02                	ld	s10,32(sp)
ffffffffc0200616:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200618:	00002517          	auipc	a0,0x2
ffffffffc020061c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0202210 <commands+0xc0>
}
ffffffffc0200620:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200622:	b4d1                	j	ffffffffc02000e6 <cprintf>
                int name_len = strlen(name);
ffffffffc0200624:	8556                	mv	a0,s5
ffffffffc0200626:	00d010ef          	jal	ra,ffffffffc0201e32 <strlen>
ffffffffc020062a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020062c:	4619                	li	a2,6
ffffffffc020062e:	85a6                	mv	a1,s1
ffffffffc0200630:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200632:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200634:	053010ef          	jal	ra,ffffffffc0201e86 <strncmp>
ffffffffc0200638:	e111                	bnez	a0,ffffffffc020063c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020063a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020063c:	0a91                	addi	s5,s5,4
ffffffffc020063e:	9ad2                	add	s5,s5,s4
ffffffffc0200640:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200644:	8a56                	mv	s4,s5
ffffffffc0200646:	bf2d                	j	ffffffffc0200580 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200648:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020064c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200650:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200654:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200660:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200664:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200668:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200670:	00eaeab3          	or	s5,s5,a4
ffffffffc0200674:	00fb77b3          	and	a5,s6,a5
ffffffffc0200678:	00faeab3          	or	s5,s5,a5
ffffffffc020067c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020067e:	000c9c63          	bnez	s9,ffffffffc0200696 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200682:	1a82                	slli	s5,s5,0x20
ffffffffc0200684:	00368793          	addi	a5,a3,3
ffffffffc0200688:	020ada93          	srli	s5,s5,0x20
ffffffffc020068c:	9abe                	add	s5,s5,a5
ffffffffc020068e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200692:	8a56                	mv	s4,s5
ffffffffc0200694:	b5f5                	j	ffffffffc0200580 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200696:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020069a:	85ca                	mv	a1,s2
ffffffffc020069c:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006aa:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006b2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006bc:	8d59                	or	a0,a0,a4
ffffffffc02006be:	00fb77b3          	and	a5,s6,a5
ffffffffc02006c2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006c4:	1502                	slli	a0,a0,0x20
ffffffffc02006c6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006c8:	9522                	add	a0,a0,s0
ffffffffc02006ca:	79e010ef          	jal	ra,ffffffffc0201e68 <strcmp>
ffffffffc02006ce:	66a2                	ld	a3,8(sp)
ffffffffc02006d0:	f94d                	bnez	a0,ffffffffc0200682 <dtb_init+0x228>
ffffffffc02006d2:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200682 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006d6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006da:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006de:	00002517          	auipc	a0,0x2
ffffffffc02006e2:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0202248 <commands+0xf8>
           fdt32_to_cpu(x >> 32);
ffffffffc02006e6:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ea:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02006ee:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f2:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02006f6:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fa:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006fe:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0187d693          	srli	a3,a5,0x18
ffffffffc0200706:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020070a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020070e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200716:	010f6f33          	or	t5,t5,a6
ffffffffc020071a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020071e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200722:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200726:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072a:	0186f6b3          	and	a3,a3,s8
ffffffffc020072e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200732:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107581b          	srliw	a6,a4,0x10
ffffffffc020073a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	8361                	srli	a4,a4,0x18
ffffffffc0200740:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200744:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200748:	01e6e6b3          	or	a3,a3,t5
ffffffffc020074c:	00cb7633          	and	a2,s6,a2
ffffffffc0200750:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200754:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200758:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200760:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200764:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200768:	0088989b          	slliw	a7,a7,0x8
ffffffffc020076c:	011b78b3          	and	a7,s6,a7
ffffffffc0200770:	005eeeb3          	or	t4,t4,t0
ffffffffc0200774:	00c6e733          	or	a4,a3,a2
ffffffffc0200778:	006c6c33          	or	s8,s8,t1
ffffffffc020077c:	010b76b3          	and	a3,s6,a6
ffffffffc0200780:	00bb7b33          	and	s6,s6,a1
ffffffffc0200784:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200788:	016c6b33          	or	s6,s8,s6
ffffffffc020078c:	01146433          	or	s0,s0,a7
ffffffffc0200790:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200792:	1702                	slli	a4,a4,0x20
ffffffffc0200794:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200796:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200798:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020079a:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020079c:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007a0:	0167eb33          	or	s6,a5,s6
ffffffffc02007a4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007a6:	941ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007aa:	85a2                	mv	a1,s0
ffffffffc02007ac:	00002517          	auipc	a0,0x2
ffffffffc02007b0:	abc50513          	addi	a0,a0,-1348 # ffffffffc0202268 <commands+0x118>
ffffffffc02007b4:	933ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007b8:	014b5613          	srli	a2,s6,0x14
ffffffffc02007bc:	85da                	mv	a1,s6
ffffffffc02007be:	00002517          	auipc	a0,0x2
ffffffffc02007c2:	ac250513          	addi	a0,a0,-1342 # ffffffffc0202280 <commands+0x130>
ffffffffc02007c6:	921ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007ca:	008b05b3          	add	a1,s6,s0
ffffffffc02007ce:	15fd                	addi	a1,a1,-1
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	ad050513          	addi	a0,a0,-1328 # ffffffffc02022a0 <commands+0x150>
ffffffffc02007d8:	90fff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007dc:	00002517          	auipc	a0,0x2
ffffffffc02007e0:	b1450513          	addi	a0,a0,-1260 # ffffffffc02022f0 <commands+0x1a0>
        memory_base = mem_base;
ffffffffc02007e4:	00006797          	auipc	a5,0x6
ffffffffc02007e8:	c687b623          	sd	s0,-916(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc02007ec:	00006797          	auipc	a5,0x6
ffffffffc02007f0:	c767b623          	sd	s6,-916(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007f4:	b3f5                	j	ffffffffc02005e0 <dtb_init+0x186>

ffffffffc02007f6 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007f6:	00006517          	auipc	a0,0x6
ffffffffc02007fa:	c5a53503          	ld	a0,-934(a0) # ffffffffc0206450 <memory_base>
ffffffffc02007fe:	8082                	ret

ffffffffc0200800 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200800:	00006517          	auipc	a0,0x6
ffffffffc0200804:	c5853503          	ld	a0,-936(a0) # ffffffffc0206458 <memory_size>
ffffffffc0200808:	8082                	ret

ffffffffc020080a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020080a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020080e:	8082                	ret

ffffffffc0200810 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200810:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200814:	8082                	ret

ffffffffc0200816 <idt_init>:
     */
    
    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200816:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020081a:	00000797          	auipc	a5,0x0
ffffffffc020081e:	3a278793          	addi	a5,a5,930 # ffffffffc0200bbc <__alltraps>
ffffffffc0200822:	10579073          	csrw	stvec,a5
}
ffffffffc0200826:	8082                	ret

ffffffffc0200828 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200828:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020082a:	1141                	addi	sp,sp,-16
ffffffffc020082c:	e022                	sd	s0,0(sp)
ffffffffc020082e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200830:	00002517          	auipc	a0,0x2
ffffffffc0200834:	ad850513          	addi	a0,a0,-1320 # ffffffffc0202308 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200838:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020083a:	8adff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020083e:	640c                	ld	a1,8(s0)
ffffffffc0200840:	00002517          	auipc	a0,0x2
ffffffffc0200844:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202320 <commands+0x1d0>
ffffffffc0200848:	89fff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020084c:	680c                	ld	a1,16(s0)
ffffffffc020084e:	00002517          	auipc	a0,0x2
ffffffffc0200852:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202338 <commands+0x1e8>
ffffffffc0200856:	891ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020085a:	6c0c                	ld	a1,24(s0)
ffffffffc020085c:	00002517          	auipc	a0,0x2
ffffffffc0200860:	af450513          	addi	a0,a0,-1292 # ffffffffc0202350 <commands+0x200>
ffffffffc0200864:	883ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200868:	700c                	ld	a1,32(s0)
ffffffffc020086a:	00002517          	auipc	a0,0x2
ffffffffc020086e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0202368 <commands+0x218>
ffffffffc0200872:	875ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200876:	740c                	ld	a1,40(s0)
ffffffffc0200878:	00002517          	auipc	a0,0x2
ffffffffc020087c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0202380 <commands+0x230>
ffffffffc0200880:	867ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200884:	780c                	ld	a1,48(s0)
ffffffffc0200886:	00002517          	auipc	a0,0x2
ffffffffc020088a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0202398 <commands+0x248>
ffffffffc020088e:	859ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200892:	7c0c                	ld	a1,56(s0)
ffffffffc0200894:	00002517          	auipc	a0,0x2
ffffffffc0200898:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02023b0 <commands+0x260>
ffffffffc020089c:	84bff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008a0:	602c                	ld	a1,64(s0)
ffffffffc02008a2:	00002517          	auipc	a0,0x2
ffffffffc02008a6:	b2650513          	addi	a0,a0,-1242 # ffffffffc02023c8 <commands+0x278>
ffffffffc02008aa:	83dff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008ae:	642c                	ld	a1,72(s0)
ffffffffc02008b0:	00002517          	auipc	a0,0x2
ffffffffc02008b4:	b3050513          	addi	a0,a0,-1232 # ffffffffc02023e0 <commands+0x290>
ffffffffc02008b8:	82fff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008bc:	682c                	ld	a1,80(s0)
ffffffffc02008be:	00002517          	auipc	a0,0x2
ffffffffc02008c2:	b3a50513          	addi	a0,a0,-1222 # ffffffffc02023f8 <commands+0x2a8>
ffffffffc02008c6:	821ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008ca:	6c2c                	ld	a1,88(s0)
ffffffffc02008cc:	00002517          	auipc	a0,0x2
ffffffffc02008d0:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202410 <commands+0x2c0>
ffffffffc02008d4:	813ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008d8:	702c                	ld	a1,96(s0)
ffffffffc02008da:	00002517          	auipc	a0,0x2
ffffffffc02008de:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0202428 <commands+0x2d8>
ffffffffc02008e2:	805ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008e6:	742c                	ld	a1,104(s0)
ffffffffc02008e8:	00002517          	auipc	a0,0x2
ffffffffc02008ec:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202440 <commands+0x2f0>
ffffffffc02008f0:	ff6ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008f4:	782c                	ld	a1,112(s0)
ffffffffc02008f6:	00002517          	auipc	a0,0x2
ffffffffc02008fa:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202458 <commands+0x308>
ffffffffc02008fe:	fe8ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200902:	7c2c                	ld	a1,120(s0)
ffffffffc0200904:	00002517          	auipc	a0,0x2
ffffffffc0200908:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202470 <commands+0x320>
ffffffffc020090c:	fdaff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200910:	604c                	ld	a1,128(s0)
ffffffffc0200912:	00002517          	auipc	a0,0x2
ffffffffc0200916:	b7650513          	addi	a0,a0,-1162 # ffffffffc0202488 <commands+0x338>
ffffffffc020091a:	fccff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020091e:	644c                	ld	a1,136(s0)
ffffffffc0200920:	00002517          	auipc	a0,0x2
ffffffffc0200924:	b8050513          	addi	a0,a0,-1152 # ffffffffc02024a0 <commands+0x350>
ffffffffc0200928:	fbeff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020092c:	684c                	ld	a1,144(s0)
ffffffffc020092e:	00002517          	auipc	a0,0x2
ffffffffc0200932:	b8a50513          	addi	a0,a0,-1142 # ffffffffc02024b8 <commands+0x368>
ffffffffc0200936:	fb0ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020093a:	6c4c                	ld	a1,152(s0)
ffffffffc020093c:	00002517          	auipc	a0,0x2
ffffffffc0200940:	b9450513          	addi	a0,a0,-1132 # ffffffffc02024d0 <commands+0x380>
ffffffffc0200944:	fa2ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200948:	704c                	ld	a1,160(s0)
ffffffffc020094a:	00002517          	auipc	a0,0x2
ffffffffc020094e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02024e8 <commands+0x398>
ffffffffc0200952:	f94ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200956:	744c                	ld	a1,168(s0)
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202500 <commands+0x3b0>
ffffffffc0200960:	f86ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200964:	784c                	ld	a1,176(s0)
ffffffffc0200966:	00002517          	auipc	a0,0x2
ffffffffc020096a:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202518 <commands+0x3c8>
ffffffffc020096e:	f78ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200972:	7c4c                	ld	a1,184(s0)
ffffffffc0200974:	00002517          	auipc	a0,0x2
ffffffffc0200978:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202530 <commands+0x3e0>
ffffffffc020097c:	f6aff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200980:	606c                	ld	a1,192(s0)
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202548 <commands+0x3f8>
ffffffffc020098a:	f5cff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc020098e:	646c                	ld	a1,200(s0)
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202560 <commands+0x410>
ffffffffc0200998:	f4eff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc020099c:	686c                	ld	a1,208(s0)
ffffffffc020099e:	00002517          	auipc	a0,0x2
ffffffffc02009a2:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202578 <commands+0x428>
ffffffffc02009a6:	f40ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009aa:	6c6c                	ld	a1,216(s0)
ffffffffc02009ac:	00002517          	auipc	a0,0x2
ffffffffc02009b0:	be450513          	addi	a0,a0,-1052 # ffffffffc0202590 <commands+0x440>
ffffffffc02009b4:	f32ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009b8:	706c                	ld	a1,224(s0)
ffffffffc02009ba:	00002517          	auipc	a0,0x2
ffffffffc02009be:	bee50513          	addi	a0,a0,-1042 # ffffffffc02025a8 <commands+0x458>
ffffffffc02009c2:	f24ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009c6:	746c                	ld	a1,232(s0)
ffffffffc02009c8:	00002517          	auipc	a0,0x2
ffffffffc02009cc:	bf850513          	addi	a0,a0,-1032 # ffffffffc02025c0 <commands+0x470>
ffffffffc02009d0:	f16ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009d4:	786c                	ld	a1,240(s0)
ffffffffc02009d6:	00002517          	auipc	a0,0x2
ffffffffc02009da:	c0250513          	addi	a0,a0,-1022 # ffffffffc02025d8 <commands+0x488>
ffffffffc02009de:	f08ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009e2:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009e4:	6402                	ld	s0,0(sp)
ffffffffc02009e6:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009e8:	00002517          	auipc	a0,0x2
ffffffffc02009ec:	c0850513          	addi	a0,a0,-1016 # ffffffffc02025f0 <commands+0x4a0>
}
ffffffffc02009f0:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009f2:	ef4ff06f          	j	ffffffffc02000e6 <cprintf>

ffffffffc02009f6 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009f6:	1141                	addi	sp,sp,-16
ffffffffc02009f8:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009fa:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009fc:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009fe:	00002517          	auipc	a0,0x2
ffffffffc0200a02:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202608 <commands+0x4b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a06:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a08:	edeff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a0c:	8522                	mv	a0,s0
ffffffffc0200a0e:	e1bff0ef          	jal	ra,ffffffffc0200828 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a12:	10043583          	ld	a1,256(s0)
ffffffffc0200a16:	00002517          	auipc	a0,0x2
ffffffffc0200a1a:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202620 <commands+0x4d0>
ffffffffc0200a1e:	ec8ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a22:	10843583          	ld	a1,264(s0)
ffffffffc0200a26:	00002517          	auipc	a0,0x2
ffffffffc0200a2a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202638 <commands+0x4e8>
ffffffffc0200a2e:	eb8ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a32:	11043583          	ld	a1,272(s0)
ffffffffc0200a36:	00002517          	auipc	a0,0x2
ffffffffc0200a3a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202650 <commands+0x500>
ffffffffc0200a3e:	ea8ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a42:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a46:	6402                	ld	s0,0(sp)
ffffffffc0200a48:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202668 <commands+0x518>
}
ffffffffc0200a52:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a54:	e92ff06f          	j	ffffffffc02000e6 <cprintf>

ffffffffc0200a58 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a58:	11853783          	ld	a5,280(a0)
ffffffffc0200a5c:	472d                	li	a4,11
ffffffffc0200a5e:	0786                	slli	a5,a5,0x1
ffffffffc0200a60:	8385                	srli	a5,a5,0x1
ffffffffc0200a62:	08f76963          	bltu	a4,a5,ffffffffc0200af4 <interrupt_handler+0x9c>
ffffffffc0200a66:	00002717          	auipc	a4,0x2
ffffffffc0200a6a:	ce270713          	addi	a4,a4,-798 # ffffffffc0202748 <commands+0x5f8>
ffffffffc0200a6e:	078a                	slli	a5,a5,0x2
ffffffffc0200a70:	97ba                	add	a5,a5,a4
ffffffffc0200a72:	439c                	lw	a5,0(a5)
ffffffffc0200a74:	97ba                	add	a5,a5,a4
ffffffffc0200a76:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a78:	00002517          	auipc	a0,0x2
ffffffffc0200a7c:	c6850513          	addi	a0,a0,-920 # ffffffffc02026e0 <commands+0x590>
ffffffffc0200a80:	e66ff06f          	j	ffffffffc02000e6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a84:	00002517          	auipc	a0,0x2
ffffffffc0200a88:	c3c50513          	addi	a0,a0,-964 # ffffffffc02026c0 <commands+0x570>
ffffffffc0200a8c:	e5aff06f          	j	ffffffffc02000e6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a90:	00002517          	auipc	a0,0x2
ffffffffc0200a94:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202680 <commands+0x530>
ffffffffc0200a98:	e4eff06f          	j	ffffffffc02000e6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a9c:	00002517          	auipc	a0,0x2
ffffffffc0200aa0:	c6450513          	addi	a0,a0,-924 # ffffffffc0202700 <commands+0x5b0>
ffffffffc0200aa4:	e42ff06f          	j	ffffffffc02000e6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200aa8:	1141                	addi	sp,sp,-16
ffffffffc0200aaa:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200aac:	991ff0ef          	jal	ra,ffffffffc020043c <clock_set_next_event>
            ticks++;
ffffffffc0200ab0:	00006797          	auipc	a5,0x6
ffffffffc0200ab4:	99878793          	addi	a5,a5,-1640 # ffffffffc0206448 <ticks>
ffffffffc0200ab8:	6398                	ld	a4,0(a5)
            if(ticks==TICK_NUM){
ffffffffc0200aba:	06400693          	li	a3,100
            ticks++;
ffffffffc0200abe:	0705                	addi	a4,a4,1
ffffffffc0200ac0:	e398                	sd	a4,0(a5)
            if(ticks==TICK_NUM){
ffffffffc0200ac2:	639c                	ld	a5,0(a5)
ffffffffc0200ac4:	02d78963          	beq	a5,a3,ffffffffc0200af6 <interrupt_handler+0x9e>
               print_ticks(TICK_NUM);
               ticks=0;
               PRINT_COUNT++;
            }
            if(PRINT_COUNT==10){
ffffffffc0200ac8:	00006717          	auipc	a4,0x6
ffffffffc0200acc:	99872703          	lw	a4,-1640(a4) # ffffffffc0206460 <PRINT_COUNT>
ffffffffc0200ad0:	47a9                	li	a5,10
ffffffffc0200ad2:	04f70763          	beq	a4,a5,ffffffffc0200b20 <interrupt_handler+0xc8>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ad6:	60a2                	ld	ra,8(sp)
ffffffffc0200ad8:	0141                	addi	sp,sp,16
ffffffffc0200ada:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200adc:	00002517          	auipc	a0,0x2
ffffffffc0200ae0:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202728 <commands+0x5d8>
ffffffffc0200ae4:	e02ff06f          	j	ffffffffc02000e6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ae8:	00002517          	auipc	a0,0x2
ffffffffc0200aec:	bb850513          	addi	a0,a0,-1096 # ffffffffc02026a0 <commands+0x550>
ffffffffc0200af0:	df6ff06f          	j	ffffffffc02000e6 <cprintf>
            print_trapframe(tf);
ffffffffc0200af4:	b709                	j	ffffffffc02009f6 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200af6:	06400593          	li	a1,100
ffffffffc0200afa:	00002517          	auipc	a0,0x2
ffffffffc0200afe:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202718 <commands+0x5c8>
ffffffffc0200b02:	de4ff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
               PRINT_COUNT++;
ffffffffc0200b06:	00006697          	auipc	a3,0x6
ffffffffc0200b0a:	95a68693          	addi	a3,a3,-1702 # ffffffffc0206460 <PRINT_COUNT>
ffffffffc0200b0e:	429c                	lw	a5,0(a3)
               ticks=0;
ffffffffc0200b10:	00006717          	auipc	a4,0x6
ffffffffc0200b14:	92073c23          	sd	zero,-1736(a4) # ffffffffc0206448 <ticks>
               PRINT_COUNT++;
ffffffffc0200b18:	0017871b          	addiw	a4,a5,1
ffffffffc0200b1c:	c298                	sw	a4,0(a3)
ffffffffc0200b1e:	bf4d                	j	ffffffffc0200ad0 <interrupt_handler+0x78>
}
ffffffffc0200b20:	60a2                	ld	ra,8(sp)
ffffffffc0200b22:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200b24:	2f40106f          	j	ffffffffc0201e18 <sbi_shutdown>

ffffffffc0200b28 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b28:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b2c:	1141                	addi	sp,sp,-16
ffffffffc0200b2e:	e022                	sd	s0,0(sp)
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b32:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b34:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b36:	04e78663          	beq	a5,a4,ffffffffc0200b82 <exception_handler+0x5a>
ffffffffc0200b3a:	02f76c63          	bltu	a4,a5,ffffffffc0200b72 <exception_handler+0x4a>
ffffffffc0200b3e:	4709                	li	a4,2
ffffffffc0200b40:	02e79563          	bne	a5,a4,ffffffffc0200b6a <exception_handler+0x42>
             /* LAB3 CHALLENGE3   2311656 :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
           cprintf("Exception type:Illegal instruction\n");
ffffffffc0200b44:	00002517          	auipc	a0,0x2
ffffffffc0200b48:	c3450513          	addi	a0,a0,-972 # ffffffffc0202778 <commands+0x628>
ffffffffc0200b4c:	d9aff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
           cprintf("Illegal instruction caught at %p\n",tf->epc);
ffffffffc0200b50:	10843583          	ld	a1,264(s0)
ffffffffc0200b54:	00002517          	auipc	a0,0x2
ffffffffc0200b58:	c4c50513          	addi	a0,a0,-948 # ffffffffc02027a0 <commands+0x650>
ffffffffc0200b5c:	d8aff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
           tf->epc+=4;
ffffffffc0200b60:	10843783          	ld	a5,264(s0)
ffffffffc0200b64:	0791                	addi	a5,a5,4
ffffffffc0200b66:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b6a:	60a2                	ld	ra,8(sp)
ffffffffc0200b6c:	6402                	ld	s0,0(sp)
ffffffffc0200b6e:	0141                	addi	sp,sp,16
ffffffffc0200b70:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b72:	17f1                	addi	a5,a5,-4
ffffffffc0200b74:	471d                	li	a4,7
ffffffffc0200b76:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b6a <exception_handler+0x42>
}
ffffffffc0200b7a:	6402                	ld	s0,0(sp)
ffffffffc0200b7c:	60a2                	ld	ra,8(sp)
ffffffffc0200b7e:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b80:	bd9d                	j	ffffffffc02009f6 <print_trapframe>
           cprintf("Exception type: breakpoint\n");
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	c4650513          	addi	a0,a0,-954 # ffffffffc02027c8 <commands+0x678>
ffffffffc0200b8a:	d5cff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
           cprintf("ebreak caught at %p\n",tf->epc);
ffffffffc0200b8e:	10843583          	ld	a1,264(s0)
ffffffffc0200b92:	00002517          	auipc	a0,0x2
ffffffffc0200b96:	c5650513          	addi	a0,a0,-938 # ffffffffc02027e8 <commands+0x698>
ffffffffc0200b9a:	d4cff0ef          	jal	ra,ffffffffc02000e6 <cprintf>
           tf->epc += 2; 
ffffffffc0200b9e:	10843783          	ld	a5,264(s0)
}
ffffffffc0200ba2:	60a2                	ld	ra,8(sp)
           tf->epc += 2; 
ffffffffc0200ba4:	0789                	addi	a5,a5,2
ffffffffc0200ba6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200baa:	6402                	ld	s0,0(sp)
ffffffffc0200bac:	0141                	addi	sp,sp,16
ffffffffc0200bae:	8082                	ret

ffffffffc0200bb0 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bb0:	11853783          	ld	a5,280(a0)
ffffffffc0200bb4:	0007c363          	bltz	a5,ffffffffc0200bba <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bb8:	bf85                	j	ffffffffc0200b28 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bba:	bd79                	j	ffffffffc0200a58 <interrupt_handler>

ffffffffc0200bbc <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200bbc:	14011073          	csrw	sscratch,sp
ffffffffc0200bc0:	712d                	addi	sp,sp,-288
ffffffffc0200bc2:	e002                	sd	zero,0(sp)
ffffffffc0200bc4:	e406                	sd	ra,8(sp)
ffffffffc0200bc6:	ec0e                	sd	gp,24(sp)
ffffffffc0200bc8:	f012                	sd	tp,32(sp)
ffffffffc0200bca:	f416                	sd	t0,40(sp)
ffffffffc0200bcc:	f81a                	sd	t1,48(sp)
ffffffffc0200bce:	fc1e                	sd	t2,56(sp)
ffffffffc0200bd0:	e0a2                	sd	s0,64(sp)
ffffffffc0200bd2:	e4a6                	sd	s1,72(sp)
ffffffffc0200bd4:	e8aa                	sd	a0,80(sp)
ffffffffc0200bd6:	ecae                	sd	a1,88(sp)
ffffffffc0200bd8:	f0b2                	sd	a2,96(sp)
ffffffffc0200bda:	f4b6                	sd	a3,104(sp)
ffffffffc0200bdc:	f8ba                	sd	a4,112(sp)
ffffffffc0200bde:	fcbe                	sd	a5,120(sp)
ffffffffc0200be0:	e142                	sd	a6,128(sp)
ffffffffc0200be2:	e546                	sd	a7,136(sp)
ffffffffc0200be4:	e94a                	sd	s2,144(sp)
ffffffffc0200be6:	ed4e                	sd	s3,152(sp)
ffffffffc0200be8:	f152                	sd	s4,160(sp)
ffffffffc0200bea:	f556                	sd	s5,168(sp)
ffffffffc0200bec:	f95a                	sd	s6,176(sp)
ffffffffc0200bee:	fd5e                	sd	s7,184(sp)
ffffffffc0200bf0:	e1e2                	sd	s8,192(sp)
ffffffffc0200bf2:	e5e6                	sd	s9,200(sp)
ffffffffc0200bf4:	e9ea                	sd	s10,208(sp)
ffffffffc0200bf6:	edee                	sd	s11,216(sp)
ffffffffc0200bf8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bfa:	f5f6                	sd	t4,232(sp)
ffffffffc0200bfc:	f9fa                	sd	t5,240(sp)
ffffffffc0200bfe:	fdfe                	sd	t6,248(sp)
ffffffffc0200c00:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c04:	100024f3          	csrr	s1,sstatus
ffffffffc0200c08:	14102973          	csrr	s2,sepc
ffffffffc0200c0c:	143029f3          	csrr	s3,stval
ffffffffc0200c10:	14202a73          	csrr	s4,scause
ffffffffc0200c14:	e822                	sd	s0,16(sp)
ffffffffc0200c16:	e226                	sd	s1,256(sp)
ffffffffc0200c18:	e64a                	sd	s2,264(sp)
ffffffffc0200c1a:	ea4e                	sd	s3,272(sp)
ffffffffc0200c1c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c1e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c20:	f91ff0ef          	jal	ra,ffffffffc0200bb0 <trap>

ffffffffc0200c24 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c24:	6492                	ld	s1,256(sp)
ffffffffc0200c26:	6932                	ld	s2,264(sp)
ffffffffc0200c28:	10049073          	csrw	sstatus,s1
ffffffffc0200c2c:	14191073          	csrw	sepc,s2
ffffffffc0200c30:	60a2                	ld	ra,8(sp)
ffffffffc0200c32:	61e2                	ld	gp,24(sp)
ffffffffc0200c34:	7202                	ld	tp,32(sp)
ffffffffc0200c36:	72a2                	ld	t0,40(sp)
ffffffffc0200c38:	7342                	ld	t1,48(sp)
ffffffffc0200c3a:	73e2                	ld	t2,56(sp)
ffffffffc0200c3c:	6406                	ld	s0,64(sp)
ffffffffc0200c3e:	64a6                	ld	s1,72(sp)
ffffffffc0200c40:	6546                	ld	a0,80(sp)
ffffffffc0200c42:	65e6                	ld	a1,88(sp)
ffffffffc0200c44:	7606                	ld	a2,96(sp)
ffffffffc0200c46:	76a6                	ld	a3,104(sp)
ffffffffc0200c48:	7746                	ld	a4,112(sp)
ffffffffc0200c4a:	77e6                	ld	a5,120(sp)
ffffffffc0200c4c:	680a                	ld	a6,128(sp)
ffffffffc0200c4e:	68aa                	ld	a7,136(sp)
ffffffffc0200c50:	694a                	ld	s2,144(sp)
ffffffffc0200c52:	69ea                	ld	s3,152(sp)
ffffffffc0200c54:	7a0a                	ld	s4,160(sp)
ffffffffc0200c56:	7aaa                	ld	s5,168(sp)
ffffffffc0200c58:	7b4a                	ld	s6,176(sp)
ffffffffc0200c5a:	7bea                	ld	s7,184(sp)
ffffffffc0200c5c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c5e:	6cae                	ld	s9,200(sp)
ffffffffc0200c60:	6d4e                	ld	s10,208(sp)
ffffffffc0200c62:	6dee                	ld	s11,216(sp)
ffffffffc0200c64:	7e0e                	ld	t3,224(sp)
ffffffffc0200c66:	7eae                	ld	t4,232(sp)
ffffffffc0200c68:	7f4e                	ld	t5,240(sp)
ffffffffc0200c6a:	7fee                	ld	t6,248(sp)
ffffffffc0200c6c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c6e:	10200073          	sret

ffffffffc0200c72 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c72:	00005797          	auipc	a5,0x5
ffffffffc0200c76:	3b678793          	addi	a5,a5,950 # ffffffffc0206028 <free_area>
ffffffffc0200c7a:	e79c                	sd	a5,8(a5)
ffffffffc0200c7c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c7e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c82:	8082                	ret

ffffffffc0200c84 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c84:	00005517          	auipc	a0,0x5
ffffffffc0200c88:	3b456503          	lwu	a0,948(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200c8c:	8082                	ret

ffffffffc0200c8e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200c8e:	c94d                	beqz	a0,ffffffffc0200d40 <best_fit_alloc_pages+0xb2>
    if (n > nr_free) {
ffffffffc0200c90:	00005617          	auipc	a2,0x5
ffffffffc0200c94:	39860613          	addi	a2,a2,920 # ffffffffc0206028 <free_area>
ffffffffc0200c98:	01062803          	lw	a6,16(a2)
ffffffffc0200c9c:	86aa                	mv	a3,a0
ffffffffc0200c9e:	02081793          	slli	a5,a6,0x20
ffffffffc0200ca2:	9381                	srli	a5,a5,0x20
ffffffffc0200ca4:	08a7ea63          	bltu	a5,a0,ffffffffc0200d38 <best_fit_alloc_pages+0xaa>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ca8:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200caa:	0018059b          	addiw	a1,a6,1
ffffffffc0200cae:	1582                	slli	a1,a1,0x20
ffffffffc0200cb0:	9181                	srli	a1,a1,0x20
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cb2:	08c78363          	beq	a5,a2,ffffffffc0200d38 <best_fit_alloc_pages+0xaa>
    struct Page *page = NULL;
ffffffffc0200cb6:	4881                	li	a7,0
ffffffffc0200cb8:	a811                	j	ffffffffc0200ccc <best_fit_alloc_pages+0x3e>
        else if ((p->property > n) && (p->property < min_size))
ffffffffc0200cba:	00e6f663          	bgeu	a3,a4,ffffffffc0200cc6 <best_fit_alloc_pages+0x38>
ffffffffc0200cbe:	00b77463          	bgeu	a4,a1,ffffffffc0200cc6 <best_fit_alloc_pages+0x38>
ffffffffc0200cc2:	85ba                	mv	a1,a4
        struct Page *p = le2page(le, page_link);
ffffffffc0200cc4:	88aa                	mv	a7,a0
ffffffffc0200cc6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cc8:	06c78463          	beq	a5,a2,ffffffffc0200d30 <best_fit_alloc_pages+0xa2>
        if (p->property == n)
ffffffffc0200ccc:	ff87e703          	lwu	a4,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0200cd0:	fe878513          	addi	a0,a5,-24
        if (p->property == n)
ffffffffc0200cd4:	fed713e3          	bne	a4,a3,ffffffffc0200cba <best_fit_alloc_pages+0x2c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200cd8:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200cda:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200cdc:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200cde:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200ce2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200ce4:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200ce6:	02059793          	slli	a5,a1,0x20
ffffffffc0200cea:	9381                	srli	a5,a5,0x20
ffffffffc0200cec:	02f6f863          	bgeu	a3,a5,ffffffffc0200d1c <best_fit_alloc_pages+0x8e>
            struct Page *p = page + n;
ffffffffc0200cf0:	00269793          	slli	a5,a3,0x2
ffffffffc0200cf4:	97b6                	add	a5,a5,a3
ffffffffc0200cf6:	078e                	slli	a5,a5,0x3
ffffffffc0200cf8:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200cfa:	411585bb          	subw	a1,a1,a7
ffffffffc0200cfe:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d00:	4689                	li	a3,2
ffffffffc0200d02:	00878593          	addi	a1,a5,8
ffffffffc0200d06:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d0a:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200d0c:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200d10:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200d14:	e28c                	sd	a1,0(a3)
ffffffffc0200d16:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200d18:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200d1a:	ef98                	sd	a4,24(a5)
ffffffffc0200d1c:	4118083b          	subw	a6,a6,a7
ffffffffc0200d20:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200d24:	57f5                	li	a5,-3
ffffffffc0200d26:	00850713          	addi	a4,a0,8
ffffffffc0200d2a:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200d2e:	8082                	ret
        return NULL;
ffffffffc0200d30:	4501                	li	a0,0
    if (page != NULL) {
ffffffffc0200d32:	00089563          	bnez	a7,ffffffffc0200d3c <best_fit_alloc_pages+0xae>
}
ffffffffc0200d36:	8082                	ret
        return NULL;
ffffffffc0200d38:	4501                	li	a0,0
}
ffffffffc0200d3a:	8082                	ret
ffffffffc0200d3c:	8546                	mv	a0,a7
ffffffffc0200d3e:	bf69                	j	ffffffffc0200cd8 <best_fit_alloc_pages+0x4a>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d40:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200d42:	00002697          	auipc	a3,0x2
ffffffffc0200d46:	abe68693          	addi	a3,a3,-1346 # ffffffffc0202800 <commands+0x6b0>
ffffffffc0200d4a:	00002617          	auipc	a2,0x2
ffffffffc0200d4e:	abe60613          	addi	a2,a2,-1346 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0200d52:	06a00593          	li	a1,106
ffffffffc0200d56:	00002517          	auipc	a0,0x2
ffffffffc0200d5a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0202820 <commands+0x6d0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d5e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d60:	e80ff0ef          	jal	ra,ffffffffc02003e0 <__panic>

ffffffffc0200d64 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200d64:	715d                	addi	sp,sp,-80
ffffffffc0200d66:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200d68:	00005417          	auipc	s0,0x5
ffffffffc0200d6c:	2c040413          	addi	s0,s0,704 # ffffffffc0206028 <free_area>
ffffffffc0200d70:	641c                	ld	a5,8(s0)
ffffffffc0200d72:	e486                	sd	ra,72(sp)
ffffffffc0200d74:	fc26                	sd	s1,56(sp)
ffffffffc0200d76:	f84a                	sd	s2,48(sp)
ffffffffc0200d78:	f44e                	sd	s3,40(sp)
ffffffffc0200d7a:	f052                	sd	s4,32(sp)
ffffffffc0200d7c:	ec56                	sd	s5,24(sp)
ffffffffc0200d7e:	e85a                	sd	s6,16(sp)
ffffffffc0200d80:	e45e                	sd	s7,8(sp)
ffffffffc0200d82:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d84:	26878b63          	beq	a5,s0,ffffffffc0200ffa <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200d88:	4481                	li	s1,0
ffffffffc0200d8a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d8c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d90:	8b09                	andi	a4,a4,2
ffffffffc0200d92:	26070863          	beqz	a4,ffffffffc0201002 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200d96:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d9a:	679c                	ld	a5,8(a5)
ffffffffc0200d9c:	2905                	addiw	s2,s2,1
ffffffffc0200d9e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200da0:	fe8796e3          	bne	a5,s0,ffffffffc0200d8c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200da4:	89a6                	mv	s3,s1
ffffffffc0200da6:	167000ef          	jal	ra,ffffffffc020170c <nr_free_pages>
ffffffffc0200daa:	33351c63          	bne	a0,s3,ffffffffc02010e2 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dae:	4505                	li	a0,1
ffffffffc0200db0:	0df000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200db4:	8a2a                	mv	s4,a0
ffffffffc0200db6:	36050663          	beqz	a0,ffffffffc0201122 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dba:	4505                	li	a0,1
ffffffffc0200dbc:	0d3000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200dc0:	89aa                	mv	s3,a0
ffffffffc0200dc2:	34050063          	beqz	a0,ffffffffc0201102 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dc6:	4505                	li	a0,1
ffffffffc0200dc8:	0c7000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200dcc:	8aaa                	mv	s5,a0
ffffffffc0200dce:	2c050a63          	beqz	a0,ffffffffc02010a2 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dd2:	253a0863          	beq	s4,s3,ffffffffc0201022 <best_fit_check+0x2be>
ffffffffc0200dd6:	24aa0663          	beq	s4,a0,ffffffffc0201022 <best_fit_check+0x2be>
ffffffffc0200dda:	24a98463          	beq	s3,a0,ffffffffc0201022 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dde:	000a2783          	lw	a5,0(s4)
ffffffffc0200de2:	26079063          	bnez	a5,ffffffffc0201042 <best_fit_check+0x2de>
ffffffffc0200de6:	0009a783          	lw	a5,0(s3)
ffffffffc0200dea:	24079c63          	bnez	a5,ffffffffc0201042 <best_fit_check+0x2de>
ffffffffc0200dee:	411c                	lw	a5,0(a0)
ffffffffc0200df0:	24079963          	bnez	a5,ffffffffc0201042 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200df4:	00005797          	auipc	a5,0x5
ffffffffc0200df8:	67c7b783          	ld	a5,1660(a5) # ffffffffc0206470 <pages>
ffffffffc0200dfc:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e00:	870d                	srai	a4,a4,0x3
ffffffffc0200e02:	00002597          	auipc	a1,0x2
ffffffffc0200e06:	10e5b583          	ld	a1,270(a1) # ffffffffc0202f10 <error_string+0x38>
ffffffffc0200e0a:	02b70733          	mul	a4,a4,a1
ffffffffc0200e0e:	00002617          	auipc	a2,0x2
ffffffffc0200e12:	10a63603          	ld	a2,266(a2) # ffffffffc0202f18 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e16:	00005697          	auipc	a3,0x5
ffffffffc0200e1a:	6526b683          	ld	a3,1618(a3) # ffffffffc0206468 <npage>
ffffffffc0200e1e:	06b2                	slli	a3,a3,0xc
ffffffffc0200e20:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e22:	0732                	slli	a4,a4,0xc
ffffffffc0200e24:	22d77f63          	bgeu	a4,a3,ffffffffc0201062 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e28:	40f98733          	sub	a4,s3,a5
ffffffffc0200e2c:	870d                	srai	a4,a4,0x3
ffffffffc0200e2e:	02b70733          	mul	a4,a4,a1
ffffffffc0200e32:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e34:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e36:	3ed77663          	bgeu	a4,a3,ffffffffc0201222 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e3a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e3e:	878d                	srai	a5,a5,0x3
ffffffffc0200e40:	02b787b3          	mul	a5,a5,a1
ffffffffc0200e44:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e46:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e48:	3ad7fd63          	bgeu	a5,a3,ffffffffc0201202 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200e4c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e4e:	00043c03          	ld	s8,0(s0)
ffffffffc0200e52:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e56:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e5a:	e400                	sd	s0,8(s0)
ffffffffc0200e5c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e5e:	00005797          	auipc	a5,0x5
ffffffffc0200e62:	1c07ad23          	sw	zero,474(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e66:	029000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200e6a:	36051c63          	bnez	a0,ffffffffc02011e2 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200e6e:	4585                	li	a1,1
ffffffffc0200e70:	8552                	mv	a0,s4
ffffffffc0200e72:	05b000ef          	jal	ra,ffffffffc02016cc <free_pages>
    free_page(p1);
ffffffffc0200e76:	4585                	li	a1,1
ffffffffc0200e78:	854e                	mv	a0,s3
ffffffffc0200e7a:	053000ef          	jal	ra,ffffffffc02016cc <free_pages>
    free_page(p2);
ffffffffc0200e7e:	4585                	li	a1,1
ffffffffc0200e80:	8556                	mv	a0,s5
ffffffffc0200e82:	04b000ef          	jal	ra,ffffffffc02016cc <free_pages>
    assert(nr_free == 3);
ffffffffc0200e86:	4818                	lw	a4,16(s0)
ffffffffc0200e88:	478d                	li	a5,3
ffffffffc0200e8a:	32f71c63          	bne	a4,a5,ffffffffc02011c2 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e8e:	4505                	li	a0,1
ffffffffc0200e90:	7fe000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200e94:	89aa                	mv	s3,a0
ffffffffc0200e96:	30050663          	beqz	a0,ffffffffc02011a2 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e9a:	4505                	li	a0,1
ffffffffc0200e9c:	7f2000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200ea0:	8aaa                	mv	s5,a0
ffffffffc0200ea2:	2e050063          	beqz	a0,ffffffffc0201182 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ea6:	4505                	li	a0,1
ffffffffc0200ea8:	7e6000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200eac:	8a2a                	mv	s4,a0
ffffffffc0200eae:	2a050a63          	beqz	a0,ffffffffc0201162 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200eb2:	4505                	li	a0,1
ffffffffc0200eb4:	7da000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200eb8:	28051563          	bnez	a0,ffffffffc0201142 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200ebc:	4585                	li	a1,1
ffffffffc0200ebe:	854e                	mv	a0,s3
ffffffffc0200ec0:	00d000ef          	jal	ra,ffffffffc02016cc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ec4:	641c                	ld	a5,8(s0)
ffffffffc0200ec6:	1a878e63          	beq	a5,s0,ffffffffc0201082 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200eca:	4505                	li	a0,1
ffffffffc0200ecc:	7c2000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200ed0:	52a99963          	bne	s3,a0,ffffffffc0201402 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200ed4:	4505                	li	a0,1
ffffffffc0200ed6:	7b8000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200eda:	50051463          	bnez	a0,ffffffffc02013e2 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200ede:	481c                	lw	a5,16(s0)
ffffffffc0200ee0:	4e079163          	bnez	a5,ffffffffc02013c2 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200ee4:	854e                	mv	a0,s3
ffffffffc0200ee6:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ee8:	01843023          	sd	s8,0(s0)
ffffffffc0200eec:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200ef0:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200ef4:	7d8000ef          	jal	ra,ffffffffc02016cc <free_pages>
    free_page(p1);
ffffffffc0200ef8:	4585                	li	a1,1
ffffffffc0200efa:	8556                	mv	a0,s5
ffffffffc0200efc:	7d0000ef          	jal	ra,ffffffffc02016cc <free_pages>
    free_page(p2);
ffffffffc0200f00:	4585                	li	a1,1
ffffffffc0200f02:	8552                	mv	a0,s4
ffffffffc0200f04:	7c8000ef          	jal	ra,ffffffffc02016cc <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f08:	4515                	li	a0,5
ffffffffc0200f0a:	784000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200f0e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f10:	48050963          	beqz	a0,ffffffffc02013a2 <best_fit_check+0x63e>
ffffffffc0200f14:	651c                	ld	a5,8(a0)
ffffffffc0200f16:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f18:	8b85                	andi	a5,a5,1
ffffffffc0200f1a:	46079463          	bnez	a5,ffffffffc0201382 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f1e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f20:	00043a83          	ld	s5,0(s0)
ffffffffc0200f24:	00843a03          	ld	s4,8(s0)
ffffffffc0200f28:	e000                	sd	s0,0(s0)
ffffffffc0200f2a:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f2c:	762000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200f30:	42051963          	bnez	a0,ffffffffc0201362 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f34:	4589                	li	a1,2
ffffffffc0200f36:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200f3a:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200f3e:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200f42:	00005797          	auipc	a5,0x5
ffffffffc0200f46:	0e07ab23          	sw	zero,246(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200f4a:	782000ef          	jal	ra,ffffffffc02016cc <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200f4e:	8562                	mv	a0,s8
ffffffffc0200f50:	4585                	li	a1,1
ffffffffc0200f52:	77a000ef          	jal	ra,ffffffffc02016cc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f56:	4511                	li	a0,4
ffffffffc0200f58:	736000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200f5c:	3e051363          	bnez	a0,ffffffffc0201342 <best_fit_check+0x5de>
ffffffffc0200f60:	0309b783          	ld	a5,48(s3)
ffffffffc0200f64:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f66:	8b85                	andi	a5,a5,1
ffffffffc0200f68:	3a078d63          	beqz	a5,ffffffffc0201322 <best_fit_check+0x5be>
ffffffffc0200f6c:	0389a703          	lw	a4,56(s3)
ffffffffc0200f70:	4789                	li	a5,2
ffffffffc0200f72:	3af71863          	bne	a4,a5,ffffffffc0201322 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f76:	4505                	li	a0,1
ffffffffc0200f78:	716000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200f7c:	8baa                	mv	s7,a0
ffffffffc0200f7e:	38050263          	beqz	a0,ffffffffc0201302 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f82:	4509                	li	a0,2
ffffffffc0200f84:	70a000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200f88:	34050d63          	beqz	a0,ffffffffc02012e2 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200f8c:	337c1b63          	bne	s8,s7,ffffffffc02012c2 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200f90:	854e                	mv	a0,s3
ffffffffc0200f92:	4595                	li	a1,5
ffffffffc0200f94:	738000ef          	jal	ra,ffffffffc02016cc <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f98:	4515                	li	a0,5
ffffffffc0200f9a:	6f4000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200f9e:	89aa                	mv	s3,a0
ffffffffc0200fa0:	30050163          	beqz	a0,ffffffffc02012a2 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200fa4:	4505                	li	a0,1
ffffffffc0200fa6:	6e8000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200faa:	2c051c63          	bnez	a0,ffffffffc0201282 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200fae:	481c                	lw	a5,16(s0)
ffffffffc0200fb0:	2a079963          	bnez	a5,ffffffffc0201262 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fb4:	4595                	li	a1,5
ffffffffc0200fb6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200fb8:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200fbc:	01543023          	sd	s5,0(s0)
ffffffffc0200fc0:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200fc4:	708000ef          	jal	ra,ffffffffc02016cc <free_pages>
    return listelm->next;
ffffffffc0200fc8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fca:	00878963          	beq	a5,s0,ffffffffc0200fdc <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fce:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fd2:	679c                	ld	a5,8(a5)
ffffffffc0200fd4:	397d                	addiw	s2,s2,-1
ffffffffc0200fd6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fd8:	fe879be3          	bne	a5,s0,ffffffffc0200fce <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200fdc:	26091363          	bnez	s2,ffffffffc0201242 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200fe0:	e0ed                	bnez	s1,ffffffffc02010c2 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200fe2:	60a6                	ld	ra,72(sp)
ffffffffc0200fe4:	6406                	ld	s0,64(sp)
ffffffffc0200fe6:	74e2                	ld	s1,56(sp)
ffffffffc0200fe8:	7942                	ld	s2,48(sp)
ffffffffc0200fea:	79a2                	ld	s3,40(sp)
ffffffffc0200fec:	7a02                	ld	s4,32(sp)
ffffffffc0200fee:	6ae2                	ld	s5,24(sp)
ffffffffc0200ff0:	6b42                	ld	s6,16(sp)
ffffffffc0200ff2:	6ba2                	ld	s7,8(sp)
ffffffffc0200ff4:	6c02                	ld	s8,0(sp)
ffffffffc0200ff6:	6161                	addi	sp,sp,80
ffffffffc0200ff8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ffa:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200ffc:	4481                	li	s1,0
ffffffffc0200ffe:	4901                	li	s2,0
ffffffffc0201000:	b35d                	j	ffffffffc0200da6 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0201002:	00002697          	auipc	a3,0x2
ffffffffc0201006:	83668693          	addi	a3,a3,-1994 # ffffffffc0202838 <commands+0x6e8>
ffffffffc020100a:	00001617          	auipc	a2,0x1
ffffffffc020100e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201012:	10900593          	li	a1,265
ffffffffc0201016:	00002517          	auipc	a0,0x2
ffffffffc020101a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020101e:	bc2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201022:	00002697          	auipc	a3,0x2
ffffffffc0201026:	8a668693          	addi	a3,a3,-1882 # ffffffffc02028c8 <commands+0x778>
ffffffffc020102a:	00001617          	auipc	a2,0x1
ffffffffc020102e:	7de60613          	addi	a2,a2,2014 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201032:	0d500593          	li	a1,213
ffffffffc0201036:	00001517          	auipc	a0,0x1
ffffffffc020103a:	7ea50513          	addi	a0,a0,2026 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020103e:	ba2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201042:	00002697          	auipc	a3,0x2
ffffffffc0201046:	8ae68693          	addi	a3,a3,-1874 # ffffffffc02028f0 <commands+0x7a0>
ffffffffc020104a:	00001617          	auipc	a2,0x1
ffffffffc020104e:	7be60613          	addi	a2,a2,1982 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201052:	0d600593          	li	a1,214
ffffffffc0201056:	00001517          	auipc	a0,0x1
ffffffffc020105a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020105e:	b82ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201062:	00002697          	auipc	a3,0x2
ffffffffc0201066:	8ce68693          	addi	a3,a3,-1842 # ffffffffc0202930 <commands+0x7e0>
ffffffffc020106a:	00001617          	auipc	a2,0x1
ffffffffc020106e:	79e60613          	addi	a2,a2,1950 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201072:	0d800593          	li	a1,216
ffffffffc0201076:	00001517          	auipc	a0,0x1
ffffffffc020107a:	7aa50513          	addi	a0,a0,1962 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020107e:	b62ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201082:	00002697          	auipc	a3,0x2
ffffffffc0201086:	93668693          	addi	a3,a3,-1738 # ffffffffc02029b8 <commands+0x868>
ffffffffc020108a:	00001617          	auipc	a2,0x1
ffffffffc020108e:	77e60613          	addi	a2,a2,1918 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201092:	0f100593          	li	a1,241
ffffffffc0201096:	00001517          	auipc	a0,0x1
ffffffffc020109a:	78a50513          	addi	a0,a0,1930 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020109e:	b42ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010a2:	00002697          	auipc	a3,0x2
ffffffffc02010a6:	80668693          	addi	a3,a3,-2042 # ffffffffc02028a8 <commands+0x758>
ffffffffc02010aa:	00001617          	auipc	a2,0x1
ffffffffc02010ae:	75e60613          	addi	a2,a2,1886 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02010b2:	0d300593          	li	a1,211
ffffffffc02010b6:	00001517          	auipc	a0,0x1
ffffffffc02010ba:	76a50513          	addi	a0,a0,1898 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02010be:	b22ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(total == 0);
ffffffffc02010c2:	00002697          	auipc	a3,0x2
ffffffffc02010c6:	a2668693          	addi	a3,a3,-1498 # ffffffffc0202ae8 <commands+0x998>
ffffffffc02010ca:	00001617          	auipc	a2,0x1
ffffffffc02010ce:	73e60613          	addi	a2,a2,1854 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02010d2:	14b00593          	li	a1,331
ffffffffc02010d6:	00001517          	auipc	a0,0x1
ffffffffc02010da:	74a50513          	addi	a0,a0,1866 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02010de:	b02ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(total == nr_free_pages());
ffffffffc02010e2:	00001697          	auipc	a3,0x1
ffffffffc02010e6:	76668693          	addi	a3,a3,1894 # ffffffffc0202848 <commands+0x6f8>
ffffffffc02010ea:	00001617          	auipc	a2,0x1
ffffffffc02010ee:	71e60613          	addi	a2,a2,1822 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02010f2:	10c00593          	li	a1,268
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	72a50513          	addi	a0,a0,1834 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02010fe:	ae2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201102:	00001697          	auipc	a3,0x1
ffffffffc0201106:	78668693          	addi	a3,a3,1926 # ffffffffc0202888 <commands+0x738>
ffffffffc020110a:	00001617          	auipc	a2,0x1
ffffffffc020110e:	6fe60613          	addi	a2,a2,1790 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201112:	0d200593          	li	a1,210
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	70a50513          	addi	a0,a0,1802 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020111e:	ac2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201122:	00001697          	auipc	a3,0x1
ffffffffc0201126:	74668693          	addi	a3,a3,1862 # ffffffffc0202868 <commands+0x718>
ffffffffc020112a:	00001617          	auipc	a2,0x1
ffffffffc020112e:	6de60613          	addi	a2,a2,1758 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201132:	0d100593          	li	a1,209
ffffffffc0201136:	00001517          	auipc	a0,0x1
ffffffffc020113a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020113e:	aa2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201142:	00002697          	auipc	a3,0x2
ffffffffc0201146:	84e68693          	addi	a3,a3,-1970 # ffffffffc0202990 <commands+0x840>
ffffffffc020114a:	00001617          	auipc	a2,0x1
ffffffffc020114e:	6be60613          	addi	a2,a2,1726 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201152:	0ee00593          	li	a1,238
ffffffffc0201156:	00001517          	auipc	a0,0x1
ffffffffc020115a:	6ca50513          	addi	a0,a0,1738 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020115e:	a82ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201162:	00001697          	auipc	a3,0x1
ffffffffc0201166:	74668693          	addi	a3,a3,1862 # ffffffffc02028a8 <commands+0x758>
ffffffffc020116a:	00001617          	auipc	a2,0x1
ffffffffc020116e:	69e60613          	addi	a2,a2,1694 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201172:	0ec00593          	li	a1,236
ffffffffc0201176:	00001517          	auipc	a0,0x1
ffffffffc020117a:	6aa50513          	addi	a0,a0,1706 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020117e:	a62ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201182:	00001697          	auipc	a3,0x1
ffffffffc0201186:	70668693          	addi	a3,a3,1798 # ffffffffc0202888 <commands+0x738>
ffffffffc020118a:	00001617          	auipc	a2,0x1
ffffffffc020118e:	67e60613          	addi	a2,a2,1662 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201192:	0eb00593          	li	a1,235
ffffffffc0201196:	00001517          	auipc	a0,0x1
ffffffffc020119a:	68a50513          	addi	a0,a0,1674 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020119e:	a42ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011a2:	00001697          	auipc	a3,0x1
ffffffffc02011a6:	6c668693          	addi	a3,a3,1734 # ffffffffc0202868 <commands+0x718>
ffffffffc02011aa:	00001617          	auipc	a2,0x1
ffffffffc02011ae:	65e60613          	addi	a2,a2,1630 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02011b2:	0ea00593          	li	a1,234
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	66a50513          	addi	a0,a0,1642 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02011be:	a22ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(nr_free == 3);
ffffffffc02011c2:	00001697          	auipc	a3,0x1
ffffffffc02011c6:	7e668693          	addi	a3,a3,2022 # ffffffffc02029a8 <commands+0x858>
ffffffffc02011ca:	00001617          	auipc	a2,0x1
ffffffffc02011ce:	63e60613          	addi	a2,a2,1598 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02011d2:	0e800593          	li	a1,232
ffffffffc02011d6:	00001517          	auipc	a0,0x1
ffffffffc02011da:	64a50513          	addi	a0,a0,1610 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02011de:	a02ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011e2:	00001697          	auipc	a3,0x1
ffffffffc02011e6:	7ae68693          	addi	a3,a3,1966 # ffffffffc0202990 <commands+0x840>
ffffffffc02011ea:	00001617          	auipc	a2,0x1
ffffffffc02011ee:	61e60613          	addi	a2,a2,1566 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02011f2:	0e300593          	li	a1,227
ffffffffc02011f6:	00001517          	auipc	a0,0x1
ffffffffc02011fa:	62a50513          	addi	a0,a0,1578 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02011fe:	9e2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201202:	00001697          	auipc	a3,0x1
ffffffffc0201206:	76e68693          	addi	a3,a3,1902 # ffffffffc0202970 <commands+0x820>
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	5fe60613          	addi	a2,a2,1534 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201212:	0da00593          	li	a1,218
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	60a50513          	addi	a0,a0,1546 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020121e:	9c2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201222:	00001697          	auipc	a3,0x1
ffffffffc0201226:	72e68693          	addi	a3,a3,1838 # ffffffffc0202950 <commands+0x800>
ffffffffc020122a:	00001617          	auipc	a2,0x1
ffffffffc020122e:	5de60613          	addi	a2,a2,1502 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201232:	0d900593          	li	a1,217
ffffffffc0201236:	00001517          	auipc	a0,0x1
ffffffffc020123a:	5ea50513          	addi	a0,a0,1514 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020123e:	9a2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(count == 0);
ffffffffc0201242:	00002697          	auipc	a3,0x2
ffffffffc0201246:	89668693          	addi	a3,a3,-1898 # ffffffffc0202ad8 <commands+0x988>
ffffffffc020124a:	00001617          	auipc	a2,0x1
ffffffffc020124e:	5be60613          	addi	a2,a2,1470 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201252:	14a00593          	li	a1,330
ffffffffc0201256:	00001517          	auipc	a0,0x1
ffffffffc020125a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020125e:	982ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(nr_free == 0);
ffffffffc0201262:	00001697          	auipc	a3,0x1
ffffffffc0201266:	78e68693          	addi	a3,a3,1934 # ffffffffc02029f0 <commands+0x8a0>
ffffffffc020126a:	00001617          	auipc	a2,0x1
ffffffffc020126e:	59e60613          	addi	a2,a2,1438 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201272:	13f00593          	li	a1,319
ffffffffc0201276:	00001517          	auipc	a0,0x1
ffffffffc020127a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020127e:	962ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201282:	00001697          	auipc	a3,0x1
ffffffffc0201286:	70e68693          	addi	a3,a3,1806 # ffffffffc0202990 <commands+0x840>
ffffffffc020128a:	00001617          	auipc	a2,0x1
ffffffffc020128e:	57e60613          	addi	a2,a2,1406 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201292:	13900593          	li	a1,313
ffffffffc0201296:	00001517          	auipc	a0,0x1
ffffffffc020129a:	58a50513          	addi	a0,a0,1418 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020129e:	942ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012a2:	00002697          	auipc	a3,0x2
ffffffffc02012a6:	81668693          	addi	a3,a3,-2026 # ffffffffc0202ab8 <commands+0x968>
ffffffffc02012aa:	00001617          	auipc	a2,0x1
ffffffffc02012ae:	55e60613          	addi	a2,a2,1374 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02012b2:	13800593          	li	a1,312
ffffffffc02012b6:	00001517          	auipc	a0,0x1
ffffffffc02012ba:	56a50513          	addi	a0,a0,1386 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02012be:	922ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(p0 + 4 == p1);
ffffffffc02012c2:	00001697          	auipc	a3,0x1
ffffffffc02012c6:	7e668693          	addi	a3,a3,2022 # ffffffffc0202aa8 <commands+0x958>
ffffffffc02012ca:	00001617          	auipc	a2,0x1
ffffffffc02012ce:	53e60613          	addi	a2,a2,1342 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02012d2:	13000593          	li	a1,304
ffffffffc02012d6:	00001517          	auipc	a0,0x1
ffffffffc02012da:	54a50513          	addi	a0,a0,1354 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02012de:	902ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02012e2:	00001697          	auipc	a3,0x1
ffffffffc02012e6:	7ae68693          	addi	a3,a3,1966 # ffffffffc0202a90 <commands+0x940>
ffffffffc02012ea:	00001617          	auipc	a2,0x1
ffffffffc02012ee:	51e60613          	addi	a2,a2,1310 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02012f2:	12f00593          	li	a1,303
ffffffffc02012f6:	00001517          	auipc	a0,0x1
ffffffffc02012fa:	52a50513          	addi	a0,a0,1322 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02012fe:	8e2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201302:	00001697          	auipc	a3,0x1
ffffffffc0201306:	76e68693          	addi	a3,a3,1902 # ffffffffc0202a70 <commands+0x920>
ffffffffc020130a:	00001617          	auipc	a2,0x1
ffffffffc020130e:	4fe60613          	addi	a2,a2,1278 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201312:	12e00593          	li	a1,302
ffffffffc0201316:	00001517          	auipc	a0,0x1
ffffffffc020131a:	50a50513          	addi	a0,a0,1290 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020131e:	8c2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201322:	00001697          	auipc	a3,0x1
ffffffffc0201326:	71e68693          	addi	a3,a3,1822 # ffffffffc0202a40 <commands+0x8f0>
ffffffffc020132a:	00001617          	auipc	a2,0x1
ffffffffc020132e:	4de60613          	addi	a2,a2,1246 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201332:	12c00593          	li	a1,300
ffffffffc0201336:	00001517          	auipc	a0,0x1
ffffffffc020133a:	4ea50513          	addi	a0,a0,1258 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020133e:	8a2ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201342:	00001697          	auipc	a3,0x1
ffffffffc0201346:	6e668693          	addi	a3,a3,1766 # ffffffffc0202a28 <commands+0x8d8>
ffffffffc020134a:	00001617          	auipc	a2,0x1
ffffffffc020134e:	4be60613          	addi	a2,a2,1214 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201352:	12b00593          	li	a1,299
ffffffffc0201356:	00001517          	auipc	a0,0x1
ffffffffc020135a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020135e:	882ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201362:	00001697          	auipc	a3,0x1
ffffffffc0201366:	62e68693          	addi	a3,a3,1582 # ffffffffc0202990 <commands+0x840>
ffffffffc020136a:	00001617          	auipc	a2,0x1
ffffffffc020136e:	49e60613          	addi	a2,a2,1182 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201372:	11f00593          	li	a1,287
ffffffffc0201376:	00001517          	auipc	a0,0x1
ffffffffc020137a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020137e:	862ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201382:	00001697          	auipc	a3,0x1
ffffffffc0201386:	68e68693          	addi	a3,a3,1678 # ffffffffc0202a10 <commands+0x8c0>
ffffffffc020138a:	00001617          	auipc	a2,0x1
ffffffffc020138e:	47e60613          	addi	a2,a2,1150 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201392:	11600593          	li	a1,278
ffffffffc0201396:	00001517          	auipc	a0,0x1
ffffffffc020139a:	48a50513          	addi	a0,a0,1162 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020139e:	842ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(p0 != NULL);
ffffffffc02013a2:	00001697          	auipc	a3,0x1
ffffffffc02013a6:	65e68693          	addi	a3,a3,1630 # ffffffffc0202a00 <commands+0x8b0>
ffffffffc02013aa:	00001617          	auipc	a2,0x1
ffffffffc02013ae:	45e60613          	addi	a2,a2,1118 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02013b2:	11500593          	li	a1,277
ffffffffc02013b6:	00001517          	auipc	a0,0x1
ffffffffc02013ba:	46a50513          	addi	a0,a0,1130 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02013be:	822ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(nr_free == 0);
ffffffffc02013c2:	00001697          	auipc	a3,0x1
ffffffffc02013c6:	62e68693          	addi	a3,a3,1582 # ffffffffc02029f0 <commands+0x8a0>
ffffffffc02013ca:	00001617          	auipc	a2,0x1
ffffffffc02013ce:	43e60613          	addi	a2,a2,1086 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02013d2:	0f700593          	li	a1,247
ffffffffc02013d6:	00001517          	auipc	a0,0x1
ffffffffc02013da:	44a50513          	addi	a0,a0,1098 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02013de:	802ff0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013e2:	00001697          	auipc	a3,0x1
ffffffffc02013e6:	5ae68693          	addi	a3,a3,1454 # ffffffffc0202990 <commands+0x840>
ffffffffc02013ea:	00001617          	auipc	a2,0x1
ffffffffc02013ee:	41e60613          	addi	a2,a2,1054 # ffffffffc0202808 <commands+0x6b8>
ffffffffc02013f2:	0f500593          	li	a1,245
ffffffffc02013f6:	00001517          	auipc	a0,0x1
ffffffffc02013fa:	42a50513          	addi	a0,a0,1066 # ffffffffc0202820 <commands+0x6d0>
ffffffffc02013fe:	fe3fe0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201402:	00001697          	auipc	a3,0x1
ffffffffc0201406:	5ce68693          	addi	a3,a3,1486 # ffffffffc02029d0 <commands+0x880>
ffffffffc020140a:	00001617          	auipc	a2,0x1
ffffffffc020140e:	3fe60613          	addi	a2,a2,1022 # ffffffffc0202808 <commands+0x6b8>
ffffffffc0201412:	0f400593          	li	a1,244
ffffffffc0201416:	00001517          	auipc	a0,0x1
ffffffffc020141a:	40a50513          	addi	a0,a0,1034 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020141e:	fc3fe0ef          	jal	ra,ffffffffc02003e0 <__panic>

ffffffffc0201422 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201422:	1141                	addi	sp,sp,-16
ffffffffc0201424:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201426:	14058a63          	beqz	a1,ffffffffc020157a <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020142a:	00259693          	slli	a3,a1,0x2
ffffffffc020142e:	96ae                	add	a3,a3,a1
ffffffffc0201430:	068e                	slli	a3,a3,0x3
ffffffffc0201432:	96aa                	add	a3,a3,a0
ffffffffc0201434:	87aa                	mv	a5,a0
ffffffffc0201436:	02d50263          	beq	a0,a3,ffffffffc020145a <best_fit_free_pages+0x38>
ffffffffc020143a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020143c:	8b05                	andi	a4,a4,1
ffffffffc020143e:	10071e63          	bnez	a4,ffffffffc020155a <best_fit_free_pages+0x138>
ffffffffc0201442:	6798                	ld	a4,8(a5)
ffffffffc0201444:	8b09                	andi	a4,a4,2
ffffffffc0201446:	10071a63          	bnez	a4,ffffffffc020155a <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc020144a:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020144e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201452:	02878793          	addi	a5,a5,40
ffffffffc0201456:	fed792e3          	bne	a5,a3,ffffffffc020143a <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc020145a:	2581                	sext.w	a1,a1
ffffffffc020145c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020145e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201462:	4789                	li	a5,2
ffffffffc0201464:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201468:	00005697          	auipc	a3,0x5
ffffffffc020146c:	bc068693          	addi	a3,a3,-1088 # ffffffffc0206028 <free_area>
ffffffffc0201470:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201472:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201474:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201478:	9db9                	addw	a1,a1,a4
ffffffffc020147a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020147c:	0ad78863          	beq	a5,a3,ffffffffc020152c <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201480:	fe878713          	addi	a4,a5,-24
ffffffffc0201484:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201488:	4581                	li	a1,0
            if (base < page) {
ffffffffc020148a:	00e56a63          	bltu	a0,a4,ffffffffc020149e <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020148e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201490:	06d70263          	beq	a4,a3,ffffffffc02014f4 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201494:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201496:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020149a:	fee57ae3          	bgeu	a0,a4,ffffffffc020148e <best_fit_free_pages+0x6c>
ffffffffc020149e:	c199                	beqz	a1,ffffffffc02014a4 <best_fit_free_pages+0x82>
ffffffffc02014a0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014a4:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02014a6:	e390                	sd	a2,0(a5)
ffffffffc02014a8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014aa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014ac:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02014ae:	02d70063          	beq	a4,a3,ffffffffc02014ce <best_fit_free_pages+0xac>
        if (p + p->property == base)
ffffffffc02014b2:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014b6:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base)
ffffffffc02014ba:	02081613          	slli	a2,a6,0x20
ffffffffc02014be:	9201                	srli	a2,a2,0x20
ffffffffc02014c0:	00261793          	slli	a5,a2,0x2
ffffffffc02014c4:	97b2                	add	a5,a5,a2
ffffffffc02014c6:	078e                	slli	a5,a5,0x3
ffffffffc02014c8:	97ae                	add	a5,a5,a1
ffffffffc02014ca:	02f50f63          	beq	a0,a5,ffffffffc0201508 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02014ce:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014d0:	00d70f63          	beq	a4,a3,ffffffffc02014ee <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02014d4:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014d6:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014da:	02059613          	slli	a2,a1,0x20
ffffffffc02014de:	9201                	srli	a2,a2,0x20
ffffffffc02014e0:	00261793          	slli	a5,a2,0x2
ffffffffc02014e4:	97b2                	add	a5,a5,a2
ffffffffc02014e6:	078e                	slli	a5,a5,0x3
ffffffffc02014e8:	97aa                	add	a5,a5,a0
ffffffffc02014ea:	04f68863          	beq	a3,a5,ffffffffc020153a <best_fit_free_pages+0x118>
}
ffffffffc02014ee:	60a2                	ld	ra,8(sp)
ffffffffc02014f0:	0141                	addi	sp,sp,16
ffffffffc02014f2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014f4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014f6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014f8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014fa:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014fc:	02d70563          	beq	a4,a3,ffffffffc0201526 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201500:	8832                	mv	a6,a2
ffffffffc0201502:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201504:	87ba                	mv	a5,a4
ffffffffc0201506:	bf41                	j	ffffffffc0201496 <best_fit_free_pages+0x74>
            p->property += base->property; // 更新前一个块的大小
ffffffffc0201508:	491c                	lw	a5,16(a0)
ffffffffc020150a:	0107883b          	addw	a6,a5,a6
ffffffffc020150e:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201512:	57f5                	li	a5,-3
ffffffffc0201514:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201518:	6d10                	ld	a2,24(a0)
ffffffffc020151a:	711c                	ld	a5,32(a0)
            base = p;                      // 指针指向前一个空闲块，便于向后合并
ffffffffc020151c:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc020151e:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201520:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201522:	e390                	sd	a2,0(a5)
ffffffffc0201524:	b775                	j	ffffffffc02014d0 <best_fit_free_pages+0xae>
ffffffffc0201526:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201528:	873e                	mv	a4,a5
ffffffffc020152a:	b761                	j	ffffffffc02014b2 <best_fit_free_pages+0x90>
}
ffffffffc020152c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020152e:	e390                	sd	a2,0(a5)
ffffffffc0201530:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201532:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201534:	ed1c                	sd	a5,24(a0)
ffffffffc0201536:	0141                	addi	sp,sp,16
ffffffffc0201538:	8082                	ret
            base->property += p->property;
ffffffffc020153a:	ff872783          	lw	a5,-8(a4)
ffffffffc020153e:	ff070693          	addi	a3,a4,-16
ffffffffc0201542:	9dbd                	addw	a1,a1,a5
ffffffffc0201544:	c90c                	sw	a1,16(a0)
ffffffffc0201546:	57f5                	li	a5,-3
ffffffffc0201548:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020154c:	6314                	ld	a3,0(a4)
ffffffffc020154e:	671c                	ld	a5,8(a4)
}
ffffffffc0201550:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201552:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201554:	e394                	sd	a3,0(a5)
ffffffffc0201556:	0141                	addi	sp,sp,16
ffffffffc0201558:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020155a:	00001697          	auipc	a3,0x1
ffffffffc020155e:	59e68693          	addi	a3,a3,1438 # ffffffffc0202af8 <commands+0x9a8>
ffffffffc0201562:	00001617          	auipc	a2,0x1
ffffffffc0201566:	2a660613          	addi	a2,a2,678 # ffffffffc0202808 <commands+0x6b8>
ffffffffc020156a:	09700593          	li	a1,151
ffffffffc020156e:	00001517          	auipc	a0,0x1
ffffffffc0201572:	2b250513          	addi	a0,a0,690 # ffffffffc0202820 <commands+0x6d0>
ffffffffc0201576:	e6bfe0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(n > 0);
ffffffffc020157a:	00001697          	auipc	a3,0x1
ffffffffc020157e:	28668693          	addi	a3,a3,646 # ffffffffc0202800 <commands+0x6b0>
ffffffffc0201582:	00001617          	auipc	a2,0x1
ffffffffc0201586:	28660613          	addi	a2,a2,646 # ffffffffc0202808 <commands+0x6b8>
ffffffffc020158a:	09400593          	li	a1,148
ffffffffc020158e:	00001517          	auipc	a0,0x1
ffffffffc0201592:	29250513          	addi	a0,a0,658 # ffffffffc0202820 <commands+0x6d0>
ffffffffc0201596:	e4bfe0ef          	jal	ra,ffffffffc02003e0 <__panic>

ffffffffc020159a <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020159a:	1141                	addi	sp,sp,-16
ffffffffc020159c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020159e:	c9e1                	beqz	a1,ffffffffc020166e <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02015a0:	00259693          	slli	a3,a1,0x2
ffffffffc02015a4:	96ae                	add	a3,a3,a1
ffffffffc02015a6:	068e                	slli	a3,a3,0x3
ffffffffc02015a8:	96aa                	add	a3,a3,a0
ffffffffc02015aa:	87aa                	mv	a5,a0
ffffffffc02015ac:	00d50f63          	beq	a0,a3,ffffffffc02015ca <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02015b0:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02015b2:	8b05                	andi	a4,a4,1
ffffffffc02015b4:	cf49                	beqz	a4,ffffffffc020164e <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0; // 将页框的标志位和空闲块大小设置为0
ffffffffc02015b6:	0007a823          	sw	zero,16(a5)
ffffffffc02015ba:	0007b423          	sd	zero,8(a5)
ffffffffc02015be:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015c2:	02878793          	addi	a5,a5,40
ffffffffc02015c6:	fed795e3          	bne	a5,a3,ffffffffc02015b0 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02015ca:	2581                	sext.w	a1,a1
ffffffffc02015cc:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015ce:	4789                	li	a5,2
ffffffffc02015d0:	00850713          	addi	a4,a0,8
ffffffffc02015d4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	a5068693          	addi	a3,a3,-1456 # ffffffffc0206028 <free_area>
ffffffffc02015e0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015e2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015e4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015e8:	9db9                	addw	a1,a1,a4
ffffffffc02015ea:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ec:	04d78a63          	beq	a5,a3,ffffffffc0201640 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02015f0:	fe878713          	addi	a4,a5,-24
ffffffffc02015f4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015f8:	4581                	li	a1,0
            if (base < page)
ffffffffc02015fa:	00e56a63          	bltu	a0,a4,ffffffffc020160e <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc02015fe:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201600:	02d70263          	beq	a4,a3,ffffffffc0201624 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201604:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201606:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020160a:	fee57ae3          	bgeu	a0,a4,ffffffffc02015fe <best_fit_init_memmap+0x64>
ffffffffc020160e:	c199                	beqz	a1,ffffffffc0201614 <best_fit_init_memmap+0x7a>
ffffffffc0201610:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201614:	6398                	ld	a4,0(a5)
}
ffffffffc0201616:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201618:	e390                	sd	a2,0(a5)
ffffffffc020161a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020161c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020161e:	ed18                	sd	a4,24(a0)
ffffffffc0201620:	0141                	addi	sp,sp,16
ffffffffc0201622:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201624:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201626:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201628:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020162a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020162c:	00d70663          	beq	a4,a3,ffffffffc0201638 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201630:	8832                	mv	a6,a2
ffffffffc0201632:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201634:	87ba                	mv	a5,a4
ffffffffc0201636:	bfc1                	j	ffffffffc0201606 <best_fit_init_memmap+0x6c>
}
ffffffffc0201638:	60a2                	ld	ra,8(sp)
ffffffffc020163a:	e290                	sd	a2,0(a3)
ffffffffc020163c:	0141                	addi	sp,sp,16
ffffffffc020163e:	8082                	ret
ffffffffc0201640:	60a2                	ld	ra,8(sp)
ffffffffc0201642:	e390                	sd	a2,0(a5)
ffffffffc0201644:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201646:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201648:	ed1c                	sd	a5,24(a0)
ffffffffc020164a:	0141                	addi	sp,sp,16
ffffffffc020164c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020164e:	00001697          	auipc	a3,0x1
ffffffffc0201652:	4d268693          	addi	a3,a3,1234 # ffffffffc0202b20 <commands+0x9d0>
ffffffffc0201656:	00001617          	auipc	a2,0x1
ffffffffc020165a:	1b260613          	addi	a2,a2,434 # ffffffffc0202808 <commands+0x6b8>
ffffffffc020165e:	04a00593          	li	a1,74
ffffffffc0201662:	00001517          	auipc	a0,0x1
ffffffffc0201666:	1be50513          	addi	a0,a0,446 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020166a:	d77fe0ef          	jal	ra,ffffffffc02003e0 <__panic>
    assert(n > 0);
ffffffffc020166e:	00001697          	auipc	a3,0x1
ffffffffc0201672:	19268693          	addi	a3,a3,402 # ffffffffc0202800 <commands+0x6b0>
ffffffffc0201676:	00001617          	auipc	a2,0x1
ffffffffc020167a:	19260613          	addi	a2,a2,402 # ffffffffc0202808 <commands+0x6b8>
ffffffffc020167e:	04700593          	li	a1,71
ffffffffc0201682:	00001517          	auipc	a0,0x1
ffffffffc0201686:	19e50513          	addi	a0,a0,414 # ffffffffc0202820 <commands+0x6d0>
ffffffffc020168a:	d57fe0ef          	jal	ra,ffffffffc02003e0 <__panic>

ffffffffc020168e <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020168e:	100027f3          	csrr	a5,sstatus
ffffffffc0201692:	8b89                	andi	a5,a5,2
ffffffffc0201694:	e799                	bnez	a5,ffffffffc02016a2 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201696:	00005797          	auipc	a5,0x5
ffffffffc020169a:	de27b783          	ld	a5,-542(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020169e:	6f9c                	ld	a5,24(a5)
ffffffffc02016a0:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02016a2:	1141                	addi	sp,sp,-16
ffffffffc02016a4:	e406                	sd	ra,8(sp)
ffffffffc02016a6:	e022                	sd	s0,0(sp)
ffffffffc02016a8:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02016aa:	966ff0ef          	jal	ra,ffffffffc0200810 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016ae:	00005797          	auipc	a5,0x5
ffffffffc02016b2:	dca7b783          	ld	a5,-566(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016b6:	6f9c                	ld	a5,24(a5)
ffffffffc02016b8:	8522                	mv	a0,s0
ffffffffc02016ba:	9782                	jalr	a5
ffffffffc02016bc:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02016be:	94cff0ef          	jal	ra,ffffffffc020080a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02016c2:	60a2                	ld	ra,8(sp)
ffffffffc02016c4:	8522                	mv	a0,s0
ffffffffc02016c6:	6402                	ld	s0,0(sp)
ffffffffc02016c8:	0141                	addi	sp,sp,16
ffffffffc02016ca:	8082                	ret

ffffffffc02016cc <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016cc:	100027f3          	csrr	a5,sstatus
ffffffffc02016d0:	8b89                	andi	a5,a5,2
ffffffffc02016d2:	e799                	bnez	a5,ffffffffc02016e0 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02016d4:	00005797          	auipc	a5,0x5
ffffffffc02016d8:	da47b783          	ld	a5,-604(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016dc:	739c                	ld	a5,32(a5)
ffffffffc02016de:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02016e0:	1101                	addi	sp,sp,-32
ffffffffc02016e2:	ec06                	sd	ra,24(sp)
ffffffffc02016e4:	e822                	sd	s0,16(sp)
ffffffffc02016e6:	e426                	sd	s1,8(sp)
ffffffffc02016e8:	842a                	mv	s0,a0
ffffffffc02016ea:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02016ec:	924ff0ef          	jal	ra,ffffffffc0200810 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02016f0:	00005797          	auipc	a5,0x5
ffffffffc02016f4:	d887b783          	ld	a5,-632(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016f8:	739c                	ld	a5,32(a5)
ffffffffc02016fa:	85a6                	mv	a1,s1
ffffffffc02016fc:	8522                	mv	a0,s0
ffffffffc02016fe:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201700:	6442                	ld	s0,16(sp)
ffffffffc0201702:	60e2                	ld	ra,24(sp)
ffffffffc0201704:	64a2                	ld	s1,8(sp)
ffffffffc0201706:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201708:	902ff06f          	j	ffffffffc020080a <intr_enable>

ffffffffc020170c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020170c:	100027f3          	csrr	a5,sstatus
ffffffffc0201710:	8b89                	andi	a5,a5,2
ffffffffc0201712:	e799                	bnez	a5,ffffffffc0201720 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201714:	00005797          	auipc	a5,0x5
ffffffffc0201718:	d647b783          	ld	a5,-668(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020171c:	779c                	ld	a5,40(a5)
ffffffffc020171e:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201720:	1141                	addi	sp,sp,-16
ffffffffc0201722:	e406                	sd	ra,8(sp)
ffffffffc0201724:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201726:	8eaff0ef          	jal	ra,ffffffffc0200810 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020172a:	00005797          	auipc	a5,0x5
ffffffffc020172e:	d4e7b783          	ld	a5,-690(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201732:	779c                	ld	a5,40(a5)
ffffffffc0201734:	9782                	jalr	a5
ffffffffc0201736:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201738:	8d2ff0ef          	jal	ra,ffffffffc020080a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020173c:	60a2                	ld	ra,8(sp)
ffffffffc020173e:	8522                	mv	a0,s0
ffffffffc0201740:	6402                	ld	s0,0(sp)
ffffffffc0201742:	0141                	addi	sp,sp,16
ffffffffc0201744:	8082                	ret

ffffffffc0201746 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201746:	00001797          	auipc	a5,0x1
ffffffffc020174a:	40278793          	addi	a5,a5,1026 # ffffffffc0202b48 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020174e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201750:	7179                	addi	sp,sp,-48
ffffffffc0201752:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201754:	00001517          	auipc	a0,0x1
ffffffffc0201758:	42c50513          	addi	a0,a0,1068 # ffffffffc0202b80 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020175c:	00005417          	auipc	s0,0x5
ffffffffc0201760:	d1c40413          	addi	s0,s0,-740 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201764:	f406                	sd	ra,40(sp)
ffffffffc0201766:	ec26                	sd	s1,24(sp)
ffffffffc0201768:	e44e                	sd	s3,8(sp)
ffffffffc020176a:	e84a                	sd	s2,16(sp)
ffffffffc020176c:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020176e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201770:	977fe0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    pmm_manager->init();
ffffffffc0201774:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201776:	00005497          	auipc	s1,0x5
ffffffffc020177a:	d1a48493          	addi	s1,s1,-742 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc020177e:	679c                	ld	a5,8(a5)
ffffffffc0201780:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201782:	57f5                	li	a5,-3
ffffffffc0201784:	07fa                	slli	a5,a5,0x1e
ffffffffc0201786:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201788:	86eff0ef          	jal	ra,ffffffffc02007f6 <get_memory_base>
ffffffffc020178c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020178e:	872ff0ef          	jal	ra,ffffffffc0200800 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201792:	16050163          	beqz	a0,ffffffffc02018f4 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201796:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201798:	00001517          	auipc	a0,0x1
ffffffffc020179c:	43050513          	addi	a0,a0,1072 # ffffffffc0202bc8 <best_fit_pmm_manager+0x80>
ffffffffc02017a0:	947fe0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017a4:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02017a8:	864e                	mv	a2,s3
ffffffffc02017aa:	fffa0693          	addi	a3,s4,-1
ffffffffc02017ae:	85ca                	mv	a1,s2
ffffffffc02017b0:	00001517          	auipc	a0,0x1
ffffffffc02017b4:	43050513          	addi	a0,a0,1072 # ffffffffc0202be0 <best_fit_pmm_manager+0x98>
ffffffffc02017b8:	92ffe0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02017bc:	c80007b7          	lui	a5,0xc8000
ffffffffc02017c0:	8652                	mv	a2,s4
ffffffffc02017c2:	0d47e863          	bltu	a5,s4,ffffffffc0201892 <pmm_init+0x14c>
ffffffffc02017c6:	00006797          	auipc	a5,0x6
ffffffffc02017ca:	cd978793          	addi	a5,a5,-807 # ffffffffc020749f <end+0xfff>
ffffffffc02017ce:	757d                	lui	a0,0xfffff
ffffffffc02017d0:	8d7d                	and	a0,a0,a5
ffffffffc02017d2:	8231                	srli	a2,a2,0xc
ffffffffc02017d4:	00005597          	auipc	a1,0x5
ffffffffc02017d8:	c9458593          	addi	a1,a1,-876 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017dc:	00005817          	auipc	a6,0x5
ffffffffc02017e0:	c9480813          	addi	a6,a6,-876 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02017e4:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02017e6:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017ea:	000807b7          	lui	a5,0x80
ffffffffc02017ee:	02f60663          	beq	a2,a5,ffffffffc020181a <pmm_init+0xd4>
ffffffffc02017f2:	4701                	li	a4,0
ffffffffc02017f4:	4781                	li	a5,0
ffffffffc02017f6:	4305                	li	t1,1
ffffffffc02017f8:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc02017fc:	953a                	add	a0,a0,a4
ffffffffc02017fe:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc0201802:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201806:	6190                	ld	a2,0(a1)
ffffffffc0201808:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020180a:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020180e:	011606b3          	add	a3,a2,a7
ffffffffc0201812:	02870713          	addi	a4,a4,40
ffffffffc0201816:	fed7e3e3          	bltu	a5,a3,ffffffffc02017fc <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020181a:	00261693          	slli	a3,a2,0x2
ffffffffc020181e:	96b2                	add	a3,a3,a2
ffffffffc0201820:	fec007b7          	lui	a5,0xfec00
ffffffffc0201824:	97aa                	add	a5,a5,a0
ffffffffc0201826:	068e                	slli	a3,a3,0x3
ffffffffc0201828:	96be                	add	a3,a3,a5
ffffffffc020182a:	c02007b7          	lui	a5,0xc0200
ffffffffc020182e:	0af6e763          	bltu	a3,a5,ffffffffc02018dc <pmm_init+0x196>
ffffffffc0201832:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201834:	77fd                	lui	a5,0xfffff
ffffffffc0201836:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020183a:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020183c:	04b6ee63          	bltu	a3,a1,ffffffffc0201898 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201840:	601c                	ld	a5,0(s0)
ffffffffc0201842:	7b9c                	ld	a5,48(a5)
ffffffffc0201844:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201846:	00001517          	auipc	a0,0x1
ffffffffc020184a:	42250513          	addi	a0,a0,1058 # ffffffffc0202c68 <best_fit_pmm_manager+0x120>
ffffffffc020184e:	899fe0ef          	jal	ra,ffffffffc02000e6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201852:	00003597          	auipc	a1,0x3
ffffffffc0201856:	7ae58593          	addi	a1,a1,1966 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020185a:	00005797          	auipc	a5,0x5
ffffffffc020185e:	c2b7b723          	sd	a1,-978(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201862:	c02007b7          	lui	a5,0xc0200
ffffffffc0201866:	0af5e363          	bltu	a1,a5,ffffffffc020190c <pmm_init+0x1c6>
ffffffffc020186a:	6090                	ld	a2,0(s1)
}
ffffffffc020186c:	7402                	ld	s0,32(sp)
ffffffffc020186e:	70a2                	ld	ra,40(sp)
ffffffffc0201870:	64e2                	ld	s1,24(sp)
ffffffffc0201872:	6942                	ld	s2,16(sp)
ffffffffc0201874:	69a2                	ld	s3,8(sp)
ffffffffc0201876:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201878:	40c58633          	sub	a2,a1,a2
ffffffffc020187c:	00005797          	auipc	a5,0x5
ffffffffc0201880:	c0c7b223          	sd	a2,-1020(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201884:	00001517          	auipc	a0,0x1
ffffffffc0201888:	40450513          	addi	a0,a0,1028 # ffffffffc0202c88 <best_fit_pmm_manager+0x140>
}
ffffffffc020188c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020188e:	859fe06f          	j	ffffffffc02000e6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201892:	c8000637          	lui	a2,0xc8000
ffffffffc0201896:	bf05                	j	ffffffffc02017c6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201898:	6705                	lui	a4,0x1
ffffffffc020189a:	177d                	addi	a4,a4,-1
ffffffffc020189c:	96ba                	add	a3,a3,a4
ffffffffc020189e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018a0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018a4:	02c7f063          	bgeu	a5,a2,ffffffffc02018c4 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02018a8:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02018aa:	fff80737          	lui	a4,0xfff80
ffffffffc02018ae:	973e                	add	a4,a4,a5
ffffffffc02018b0:	00271793          	slli	a5,a4,0x2
ffffffffc02018b4:	97ba                	add	a5,a5,a4
ffffffffc02018b6:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02018b8:	8d95                	sub	a1,a1,a3
ffffffffc02018ba:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02018bc:	81b1                	srli	a1,a1,0xc
ffffffffc02018be:	953e                	add	a0,a0,a5
ffffffffc02018c0:	9702                	jalr	a4
}
ffffffffc02018c2:	bfbd                	j	ffffffffc0201840 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02018c4:	00001617          	auipc	a2,0x1
ffffffffc02018c8:	37460613          	addi	a2,a2,884 # ffffffffc0202c38 <best_fit_pmm_manager+0xf0>
ffffffffc02018cc:	06b00593          	li	a1,107
ffffffffc02018d0:	00001517          	auipc	a0,0x1
ffffffffc02018d4:	38850513          	addi	a0,a0,904 # ffffffffc0202c58 <best_fit_pmm_manager+0x110>
ffffffffc02018d8:	b09fe0ef          	jal	ra,ffffffffc02003e0 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018dc:	00001617          	auipc	a2,0x1
ffffffffc02018e0:	33460613          	addi	a2,a2,820 # ffffffffc0202c10 <best_fit_pmm_manager+0xc8>
ffffffffc02018e4:	07100593          	li	a1,113
ffffffffc02018e8:	00001517          	auipc	a0,0x1
ffffffffc02018ec:	2d050513          	addi	a0,a0,720 # ffffffffc0202bb8 <best_fit_pmm_manager+0x70>
ffffffffc02018f0:	af1fe0ef          	jal	ra,ffffffffc02003e0 <__panic>
        panic("DTB memory info not available");
ffffffffc02018f4:	00001617          	auipc	a2,0x1
ffffffffc02018f8:	2a460613          	addi	a2,a2,676 # ffffffffc0202b98 <best_fit_pmm_manager+0x50>
ffffffffc02018fc:	05a00593          	li	a1,90
ffffffffc0201900:	00001517          	auipc	a0,0x1
ffffffffc0201904:	2b850513          	addi	a0,a0,696 # ffffffffc0202bb8 <best_fit_pmm_manager+0x70>
ffffffffc0201908:	ad9fe0ef          	jal	ra,ffffffffc02003e0 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020190c:	86ae                	mv	a3,a1
ffffffffc020190e:	00001617          	auipc	a2,0x1
ffffffffc0201912:	30260613          	addi	a2,a2,770 # ffffffffc0202c10 <best_fit_pmm_manager+0xc8>
ffffffffc0201916:	08c00593          	li	a1,140
ffffffffc020191a:	00001517          	auipc	a0,0x1
ffffffffc020191e:	29e50513          	addi	a0,a0,670 # ffffffffc0202bb8 <best_fit_pmm_manager+0x70>
ffffffffc0201922:	abffe0ef          	jal	ra,ffffffffc02003e0 <__panic>

ffffffffc0201926 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201926:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020192a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020192c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201930:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201932:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201936:	f022                	sd	s0,32(sp)
ffffffffc0201938:	ec26                	sd	s1,24(sp)
ffffffffc020193a:	e84a                	sd	s2,16(sp)
ffffffffc020193c:	f406                	sd	ra,40(sp)
ffffffffc020193e:	e44e                	sd	s3,8(sp)
ffffffffc0201940:	84aa                	mv	s1,a0
ffffffffc0201942:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201944:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201948:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020194a:	03067e63          	bgeu	a2,a6,ffffffffc0201986 <printnum+0x60>
ffffffffc020194e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201950:	00805763          	blez	s0,ffffffffc020195e <printnum+0x38>
ffffffffc0201954:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201956:	85ca                	mv	a1,s2
ffffffffc0201958:	854e                	mv	a0,s3
ffffffffc020195a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020195c:	fc65                	bnez	s0,ffffffffc0201954 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020195e:	1a02                	slli	s4,s4,0x20
ffffffffc0201960:	00001797          	auipc	a5,0x1
ffffffffc0201964:	36878793          	addi	a5,a5,872 # ffffffffc0202cc8 <best_fit_pmm_manager+0x180>
ffffffffc0201968:	020a5a13          	srli	s4,s4,0x20
ffffffffc020196c:	9a3e                	add	s4,s4,a5
}
ffffffffc020196e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201970:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201974:	70a2                	ld	ra,40(sp)
ffffffffc0201976:	69a2                	ld	s3,8(sp)
ffffffffc0201978:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020197a:	85ca                	mv	a1,s2
ffffffffc020197c:	87a6                	mv	a5,s1
}
ffffffffc020197e:	6942                	ld	s2,16(sp)
ffffffffc0201980:	64e2                	ld	s1,24(sp)
ffffffffc0201982:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201984:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201986:	03065633          	divu	a2,a2,a6
ffffffffc020198a:	8722                	mv	a4,s0
ffffffffc020198c:	f9bff0ef          	jal	ra,ffffffffc0201926 <printnum>
ffffffffc0201990:	b7f9                	j	ffffffffc020195e <printnum+0x38>

ffffffffc0201992 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201992:	7119                	addi	sp,sp,-128
ffffffffc0201994:	f4a6                	sd	s1,104(sp)
ffffffffc0201996:	f0ca                	sd	s2,96(sp)
ffffffffc0201998:	ecce                	sd	s3,88(sp)
ffffffffc020199a:	e8d2                	sd	s4,80(sp)
ffffffffc020199c:	e4d6                	sd	s5,72(sp)
ffffffffc020199e:	e0da                	sd	s6,64(sp)
ffffffffc02019a0:	fc5e                	sd	s7,56(sp)
ffffffffc02019a2:	f06a                	sd	s10,32(sp)
ffffffffc02019a4:	fc86                	sd	ra,120(sp)
ffffffffc02019a6:	f8a2                	sd	s0,112(sp)
ffffffffc02019a8:	f862                	sd	s8,48(sp)
ffffffffc02019aa:	f466                	sd	s9,40(sp)
ffffffffc02019ac:	ec6e                	sd	s11,24(sp)
ffffffffc02019ae:	892a                	mv	s2,a0
ffffffffc02019b0:	84ae                	mv	s1,a1
ffffffffc02019b2:	8d32                	mv	s10,a2
ffffffffc02019b4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019b6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02019ba:	5b7d                	li	s6,-1
ffffffffc02019bc:	00001a97          	auipc	s5,0x1
ffffffffc02019c0:	340a8a93          	addi	s5,s5,832 # ffffffffc0202cfc <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019c4:	00001b97          	auipc	s7,0x1
ffffffffc02019c8:	514b8b93          	addi	s7,s7,1300 # ffffffffc0202ed8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019cc:	000d4503          	lbu	a0,0(s10)
ffffffffc02019d0:	001d0413          	addi	s0,s10,1
ffffffffc02019d4:	01350a63          	beq	a0,s3,ffffffffc02019e8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02019d8:	c121                	beqz	a0,ffffffffc0201a18 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02019da:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019dc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02019de:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019e0:	fff44503          	lbu	a0,-1(s0)
ffffffffc02019e4:	ff351ae3          	bne	a0,s3,ffffffffc02019d8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019e8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02019ec:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02019f0:	4c81                	li	s9,0
ffffffffc02019f2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02019f4:	5c7d                	li	s8,-1
ffffffffc02019f6:	5dfd                	li	s11,-1
ffffffffc02019f8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02019fc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019fe:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a02:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a06:	00140d13          	addi	s10,s0,1
ffffffffc0201a0a:	04b56263          	bltu	a0,a1,ffffffffc0201a4e <vprintfmt+0xbc>
ffffffffc0201a0e:	058a                	slli	a1,a1,0x2
ffffffffc0201a10:	95d6                	add	a1,a1,s5
ffffffffc0201a12:	4194                	lw	a3,0(a1)
ffffffffc0201a14:	96d6                	add	a3,a3,s5
ffffffffc0201a16:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a18:	70e6                	ld	ra,120(sp)
ffffffffc0201a1a:	7446                	ld	s0,112(sp)
ffffffffc0201a1c:	74a6                	ld	s1,104(sp)
ffffffffc0201a1e:	7906                	ld	s2,96(sp)
ffffffffc0201a20:	69e6                	ld	s3,88(sp)
ffffffffc0201a22:	6a46                	ld	s4,80(sp)
ffffffffc0201a24:	6aa6                	ld	s5,72(sp)
ffffffffc0201a26:	6b06                	ld	s6,64(sp)
ffffffffc0201a28:	7be2                	ld	s7,56(sp)
ffffffffc0201a2a:	7c42                	ld	s8,48(sp)
ffffffffc0201a2c:	7ca2                	ld	s9,40(sp)
ffffffffc0201a2e:	7d02                	ld	s10,32(sp)
ffffffffc0201a30:	6de2                	ld	s11,24(sp)
ffffffffc0201a32:	6109                	addi	sp,sp,128
ffffffffc0201a34:	8082                	ret
            padc = '0';
ffffffffc0201a36:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a38:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a3c:	846a                	mv	s0,s10
ffffffffc0201a3e:	00140d13          	addi	s10,s0,1
ffffffffc0201a42:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a46:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a4a:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a0e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201a4e:	85a6                	mv	a1,s1
ffffffffc0201a50:	02500513          	li	a0,37
ffffffffc0201a54:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a56:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a5a:	8d22                	mv	s10,s0
ffffffffc0201a5c:	f73788e3          	beq	a5,s3,ffffffffc02019cc <vprintfmt+0x3a>
ffffffffc0201a60:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a64:	1d7d                	addi	s10,s10,-1
ffffffffc0201a66:	ff379de3          	bne	a5,s3,ffffffffc0201a60 <vprintfmt+0xce>
ffffffffc0201a6a:	b78d                	j	ffffffffc02019cc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201a6c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201a70:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a74:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201a76:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201a7a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201a7e:	02d86463          	bltu	a6,a3,ffffffffc0201aa6 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201a82:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201a86:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201a8a:	0186873b          	addw	a4,a3,s8
ffffffffc0201a8e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201a92:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201a94:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201a98:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201a9a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201a9e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201aa2:	fed870e3          	bgeu	a6,a3,ffffffffc0201a82 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201aa6:	f40ddce3          	bgez	s11,ffffffffc02019fe <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201aaa:	8de2                	mv	s11,s8
ffffffffc0201aac:	5c7d                	li	s8,-1
ffffffffc0201aae:	bf81                	j	ffffffffc02019fe <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201ab0:	fffdc693          	not	a3,s11
ffffffffc0201ab4:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ab6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aba:	00144603          	lbu	a2,1(s0)
ffffffffc0201abe:	2d81                	sext.w	s11,s11
ffffffffc0201ac0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201ac2:	bf35                	j	ffffffffc02019fe <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201ac4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ac8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201acc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ace:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201ad0:	bfd9                	j	ffffffffc0201aa6 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201ad2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ad4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ad8:	01174463          	blt	a4,a7,ffffffffc0201ae0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201adc:	1a088e63          	beqz	a7,ffffffffc0201c98 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201ae0:	000a3603          	ld	a2,0(s4)
ffffffffc0201ae4:	46c1                	li	a3,16
ffffffffc0201ae6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201ae8:	2781                	sext.w	a5,a5
ffffffffc0201aea:	876e                	mv	a4,s11
ffffffffc0201aec:	85a6                	mv	a1,s1
ffffffffc0201aee:	854a                	mv	a0,s2
ffffffffc0201af0:	e37ff0ef          	jal	ra,ffffffffc0201926 <printnum>
            break;
ffffffffc0201af4:	bde1                	j	ffffffffc02019cc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201af6:	000a2503          	lw	a0,0(s4)
ffffffffc0201afa:	85a6                	mv	a1,s1
ffffffffc0201afc:	0a21                	addi	s4,s4,8
ffffffffc0201afe:	9902                	jalr	s2
            break;
ffffffffc0201b00:	b5f1                	j	ffffffffc02019cc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b02:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b04:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b08:	01174463          	blt	a4,a7,ffffffffc0201b10 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b0c:	18088163          	beqz	a7,ffffffffc0201c8e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b10:	000a3603          	ld	a2,0(s4)
ffffffffc0201b14:	46a9                	li	a3,10
ffffffffc0201b16:	8a2e                	mv	s4,a1
ffffffffc0201b18:	bfc1                	j	ffffffffc0201ae8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b1a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b1e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b20:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b22:	bdf1                	j	ffffffffc02019fe <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b24:	85a6                	mv	a1,s1
ffffffffc0201b26:	02500513          	li	a0,37
ffffffffc0201b2a:	9902                	jalr	s2
            break;
ffffffffc0201b2c:	b545                	j	ffffffffc02019cc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b2e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b32:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b34:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b36:	b5e1                	j	ffffffffc02019fe <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b38:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b3a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b3e:	01174463          	blt	a4,a7,ffffffffc0201b46 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b42:	14088163          	beqz	a7,ffffffffc0201c84 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b46:	000a3603          	ld	a2,0(s4)
ffffffffc0201b4a:	46a1                	li	a3,8
ffffffffc0201b4c:	8a2e                	mv	s4,a1
ffffffffc0201b4e:	bf69                	j	ffffffffc0201ae8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201b50:	03000513          	li	a0,48
ffffffffc0201b54:	85a6                	mv	a1,s1
ffffffffc0201b56:	e03e                	sd	a5,0(sp)
ffffffffc0201b58:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b5a:	85a6                	mv	a1,s1
ffffffffc0201b5c:	07800513          	li	a0,120
ffffffffc0201b60:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b62:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b64:	6782                	ld	a5,0(sp)
ffffffffc0201b66:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b68:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201b6c:	bfb5                	j	ffffffffc0201ae8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b6e:	000a3403          	ld	s0,0(s4)
ffffffffc0201b72:	008a0713          	addi	a4,s4,8
ffffffffc0201b76:	e03a                	sd	a4,0(sp)
ffffffffc0201b78:	14040263          	beqz	s0,ffffffffc0201cbc <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201b7c:	0fb05763          	blez	s11,ffffffffc0201c6a <vprintfmt+0x2d8>
ffffffffc0201b80:	02d00693          	li	a3,45
ffffffffc0201b84:	0cd79163          	bne	a5,a3,ffffffffc0201c46 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b88:	00044783          	lbu	a5,0(s0)
ffffffffc0201b8c:	0007851b          	sext.w	a0,a5
ffffffffc0201b90:	cf85                	beqz	a5,ffffffffc0201bc8 <vprintfmt+0x236>
ffffffffc0201b92:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b96:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b9a:	000c4563          	bltz	s8,ffffffffc0201ba4 <vprintfmt+0x212>
ffffffffc0201b9e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201ba0:	036c0263          	beq	s8,s6,ffffffffc0201bc4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201ba4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ba6:	0e0c8e63          	beqz	s9,ffffffffc0201ca2 <vprintfmt+0x310>
ffffffffc0201baa:	3781                	addiw	a5,a5,-32
ffffffffc0201bac:	0ef47b63          	bgeu	s0,a5,ffffffffc0201ca2 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201bb0:	03f00513          	li	a0,63
ffffffffc0201bb4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bb6:	000a4783          	lbu	a5,0(s4)
ffffffffc0201bba:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bbc:	0a05                	addi	s4,s4,1
ffffffffc0201bbe:	0007851b          	sext.w	a0,a5
ffffffffc0201bc2:	ffe1                	bnez	a5,ffffffffc0201b9a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201bc4:	01b05963          	blez	s11,ffffffffc0201bd6 <vprintfmt+0x244>
ffffffffc0201bc8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201bca:	85a6                	mv	a1,s1
ffffffffc0201bcc:	02000513          	li	a0,32
ffffffffc0201bd0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bd2:	fe0d9be3          	bnez	s11,ffffffffc0201bc8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bd6:	6a02                	ld	s4,0(sp)
ffffffffc0201bd8:	bbd5                	j	ffffffffc02019cc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bda:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bdc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201be0:	01174463          	blt	a4,a7,ffffffffc0201be8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201be4:	08088d63          	beqz	a7,ffffffffc0201c7e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201be8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201bec:	0a044d63          	bltz	s0,ffffffffc0201ca6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201bf0:	8622                	mv	a2,s0
ffffffffc0201bf2:	8a66                	mv	s4,s9
ffffffffc0201bf4:	46a9                	li	a3,10
ffffffffc0201bf6:	bdcd                	j	ffffffffc0201ae8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201bf8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201bfc:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201bfe:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c00:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c04:	8fb5                	xor	a5,a5,a3
ffffffffc0201c06:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c0a:	02d74163          	blt	a4,a3,ffffffffc0201c2c <vprintfmt+0x29a>
ffffffffc0201c0e:	00369793          	slli	a5,a3,0x3
ffffffffc0201c12:	97de                	add	a5,a5,s7
ffffffffc0201c14:	639c                	ld	a5,0(a5)
ffffffffc0201c16:	cb99                	beqz	a5,ffffffffc0201c2c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c18:	86be                	mv	a3,a5
ffffffffc0201c1a:	00001617          	auipc	a2,0x1
ffffffffc0201c1e:	0de60613          	addi	a2,a2,222 # ffffffffc0202cf8 <best_fit_pmm_manager+0x1b0>
ffffffffc0201c22:	85a6                	mv	a1,s1
ffffffffc0201c24:	854a                	mv	a0,s2
ffffffffc0201c26:	0ce000ef          	jal	ra,ffffffffc0201cf4 <printfmt>
ffffffffc0201c2a:	b34d                	j	ffffffffc02019cc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c2c:	00001617          	auipc	a2,0x1
ffffffffc0201c30:	0bc60613          	addi	a2,a2,188 # ffffffffc0202ce8 <best_fit_pmm_manager+0x1a0>
ffffffffc0201c34:	85a6                	mv	a1,s1
ffffffffc0201c36:	854a                	mv	a0,s2
ffffffffc0201c38:	0bc000ef          	jal	ra,ffffffffc0201cf4 <printfmt>
ffffffffc0201c3c:	bb41                	j	ffffffffc02019cc <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c3e:	00001417          	auipc	s0,0x1
ffffffffc0201c42:	0a240413          	addi	s0,s0,162 # ffffffffc0202ce0 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c46:	85e2                	mv	a1,s8
ffffffffc0201c48:	8522                	mv	a0,s0
ffffffffc0201c4a:	e43e                	sd	a5,8(sp)
ffffffffc0201c4c:	200000ef          	jal	ra,ffffffffc0201e4c <strnlen>
ffffffffc0201c50:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c54:	01b05b63          	blez	s11,ffffffffc0201c6a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201c58:	67a2                	ld	a5,8(sp)
ffffffffc0201c5a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c5e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201c60:	85a6                	mv	a1,s1
ffffffffc0201c62:	8552                	mv	a0,s4
ffffffffc0201c64:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c66:	fe0d9ce3          	bnez	s11,ffffffffc0201c5e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c6a:	00044783          	lbu	a5,0(s0)
ffffffffc0201c6e:	00140a13          	addi	s4,s0,1
ffffffffc0201c72:	0007851b          	sext.w	a0,a5
ffffffffc0201c76:	d3a5                	beqz	a5,ffffffffc0201bd6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c78:	05e00413          	li	s0,94
ffffffffc0201c7c:	bf39                	j	ffffffffc0201b9a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201c7e:	000a2403          	lw	s0,0(s4)
ffffffffc0201c82:	b7ad                	j	ffffffffc0201bec <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201c84:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c88:	46a1                	li	a3,8
ffffffffc0201c8a:	8a2e                	mv	s4,a1
ffffffffc0201c8c:	bdb1                	j	ffffffffc0201ae8 <vprintfmt+0x156>
ffffffffc0201c8e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c92:	46a9                	li	a3,10
ffffffffc0201c94:	8a2e                	mv	s4,a1
ffffffffc0201c96:	bd89                	j	ffffffffc0201ae8 <vprintfmt+0x156>
ffffffffc0201c98:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c9c:	46c1                	li	a3,16
ffffffffc0201c9e:	8a2e                	mv	s4,a1
ffffffffc0201ca0:	b5a1                	j	ffffffffc0201ae8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201ca2:	9902                	jalr	s2
ffffffffc0201ca4:	bf09                	j	ffffffffc0201bb6 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201ca6:	85a6                	mv	a1,s1
ffffffffc0201ca8:	02d00513          	li	a0,45
ffffffffc0201cac:	e03e                	sd	a5,0(sp)
ffffffffc0201cae:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201cb0:	6782                	ld	a5,0(sp)
ffffffffc0201cb2:	8a66                	mv	s4,s9
ffffffffc0201cb4:	40800633          	neg	a2,s0
ffffffffc0201cb8:	46a9                	li	a3,10
ffffffffc0201cba:	b53d                	j	ffffffffc0201ae8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201cbc:	03b05163          	blez	s11,ffffffffc0201cde <vprintfmt+0x34c>
ffffffffc0201cc0:	02d00693          	li	a3,45
ffffffffc0201cc4:	f6d79de3          	bne	a5,a3,ffffffffc0201c3e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201cc8:	00001417          	auipc	s0,0x1
ffffffffc0201ccc:	01840413          	addi	s0,s0,24 # ffffffffc0202ce0 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cd0:	02800793          	li	a5,40
ffffffffc0201cd4:	02800513          	li	a0,40
ffffffffc0201cd8:	00140a13          	addi	s4,s0,1
ffffffffc0201cdc:	bd6d                	j	ffffffffc0201b96 <vprintfmt+0x204>
ffffffffc0201cde:	00001a17          	auipc	s4,0x1
ffffffffc0201ce2:	003a0a13          	addi	s4,s4,3 # ffffffffc0202ce1 <best_fit_pmm_manager+0x199>
ffffffffc0201ce6:	02800513          	li	a0,40
ffffffffc0201cea:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cee:	05e00413          	li	s0,94
ffffffffc0201cf2:	b565                	j	ffffffffc0201b9a <vprintfmt+0x208>

ffffffffc0201cf4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cf4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201cf6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cfa:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201cfc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201cfe:	ec06                	sd	ra,24(sp)
ffffffffc0201d00:	f83a                	sd	a4,48(sp)
ffffffffc0201d02:	fc3e                	sd	a5,56(sp)
ffffffffc0201d04:	e0c2                	sd	a6,64(sp)
ffffffffc0201d06:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d08:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d0a:	c89ff0ef          	jal	ra,ffffffffc0201992 <vprintfmt>
}
ffffffffc0201d0e:	60e2                	ld	ra,24(sp)
ffffffffc0201d10:	6161                	addi	sp,sp,80
ffffffffc0201d12:	8082                	ret

ffffffffc0201d14 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d14:	715d                	addi	sp,sp,-80
ffffffffc0201d16:	e486                	sd	ra,72(sp)
ffffffffc0201d18:	e0a6                	sd	s1,64(sp)
ffffffffc0201d1a:	fc4a                	sd	s2,56(sp)
ffffffffc0201d1c:	f84e                	sd	s3,48(sp)
ffffffffc0201d1e:	f452                	sd	s4,40(sp)
ffffffffc0201d20:	f056                	sd	s5,32(sp)
ffffffffc0201d22:	ec5a                	sd	s6,24(sp)
ffffffffc0201d24:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d26:	c901                	beqz	a0,ffffffffc0201d36 <readline+0x22>
ffffffffc0201d28:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d2a:	00001517          	auipc	a0,0x1
ffffffffc0201d2e:	fce50513          	addi	a0,a0,-50 # ffffffffc0202cf8 <best_fit_pmm_manager+0x1b0>
ffffffffc0201d32:	bb4fe0ef          	jal	ra,ffffffffc02000e6 <cprintf>
readline(const char *prompt) {
ffffffffc0201d36:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d38:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d3a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d3c:	4aa9                	li	s5,10
ffffffffc0201d3e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d40:	00004b97          	auipc	s7,0x4
ffffffffc0201d44:	300b8b93          	addi	s7,s7,768 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d48:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201d4c:	c12fe0ef          	jal	ra,ffffffffc020015e <getchar>
        if (c < 0) {
ffffffffc0201d50:	00054a63          	bltz	a0,ffffffffc0201d64 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d54:	00a95a63          	bge	s2,a0,ffffffffc0201d68 <readline+0x54>
ffffffffc0201d58:	029a5263          	bge	s4,s1,ffffffffc0201d7c <readline+0x68>
        c = getchar();
ffffffffc0201d5c:	c02fe0ef          	jal	ra,ffffffffc020015e <getchar>
        if (c < 0) {
ffffffffc0201d60:	fe055ae3          	bgez	a0,ffffffffc0201d54 <readline+0x40>
            return NULL;
ffffffffc0201d64:	4501                	li	a0,0
ffffffffc0201d66:	a091                	j	ffffffffc0201daa <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201d68:	03351463          	bne	a0,s3,ffffffffc0201d90 <readline+0x7c>
ffffffffc0201d6c:	e8a9                	bnez	s1,ffffffffc0201dbe <readline+0xaa>
        c = getchar();
ffffffffc0201d6e:	bf0fe0ef          	jal	ra,ffffffffc020015e <getchar>
        if (c < 0) {
ffffffffc0201d72:	fe0549e3          	bltz	a0,ffffffffc0201d64 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d76:	fea959e3          	bge	s2,a0,ffffffffc0201d68 <readline+0x54>
ffffffffc0201d7a:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201d7c:	e42a                	sd	a0,8(sp)
ffffffffc0201d7e:	b9efe0ef          	jal	ra,ffffffffc020011c <cputchar>
            buf[i ++] = c;
ffffffffc0201d82:	6522                	ld	a0,8(sp)
ffffffffc0201d84:	009b87b3          	add	a5,s7,s1
ffffffffc0201d88:	2485                	addiw	s1,s1,1
ffffffffc0201d8a:	00a78023          	sb	a0,0(a5)
ffffffffc0201d8e:	bf7d                	j	ffffffffc0201d4c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201d90:	01550463          	beq	a0,s5,ffffffffc0201d98 <readline+0x84>
ffffffffc0201d94:	fb651ce3          	bne	a0,s6,ffffffffc0201d4c <readline+0x38>
            cputchar(c);
ffffffffc0201d98:	b84fe0ef          	jal	ra,ffffffffc020011c <cputchar>
            buf[i] = '\0';
ffffffffc0201d9c:	00004517          	auipc	a0,0x4
ffffffffc0201da0:	2a450513          	addi	a0,a0,676 # ffffffffc0206040 <buf>
ffffffffc0201da4:	94aa                	add	s1,s1,a0
ffffffffc0201da6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201daa:	60a6                	ld	ra,72(sp)
ffffffffc0201dac:	6486                	ld	s1,64(sp)
ffffffffc0201dae:	7962                	ld	s2,56(sp)
ffffffffc0201db0:	79c2                	ld	s3,48(sp)
ffffffffc0201db2:	7a22                	ld	s4,40(sp)
ffffffffc0201db4:	7a82                	ld	s5,32(sp)
ffffffffc0201db6:	6b62                	ld	s6,24(sp)
ffffffffc0201db8:	6bc2                	ld	s7,16(sp)
ffffffffc0201dba:	6161                	addi	sp,sp,80
ffffffffc0201dbc:	8082                	ret
            cputchar(c);
ffffffffc0201dbe:	4521                	li	a0,8
ffffffffc0201dc0:	b5cfe0ef          	jal	ra,ffffffffc020011c <cputchar>
            i --;
ffffffffc0201dc4:	34fd                	addiw	s1,s1,-1
ffffffffc0201dc6:	b759                	j	ffffffffc0201d4c <readline+0x38>

ffffffffc0201dc8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201dc8:	4781                	li	a5,0
ffffffffc0201dca:	00004717          	auipc	a4,0x4
ffffffffc0201dce:	24e73703          	ld	a4,590(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dd2:	88ba                	mv	a7,a4
ffffffffc0201dd4:	852a                	mv	a0,a0
ffffffffc0201dd6:	85be                	mv	a1,a5
ffffffffc0201dd8:	863e                	mv	a2,a5
ffffffffc0201dda:	00000073          	ecall
ffffffffc0201dde:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201de0:	8082                	ret

ffffffffc0201de2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201de2:	4781                	li	a5,0
ffffffffc0201de4:	00004717          	auipc	a4,0x4
ffffffffc0201de8:	6b473703          	ld	a4,1716(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201dec:	88ba                	mv	a7,a4
ffffffffc0201dee:	852a                	mv	a0,a0
ffffffffc0201df0:	85be                	mv	a1,a5
ffffffffc0201df2:	863e                	mv	a2,a5
ffffffffc0201df4:	00000073          	ecall
ffffffffc0201df8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201dfa:	8082                	ret

ffffffffc0201dfc <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201dfc:	4501                	li	a0,0
ffffffffc0201dfe:	00004797          	auipc	a5,0x4
ffffffffc0201e02:	2127b783          	ld	a5,530(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e06:	88be                	mv	a7,a5
ffffffffc0201e08:	852a                	mv	a0,a0
ffffffffc0201e0a:	85aa                	mv	a1,a0
ffffffffc0201e0c:	862a                	mv	a2,a0
ffffffffc0201e0e:	00000073          	ecall
ffffffffc0201e12:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e14:	2501                	sext.w	a0,a0
ffffffffc0201e16:	8082                	ret

ffffffffc0201e18 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e18:	4781                	li	a5,0
ffffffffc0201e1a:	00004717          	auipc	a4,0x4
ffffffffc0201e1e:	20673703          	ld	a4,518(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e22:	88ba                	mv	a7,a4
ffffffffc0201e24:	853e                	mv	a0,a5
ffffffffc0201e26:	85be                	mv	a1,a5
ffffffffc0201e28:	863e                	mv	a2,a5
ffffffffc0201e2a:	00000073          	ecall
ffffffffc0201e2e:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e30:	8082                	ret

ffffffffc0201e32 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e32:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e36:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e38:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e3a:	cb81                	beqz	a5,ffffffffc0201e4a <strlen+0x18>
        cnt ++;
ffffffffc0201e3c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e3e:	00a707b3          	add	a5,a4,a0
ffffffffc0201e42:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e46:	fbfd                	bnez	a5,ffffffffc0201e3c <strlen+0xa>
ffffffffc0201e48:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e4a:	8082                	ret

ffffffffc0201e4c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e4c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e4e:	e589                	bnez	a1,ffffffffc0201e58 <strnlen+0xc>
ffffffffc0201e50:	a811                	j	ffffffffc0201e64 <strnlen+0x18>
        cnt ++;
ffffffffc0201e52:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e54:	00f58863          	beq	a1,a5,ffffffffc0201e64 <strnlen+0x18>
ffffffffc0201e58:	00f50733          	add	a4,a0,a5
ffffffffc0201e5c:	00074703          	lbu	a4,0(a4)
ffffffffc0201e60:	fb6d                	bnez	a4,ffffffffc0201e52 <strnlen+0x6>
ffffffffc0201e62:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e64:	852e                	mv	a0,a1
ffffffffc0201e66:	8082                	ret

ffffffffc0201e68 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e68:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e6c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e70:	cb89                	beqz	a5,ffffffffc0201e82 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201e72:	0505                	addi	a0,a0,1
ffffffffc0201e74:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e76:	fee789e3          	beq	a5,a4,ffffffffc0201e68 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e7a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201e7e:	9d19                	subw	a0,a0,a4
ffffffffc0201e80:	8082                	ret
ffffffffc0201e82:	4501                	li	a0,0
ffffffffc0201e84:	bfed                	j	ffffffffc0201e7e <strcmp+0x16>

ffffffffc0201e86 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e86:	c20d                	beqz	a2,ffffffffc0201ea8 <strncmp+0x22>
ffffffffc0201e88:	962e                	add	a2,a2,a1
ffffffffc0201e8a:	a031                	j	ffffffffc0201e96 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201e8c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e8e:	00e79a63          	bne	a5,a4,ffffffffc0201ea2 <strncmp+0x1c>
ffffffffc0201e92:	00b60b63          	beq	a2,a1,ffffffffc0201ea8 <strncmp+0x22>
ffffffffc0201e96:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201e9a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e9c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201ea0:	f7f5                	bnez	a5,ffffffffc0201e8c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ea2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201ea6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ea8:	4501                	li	a0,0
ffffffffc0201eaa:	8082                	ret

ffffffffc0201eac <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201eac:	00054783          	lbu	a5,0(a0)
ffffffffc0201eb0:	c799                	beqz	a5,ffffffffc0201ebe <strchr+0x12>
        if (*s == c) {
ffffffffc0201eb2:	00f58763          	beq	a1,a5,ffffffffc0201ec0 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201eb6:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201eba:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201ebc:	fbfd                	bnez	a5,ffffffffc0201eb2 <strchr+0x6>
    }
    return NULL;
ffffffffc0201ebe:	4501                	li	a0,0
}
ffffffffc0201ec0:	8082                	ret

ffffffffc0201ec2 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ec2:	ca01                	beqz	a2,ffffffffc0201ed2 <memset+0x10>
ffffffffc0201ec4:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ec6:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ec8:	0785                	addi	a5,a5,1
ffffffffc0201eca:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201ece:	fec79de3          	bne	a5,a2,ffffffffc0201ec8 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ed2:	8082                	ret
