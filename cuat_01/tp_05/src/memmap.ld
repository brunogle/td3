OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

/*
Direcciones de comienzo de las distintas areas de memoria.

*/
_ISR_INIT = 0x00000000; 

_ROM_INIT = 0x70010000; 

_STACK_INIT = 0x70020000;

_RAM_INIT = 0x70030000;

/*
Tamaños de los distintos stacks
*/
C_STACK_SIZE   = 8K;
IRQ_STACK_SIZE = 8K;
FIQ_STACK_SIZE = 8K;
SVC_STACK_SIZE = 8K;
ABT_STACK_SIZE = 8K;
UND_STACK_SIZE = 8K;

/*
Tamaño reservado para tablas de paginacion
*/
PAGE_TABLE_SIZE = 64K;



MEMORY 
{
    isr(rwx) : org = _ISR_INIT, len = 0x40
    rom(rwx) : org = _ROM_INIT, len = 16k
    stack(rw) : org = _STACK_INIT, len = 48k
    ram(rwx) : org = _RAM_INIT, len = 8M
}


SECTIONS
{
    /*
    Esta es la unica seccion que tiene VMAs en la ROM.
    */
    .bootloader : ALIGN(4K)
    {
        *(.bootloader.main);
        *(.bootloader*);
    } >rom
    _BOOTLOADER_INIT = ADDR(.bootloader);
    _BOOTLOADER_SIZE = SIZEOF(.bootloader);

    /*
    Esta seccion contiene todo el codigo ademas del bootloader.
    El bootloader copiara toda la seccion a RAM para su ejecucion.
    */
    .text : ALIGN(4K)
    {
        *(.text*);
    } >ram AT>rom
    _TEXT_INIT = ADDR(.text); /* VMA de .text */
    _TEXT_LOAD = LOADADDR(.text); /* LMA de .text */
    _TEXT_SIZE = SIZEOF(.text); /* size de .text */

    /*
    Variables globales y estaticas no inicializadas.
    */
    .bss : ALIGN(4K)
    {
        *(.bss*)
    } > ram
    _BSS_INIT = ADDR(.bss);
    _BSS_SIZE = SIZEOF(.bss);


    /*
    Variables globales y estaticas inicializadas.
    Las definiciones son cargadas en ROM, pero son
    copiadas a RAM por el bootloader.
    */
    .data : ALIGN(4K)
    {
        *(.data*)
    } > ram AT>rom
    _DATA_INIT = ADDR(.data);
    _DATA_LOAD = LOADADDR(.data);
    _DATA_SIZE = SIZEOF(.data);

    /*
    Datos constantes.
    Los datos son cargados en ROM, pero son
    copiados a RAM por el bootloader.
    */
    .rodata : ALIGN(4K)
    {
        *(.rodata*)
    } > ram AT>rom
    _RODATA_INIT = ADDR(.data);
    _RODATA_LOAD = LOADADDR(.data);
    _RODATA_SIZE = SIZEOF(.data);


    /*
    Tabla de interrupciones.
    Es copiada a _ISR_INIT por el bootloader.
    */
    .isr_table : ALIGN(4K)
    {
        *(.isr_table*);
    } >isr AT>rom
    _ISR_LOAD = LOADADDR(.isr_table);
    _ISR_SIZE = SIZEOF(.isr_table);


    /*
    Tablas de paginacion.
    Son escritas por el kernel
    */
    .page_tables : ALIGN(16K)
    {
        _L1_PAGE_TABLES_INIT = .; /* Comienzo de la tabla de L1 */
        . += 4096*4; /* La primer tabla son 4096 entradas de 4 bytes cada una */
        _L2_PAGE_TABLES_INIT = .; /* Comienzo de las tablas de L2 */
        . += _L1_PAGE_TABLES_INIT + PAGE_TABLE_SIZE; /* Dejo espacio para la maxima cantidad posible de tablas de L2 */
    } > ram
    _PAGE_TABLES_INIT = ADDR(.page_tables);
    _PAGE_TABLES_SIZE = SIZEOF(.page_tables);


    /*
    Un stack disitinto para cada modo
    */
    .stack : ALIGN(4K)
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
        _STACK_INIT = ADDR(.stack);
        _STACK_SIZE = SIZEOF(.stack);


}