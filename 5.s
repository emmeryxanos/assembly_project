        AREA Module5, CODE, READONLY
        EXPORT Calc_TreatCost
        IMPORT PATIENT_ARRAY
        IMPORT BILLING_ARRAY
        IMPORT TREATMENT_TABLE
        IMPORT MAX_PATIENTS

Calc_TreatCost
        PUSH {R4-R10, LR}
        
        MOV R0, #0                  ; patient index
        MOV R10, #3
                 ; R10 = 3 (should be correct)
        
TreatLoop
        CMP R0, R10
        BGE TreatDone
        
        ; ----- PATIENT ADDRESS (hardcoded size 44) -----
        LDR R1, =PATIENT_ARRAY      ; Base
        MOV R2, #44                 ; HARDCODED patient struct size
        MUL R3, R0, R2
        ADD R1, R1, R3              ; R1 = &patient[i]
        
        ; ----- READ TREATMENT CODE -----
        LDRB R4, [R1, #12]          ; offset 12
        
        ; ----- GET COST FROM TABLE -----
        LSL R5, R4, #2              ; code * 4
        LDR R6, =TREATMENT_TABLE
        LDR R7, [R6, R5]            ; cost
        
        ; ----- BILLING ADDRESS (hardcoded size 16) -----
        LDR R8, =BILLING_ARRAY
        MOV R9, #16                 ; HARDCODED billing struct size
        MUL R3, R0, R9
        ADD R8, R8, R3              ; R8 = &billing[i]
        
        ; ----- STORE COST -----
        STR R7, [R8, #0]
        
        ADD R0, R0, #1
        B TreatLoop

TreatDone
        POP {R4-R10, LR}
        BX LR
        END
