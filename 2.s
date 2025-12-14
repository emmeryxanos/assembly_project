		AREA Module2, CODE, READONLY
		EXPORT Second_Module
		IMPORT PATIENT_ARRAY
		IMPORT VITAL_INDEX
		IMPORT HR_SENSORS
		IMPORT O2_SENSORS
		IMPORT BP_SENSORS
		;IMPORT init_itm
		;IMPORT print_string
		;IMPORT print_number
		

Second_Module
    PUSH {R0-R12, LR}          ; Save ALL registers including R11-R12
    ;BL init_itm
   ; LDR R0, =debug_second_start
   ; BL print_string
    
    ; Arrays of sensor addresses
    LDR R0, =HR_SENSORS
    LDR R1, =BP_SENSORS
    LDR R2, =O2_SENSORS

    MOV R3, #0                ; patient index (0-2)

patient_loop
    CMP R3, #3
    BGE done

    ; ---------- Get patient struct address ----------
    LDR R4, =PATIENT_ARRAY     ; Base address
    MOV R5, #44               ; Patient struct size
    MUL R5, R3, R5            ; R5 = index * 44
    ADD R4, R4, R5            ; R4 = &PATIENT_ARRAY[index]

    ; ---------- Get current index for circular buffer ----------
    LDR R5, =VITAL_INDEX
    LDRB R6, [R5, R3]         ; R6 = current index (0-9)

    ; ---------- Get buffer pointers from patient struct ----------
    LDR R7, [R4, #24]         ; HR buffer pointer
    LDR R8, [R4, #28]         ; BP buffer pointer  
    LDR R9, [R4, #32]         ; O2 buffer pointer

    ; Check if buffers are valid
    CMP R7, #0
    BEQ skip_patient
    CMP R8, #0
    BEQ skip_patient
    CMP R9, #0
    BEQ skip_patient

    ; ---------- Read HR from sensor ----------
    LDR R10, [R0, R3, LSL #2]  ; R10 = address of HR sensor value
    LDR R11, [R10]             ; R11 = actual HR value
    
     ; Restore R11
    
    ; Store in buffer: HR_buffer[current_index]
    STR R11, [R7, R6, LSL #2]  ; offset = index * 4 bytes

    ; ---------- Read BP from sensor ----------
    LDR R10, [R1, R3, LSL #2]  ; BP sensor address
    LDR R11, [R10]             ; BP value
    STR R11, [R8, R6, LSL #2]  ; Store in BP buffer

    ; ---------- Read O2 from sensor ----------
    LDR R10, [R2, R3, LSL #2]  ; O2 sensor address
    LDR R11, [R10]             ; O2 value
    STR R11, [R9, R6, LSL #2]  ; Store in O2 buffer

    ; ---------- Update circular buffer index ----------
    ADD R6, R6, #1            ; Increment index
    CMP R6, #10               ; Check if >= 10
    BLT store_index
    MOV R6, #0               ; Wrap around to 0
    
store_index
    STRB R6, [R5, R3]        ; Store back to VITAL_INDEX array

skip_patient
    ADD R3, R3, #1           ; Next patient
    B patient_loop

done
    POP {R0-R12, LR}
    BX LR

  ;  ALIGN 4
;debug_second_start DCB "\r\n=== Second_Module Start ===", 0
;Debug_store        DCB "Storing Patient ", 0
;debug_store2       DCB " HR=", 0
;debug_store3       DCB " at index ", 0
;debug_store4       DCB " buffer@", 0

    END
