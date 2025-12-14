		AREA Module7, CODE, READONLY
        EXPORT Calc_MedBill
        IMPORT PATIENT_ARRAY
        IMPORT BILLING_ARRAY
        IMPORT STAY_DAYS
        IMPORT MedListPointers    ; Array of pointers: [ML1, ML2, ML3]

Calc_MedBill
        PUSH {R4-R8, LR}
        MOV R0, #0                ; patient index
        MOV R8, #3                ; patient count

MedLoop
        CMP R0, R8
        BGE MedDone

        ; ----- GET MEDICINE LIST POINTER FROM MedListPointers -----
        ; Instead of reading from patient struct (which might be wrong)
        LDR R1, =MedListPointers   ; Array: [ML1, ML2, ML3]
        LDR R4, [R1, R0, LSL #2]   ; R4 = MedListPointers[index]
        ; This gets ML1 for patient 0, ML2 for patient 1, ML3 for patient 2

        ; ----- GET STAY DAYS -----
        LDR R5, =STAY_DAYS
        LDRB R6, [R5, R0]         ; stay_days[i]

        ; ----- PROCESS MEDICINE 1 -----
        LDR R7, [R4, #0]          ; price1
        LDR R5, [R4, #4]          ; qty1
        MUL R7, R7, R5            ; price1 × qty1
        MUL R7, R7, R6            ; × days
        MOV R5, R7                ; total = medicine1

        ; ----- PROCESS MEDICINE 2 (check if exists) -----
        LDR R7, [R4, #8]          ; price2
        CMP R7, #0                ; check for 0 (terminator)
        BEQ StoreResult
        
        LDR R3, [R4, #12]         ; qty2
        MUL R7, R7, R3            ; price2 × qty2
        MUL R7, R7, R6            ; × days
        ADD R5, R5, R7            ; total += medicine2

StoreResult
        ; ----- GET BILLING[i] ADDRESS -----
        LDR R7, =BILLING_ARRAY
        MOV R3, #16               ; billing struct size
        MUL R1, R0, R3
        ADD R7, R7, R1            ; R7 = &billing[i]

        ; ----- STORE AT OFFSET 8 -----
        STR R5, [R7, #0x08]

        ADD R0, R0, #1
        B MedLoop

MedDone
        POP {R4-R8, LR}
        BX LR
        END
