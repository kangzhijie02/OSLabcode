#ifndef __KERN_MM_SLUB_PMM_H__
#define  __KERN_MM_SLUB_PMM_H__

#include <pmm.h>

extern const struct pmm_manager slub_pmm_manager;
#define CACHE_NUM 6
#define PAGE_SIZE 4096
#define le2slub(le, member)                 \
    to_struct((le), struct slab, member)
#endif /* ! __KERN_MM_SLUB_PMM_H__ */
