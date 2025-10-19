#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <slub_pmm.h>
#include <buddy_system_pmm.h>
/*
slub的核心原理：buddy system分配页级别的内存块，如果用户需要申请字节大小的内存，buddy system会产生大量
内存碎片，降低内存利用率。所以设计slub进行字节级别的被村分配。slub的数据结构以及函数如下：
数据结构：
kmem_cache:实现slab的管理。slab_full连接完全分配的slab，slabs_partial连接部分分配的slab，
slabs_free连接完全未分配的slab。obj_size表示不同cache中slab的大小，obj_count表示分配一页内存后可以得到
多少个对象。一页的开始为slab结构，然后是obj。
slab:对obj对象进行管理。slab_link用于连接slab自身到链表中，objlist用于连接对象，每个未分配的对象开始为
链接指针，分配后整个obj用于存储数据。指针start标记每一页对象开始的地址。free_cnt表示该slab中未分配
对象的个数，in_use表示该slab中已经分配对象的个数。
函数：
*cache_init，slub_init：
slub_init()函数是总的初始化函数，依次调用buddy_system_init()和cache_init()完成两级初始化。
其中buddy_system_init()负责底层伙伴系统的初始化，为SLUB分配器提供基础的物理页面管理能力。
其次，cache_init()函数精心构建6个不同大小的对象缓存，规格分别为32、64、128、256,512和1024字节。
代码初始化了三个关键链表：slabs_full，slabs_partial，slabs_free。同时，函数精确计算每个slab页能够容纳的对象数量。
*create_slab
该函数实现SLUB分配器的slab创建过程。首先进行大小验证并调用伙伴系统分配物理页面，将页面起始地址作为slab管理头。
然后初始化slab元数据。随后将页面剩余空间划分为等大小对象，为每个对象初始化链表节点并加入objlist空闲链表。
最后将新建的slab连接到对应大小的缓存池空闲链表中。
*slub_alloc_objs
该函数实现SLUB分配器的对象分配核心逻辑。首先需要进行边界检查，拒绝超过1024字节的大对象请求，该请求可以让伙伴系统实现。
通过order_up计算对齐后的大小，在五级缓存中寻找首个足够大的缓存池。然后，优先从部分空闲slab分配，
其次从完全空闲slab分配，同时将其移至部分空闲链表。最后如果部分空闲，完全空闲slab为空，就创建新slab。
根据slab状态变化动态调整其所属链表，当对象用尽时移至全满链表，从空闲变为使用时移至部分空闲链表。
*slub_free_objs
该函数实现SLUB分配器的对象释放与内存回收。通过对象地址定位所属slab及缓存，将被释放对象重新链入slab空闲队列。
根据slab状态变化进行回收，当所有对象释放后（in_use=0），清空slab并归还物理页至伙伴系统。
当从全满状态释放首个对象时（free_cnt=1），将slab移回部分分配链表。
*slub_check
该函数实现对slub内存管理算法的准确性验证，通过不同方面的测试对slub实现进行验证。

*/

struct kmem_cache
{
    list_entry_t slabs_full;    // 连接完全分配的slab
    list_entry_t slabs_partial; // 连接部分分配的slab
    list_entry_t slabs_free;    // 连接完全未分配的slab
    size_t obj_size;            // slab中对象大小
    size_t obj_count;           // 每个slab中的空闲对象数量
};
struct slab
{
    size_t id;
    list_entry_t slab_link; // 连接slab
    list_entry_t objlist;   // 连接对象obj
    void *start;            // 空闲对象开始的地方
    size_t free_cnt;        // 该slab中空闲obj数量
    size_t in_use;          // 正在使用的对象数量
} slab;
static struct kmem_cache cache[CACHE_NUM];
static size_t SLAB_SIZE;
static size_t id=1;
// cache 32,64,128,256,512,1024
static void cache_init(void)
{
    size_t size = 32;
    SLAB_SIZE = sizeof(slab);
    for (int i = 0; i < CACHE_NUM; i++)
    {
        list_init(&(cache[i].slabs_full));
        list_init(&(cache[i].slabs_partial));
        list_init(&(cache[i].slabs_free));
        cache[i].obj_size = size;
        cache[i].obj_count = (PAGE_SIZE - SLAB_SIZE) / size;
        size <<= 1;
    }
}
static void slub_init(void)
{
    buddy_system_init();
    cache_init();
}
static void slub_init_memmap(struct Page *base, size_t n)
{
    buddy_system_init_memmap(base, n);
}

static struct slab *create_slab(size_t size)
{
    if(size>1024)return NULL;
    struct Page *p = buddy_system_alloc_pages(1); // 申请一页内存
    if (p == NULL)
        return NULL;                                   // 确保申请页不为空
    struct slab *s = (struct slab *)KADDR(page2pa(p)); // slab存在页头
    list_init(&(s->slab_link));                        // 初始化slab链表指针
    list_init(&(s->objlist));                          // 初始化对象指针
    s->id=id;
    id++;
    size = (size + 7) & ~7; // 向上对齐到8字节边界，size+7确保至少达到下一个边界，～7去除低三位，即8字节边界对其
    s->free_cnt = (PAGE_SIZE - SLAB_SIZE) / size;
    s->in_use = 0;
    s->start = KADDR(page2pa(p)) + SLAB_SIZE; // 对象开始的地方
    //cprintf("create slab%d:s->free_cnt=%d,s->in_use=%d,s->start=%p\n",s->id,s->free_cnt,s->in_use,s->start);
    char *obj_ptr = s->start;
    // 初始化所有对象，对象开头即为前向后向指针
    for (size_t i = 0; i < s->free_cnt; i++)
    {
        list_entry_t *le = (list_entry_t *)obj_ptr;
        list_init(le);             // 初始化prev/next指针
        list_add_before(&s->objlist, le); // 加入空闲链表
        obj_ptr += size;
    }
    // 将slab加入对应cache中
    for (int i = 0; i < CACHE_NUM; i++)
    {
        if (cache[i].obj_size == size)
        {
            list_add(&(cache[i].slabs_free), &(s->slab_link));
            break;
        }
    }
    return s;
}
// n表示申请的字节数
static void* slub_alloc_objs(size_t n)
{
    if(n>1024)return NULL;
    size_t order = order_up(n);
    size_t bit_cnt=1<<order;
    list_entry_t *le;
    struct slab *target_slab = NULL; // 目标slab，从中获取对象
    struct kmem_cache* ca=NULL;
    for (int i = 0; i < CACHE_NUM; i++)
    {
        if (cache[i].obj_size >= bit_cnt)
        {
            //如果部分空闲链表不空
            if (!list_empty(&(cache[i].slabs_partial)))
            {
                le = list_next(&(cache[i].slabs_partial));
                target_slab = le2slub(le, slab_link);
                ca=&cache[i];
                break;
                //如果全部空闲链表不空
            }else if(!list_empty(&(cache[i].slabs_free))){
                le = list_next(&(cache[i].slabs_free));
                target_slab = le2slub(le, slab_link);
                list_del(le);
                list_add(&(cache[i].slabs_partial),le);
                ca=&cache[i];
                break;
                //如果部分空闲链表，全部可空闲链表均为空
            }else{
                target_slab=create_slab(cache[i].obj_size);
                if(!target_slab)return NULL ;
                else{
                le = list_next(&(cache[i].slabs_free));
                target_slab = le2slub(le, slab_link);
                list_del(le);
                list_add(&(cache[i].slabs_partial),le);
                ca=&cache[i];
                break;
                }

            }
        }
    }
    if(target_slab!=NULL && ca!=NULL && !list_empty(&target_slab->objlist)){
        le=list_next(&(target_slab->objlist));
        list_del(le);
        target_slab->free_cnt--;
        target_slab->in_use++;
        //表示slab由部分分配变为全部分配
        if(target_slab->free_cnt==0){
            list_del(&(target_slab->slab_link));
            list_add(&(ca->slabs_full),&(target_slab->slab_link));
        }
        ////表示slab由完全不分配变为部分分配
        if(target_slab->in_use==1){
            list_del(&(target_slab->slab_link));
            list_add(&(ca->slabs_partial),&(target_slab->slab_link));
        }
        //cprintf("slub%d:s->free_cnt=%d,s->in_use=%d,obj_address=%p\n",target_slab->id,target_slab->free_cnt,target_slab->in_use,le);
        return (void*)le;


    }
    return NULL;
}
static struct Page * slub_alloc_pages(size_t n){
    slub_alloc_objs(n);
    return NULL;
}
static struct kmem_cache* slab2cache(struct slab* s){
    for(int i=0;i<CACHE_NUM;i++){
        //slab_full
        list_entry_t*le=&(cache[i].slabs_full);
        while((le=list_next(le))!=&(cache[i].slabs_full)){
            struct slab* a=le2slub(le,slab_link);
            if(a==s)return &(cache[i]);
        }
        //slab_partial
        le=&(cache[i].slabs_partial);
        while((le=list_next(le))!=&(cache[i].slabs_partial)){
            struct slab* a=le2slub(le,slab_link);
            if(a==s)return &(cache[i]);
        }
        //不可能在slab_free里面
    }
    return NULL;
}
static void slub_free_objs(struct Page* p, size_t n)
{
    void * obj=(void *)p;
    //memset(obj,0,n);//清理申请内存
    struct slab* s=(struct slab*)((uintptr_t)obj&~(PAGE_SIZE-1));//由obj找到slab的位置
    struct kmem_cache* c=slab2cache(s);
    if(c){
    list_add(&(s->objlist),obj);//将对象添加到slab的空闲队列中
    s->free_cnt++;
    s->in_use--;
    //表示该slab现在为空闲slab，需要加入到slab_free
    if(s->in_use==0){
        list_del(&(s->slab_link));//从slab_partial中删除s
        //list_add(&(c->slabs_free),&(s->slab_link));//不需要添加到slab_free
        //接着将该slab删除，归还到上一级。
        memset(s,0,PAGE_SIZE);
        struct Page *page = pa2page(PADDR(s));
        //重置Page结构的状态
        page->flags=page->ref = 0;  // 清除所有标志,引用计数归零
        page->property = 1;  // 设置为1页大小
        //SetPageProperty(page);  // 标记为空闲
        buddy_system_free_pages(page,1);

    }
    //表示该slab现在为部分分配的slab，需要从slab_full摘除，放到slab_partial
    if(s->free_cnt==1){
        list_del(&(s->slab_link));//从slab_full中删除
        list_add(&(c->slabs_partial),&(s->slab_link));//添加到slab_partial

    }

    }
    return;
}

static size_t slub_nr_free_pages(void)
{
   /* for (int i = 0; i < CACHE_NUM; i++) {
        cprintf("Cache[%d]: obj_size=%d, obj_count=%d\n", 
                i, cache[i].obj_size, cache[i].obj_count);
        
        // 统计各链表的slab数量
        int full_count = 0, partial_count = 0, free_count = 0;
        list_entry_t *le = &cache[i].slabs_full;
        while ((le = list_next(le)) != &cache[i].slabs_full) {
            full_count++;
        }
        le = &cache[i].slabs_partial;
        while ((le = list_next(le)) != &cache[i].slabs_partial) {
            partial_count++;
        }
        le = &cache[i].slabs_free;
        while ((le = list_next(le)) != &cache[i].slabs_free) {
            free_count++;
        }
        
        cprintf("  full: %d, partial: %d, free: %d\n", 
                full_count, partial_count, free_count);
    }*/
    
    return buddy_system_nr_free_pages();
}
static void slub_check(void)
{
    cprintf("----------slub_check------------\n");
    cprintf("slab size=%d\n",SLAB_SIZE);
    cprintf("1.创建slab实例：\n");
    create_slab(32);
    create_slab(64);
    create_slab(256);
    slub_nr_free_pages();
    cprintf("2.对象分配与释放\n");
    void* a=slub_alloc_objs(32);
    void*b=slub_alloc_objs(64);
    slub_nr_free_pages();
    slub_free_objs(a,32);
    slub_free_objs(b,64);
    slub_nr_free_pages();
    cprintf("2.对象超额分配与释放\n");
    void* obj_256[17];
    for(int i=0;i<17;i++){
        obj_256[i]=slub_alloc_objs(256);
    }
    slub_nr_free_pages();
    for(int i=0;i<17;i++){
        slub_free_objs(obj_256[i],256);
    }
    slub_nr_free_pages();
    cprintf("3.不创建slab，直接分配对象\n");
    void* obj_1024[6];
    for(int i=0;i<6;i++){
        obj_1024[i]=slub_alloc_objs(1024);
    }
    slub_nr_free_pages();
    for(int i=0;i<6;i++){
        slub_free_objs(obj_1024[i],1024);
    }
    slub_nr_free_pages();
    cprintf("4.创建违法slab以及违法分配对象\n");
    struct slab* s=create_slab(2048);
    assert(s==NULL);
    slub_nr_free_pages();
    void*obj_2048=slub_alloc_objs(2048);
    assert(obj_2048==NULL);
    slub_nr_free_pages();
    cprintf("5.连续分配释放对象\n");
    for(int i=0;i<100;i++){
        void*obj=slub_alloc_objs(512);
        slub_free_objs(obj,512);
    }
    slub_nr_free_pages();


}
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_objs,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};