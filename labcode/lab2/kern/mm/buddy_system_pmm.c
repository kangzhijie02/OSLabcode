#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>
/*
设计文档：
buddy system实现效果为初始化小于可用内存的最大2次幂内存块。分配内存块时，分配大于等于需求内存块的最小2次幂内存块大小，
然后需要在现有的可空闲链表找到符合次幂的内存块，如果没有需要将大内存块进行分裂找到合适的内存块，其余内存块继续连接到空闲链表中。
释放过程中需要在空闲链表中找到该内存块的伙伴块，如果存在将两个内存块合并为更大的内存块，然后进行回溯直到不存在伙伴块或达到最大次幂
为止。如果不存在伙伴块，就将该空闲块连接到对应的空闲链表中。现对buddy system实现数据结构及函数进行设计：
数据结构：
Page：每个内存块还是使用Page表示
free_area[MAX_ORDER + 1]：使用数组表示不同order次幂的链表，比如free_area[order]表示该链表中都是2的order次幂大小的空闲内存块。
在文档中分析可知，DRAM默认大小为128MB，但是实际小于128MB，所以将MAX_ORDER设置为15。
函数：
buddy_system_init：对声明的链表进行初始化，并且将nr_free（表示该链表中空闲块数量)初始化为0.

buddy_system_init_memmap：首先检查并确保内存块数量n大于0，然后遍历所有页面，清零标志位、属性值和引用计数。
接着计算最大可用阶数max_order，并设置全局变量MAX_ORDERS、MAX_PAGES和BASE_ADDR。将起始页面base的属性设置为max_order，标记为可用属性页，
最后将其插入对应阶数的空闲链表free_area[max_order]中，并递增该阶数的空闲块计数。完成初始化后，系统即可使用伙伴算法管理这些内存块。

buddy_system_alloc_pages:首先检查请求页数n的合法性，并计算所需阶数order。从order开始向上遍历空闲链表，找到第一个可用的空闲块。
将该块从链表中移除，并减少对应阶数的空闲块计数。如果当前块阶数大于所需阶数，则进行分裂：将剩余部分作为伙伴块插入低一阶的空闲链表，直到块大小与需求匹配。
最后清除分配块的Property标志，设置实际分配大小，返回分配页的指针。若找不到合适内存块则返回NULL。

buddy_system_free_pages：首先验证释放页面的合法性，初始化页面属性并将引用计数清零。
然后尝试与相邻的伙伴块合并：从当前阶数开始向上遍历，若找到对应的空闲伙伴块，则将其从链表中移除，合并成更高阶的大内存块。
合并过程持续直到无法找到伙伴块或达到最大阶数为止。最后将合并后的内存块插入对应阶数的空闲链表，并更新空闲块计数，完成内存回收。

buddy_system_check:通过多阶段测试验证内存管理器的正确性。首先检查初始状态，然后进行基本分配、非2幂次方分配和小块分配测试。
接着测试内存释放与合并功能，验证大块分配能力。最后进行伙伴块分配与释放测试，模拟相邻内存块的合并过程。
每个测试阶段都通过断言验证结果，并调用状态检查函数输出内存使用情况，验证伙伴系统的分配、释放和合并机制是否正常工作。

buddy_system_nr_free_pages:使用for循环和格式化输出函数cprintf输出每个空闲链表的状态，即其对应的空闲块的数量。
由于free_area[i]的属性nr_free表示当前链表空闲内存块数量。free_area[i].nr_free*(1<<i)
表示当前链表中空闲页的总数量，所以使用for循环得到空闲总数量。

辅助函数：
order_down:使用while循环每次向右移一位，直到找到最高位的1,此时order表示了log2 n的下取整。
order_up：使用while循环找到第一个比n大的数，此时order即为该数的次幂，表示了log2 n的上取整。
设计好数据结构以及函数后，接下来就要实现buddy system。
*/
static free_area_t free_area[MAX_ORDER + 1];
static unsigned int MAX_PAGES;
static unsigned int MAX_ORDERS;
static uintptr_t BASE_ADDR;
// 使用位运算实现n的指数向下取整，确保内存块不会大于现有内存
unsigned int order_down(size_t n)
{
    if (n == 0)
        return 0;
    // 找到最高位1的位置
    unsigned int order = 0;
    while (n >>= 1)
    {
        order++;
    }
    return order;
}
// 使用位运算实现n的指数向上取整，确保选取的内存块比申请的要大。
unsigned int order_up(size_t n)
{
    if (n == 0)
        return 0;
    unsigned int order = 0;
    size_t size = 1;
    // 找到第一个大于等于n的2的幂
    while (size < n)
    {
        order++;
        size <<= 1;
    }

    return order;
}
//初始化空闲链表和空闲块数
void buddy_system_init(void)
{
    for (int i = 0; i <= MAX_ORDER; i++)
    {
        list_init(&(free_area[i].free_list));
        free_area[i].nr_free = 0;
    }
}
void buddy_system_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0); // 确保初始化内存块大于0
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = p->property = 0; // 将页框的标志位和空闲块大小设置为0
        set_page_ref(p, 0);         // 把页框的引用计数器归零，表示未被虚拟页引用
    }
    unsigned int max_order = order_down(n);
    MAX_ORDERS = max_order;
    MAX_PAGES = (1 << max_order);
    BASE_ADDR = page2pa(base);
    cprintf("%d 的地址：%p\n", n, BASE_ADDR);
    base->property = max_order;
    SetPageProperty(base);
    list_add(&(free_area[max_order].free_list), &(base->page_link)); // 将该内存块加入链表
    free_area[max_order].nr_free++;                                  // 当前该大小的块加1
}

struct Page *buddy_system_alloc_pages(size_t n)
{
    // 判断请求的页面数n是否合法
    assert(n > 0 && n <= MAX_PAGES);
    unsigned int order = order_up(n);//找到比申请块大的最小空闲块
    //分配空闲块的过程
    for (unsigned int i = order; i <= MAX_ORDERS; i++)
    {
        if (free_area[i].nr_free > 0)
        {
            list_entry_t *le = list_next(&free_area[i].free_list);
            struct Page *p = le2page(le, page_link);
            list_del(&(p->page_link));
            free_area[i].nr_free--;
            unsigned int cur_order = i;
            //对空闲块开始分割
            while (cur_order > order)
            {
                cur_order--;
                struct Page *buddy = p + (1UL << cur_order);
                buddy->property = cur_order;
                SetPageProperty(buddy);
                list_add(&(free_area[cur_order].free_list), &(buddy->page_link)); // 将该内存块加入链表
                free_area[cur_order].nr_free++;
            }
            p->property = 1 << order;
            ClearPageProperty(p);
            //cprintf("%d bloack address：%p,flages:%x,property:%d\n", n, (page2pa(p) - BASE_ADDR), p->flags, p->property);
            return p;
        }
    }
    return NULL;
}
struct Page *buddy_block(struct Page *base, size_t order)
{
    unsigned long n = 1 << order;
    unsigned long res = (page2pa(base) - BASE_ADDR) / (n * PAGE_SIZE);
    struct Page *p = NULL;
    if (res % 2 == 0)
        p = base + n;
    else
        p = base - n;
    if (PageProperty(p) && (p->property == order))
        return p;
    else
        return NULL;
}
bool buddy_location(struct Page *base, size_t order)
{
    unsigned long n = 1 << order;
    unsigned long res = (page2pa(base) - BASE_ADDR) / (n * PAGE_SIZE);
    if (res % 2 == 0)
        return true;
    else
        return false;
}

void buddy_system_free_pages(struct Page *base, size_t n)
{
    assert(n > 0 && n <= MAX_PAGES);
    unsigned int order = order_up(n);
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    while (order < MAX_ORDERS)
    {
        if (buddy_block(base, order) != NULL)
        {
            struct Page *page = buddy_block(base, order);
            list_del(&(page->page_link));
            free_area[order].nr_free--;
            if (!buddy_location(base, order)){
                ClearPageProperty(base);
                base = page;

            }
            else{
                 ClearPageProperty(page);
            }
            order++;
        }
        else
            break;
    }
    base->property = order;
    SetPageProperty(base);
    list_add(&free_area[order].free_list, &(base->page_link));
    free_area[order].nr_free++;
}

size_t buddy_system_nr_free_pages(void)
{
    size_t total_free = 0;
    for (int i = 0; i <= MAX_ORDERS; i++)
    {
        cprintf("free_area[%d]'s Total free count: %d\n", i, free_area[i].nr_free);
        total_free += free_area[i].nr_free * (1 << i);
    }
    cprintf("Total free pages:%d\n", total_free);
    cprintf("================================\n");
    return total_free;
}
void buddy_system_check(void)
{
    cprintf("========== Buddy System Check ==========\n");

    // 初始状态
    cprintf("1. Initial state:\n");
    buddy_system_nr_free_pages();

    // 测试基本分配
    cprintf("2. Basic allocation test:\n");
    struct Page *p1 = buddy_system_alloc_pages(32);
    assert(p1 != NULL);
    assert(p1->property==32 && !PageProperty(p1));
    buddy_system_nr_free_pages();
    

    struct Page *p2 = buddy_system_alloc_pages(64);
    assert(p2 != NULL);
    assert(p2->property==64 && !PageProperty(p2));
    buddy_system_nr_free_pages();
    

    struct Page *p3 = buddy_system_alloc_pages(16);
    assert(p3 != NULL);
    assert(p3->property==16 && !PageProperty(p3));
    buddy_system_nr_free_pages();
    

    // 测试非2的幂次方分配
   cprintf("3. Non-power-of-two allocation:\n");
    struct Page *p4 = buddy_system_alloc_pages(30); // 应该向上取整到32
    assert(p4 != NULL);
    assert(p4->property==32 && !PageProperty(p4));
    buddy_system_nr_free_pages();
    

    // 测试小分配
    cprintf("4. Small allocation:\n");
    struct Page *p5 = buddy_system_alloc_pages(1);
    assert(p5 != NULL);
    buddy_system_nr_free_pages();
   

    // 测试释放和合并
    cprintf("5. Free and merge test:\n");
    buddy_system_free_pages(p1, 32);
    buddy_system_nr_free_pages();
    

    buddy_system_free_pages(p3, 16);
    buddy_system_nr_free_pages();
    

    // 测试大分配
    cprintf("6. Large allocation:\n");
    struct Page *p6 = buddy_system_alloc_pages(8192);
    if (p6 != NULL)
    {
        buddy_system_nr_free_pages();
        
        buddy_system_free_pages(p6, 8192);
    }

    // 清理所有分配
   cprintf("7. Cleanup all allocations:\n");
    buddy_system_free_pages(p2, 64);
    buddy_system_free_pages(p4, 32);
    buddy_system_free_pages(p5, 1);

    // 清理分配后的状态
    cprintf("8. Cleanup state:\n");
    buddy_system_nr_free_pages();
    
    // 伙伴块分配和合并
    cprintf("9. Buddy block alloc and free:\n");
    struct Page *p7 = buddy_system_alloc_pages(128);
    assert(p7 != NULL);
    assert(p7->property==128 && !PageProperty(p7));
    struct Page *p8 = buddy_system_alloc_pages(128);
    assert(p8 != NULL);
    assert(p8->property==128 && !PageProperty(p8));
   buddy_system_nr_free_pages();
    
    buddy_system_free_pages(p7, 128);
    buddy_system_nr_free_pages();
    
    buddy_system_free_pages(p8, 128);
    cprintf("10. Final state:\n");
    buddy_system_nr_free_pages();
    //非法内存分配
    //struct Page *p9 = buddy_system_alloc_pages(16385);
    //struct Page *p10 = buddy_system_alloc_pages(0);
    // 12. 重复分配释放测试
    cprintf("11. Repeated alloc/free test:\n");
    for (int i = 0; i < 5; i++) {
        struct Page *temp = buddy_system_alloc_pages(64);
        assert(temp != NULL);
        buddy_system_free_pages(temp, 64);
    }
    buddy_system_nr_free_pages();
    
    cprintf("========== Buddy System Check Completed ==========\n");
}
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};
