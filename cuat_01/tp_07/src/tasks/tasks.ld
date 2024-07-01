
/*
Tamaño del stack de la tarea
*/
STACK_SIZE = 4K;


SECTIONS
{
    
    
    .text_task1 : ALIGN(4K)
    {
        *(.text.task1);
    } >ram AT>rom
    _TASK1_TEXT_INIT = ADDR(.text_task1);
    _TASK1_TEXT_LOAD = LOADADDR(.text_task1);
    _TASK1_TEXT_SIZE = SIZEOF(.text_task1);

    .data_task1 : ALIGN(4K)
    {
        *(.data.task1);
    } >ram  AT>rom
    _TASK1_DATA_INIT = ADDR(.data_task1);
    _TASK1_DATA_LOAD = LOADADDR(.data_task1);
    _TASK1_DATA_SIZE = SIZEOF(.data_task1);

    .stack_task1 : ALIGN(4K)
    {
        . += STACK_SIZE;
    } >ram
    _TASK1_STACK_INIT = ADDR(.stack_task1);
    _TASK1_STACK_SIZE = SIZEOF(.stack_task1);

    .bss_task1 : ALIGN(4K)
    {
        *(.bss.task1*);
    } >ram
    _TASK1_BSS_INIT = ADDR(.bss_task1);
    _TASK1_BSS_SIZE = SIZEOF(.bss_task1);

    .rodata_task1 : ALIGN(4K)
    {
        *(.rodata.task1*);
    } >ram AT>rom
    _TASK1_RODATA_INIT = ADDR(.rodata_task1);
    _TASK1_RODATA_LOAD = LOADADDR(.rodata_task1);
    _TASK1_RODATA_SIZE = SIZEOF(.rodata_task1);

    .readingArea_task1 0x70A00000 : ALIGN(4K)
    {
        *(.readingArea.task1);
    } >ram
    _TASK1_READINGAREA_INIT = ADDR(.readingArea_task1);
    _TASK1_READINGAREA_LOAD = LOADADDR(.readingArea_task1);
    _TASK1_READINGAREA_SIZE = SIZEOF(.readingArea_task1);



    .text_task2 : ALIGN(4K)
    {
        *(.text.task2);
    } >ram AT>rom
    _TASK2_TEXT_INIT = ADDR(.text_task2);
    _TASK2_TEXT_LOAD = LOADADDR(.text_task2);
    _TASK2_TEXT_SIZE = SIZEOF(.text_task2);

    .data_task2 : ALIGN(4K)
    {
        *(.data.task2);
    } >ram AT>rom
    _TASK2_DATA_INIT = ADDR(.data_task2);
    _TASK2_DATA_LOAD = LOADADDR(.data_task2);
    _TASK2_DATA_SIZE = SIZEOF(.data_task2);

    .stack_task2 : ALIGN(4K)
    {
        . += STACK_SIZE;
    } >ram
    _TASK2_STACK_INIT = ADDR(.stack_task2);
    _TASK2_STACK_SIZE = SIZEOF(.stack_task2);

    .bss_task2 : ALIGN(4K)
    {
        *(.bss.task2*);
    } >ram
    _TASK2_BSS_INIT = ADDR(.bss_task2);
    _TASK2_BSS_SIZE = SIZEOF(.bss_task2);

    .rodata_task2 : ALIGN(4K)
    {
        *(.rodata.task2*);
    } >ram AT>rom
    _TASK2_RODATA_INIT = ADDR(.rodata_task2);
    _TASK2_RODATA_LOAD = LOADADDR(.rodata_task2);
    _TASK2_RODATA_SIZE = SIZEOF(.rodata_task2);


    .readingArea_task2 0x70A10000 : ALIGN(4K)
    {
        *(.readingArea.task2);
    } >ram 
    _TASK2_READINGAREA_INIT = ADDR(.readingArea_task2);
    _TASK2_READINGAREA_LOAD = LOADADDR(.readingArea_task2);
    _TASK2_READINGAREA_SIZE = SIZEOF(.readingArea_task2);

}
