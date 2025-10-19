#ifndef __KERN_MM_BUDDY_SYSTEM_PMM_H__
#define  __KERN_MM_BUDDY_SYSTEM_PMM_H__

#include <pmm.h>

extern const struct pmm_manager buddy_system_pmm_manager;
#define MAX_ORDER 15
#define true 1
#define false 0
#define PAGE_SIZE 4096
unsigned int order_down(size_t n);
unsigned int order_up(size_t n);
void buddy_system_init(void);
void buddy_system_init_memmap(struct Page *base, size_t n);
struct Page *buddy_system_alloc_pages(size_t n);
struct Page *buddy_block(struct Page *base, size_t order);
bool buddy_location(struct Page *base, size_t order);
void buddy_system_free_pages(struct Page *base, size_t n);
size_t buddy_system_nr_free_pages(void);
void buddy_system_check(void);
#endif /* ! __KERN_MM_BUDDY_SYSTEM_PMM_H__ */

