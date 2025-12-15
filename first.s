		AREA Module1, CODE, READONLY
		EXPORT First_module
		IMPORT PATIENT_ARRAY
		IMPORT MAX_PATIENTS
		IMPORT PATIENT_SIZE
		IMPORT HR_BUFFER
		IMPORT BP_BUFFER
		IMPORT O2_BUFFER
		IMPORT ALERT_COUNT_ARRAY
		IMPORT VITAL_INDEX
		IMPORT MedListPointers
        IMPORT ML1
        IMPORT ML2  
        IMPORT ML3
		IMPORT RANDOM_IDS
        IMPORT RANDOM_AGES
        IMPORT RANDOM_WARDS
        IMPORT TREATMENT_CODES
        IMPORT ROOM_RATES
        IMPORT NameList
        IMPORT Name1
        IMPORT Name2
        IMPORT Name3


First_module
    PUSH {R0-R9, LR}
    
    ; Clear VITAL_INDEX array
    LDR R0, =VITAL_INDEX
    MOV R1, #0
    STRB R1, [R0, #0]
    STRB R1, [R0, #1]
    STRB R1, [R0, #2]
    
    ; Initialize loop variables
    MOV R3, #0                  ; patient index
        
    LDR R0, =PATIENT_ARRAY      ; Base of patient structs
    LDR R1, =MAX_PATIENTS
    LDR R1, [R1]                ; Number of patients (3)
    LDR R2, =PATIENT_SIZE
    LDR R2, [R2]                ; Size of one struct (44)

initLoop
    CMP R3, R1
    BEQ initDone

    ; R4 = &PATIENT[patient] = PATIENT_ARRAY + (index * 44)
    MOV R4, R3
    MUL R4, R4, R2              ; index * 44
    ADD R4, R0, R4              ; R4 = &patient_struct

    ; ---------- Patient ID ----------
    LDR R5, =RANDOM_IDS
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #0]

    ; ---------- Name pointer ----------
    LDR R5, =NameList
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #4]

    ; ---------- Age (byte at offset 8) ----------
    LDR R5, =RANDOM_AGES
    LDRB R5, [R5, R3]
    STRB R5, [R4, #8]           ; Store age byte
    
    ; Clear padding byte at offset 9
    MOV R6, #0
    STRB R6, [R4, #9]

    ; ---------- Ward (halfword at offset 10) ----------
    LDR R5, =RANDOM_WARDS
    LDRH R5, [R5, R3, LSL #1]   ; Load halfword
    STRH R5, [R4, #10]          ; Store halfword at offset 10

    ; ---------- Treatment code (byte at offset 12) ----------
    LDR R5, =TREATMENT_CODES
    LDRB R5, [R5, R3]
    STRB R5, [R4, #12]
    
    ; Clear padding bytes 13, 14, 15
    MOV R6, #0
    STRB R6, [R4, #13]
    STRB R6, [R4, #14]
    STRB R6, [R4, #15]

    ; ---------- Room rate (word at offset 16) ----------
    LDR R5, =ROOM_RATES
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #16]

    ; ---------- Medicine list pointer (word at offset 20) ----------
    LDR R5, =MedListPointers
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #20]

    ; ---------- Vital buffer pointers ----------
    ; Each buffer is 40 bytes per patient (10 readings * 4 bytes)
    ; Offset = patient_index * 40
    MOV R5, R3
    MOV R6, #40                 ; 10 readings * 4 bytes = 40
    MUL R5, R5, R6              ; R5 = patient_index * 40

    ; HR buffer pointer
    LDR R6, =HR_BUFFER
    ADD R7, R6, R5              ; HR_BUFFER + (index * 40)
    STR R7, [R4, #24]

    ; BP buffer pointer
    LDR R6, =BP_BUFFER
    ADD R7, R6, R5              ; BP_BUFFER + (index * 40)
    STR R7, [R4, #28]

    ; O2 buffer pointer
    LDR R6, =O2_BUFFER
    ADD R7, R6, R5              ; O2_BUFFER + (index * 40)
    STR R7, [R4, #32]

    ; Clear remaining struct bytes (offsets 36-43)
    MOV R5, #0
    STR R5, [R4, #36]           ; Clear 36-39
    STR R5, [R4, #40]           ; Clear 40-43

    ; ---------- Initialize alert count ----------
    LDR R6, =ALERT_COUNT_ARRAY
    MOV R7, #0
    STR R7, [R6, R3, LSL #2]

    ADD R3, R3, #1
    B initLoop

initDone
    POP {R0-R9, LR}
    BX LR

   END
