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
C_STACK_SIZE   = 4K;
IRQ_STACK_SIZE = 4K;
FIQ_STACK_SIZE = 4K;
SVC_STACK_SIZE = 4K;
ABT_STACK_SIZE = 4K;
UND_STACK_SIZE = 4K;

/*
Tamaño reservado para tablas de paginacion.
Minimo recomendado de 8K
*/
PAGE_TABLE_SIZE = 64K; 



MEMORY 
{
    isr(rwx) : org = _ISR_INIT, len = 0x40
    rom(rwx) : org = _ROM_INIT, len = 40k
    stack(rw) : org = _STACK_INIT, len = 40k
    ram(rwx) : org = _RAM_INIT, len = 0x1000000
}


SECTIONS
{
    /*
    Esta es la unica seccion que tiene VMAs en la ROM.
    */
    .bootloader :
    {
        *(.text.bootloader.start);
        *(.text.bootloader);
    } >rom
    _BOOTLOADER_INIT = ADDR(.bootloader);
    _BOOTLOADER_SIZE = SIZEOF(.bootloader);

    /*
    Esta seccion contiene todo el codigo excepto por el bootloader.
    El bootloader copiara toda la seccion a RAM para su ejecucion.
    */
    .text : ALIGN(4K)
    {
        *(.text.kernel);
    } >ram AT>rom
    _TEXT_INIT = ADDR(.text); /* VMA de .text */
    _TEXT_LOAD = LOADADDR(.text); /* LMA de .text */
    _TEXT_SIZE = SIZEOF(.text); /* size de .text */

    /*
    Variables globales y estaticas no inicializadas.
    */
    .bss : ALIGN(4K)
    {
        *(.bss);
    } >ram
    _BSS_INIT = ADDR(.bss);
    _BSS_SIZE = SIZEOF(.bss);

    /*
    Variables globales y estaticas inicializadas.
    Las definiciones son cargadas en ROM, pero son
    copiadas a RAM por el bootloader.
    */
    .data : ALIGN(4K)
    {
        *(.data);
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
        *(.rodata);
    } > ram AT>rom
    _RODATA_INIT = ADDR(.rodata);
    _RODATA_LOAD = LOADADDR(.rodata);
    _RODATA_SIZE = SIZEOF(.rodata);


    /*
    Tabla de interrupciones.
    Es copiada a _ISR_INIT por el bootloader.
    */
    .isr_table : ALIGN(4K)
    {
        *(.isr_table);
    } >isr AT>rom
    _ISR_LOAD = LOADADDR(.isr_table);
    _ISR_SIZE = SIZEOF(.isr_table);



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