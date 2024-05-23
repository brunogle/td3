OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

_ISR_INIT = 0x00000000; /* Comienzo del ISR */

_ROM_INIT = 0x70010000; /* Direccion del comienzo de la ROM. */

/* Direccion del comienzo de la stack.
Aca van a estar todos los stacks para todos los modos */
_STACK_INIT = 0x70020000;

_RAM_INIT = 0x70030000;

C_STACK_SIZE   = 8K;
IRQ_STACK_SIZE = 8K;
FIQ_STACK_SIZE = 8K;
SVC_STACK_SIZE = 8K;
ABT_STACK_SIZE = 8K;
UND_STACK_SIZE = 8K;




MEMORY 
{
    isr(rwx) : org = _ISR_INIT, len = 0x40

    rom(rwx) : org = _ROM_INIT, len = 16k

    /* Direccion del stack  */
    stack(rw) : org = _STACK_INIT, len = 48k

    /* Direccion de RAM. El bootloader va a copiar el kernel aca */
    ram(rwx) : org = _RAM_INIT, len = 64k
}


SECTIONS
{
    /*
    Para esta seccion, se ejecuta donde se carga (VMA=LMA)
    */
    .bootloader :
    {
        *(.bootloader*);
       
    } >rom


    .isr_table :
    {
        *(.isr_table*);
    } >isr AT>rom
    /* Defino simbolos con valores numericos importantes para realizar la copia del LMA */
    _ISR_LOAD = LOADADDR(.isr_table); /* LMA del ISR */
    _ISR_SIZE = SIZEOF(.isr_table); /* size del ISR */



    .kernel : 
    {
        *(.kernel*);
        *(.handlers*);
    } >ram AT>rom
    /* Defino simbolos con valores numericos importantes para realizar la copia del kernel */
    _KERNEL_INIT = ADDR(.kernel); /* VMA del kernel */
    _KERNEL_LOAD = LOADADDR(.kernel); /* LMA del kernel */
    _KERNEL_SIZE = SIZEOF(.kernel); /* size del kernel */

    /* Data */
    .bss :
    {
        *(.bss*)
    } > ram


    /* Tablas de paginacion */
    .page_tables : ALIGN(16K)
    {
        _L1_PAGE_TABLES_INIT = .;
        . += 4096*4;
        _L2_PAGE_TABLES_INIT = .;
    } > ram


    .stack :
        {
        __stack_start__ = .;
        . += IRQ_STACK_SIZE;
        . = ALIGN(4);
        __irq_stack_top__ = .;

        . += FIQ_STACK_SIZE;
        . = ALIGN(4);
        __fiq_stack_top__ = .;

        . += SVC_STACK_SIZE;
        . = ALIGN(4);
        __svc_stack_top__ = .;

        . += ABT_STACK_SIZE;
        . = ALIGN(4);
        __abt_stack_top__ = .;

        . += UND_STACK_SIZE;
        . = ALIGN(4);
        __und_stack_top__ = .;

        . += C_STACK_SIZE;
        . = ALIGN(4);
        __sys_stack_top__ = .;

        __stack_end__ = .;
        } > stack


}