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
		EXPORT MedListPointers
        EXPORT ML1
        EXPORT ML2  
        EXPORT ML3



First_module
    PUSH {R0-R9, LR}
	LDR R0, =VITAL_INDEX
    MOV R1, #0
    STRB R1, [R0, #0]
    STRB R1, [R0, #1]
    STRB R1, [R0, #2]
    MOV R3, #0        

    LDR R0, =PATIENT_ARRAY      ; Base of patient structs
    LDR R1, =MAX_PATIENTS
    LDR R1, [R1]               ; Number of patients (3)
    LDR R2, =PATIENT_SIZE
    LDR R2, [R2]               ; Size of one struct (44)

initLoop
    CMP R3, R1
    BEQ initDone

    ; R4 = &PATIENT[patient] = PATIENT_ARRAY + (index * 44)
    MOV R4, R3
    MUL R4, R4, R2             ; index * 44
    ADD R4, R0, R4             ; R4 = &patient_struct

    ; ---------- Patient ID ----------
    LDR R5, =RANDOM_IDS
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #0]

    ; ---------- Name pointer ----------
    LDR R5, =NameList
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #4]

    ; ---------- Age ----------
    LDR R5, =RANDOM_AGES
    LDRB R5, [R5, R3]
    STRB R5, [R4, #8]    ; Store age
    MOV R9, #0           ; ? USE R9 INSTEAD OF R0 FOR PADDING!
    STRB R9, [R4, #9]    ; Store padding at offset 9

    ; ---------- Ward ----------
    LDR R5, =RANDOM_WARDS
    LDRH R5, [R5, R3, LSL #1]
    STRH R5, [R4, #10]   ; Store ward (now properly aligned)

    ; ... rest of code stays the same ...
    ; ---------- Treatment code ----------
    LDR R5, =TREATMENT_CODES
    LDRB R5, [R5, R3]
    STRB R5, [R4, #12]
    
	
	    ; ADD PADDING BYTES 13, 14, 15
    MOV R9, #0
    STRB R9, [R4, #13]
    STRB R9, [R4, #14]
    STRB R9, [R4, #15]

    ; ---------- Room rate ----------
    LDR R5, =ROOM_RATES
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #16]

    ; ---------- Medicine list pointer ----------
    LDR R5, =MedListPointers
    LDR R5, [R5, R3, LSL #2]
    STR R5, [R4, #20]

    ; ---------- Vital buffer pointers ----------
    ; Each buffer is 40 bytes per patient (10 readings * 4 bytes)
    ; Offset = patient_index * 40
    MOV R5, R3
    MOV R6, #40                ; 10 readings * 4 bytes = 40
    MUL R5, R5, R6             ; R5 = patient_index * 40

    ; HR buffer pointer
    LDR R6, =HR_BUFFER
    ADD R7, R6, R5             ; HR_BUFFER + (index * 40)
    STR R7, [R4, #24]

    ; BP buffer pointer
    LDR R6, =BP_BUFFER
    ADD R7, R6, R5             ; BP_BUFFER + (index * 40)
    STR R7, [R4, #28]

    ; O2 buffer pointer
    LDR R6, =O2_BUFFER
    ADD R7, R6, R5             ; O2_BUFFER + (index * 40)
    STR R7, [R4, #32]

    ; Clear remaining struct bytes (offsets 36-43)
    MOV R5, #0
    STR R5, [R4, #36]          ; Clear 36-39
    STR R5, [R4, #40]          ; Clear 40-43

    ; ---------- Initialize alert count ----------
    LDR R6, =ALERT_COUNT_ARRAY
    MOV R7, #0
    STR R7, [R6, R3, LSL #2]

    ADD R3, R3, #1
    B initLoop

initDone
    POP {R0-R9, LR}
    BX LR

     AREA PatientData, DATA, READWRITE


;  Patient ID
RANDOM_IDS      DCD 143, 256, 187

;  Age
RANDOM_AGES     DCB 19, 28,23

;  Ward Number
RANDOM_WARDS    DCW 12, 22,7

; Treatment Code
TREATMENT_CODES DCB 2, 3, 1

;  Room Rate
ROOM_RATES      DCD 1500, 2300, 1800


; NAME LIST (pointers)

NameList        DCD Name1, Name2, Name3

Name1           DCB "RAIMA",0
Name2           DCB "AYMAN",0
Name3           DCB "TANVIR",0


; MEDICINE LIST POINTERS

; MEDICINE LIST POINTERS
MedListPointers DCD ML1, ML2, ML3

; Fixed medicine data (proper formatting, no spaces before commas)
ML1 DCD 500, 2, 300, 1, 0, 0      ; Patient 1: 2 medicines + terminator
ML2 DCD 800, 1, 400, 3, 0, 0      ; Patient 2: 2 medicines + terminator  
ML3 DCD 1500, 1, 0, 0, 0, 0       ; Patient 3: 1 medicine + terminator
        END
      
