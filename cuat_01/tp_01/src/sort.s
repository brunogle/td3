.global _start
.section .text


//Comienzo de codigo de test
_start:
	LDR R0, =data_destino
	LDR R1, =data_origen
	MOV R2, #10
	BL sort
end:
	B .
//Fin de codigo de test


// Subrutina sort. Implementado utilizando insertion sort.
// Ordena un array de words signados, escribe el resultado
// en otro array
//
// R0: Direccion de memoria destino
// R1: Direccion de memoria fuente
// R2: Largo del array
//
// Comienzo de codigo de sort
sort:
	// Multiplico R2 por 4 para que represente el
	//el largo del array en bytes.
	LSL R2, R2, #2 

	// Copio el array de origen al de destino
	PUSH {R0, R1, R2, LR}
	BL memcpy
	POP {R0, R1, R2, LR}

	MOV R3, #4 // R3: Posicion del elemento siendo reinsertado
	
sort_loop:
	// Reviso que todavia haya elementos por insertar
	CMP R3, R2
	BEQ sort_finished

	ADD R4, R3, R0 // R4: Posicion del elemento siendo comparado con el que se busca insertar

sort_insert:
	//Reviso si ya se llegó al principio del array, si llegó
	//es porque es el valor mas chico insertado por ahora
	CMP R4, R0
	BEQ sort_end_insert
	//Reviso si el valor se encuentra antes de un valor mas grande,
	//en ese caso termino de insertar el elemento.
	LDR R5, [R4, #-4]
	LDR R6, [R4]
	CMP R6, R5
	BGE sort_end_insert

	//Si el valor que se esta insertando no esta precedido por un valor mas chico,
	//hago un swap entre el valor siendo insertado, y el de la izquierda
	STR R6, [R4, #-4]
	STR R5, [R4]

	//Paso a revisar los pares de valores a la izquierda para revisar si hay que
	//seguir moviendo el valor que se insertando
	SUB R4, R4, #4
	B sort_insert

sort_end_insert:
	//Paso a insertar el siguiente elemento en la lista
	ADD R3, R3, #4
	B sort_loop

sort_finished:
	BX LR
//Fin de codigo de sort




// Subrutina memcpy
// Copia una cierta cantidad de bytes partiendo de una
// direccion dada de memoria a otra direccion de memoria
//
// r0: Direccion de memoria destino
// r1: Direccion de memoria fuente
// r2: Cantidad de bytes que se deben copiar
//
// Comienzo de codigo de memcpy
memcpy:
	CMP R2, #0
	BEQ memcpy_end

memcpy_loop:
	LDRB R3, [R1], #1
	STRB R3, [R0], #1
	SUBS R2, R2, #1
	BNE memcpy_loop

memcpy_end:
	BX LR
//Fin de codigo de memcpy



.section .data
data_origen: .word 1,0,-5,2,3,12,10,5,-10,3
data_destino: .word 0,0,0,0,0,0,0,0,0,0
