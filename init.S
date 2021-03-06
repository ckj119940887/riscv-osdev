#include "const.h"

.section .text, "ax", %progbits
.globl kernel_entry
kernel_entry:
  # setup paging
  la t0, boot_pdpt
  srli t0, t0, PGSHIFT
  li t1, SATP_SV39
  or t0, t0, t1
  csrw satp, t0

  # reallocate
  la t0, reallocated
  li t1, KERNBASE
  add t0, t0, t1
  add a1, a1, t1
  jr t0

reallocated:
  # setup traps
  la t0, __alltraps
  csrw stvec, t0

  # setup sp
  mv sp, a0
  addi sp, sp, 1
  slli sp, sp, PGSHIFT
  la t0, boot_kstack
  add sp, sp, t0

  # a0 = hartid
  # a1 = fdt
  tail kmain

.section .data
.balign PGSIZE
.globl boot_pdpt
boot_pdpt:
  .space PDPX(PHY_MEM_BASE) * PTE_SIZE - (. - boot_pdpt)
  # map va PHY_MEM_BASE + (0G~1G) to pa PHY_MEM_BASE + (0G~1G) (temporary)
  .quad PHY_MEM_BASE / 4 + (PTE_V | PTE_R | PTE_W | PTE_X)
  .space PDPX(KERNBASE) * PTE_SIZE - (. - boot_pdpt)
  # map va KERNBASE + (0G~4G) to pa 0G~4G
  .quad 0x00000000 / 4 + (PTE_V | PTE_R | PTE_W | PTE_X)
  .quad 0x40000000 / 4 + (PTE_V | PTE_R | PTE_W | PTE_X)
  .quad 0x80000000 / 4 + (PTE_V | PTE_R | PTE_W | PTE_X)
  .quad 0xC0000000 / 4 + (PTE_V | PTE_R | PTE_W | PTE_X)
  .space PGSIZE - (. - boot_pdpt)

.section .bss
boot_kstack:
.balign PGSIZE
  .space MAX_HARTS * PGSIZE
boot_kstack_end:

.globl virtq
virtq:
.balign PGSIZE
  .space PGSIZE
