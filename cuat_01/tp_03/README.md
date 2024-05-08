# Descripción del proyecto

En este proyecto, se agrega la configuración de las interrupciones. El bootloader además de cargar el kernel, carga el ISR a el valor de memoria 0x00000000.
Se definen todos los handlers necesarios para el manejo de cualquier tipo de interrupción y se definen stacks para cada modo del procesador.
Cuando el programa entra a la sección de kernel, este habilita las interrupciones y produce una excepción con la instrucción SWI.

## Archivos:
- `src/bootloader.s`: Aca se encuentra el codigo de bootloader, las secciones definidas en este archivo se ejecutan sobre ROM. Es el punto de entrada del programa
- `src/kernel.s`: Aca (supuestamente) se encuentra el kernel, con el codigo de ejemplo para verificar el funcionamiento de las interrupciones.
- `src/interrupts.s`: Aca se encuentra el codigo necesario para el uso de las interrucpciones (Handlers y tabla ISR)


# Ejecución

Ejecutando el comando `make debug` genera el binario, lo comienza a ejecutar en `qemu` y abre `ddd` para debuggear.
La conexión de `gdb` y la configuración del registro `pc` se realiza automáticamente. Los comandos de `gdb` que se ejecutan para realizar esto se encuentran en `gdb_init_ddd.txt`.
Al completarse el comando (cuando `ddd` se cierra), el makefile automáticamente.**mata todos los procesos de `qemu`**.

Además, el comando `make debug_seer` ejecuta el programa con un front end diferente a `ddd`, llamado `seergdb`. Esto esta implementado para probar alternativas a `ddd` que ya se encuentra obsoleto.

 
