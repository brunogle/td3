# Descripción del proyecto

Este TP trata de una implementación de Insertion Sort en ARMv7.

Se implemento la subrutina `sort` que recibe los siguientes parametros mediante los siguientes registros:

- R0: Direccion de memoria destino
- R1: Direccion de memoria fuente
- R2: Largo del array

Esta subrutina lee el array de origen (interpreta la memoria como arrays de words signados), lo ordena y guarda el resultado en el array de destino

Se implementó un test case simple para verificar el funcionamiento.



# Ejecución

Ejecutando el comando `make debug` genera el binario, lo comienza a ejecutar en `qemu` y abre `ddd` para debuggear.
La conexión de `gdb` y la configuración del registro `pc` se realiza automáticamente. Los comandos de `gdb` que se ejecutan para realizar esto se encuentran en `gdb_init.txt`.
El comando tambien configura un breakpoint y imprime en la consola el array original y ordenado. 
Al completarse el comando (cuando `ddd` se cierra), el makefile automáticamente **mata todos los procesos de `qemu`**.

 
