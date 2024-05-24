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
        *(.bootloader);
    } >rom

    /*
    Todas las secciones text* son copiadas a RAM para su ejecucion (VMA!=LMA)
    */
    .text : 
    {
        *(.text*);
    } >ram AT>rom
    /* Defino simbolos con valores numericos importantes para realizar la copia de la seccion */
    _TEXT_INIT = ADDR(.text); /* VMA del kernel */
    _TEXT_LOAD = LOADADDR(.text); /* LMA del kernel */
    _TEXT_SIZE = SIZEOF(.text); /* size del kernel */

    /* Variables globales y estaticas no inicializados. Se inicializa a cero */
    .bss :
    {
        *(.bss*)
    } > ram

    /* Variables globales y estaticas inicializadas */
    .data :
    {
        *(.data*)
    } > ram

    /* Datos constantes */
    .rodata :
    {
        *(.rodata*)
    } > ram

    /* Tabla de interrupciones */
    .isr_table :
    {
        *(.isr_table*);
    } >isr AT>rom
    /* Defino simbolos con valores numericos importantes para realizar la copia de ROM */
    _ISR_LOAD = LOADADDR(.isr_table); /* LMA del ISR */
    _ISR_SIZE = SIZEOF(.isr_table); /* size del ISR */


    /* Tablas de paginacion */
    .page_tables : ALIGN(16K)
    {
        _L1_PAGE_TABLES_INIT = .; /* Comienzo de la tabla de L1 */
        . += 4096*4; /* La primer tabla son 4096 entradas de 4 bytes cada una */
        _L2_PAGE_TABLES_INIT = .; /* Comienzo de las tablas de L2 */
    } > ram


    /*
    Un stack disitinto para cada modo
    */
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