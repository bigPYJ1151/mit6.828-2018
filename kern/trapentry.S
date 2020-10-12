/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num, ec, user)						\
.text; 															\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */				\
	name:			/* function starts here */					\
	.if ec==0; 													\
		pushl $0; 												\
	.endif;														\
	pushl $(num);												\
	jmp _alltraps; 												\
.data;															\
	.long name, num, user									
/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
/*#define TRAPHANDLER_NOEC(name, num)					\
*	.globl name;							\
*	.type name, @function;						\
*	.align 2;							\
*	name:								\
*	pushl $0;							\
*	pushl $(num);							\
*	jmp _alltraps
*/

.data
	.globl entry_data
	entry_data:

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(divide_e, T_DIVIDE, 0, 0);
TRAPHANDLER(debug_e, T_DEBUG, 0, 0); 
TRAPHANDLER(nmi_e, T_NMI, 0, 0); 
TRAPHANDLER(brkpt_e, T_BRKPT, 0, 1); 
TRAPHANDLER(oflow_e, T_OFLOW, 0, 0); 
TRAPHANDLER(bound_e, T_BOUND, 0, 0);
TRAPHANDLER(illop_e, T_ILLOP, 0, 0); 
TRAPHANDLER(device_e, T_DEVICE, 0, 0); 
TRAPHANDLER(dblflt_e, T_DBLFLT, 1, 0); 
TRAPHANDLER(tss_e, T_TSS, 1, 0); 
TRAPHANDLER(segnp_e, T_SEGNP, 1, 0); 
TRAPHANDLER(stack_e, T_STACK, 1, 0); 
TRAPHANDLER(gpflt_e, T_GPFLT, 1, 0); 
TRAPHANDLER(pgflt_e, T_PGFLT, 1, 0); 
TRAPHANDLER(fperr_e, T_FPERR, 0, 0); 
TRAPHANDLER(align_e, T_ALIGN, 1, 0); 
TRAPHANDLER(mchk_e, T_MCHK, 0, 0); 
TRAPHANDLER(simderr_e, T_SIMDERR, 0, 0); 
TRAPHANDLER(syscall_e, T_SYSCALL, 0, 1); 

TRAPHANDLER(irq_0, IRQ_OFFSET + 0, 0, 0); 
TRAPHANDLER(irq_1, IRQ_OFFSET + 1, 0, 0); 
TRAPHANDLER(irq_2, IRQ_OFFSET + 2, 0, 0); 
TRAPHANDLER(irq_3, IRQ_OFFSET + 3, 0, 0); 
TRAPHANDLER(irq_4, IRQ_OFFSET + 4, 0, 0); 
TRAPHANDLER(irq_5, IRQ_OFFSET + 5, 0, 0); 
TRAPHANDLER(irq_6, IRQ_OFFSET + 6, 0, 0); 
TRAPHANDLER(irq_7, IRQ_OFFSET + 7, 0, 0); 
TRAPHANDLER(irq_8, IRQ_OFFSET + 8, 0, 0); 
TRAPHANDLER(irq_9, IRQ_OFFSET + 9, 0, 0); 
TRAPHANDLER(irq_10, IRQ_OFFSET + 10, 0, 0); 
TRAPHANDLER(irq_11, IRQ_OFFSET + 11, 0, 0); 
TRAPHANDLER(irq_12, IRQ_OFFSET + 12, 0, 0); 
TRAPHANDLER(irq_13, IRQ_OFFSET + 13, 0, 0); 
TRAPHANDLER(irq_14, IRQ_OFFSET + 14, 0, 0); 
TRAPHANDLER(irq_15, IRQ_OFFSET + 15, 0, 0); 

.data
	.long 0, 0, 0;

/*
 * Lab 3: Your code here for _alltraps
 */


.text;
_alltraps:
	pushl %ds 
	pushl %es 
	pushal

	// Save FPU
	// subl $524, %esp
	// fxsave (%esp)

	movl $GD_KD, %eax
	movl %eax, %ds 
	movl %eax, %es 

	push %esp 
	call trap